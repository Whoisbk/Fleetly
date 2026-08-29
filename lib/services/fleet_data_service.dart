import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../models/models.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

class FleetDataService extends ChangeNotifier {
  static FleetDataService? _instance;

  FleetDataService() {
    _instance = this;
  }

  bool _adminLoading = false;
  bool _driverLoading = false;
  bool _isSubmitting = false;
  String? _error;

  FleetSummary? _fleetSummary;
  List<UserProfile> _pendingDrivers = [];
  List<UserProfile> _allDrivers = [];
  List<Vehicle> _vehicles = [];
  List<AdminDriverDay> _fleetCheckIns = [];
  List<AdminExpense> _fleetExpenses = [];
  final Map<String, List<DriverDocument>> _documentsByDriver = {};
  PeriodReport? _weekReport;
  PeriodReport? _monthReport;
  List<ActivityEvent> _recentActivity = [];

  Vehicle? _assignedVehicle;
  DriverDay? _todayDriverDay;
  List<DriverDay> _recentDriverDays = [];
  List<Expense> _todayExpenses = [];
  final Map<String, List<Expense>> _expensesByDay = {};
  final Map<String, Vehicle?> _assignedVehicleByDriver = {};

  bool get adminLoading => _adminLoading;
  bool get driverLoading => _driverLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  FleetSummary? get fleetSummary => _fleetSummary;
  List<UserProfile> get pendingDrivers => _pendingDrivers;
  List<UserProfile> get allDrivers => _allDrivers;
  List<Vehicle> get vehicles => _vehicles;
  List<AdminDriverDay> get fleetCheckIns => _fleetCheckIns;
  List<AdminExpense> get fleetExpenses => _fleetExpenses;
  PeriodReport? get weekReport => _weekReport;
  PeriodReport? get monthReport => _monthReport;
  List<ActivityEvent> get recentActivity => _recentActivity;

  List<DriverDocument> documentsForDriver(String driverId) =>
      _documentsByDriver[driverId] ?? [];

  Vehicle? assignedVehicleForDriver(String driverId) =>
      _assignedVehicleByDriver[driverId];

  Vehicle? get assignedVehicle => _assignedVehicle;
  DriverDay? get todayDriverDay => _todayDriverDay;
  List<DriverDay> get recentDriverDays => _recentDriverDays;
  List<Expense> get todayExpenses => _todayExpenses;

  bool get _useSupabase =>
      AppConstants.isSupabaseConfigured && FirebaseService.isAvailable;

  // Static accessors for screens not yet wired to Provider (use cache or demo data)
  static Vehicle? get assignedVehicleOrNull => _instance?.assignedVehicle;

  static Vehicle get assignedVehicleStatic =>
      assignedVehicleOrNull ?? _demoVehicle;

  static DriverDay? get todayDriverDayOrNull => _instance?.todayDriverDay;

  static DriverDay get todayDriverDayStatic =>
      todayDriverDayOrNull ?? _demoTodayDriverDay;

  static List<DriverDay> get recentDriverDaysStatic =>
      _instance?.recentDriverDays.isNotEmpty == true
          ? _instance!.recentDriverDays
          : _demoRecentDriverDays;

  static List<Expense> get todayExpensesStatic =>
      _instance?.todayExpenses.isNotEmpty == true
          ? _instance!.todayExpenses
          : _demoTodayExpenses;

  static FleetSummary get fleetSummaryStatic =>
      _instance?.fleetSummary ?? _demoFleetSummary;

  static List<UserProfile> get pendingDriversStatic =>
      _instance?.pendingDrivers.isNotEmpty == true
          ? _instance!.pendingDrivers
          : _demoPendingDrivers;

  static List<DriverDocument> get driverDocuments => _demoDriverDocuments;

