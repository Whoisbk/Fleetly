import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

enum LocationSettingsTarget { none, app, device }

class LocationGate {
  const LocationGate.ok()
      : message = null,
        settings = LocationSettingsTarget.none;

  const LocationGate.blocked(this.message, this.settings);

  final String? message;
  final LocationSettingsTarget settings;

  bool get granted => message == null;
}

/// Accumulates driven distance from GPS while a driver day is active.
///
/// Points are filtered so a parked phone and a bad GPS jump do not inflate
/// the total. The running total is saved on the device and copied to
/// `driver_days.distance_km` so it survives the app being closed.
class DistanceTrackingService extends ChangeNotifier {
  static const _prefsKey = 'active_distance_track';
  static const _minMoveMeters = 20.0;
  static const _maxAccuracyMeters = 65.0;
  static const _maxSpeedMps = 45.0;

  String? _driverDayId;
  int _session = 0;
  double _meters = 0;
  bool _listening = false;
  bool _hasFix = false;
  String? _warning;
  Position? _last;
  StreamSubscription<Position>? _subscription;
  Timer? _syncTimer;
  bool _dirty = false;
  bool _syncing = false;

  String? get driverDayId => _driverDayId;
  double get distanceKm => _meters / 1000;
  bool get isTracking => _listening;
  bool get hasFix => _hasFix;
  String? get warning => _warning;

  /// Live kilometres for [dayId], or the stored value when this device is
  /// not currently tracking that day.
  double kmForDay(String dayId, double storedKm) {
    if (_driverDayId != dayId) return storedKm;
    return distanceKm > storedKm ? distanceKm : storedKm;
  }

  Future<LocationGate> ensureReady() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationGate.blocked(
          'Turn on location services so the trip distance can be tracked.',
          LocationSettingsTarget.device,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationGate.blocked(
          'Location is blocked. Enable it in Settings, then start your day.',
          LocationSettingsTarget.app,
        );
      }
      if (permission == LocationPermission.denied) {
        return const LocationGate.blocked(
          'Location permission is required to track kilometres automatically.',
          LocationSettingsTarget.none,
        );
      }
      if (permission == LocationPermission.unableToDetermine) {
        return const LocationGate.blocked(
          'Could not check location permission. Try again.',
          LocationSettingsTarget.none,
        );
      }
      return const LocationGate.ok();
    } catch (e) {
      debugPrint('Location permission check failed: $e');
      return const LocationGate.blocked(
        'Could not access location. Try again.',
        LocationSettingsTarget.none,
      );
    }
  }

  /// Begin or resume tracking for an active driver day.
  Future<void> start({
    required String driverDayId,
    required double serverKm,
  }) async {
    if (_driverDayId == driverDayId && _listening) return;

    if (_driverDayId != null && _driverDayId != driverDayId) {
      await finish();
    }

    _driverDayId = driverDayId;
    await _restore(driverDayId);
    final serverMeters = serverKm * 1000;
    if (serverMeters > _meters) _meters = serverMeters;
    notifyListeners();
    await _listen();
    _scheduleSync();
  }

  /// Stop the GPS stream without discarding the distance (used if submit fails).
  Future<void> pause() async {
    await _subscription?.cancel();
    _subscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    if (_listening) {
      _listening = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_driverDayId == null || _listening) return;
    await _listen();
    _scheduleSync();
  }

  /// Stop tracking and forget the local session after the day is submitted.
  Future<void> finish() async {
    _session++;
    await pause();
    _driverDayId = null;
    _meters = 0;
    _last = null;
    _hasFix = false;
    _warning = null;
    _dirty = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> _listen() async {
    await _subscription?.cancel();
    _subscription = null;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _listening = false;
        _warning = 'Location is off. Turn it on so distance can be tracked.';
        notifyListeners();
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _listening = false;
        _warning =
            'Location permission is off, so distance is not being tracked.';
        notifyListeners();
        return;
      }

      _subscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings(),
      ).listen(
        _onPosition,
        onError: (Object error) {
          debugPrint('Location stream error: $error');
          _warning = 'Waiting for a GPS signal.';
          notifyListeners();
        },
      );
      _listening = true;
      _warning = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Could not start location tracking: $e');
      _listening = false;
      _warning = 'Could not start location tracking.';
      notifyListeners();
    }
  }

  void _onPosition(Position position) {
    if (position.isMocked) {
      _warning =
          'Fake GPS is on. Turn it off so the real distance is recorded.';
      notifyListeners();
      return;
    }

    if (position.accuracy > _maxAccuracyMeters) return;

    final previous = _last;
    if (previous == null) {
      _last = position;
      _hasFix = true;
      _warning = null;
      _persist();
      notifyListeners();
      return;
    }

    final meters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );
    final seconds =
        position.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
    if (seconds <= 0) return;

    if (meters / seconds > _maxSpeedMps) {
      if (position.accuracy <= previous.accuracy) _last = position;
      return;
    }

    if (meters < _minMoveMeters) return;

    _meters += meters;
    _last = position;
    _hasFix = true;
    _warning = null;
    _dirty = true;
    _persist();
    notifyListeners();
  }

  LocationSettings _locationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Fleetly is tracking your trip',
          notificationText: 'Distance is recorded until you end your day',
          notificationChannelName: 'Trip distance',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 20,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sync());
  }

  Future<void> _sync() async {
    final dayId = _driverDayId;
    if (dayId == null || !_dirty || _syncing) return;
    if (!AppConstants.isSupabaseConfigured || !FirebaseService.isAvailable) {
      return;
    }

    _syncing = true;
    final km = double.parse((_meters / 1000).toStringAsFixed(2));
    try {
      await SupabaseService.client
          .from('driver_days')
          .update({
            'distance_km': km,
          })
          .eq('id', dayId)
          .eq('status', 'active');
      _dirty = false;
    } catch (e) {
      debugPrint('Distance sync failed: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _restore(String driverDayId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['dayId'] != driverDayId) return;
      final meters = map['meters'];
      if (meters is num && meters > _meters) _meters = meters.toDouble();
      _last = _positionFromMap(map);
      _hasFix = _last != null || _meters > 0;
    } catch (e) {
      debugPrint('Could not restore distance session: $e');
    }
  }

  Future<void> _persist() async {
    final dayId = _driverDayId;
    final session = _session;
    if (dayId == null) return;
    final last = _last;
    final meters = _meters;
    final prefs = await SharedPreferences.getInstance();
    if (session != _session || _driverDayId != dayId) return;
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'dayId': dayId,
        'meters': meters,
        'lat': last?.latitude,
        'lng': last?.longitude,
        'accuracy': last?.accuracy,
        'at': last?.timestamp.toIso8601String(),
      }),
    );
  }

  Position? _positionFromMap(Map<dynamic, dynamic> map) {
    final lat = map['lat'];
    final lng = map['lng'];
    final at = map['at'];
    if (lat is! num || lng is! num || at is! String) return null;
    final timestamp = DateTime.tryParse(at);
    if (timestamp == null) return null;
    final accuracy = map['accuracy'];
    return Position(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      timestamp: timestamp,
      accuracy: accuracy is num ? accuracy.toDouble() : 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