  static DriverDay? getDayById(String id) {
    if (_instance != null) {
      try {
        return _instance!.recentDriverDays.firstWhere((d) => d.id == id);
      } catch (_) {}
      if (_instance!.todayDriverDay?.id == id) return _instance!.todayDriverDay;
    }
    try {
      return _demoRecentDriverDays.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Expense> getExpensesForDay(String dayId) {
    if (_instance != null && _instance!._expensesByDay.containsKey(dayId)) {
      return _instance!._expensesByDay[dayId]!;
    }
    return _demoExpensesForDay(dayId);
  }

  Future<void> loadAdminDashboard() async {
    if (!_useSupabase) {
      _fleetSummary = _demoFleetSummary;
      _pendingDrivers = _demoPendingDrivers;
      _recentActivity = _demoActivity;
      notifyListeners();
      return;
    }

    _adminLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.client;

      final profiles = await client
          .from('profiles')
          .select('id, role, status')
          .eq('role', 'driver');

      final drivers = (profiles as List).cast<Map<String, dynamic>>();
      final totalDrivers = drivers.length;
      final activeDrivers =
          drivers.where((p) => p['status'] == 'approved').length;
      final pendingCount =
          drivers.where((p) => p['status'] == 'pending').length;
      final suspendedDrivers =
          drivers.where((p) => p['status'] == 'suspended').length;

      final today = _todayDateString();
      final todayDays = await client
          .from('driver_days')
          .select('id, total_earnings')
          .eq('date', today);

      final todayDayRows = (todayDays as List).cast<Map<String, dynamic>>();
      double todayEarnings = 0;
      final todayDayIds = <String>[];
      for (final day in todayDayRows) {
        todayEarnings += _amount(day['total_earnings']);
        todayDayIds.add(day['id'] as String);
      }

      double todayExpenses = 0;
      if (todayDayIds.isNotEmpty) {
        final todayExpenseRows = await client
            .from('expenses')
            .select('amount')
            .inFilter('driver_day_id', todayDayIds);

        for (final row in (todayExpenseRows as List).cast<Map<String, dynamic>>()) {
          todayExpenses += _amount(row['amount']);
        }
      }

      _fleetSummary = FleetSummary(
        totalDrivers: totalDrivers,
        activeDrivers: activeDrivers,
        pendingDrivers: pendingCount,
        suspendedDrivers: suspendedDrivers,
        todayEarnings: todayEarnings,
        todayExpenses: todayExpenses,
      );

      final pendingRows = await client
          .from('profiles')
          .select()
          .eq('role', 'driver')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _pendingDrivers = (pendingRows as List)
          .map((row) => UserProfile.fromJson(row as Map<String, dynamic>))
          .toList();

      await _loadRecentActivity();
      _error = null;
    } catch (e) {
      _error = 'Could not load dashboard: $e';
      _fleetSummary ??= _demoFleetSummary;
      _pendingDrivers = _demoPendingDrivers;
      _recentActivity = _demoActivity;
    } finally {
      _adminLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllDrivers() async {
    if (!_useSupabase) {
      _allDrivers = [
        ..._demoPendingDrivers,
        const UserProfile(
          id: 'd1',
          email: 'thabo@driver.com',
          firstName: 'Thabo',
          lastName: 'Molefe',
          phone: '0821234567',
          role: UserRole.driver,
          status: UserStatus.approved,
        ),
        const UserProfile(
          id: 'd2',
          email: 'mpho@driver.com',
          firstName: 'Mpho',
          lastName: 'Nkosi',
          phone: '0734567890',
          role: UserRole.driver,
          status: UserStatus.suspended,
        ),
      ];
      notifyListeners();
      return;
    }

    _adminLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('role', 'driver')
          .order('created_at', ascending: false);

      _allDrivers = (rows as List)
          .map((row) => UserProfile.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Could not load drivers: $e';
      _allDrivers = _demoPendingDrivers;
    } finally {
      _adminLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureDriverLoaded(String driverId) async {
    if (driverById(driverId) != null) return;

    if (!_useSupabase) {
      final fromPending = _pendingDrivers.where((d) => d.id == driverId);
      if (fromPending.isNotEmpty) {
        _allDrivers = [..._allDrivers, ...fromPending];
        notifyListeners();
      }
      return;
    }

    try {
      final row = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', driverId)
          .maybeSingle();

      if (row != null) {
        final profile = UserProfile.fromJson(row);
        if (!_allDrivers.any((d) => d.id == driverId)) {
          _allDrivers = [..._allDrivers, profile];
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Could not load driver: $e';
      notifyListeners();
    }
  }

  Future<void> loadDriverAssignment(String driverId) async {
    if (!_useSupabase) {
      _assignedVehicleByDriver[driverId] = _demoVehicle;
      notifyListeners();
      return;
    }

    try {
      final assignment = await SupabaseService.client
          .from('driver_vehicle')
          .select('vehicles(*)')
          .eq('driver_id', driverId)
          .isFilter('end_date', null)
          .maybeSingle();

      if (assignment != null && assignment['vehicles'] != null) {
        _assignedVehicleByDriver[driverId] =
            Vehicle.fromJson(assignment['vehicles'] as Map<String, dynamic>);
      } else {
        _assignedVehicleByDriver[driverId] = null;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Could not load vehicle assignment: $e';
      notifyListeners();
    }
  }

  Future<String?> assignVehicleToDriver({
    required String driverId,
    required String vehicleId,
  }) async {
    if (!_useSupabase) {
      final vehicle = vehicleById(vehicleId) ?? _demoVehicle;
      _assignedVehicleByDriver[driverId] = vehicle;
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final client = SupabaseService.client;
      final today = _todayDateString();

      await client
          .from('driver_vehicle')
          .update({'end_date': today})
          .eq('driver_id', driverId)
          .isFilter('end_date', null);

      await client.from('driver_vehicle').insert({
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'start_date': today,
      });

      await loadDriverAssignment(driverId);
      return null;
    } catch (e) {
      return 'Could not assign vehicle: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> updateDocumentStatus({
    required String documentId,
    required DocumentStatus status,
    String? rejectionReason,
  }) async {
    if (!_useSupabase) {
      for (final entry in _documentsByDriver.entries) {
        _documentsByDriver[entry.key] = entry.value
            .map((d) => d.id == documentId
                ? DriverDocument(
                    id: d.id,
                    driverId: d.driverId,
                    documentType: d.documentType,
                    filePath: d.filePath,
                    status: status,
                    uploadedAt: d.uploadedAt,
                    rejectionReason: rejectionReason,
                  )
                : d)
            .toList();
      }
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('driver_documents').update({
        'status': status.name,
        'rejection_reason': rejectionReason,
      }).eq('id', documentId);

      final driverId = _documentsByDriver.entries
          .where((e) => e.value.any((d) => d.id == documentId))
          .map((e) => e.key)
          .firstOrNull;

      if (driverId != null) {
        await loadDriverDocuments(driverId);
      }
      return null;
    } catch (e) {
      return 'Could not update document: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadDriverDocuments(String driverId) async {
    if (!_useSupabase) {
      _documentsByDriver[driverId] = _demoDriverDocuments
          .map((d) => DriverDocument(
                id: d.id,
                driverId: driverId,
                documentType: d.documentType,
                filePath: d.filePath,
                status: d.status,
                uploadedAt: d.uploadedAt,
              ))
          .toList();
      notifyListeners();
      return;
    }

    try {
      final rows = await SupabaseService.client
          .from('driver_documents')
          .select()
          .eq('driver_id', driverId);

      _documentsByDriver[driverId] = (rows as List)
          .map((row) => DriverDocument.fromJson(row as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Could not load documents: $e';
      notifyListeners();
    }
  }

  Future<String?> updateDriverStatus(String driverId, UserStatus status) async {
    if (!_useSupabase) {
      _allDrivers = _allDrivers
          .map((d) => d.id == driverId
              ? UserProfile(
                  id: d.id,
                  email: d.email,
                  firstName: d.firstName,
                  lastName: d.lastName,
                  phone: d.phone,
                  role: d.role,
                  status: status,
                  profilePhoto: d.profilePhoto,
                )
              : d)
          .toList();
      _pendingDrivers =
          _pendingDrivers.where((d) => d.id != driverId).toList();
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('profiles')
          .update({'status': status.name}).eq('id', driverId);
      await loadAdminDashboard();
      await loadAllDrivers();
      return null;
    } catch (e) {
      return 'Could not update driver: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> approveDriver(String driverId) =>
      updateDriverStatus(driverId, UserStatus.approved);

  Future<String?> rejectDriver(String driverId) =>
      updateDriverStatus(driverId, UserStatus.rejected);

  Future<String?> suspendDriver(String driverId) =>
      updateDriverStatus(driverId, UserStatus.suspended);

  Future<String?> reactivateDriver(String driverId) =>
      updateDriverStatus(driverId, UserStatus.approved);

  Future<void> loadAllVehicles() async {
    if (!_useSupabase) {
      _vehicles = [_demoVehicle, _demoVehicle2];
      notifyListeners();
      return;
    }

    _adminLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('vehicles')
          .select()
          .order('registration_number');

      _vehicles = (rows as List)
          .map((row) => Vehicle.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Could not load vehicles: $e';
      _vehicles = [_demoVehicle];
    } finally {
      _adminLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createVehicle({
    required String registrationNumber,
    required String make,
    required String model,
    int? year,
    String? color,
  }) async {
    if (!_useSupabase) {
      final vehicle = Vehicle(
        id: 'v-new-${DateTime.now().millisecondsSinceEpoch}',
        registrationNumber: registrationNumber,
        make: make,
        model: model,
        year: year,
        color: color,
      );
      _vehicles = [..._vehicles, vehicle];
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('vehicles').insert({
        'registration_number': registrationNumber.trim(),
        'make': make.trim(),
        'model': model.trim(),
        'year': year,
        'color': color?.trim().isEmpty == true ? null : color?.trim(),
      });
      await loadAllVehicles();
      return null;
    } catch (e) {
      return 'Could not create vehicle: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> updateVehicle({
    required String vehicleId,
    required String registrationNumber,
    required String make,
    required String model,
    int? year,
    String? color,
  }) async {
    if (!_useSupabase) {
      _vehicles = _vehicles
          .map((v) => v.id == vehicleId
              ? Vehicle(
                  id: v.id,
                  registrationNumber: registrationNumber,
                  make: make,
                  model: model,
                  year: year,
                  color: color,
                )
              : v)
          .toList();
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('vehicles').update({
        'registration_number': registrationNumber.trim(),
        'make': make.trim(),
        'model': model.trim(),
        'year': year,
        'color': color?.trim().isEmpty == true ? null : color?.trim(),
      }).eq('id', vehicleId);
      await loadAllVehicles();
      return null;
    } catch (e) {
      return 'Could not update vehicle: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> deleteVehicle(String vehicleId) async {
    if (!_useSupabase) {
      _vehicles = _vehicles.where((v) => v.id != vehicleId).toList();
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('vehicles').delete().eq('id', vehicleId);
      await loadAllVehicles();
      return null;
    } catch (e) {
      return 'Could not delete vehicle: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadFleetCheckIns() async {
    if (!_useSupabase) {
      _fleetCheckIns = _demoRecentDriverDays
          .map((day) => AdminDriverDay(
                day: day,
                driverName: 'Thabo Molefe',
                vehicleLabel: _demoVehicle.registrationNumber,
              ))
          .toList();
      notifyListeners();
      return;
    }

    _adminLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('driver_days')
          .select('*, profiles(first_name, last_name), vehicles(registration_number, make, model)')
          .order('date', ascending: false)
          .limit(50);

      final dayRows = (rows as List).cast<Map<String, dynamic>>();
      final dayIds = dayRows.map((d) => d['id'] as String).toList();
      final totals = await _expenseTotalsForDays(dayIds);

      _fleetCheckIns = dayRows.map((map) {
        final profile = map['profiles'] as Map<String, dynamic>?;
        final vehicle = map['vehicles'] as Map<String, dynamic>?;
        final first = profile?['first_name'] as String? ?? '';
        final last = profile?['last_name'] as String? ?? '';
        final reg = vehicle?['registration_number'] as String? ?? '';
        final make = vehicle?['make'] as String? ?? '';
        final model = vehicle?['model'] as String? ?? '';
        final vehicleLabel = reg.isNotEmpty ? reg : '$make $model'.trim();

        final dayRow = Map<String, dynamic>.from(map);
        dayRow.remove('profiles');
        dayRow.remove('vehicles');
        final id = dayRow['id'] as String;
        final t = totals[id];

        return AdminDriverDay(
          day: DriverDay.fromJson(
            dayRow,
            fuelTotal: t?.fuel ?? 0,
            expenseTotal: t?.other ?? 0,
          ),
          driverName: '$first $last'.trim(),
          vehicleLabel: vehicleLabel,
        );
      }).toList();
    } catch (e) {
      _error = 'Could not load check-ins: $e';
      _fleetCheckIns = [];
    } finally {
      _adminLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFleetExpenses() async {
    if (!_useSupabase) {
      _fleetExpenses = _demoTodayExpenses
          .map((e) => AdminExpense(
                expense: e,
                driverName: 'Thabo Molefe',
                dayDate: DateTime.now(),
              ))
          .toList();
      notifyListeners();
      return;
    }

    _adminLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('expenses')
          .select('*, profiles(first_name, last_name), driver_days(date)')
          .order('created_at', ascending: false)
          .limit(50);

      _fleetExpenses = (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        final profile = map['profiles'] as Map<String, dynamic>?;
        final day = map['driver_days'] as Map<String, dynamic>?;
        final first = profile?['first_name'] as String? ?? '';
        final last = profile?['last_name'] as String? ?? '';
        final dayDate = day?['date'] != null
            ? DateTime.parse(day!['date'] as String)
            : DateTime.now();
        return AdminExpense(
          expense: Expense.fromJson(map),
          driverName: '$first $last'.trim(),
          dayDate: dayDate,
        );
      }).toList();
    } catch (e) {
      _error = 'Could not load expenses: $e';
      _fleetExpenses = [];
    } finally {
      _adminLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReports() async {
    if (!_useSupabase) {
      _weekReport = const PeriodReport(
        label: 'Last 7 days',
        totalEarnings: 28500,
        totalExpenses: 6200,
        dayCount: 18,
        expenseCount: 42,
      );
      _monthReport = const PeriodReport(
        label: 'Last 30 days',
        totalEarnings: 112400,
        totalExpenses: 24800,
        dayCount: 72,
        expenseCount: 156,
      );
      notifyListeners();
      return;
    }

    _adminLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final weekStart = _dateString(now.subtract(const Duration(days: 6)));
      final monthStart = _dateString(now.subtract(const Duration(days: 29)));
      final today = _todayDateString();

      _weekReport = await _buildPeriodReport(
        label: 'Last 7 days',
        fromDate: weekStart,
        toDate: today,
      );
      _monthReport = await _buildPeriodReport(
        label: 'Last 30 days',
        fromDate: monthStart,
        toDate: today,
      );
    } catch (e) {
      _error = 'Could not load reports: $e';
    } finally {
      _adminLoading = false;
      notifyListeners();
    }
  }

  Future<PeriodReport> _buildPeriodReport({
    required String label,
    required String fromDate,
    required String toDate,
  }) async {
    final client = SupabaseService.client;

    final dayRows = await client
        .from('driver_days')
        .select('id, total_earnings')
        .gte('date', fromDate)
        .lte('date', toDate);

    final days = (dayRows as List).cast<Map<String, dynamic>>();
    double earnings = 0;
    final dayIds = <String>[];
    for (final day in days) {
      earnings += _amount(day['total_earnings']);
      dayIds.add(day['id'] as String);
    }

    double expenses = 0;
    int expenseCount = 0;
    if (dayIds.isNotEmpty) {
      final expenseRows = await client
          .from('expenses')
          .select('amount')
          .inFilter('driver_day_id', dayIds);

      for (final row in (expenseRows as List).cast<Map<String, dynamic>>()) {
        expenses += _amount(row['amount']);
        expenseCount++;
      }
    }

    return PeriodReport(
      label: label,
      totalEarnings: earnings,
      totalExpenses: expenses,
      dayCount: days.length,
      expenseCount: expenseCount,
    );
  }

  Future<Map<String, ({double fuel, double other})>> _expenseTotalsForDays(
    List<String> dayIds,
  ) async {
    if (dayIds.isEmpty) return {};

    final expenseRows = await SupabaseService.client
        .from('expenses')
        .select('driver_day_id, type, amount')
        .inFilter('driver_day_id', dayIds);

    final totals = <String, ({double fuel, double other})>{};
    for (final row in (expenseRows as List).cast<Map<String, dynamic>>()) {
      final dayId = row['driver_day_id'] as String;
      final type = row['type'] as String? ?? 'other';
      final amount = _amount(row['amount']);
      final current = totals[dayId] ?? (fuel: 0, other: 0);
      if (type == 'fuel') {
        totals[dayId] = (fuel: current.fuel + amount, other: current.other);
      } else {
        totals[dayId] = (fuel: current.fuel, other: current.other + amount);
      }
    }
    return totals;
  }

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  UserProfile? driverById(String id) {
    try {
      return _allDrivers.firstWhere((d) => d.id == id);
    } catch (_) {
      try {
        return _pendingDrivers.firstWhere((d) => d.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Vehicle? vehicleById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadDriverDashboard(String driverId) async {
    if (!_useSupabase) {
      _assignedVehicle = _demoVehicle;
      _todayDriverDay = _demoTodayDriverDay;
      _recentDriverDays = _demoRecentDriverDays;
      _todayExpenses = _demoTodayExpenses;
      notifyListeners();
      return;
    }

    _driverLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.client;

      final assignment = await client
          .from('driver_vehicle')
          .select('vehicles(*)')
          .eq('driver_id', driverId)
          .isFilter('end_date', null)
          .maybeSingle();

      if (assignment != null && assignment['vehicles'] != null) {
        _assignedVehicle =
            Vehicle.fromJson(assignment['vehicles'] as Map<String, dynamic>);
      } else {
        _assignedVehicle = null;
      }

      final today = _todayDateString();
      final todayRow = await client
          .from('driver_days')
          .select()
          .eq('driver_id', driverId)
          .eq('date', today)
          .maybeSingle();

      final dayRows = await client
          .from('driver_days')
          .select()
          .eq('driver_id', driverId)
          .order('date', ascending: false)
          .limit(10);

      final allDayRows = (dayRows as List).cast<Map<String, dynamic>>();
      final dayIds = allDayRows.map((d) => d['id'] as String).toList();

      Map<String, ({double fuel, double other})> totals = {};
      if (dayIds.isNotEmpty) {
        final expenseRows = await client
            .from('expenses')
            .select()
            .inFilter('driver_day_id', dayIds);

        for (final row in (expenseRows as List).cast<Map<String, dynamic>>()) {
          final dayId = row['driver_day_id'] as String;
          final type = row['type'] as String? ?? 'other';
          final amount = _amount(row['amount']);
          final current = totals[dayId] ?? (fuel: 0, other: 0);
          if (type == 'fuel') {
            totals[dayId] = (fuel: current.fuel + amount, other: current.other);
          } else {
            totals[dayId] = (fuel: current.fuel, other: current.other + amount);
          }
        }

        _expensesByDay.clear();
        for (final row in (expenseRows as List).cast<Map<String, dynamic>>()) {
          final dayId = row['driver_day_id'] as String;
          _expensesByDay.putIfAbsent(dayId, () => []).add(Expense.fromJson(row));
        }
      }

      _recentDriverDays = allDayRows
          .map((row) {
            final id = row['id'] as String;
            final t = totals[id];
            return DriverDay.fromJson(
              row,
              fuelTotal: t?.fuel ?? 0,
              expenseTotal: t?.other ?? 0,
            );
          })
          .toList();

      if (todayRow != null) {
        final id = todayRow['id'] as String;
        final t = totals[id];
        _todayDriverDay = DriverDay.fromJson(
          todayRow,
          fuelTotal: t?.fuel ?? 0,
          expenseTotal: t?.other ?? 0,
        );
        _todayExpenses = _expensesByDay[id] ?? [];
      } else {
        _todayDriverDay = null;
        _todayExpenses = [];
      }

      _error = null;
    } catch (e) {
      _error = 'Could not load dashboard: $e';
      _assignedVehicle ??= _demoVehicle;
      _todayDriverDay ??= _demoTodayDriverDay;
      _recentDriverDays = _demoRecentDriverDays;
      _todayExpenses = _demoTodayExpenses;
    } finally {
      _driverLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecentActivity() async {
    final client = SupabaseService.client;
    final timeFmt = DateFormat('HH:mm');
    final timedEvents = <({DateTime at, ActivityEvent event})>[];

    final recentCheckIns = await client
        .from('driver_days')
        .select('started_at, profiles(first_name)')
        .not('started_at', 'is', null)
        .order('started_at', ascending: false)
        .limit(5);

    for (final row in (recentCheckIns as List).cast<Map<String, dynamic>>()) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final name = profile?['first_name'] as String? ?? 'Driver';
      final startedAt = _parseDateTime(row['started_at']);
      if (startedAt == null) continue;
      timedEvents.add((
        at: startedAt,
        event: ActivityEvent(
          title: '$name checked in',
          timeLabel: timeFmt.format(startedAt),
          category: ActivityCategory.checkIn,
        ),
      ));
    }

    final recentExpenses = await client
        .from('expenses')
        .select('type, amount, created_at, profiles(first_name)')
        .order('created_at', ascending: false)
        .limit(5);

    for (final row in (recentExpenses as List).cast<Map<String, dynamic>>()) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final name = profile?['first_name'] as String? ?? 'Driver';
      final type = row['type'] as String? ?? 'other';
      final amount = _amount(row['amount']);
      final createdAt = _parseDateTime(row['created_at']);
      if (createdAt == null) continue;

      final category = switch (type) {
        'fuel' => ActivityCategory.fuel,
        'maintenance' => ActivityCategory.maintenance,
        _ => ActivityCategory.other,
      };
      final label = switch (type) {
        'fuel' => 'fuel',
        'maintenance' => 'maintenance',
        _ => 'expense',
      };

      timedEvents.add((
        at: createdAt,
        event: ActivityEvent(
          title: '$name added $label R${amount.toStringAsFixed(0)}',
          timeLabel: timeFmt.format(createdAt),
          category: category,
        ),
      ));
    }

    timedEvents.sort((a, b) => b.at.compareTo(a.at));
    _recentActivity = timedEvents.take(5).map((e) => e.event).toList();
  }

  /// Start today's driver day (check-in). Returns null on success, error message on failure.
  Future<String?> startDay({
    required String driverId,
    required String vehicleId,
    required int startingOdometer,
  }) async {
    if (!_useSupabase) {
      _todayDriverDay = DriverDay(
        id: 'day-today',
        driverId: driverId,
        vehicleId: vehicleId,
        date: DateTime.now(),
        startedAt: DateTime.now(),
        startingOdometer: startingOdometer,
        status: DriverDayStatus.active,
      );
      _recentDriverDays = [_todayDriverDay!, ..._recentDriverDays.where((d) => d.id != 'day-today')];
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.client;
      final today = _todayDateString();

      final existing = await client
          .from('driver_days')
          .select('id, status')
          .eq('driver_id', driverId)
          .eq('date', today)
          .maybeSingle();

      if (existing != null) {
        return existing['status'] == 'active'
            ? 'You already have an active day today'
            : 'Today\'s day is already completed';
      }

      await client.from('driver_days').insert({
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'date': today,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'starting_odometer': startingOdometer,
        'status': 'active',
      });

      await loadDriverDashboard(driverId);
      return null;
    } catch (e) {
      return 'Could not start day: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// End and submit the active driver day. Returns null on success.
  Future<String?> endDay({
    required String driverId,
    required String driverDayId,
    required int endingOdometer,
    String? notes,
  }) async {
    if (!_useSupabase) {
      final today = _todayDriverDay;
      if (today == null) return 'No active day to submit';
      _todayDriverDay = DriverDay(
        id: today.id,
        driverId: today.driverId,
        vehicleId: today.vehicleId,
        date: today.date,
        startedAt: today.startedAt,
        endedAt: DateTime.now(),
        startingOdometer: today.startingOdometer,
        endingOdometer: endingOdometer,
        totalEarnings: today.totalEarnings,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        status: DriverDayStatus.completed,
        fuelTotal: today.fuelTotal,
        expenseTotal: today.expenseTotal,
      );
      _recentDriverDays = _recentDriverDays
          .map((d) => d.id == driverDayId ? _todayDriverDay! : d)
          .toList();
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('driver_days').update({
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'ending_odometer': endingOdometer,
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        'status': 'completed',
      }).eq('id', driverDayId).eq('driver_id', driverId);

      await loadDriverDashboard(driverId);
      return null;
    } catch (e) {
      return 'Could not submit day: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Set total earnings for today's active day. Returns null on success.
  Future<String?> updateEarnings({
    required String driverId,
    required String driverDayId,
    required double amount,
  }) async {
    if (!_useSupabase) {
      final today = _todayDriverDay;
      if (today == null) return 'No active day';
      _todayDriverDay = DriverDay(
        id: today.id,
        driverId: today.driverId,
        vehicleId: today.vehicleId,
        date: today.date,
        startedAt: today.startedAt,
        startingOdometer: today.startingOdometer,
        totalEarnings: amount,
        notes: today.notes,
        status: today.status,
        fuelTotal: today.fuelTotal,
        expenseTotal: today.expenseTotal,
      );
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('driver_days').update({
        'total_earnings': amount,
      }).eq('id', driverDayId).eq('driver_id', driverId);

      await loadDriverDashboard(driverId);
      return null;
    } catch (e) {
      return 'Could not save earnings: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Add a fuel or other expense entry. Returns null on success.
  Future<String?> addExpenseEntry({
    required String driverId,
    required String driverDayId,
    required String vehicleId,
    required ExpenseType type,
    required double amount,
    String? description,
  }) async {
    if (!_useSupabase) {
      final expense = Expense(
        id: 'e-new-${DateTime.now().millisecondsSinceEpoch}',
        driverDayId: driverDayId,
        type: type,
        amount: amount,
        description: description,
      );
      _todayExpenses = [..._todayExpenses, expense];
      _expensesByDay.putIfAbsent(driverDayId, () => []).add(expense);

      final today = _todayDriverDay;
      if (today != null) {
        final fuel = type == ExpenseType.fuel
            ? today.fuelTotal + amount
            : today.fuelTotal;
        final other = type != ExpenseType.fuel
            ? today.expenseTotal + amount
            : today.expenseTotal;
        _todayDriverDay = DriverDay(
          id: today.id,
          driverId: today.driverId,
          vehicleId: today.vehicleId,
          date: today.date,
          startedAt: today.startedAt,
          startingOdometer: today.startingOdometer,
          totalEarnings: today.totalEarnings,
          notes: today.notes,
          status: today.status,
          fuelTotal: fuel,
          expenseTotal: other,
        );
      }
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseService.client.from('expenses').insert({
        'driver_day_id': driverDayId,
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'type': type.name,
        'amount': amount,
        'description': description?.trim().isEmpty == true ? null : description?.trim(),
      });

      await loadDriverDashboard(driverId);
      return null;
    } catch (e) {
      return 'Could not save expense: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  static double parseAmount(String value) =>
      double.parse(value.replaceAll(',', '').trim());

  static int parseOdometer(String value) =>
      int.parse(value.replaceAll(',', '').trim());

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  double _amount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  // Demo fallbacks when Supabase is not configured
  static const _demoVehicle = Vehicle(
    id: 'v1',
    registrationNumber: 'ND 123-456',
    make: 'Toyota',
    model: 'Quantum',
    year: 2019,
    color: 'White',
  );

  static const _demoVehicle2 = Vehicle(
    id: 'v2',
    registrationNumber: 'ND 789-012',
    make: 'Toyota',
    model: 'Hiace',
    year: 2021,
    color: 'Silver',
  );

  static DriverDay get _demoTodayDriverDay => DriverDay(
        id: 'day-today',
        driverId: 'demo-driver',
        vehicleId: _demoVehicle.id,
        date: DateTime.now(),
        startedAt: DateTime.now().subtract(const Duration(hours: 3)),
        startingOdometer: 123450,
        totalEarnings: 1850,
        fuelTotal: 350,
        expenseTotal: 1200,
        status: DriverDayStatus.active,
        notes: 'Busy day on Main Road route',
      );

  static List<DriverDay> get _demoRecentDriverDays => [
        _demoTodayDriverDay,
        DriverDay(
          id: 'day-1',
          driverId: 'demo-driver',
          vehicleId: _demoVehicle.id,
          date: DateTime.now().subtract(const Duration(days: 1)),
          totalEarnings: 1620,
          fuelTotal: 300,
          expenseTotal: 0,
          status: DriverDayStatus.completed,
          startingOdometer: 123100,
          endingOdometer: 123450,
        ),
        DriverDay(
          id: 'day-2',
          driverId: 'demo-driver',
          vehicleId: _demoVehicle.id,
          date: DateTime.now().subtract(const Duration(days: 2)),
          totalEarnings: 1940,
          fuelTotal: 400,
          expenseTotal: 250,
          status: DriverDayStatus.completed,
          startingOdometer: 122800,
          endingOdometer: 123100,
        ),
      ];

  static List<Expense> get _demoTodayExpenses => [
        Expense(
          id: 'e1',
          driverDayId: 'day-today',
          type: ExpenseType.fuel,
          amount: 350,
          description: 'Shell — 25.4L',
        ),
        Expense(
          id: 'e2',
          driverDayId: 'day-today',
          type: ExpenseType.maintenance,
          amount: 1200,
          description: 'Replaced brake pads',
        ),
      ];

  static const _demoFleetSummary = FleetSummary(
    totalDrivers: 24,
    activeDrivers: 20,
    pendingDrivers: 2,
    suspendedDrivers: 2,
    todayEarnings: 42850,
    todayExpenses: 8450,
  );

  static const _demoPendingDrivers = [
    UserProfile(
      id: 'p1',
      email: 'sipho@driver.com',
      firstName: 'Sipho',
      lastName: 'Dlamini',
      phone: '0729876543',
      role: UserRole.driver,
      status: UserStatus.pending,
    ),
    UserProfile(
      id: 'p2',
      email: 'mpho@driver.com',
      firstName: 'Mpho',
      lastName: 'Nkosi',
      phone: '0734567890',
      role: UserRole.driver,
      status: UserStatus.pending,
    ),
  ];

  static const _demoActivity = [
    ActivityEvent(
      title: 'Thabo checked in',
      timeLabel: '08:02',
      category: ActivityCategory.checkIn,
    ),
    ActivityEvent(
      title: 'Mpho added fuel R350',
      timeLabel: '09:15',
      category: ActivityCategory.fuel,
    ),
    ActivityEvent(
      title: 'Sipho added maintenance R1,200',
      timeLabel: '11:30',
      category: ActivityCategory.maintenance,
    ),
  ];

  static List<DriverDocument> get _demoDriverDocuments => [
        DriverDocument(
          id: 'doc-1',
          driverId: 'demo-driver',
          documentType: DocumentType.id,
          filePath: 'drivers/demo-driver/id.pdf',
          status: DocumentStatus.approved,
          uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        DriverDocument(
          id: 'doc-2',
          driverId: 'demo-driver',
          documentType: DocumentType.pdp,
          filePath: 'drivers/demo-driver/pdp.pdf',
          status: DocumentStatus.approved,
          uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

  static List<Expense> _demoExpensesForDay(String dayId) {
    if (dayId == 'day-today') return _demoTodayExpenses;
    if (dayId == 'day-1') {
      return [
        const Expense(
          id: 'e3',
          driverDayId: 'day-1',
          type: ExpenseType.fuel,
          amount: 300,
          description: 'Engen',
        ),
      ];
    }
    if (dayId == 'day-2') {
      return [
        const Expense(
          id: 'e4',
          driverDayId: 'day-2',
          type: ExpenseType.fuel,
          amount: 400,
          description: 'Shell',
        ),
        const Expense(
          id: 'e5',
          driverDayId: 'day-2',
          type: ExpenseType.other,
          amount: 250,
          description: 'Car wash',
        ),
      ];
    }
    return [];
  }
}
