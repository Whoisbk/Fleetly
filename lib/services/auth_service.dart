import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/models.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _hasCompletedOnboarding = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get awaitingEmailConfirmation => false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get needsOnboarding =>
      _currentUser != null &&
      !_currentUser!.isAdmin &&
      _currentUser!.status == UserStatus.pending &&
      !_hasCompletedOnboarding;

  bool get _useFirebase =>
      FirebaseService.isAvailable && AppConstants.isSupabaseConfigured;

  Future<void> initialize() async {
    if (!_useFirebase) return;

    final user = FirebaseService.auth.currentUser;
    if (user != null) {
      await user.getIdToken(true);
      await _loadOrCreateProfile(
        userId: user.uid,
        email: user.email,
      );
    }

    FirebaseService.auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
        _hasCompletedOnboarding = false;
        notifyListeners();
        return;
      }
      await _loadOrCreateProfile(userId: user.uid, email: user.email);
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _error = null;

    try {
      if (!_useFirebase) {
        _currentUser = _demoUserForEmail(email);
        _hasCompletedOnboarding = _currentUser!.id != 'demo-driver-new';
        notifyListeners();
        return true;
      }

      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _error = 'Sign in failed. Please try again.';
        notifyListeners();
        return false;
      }

      await user.getIdToken(true);
      await _loadOrCreateProfile(
          userId: user.uid, email: user.email ?? email.trim());
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      if (!_useFirebase) {
        _hasCompletedOnboarding = false;
        _currentUser = UserProfile(
          id: 'demo-driver-new',
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          role: UserRole.driver,
          status: UserStatus.pending,
        );
        notifyListeners();
        return true;
      }

      final credential =
          await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _error = 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      }

      await user.updateDisplayName('$firstName $lastName');
      // Refresh token so Supabase gets the `role: authenticated` Firebase claim
      await user.getIdToken(true);

      await _loadOrCreateProfile(
        userId: user.uid,
        email: email.trim(),
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = _currentUser;
      if (user == null) {
        _error = 'Not signed in.';
        notifyListeners();
        return false;
      }

      final trimmedFirst = firstName.trim();
      final trimmedLast = lastName.trim();
      final trimmedPhone = phone.trim();

      if (!_useFirebase) {
        _currentUser = UserProfile(
          id: user.id,
          email: user.email,
          firstName: trimmedFirst,
          lastName: trimmedLast,
          phone: trimmedPhone,
          role: user.role,
          status: user.status,
          profilePhoto: user.profilePhoto,
        );
        notifyListeners();
        return true;
      }

      await SupabaseService.client.from('profiles').update({
        'first_name': trimmedFirst,
        'last_name': trimmedLast,
        'phone': trimmedPhone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      final firebaseUser = FirebaseService.auth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName('$trimmedFirst $trimmedLast'.trim());
      }

      _currentUser = UserProfile(
        id: user.id,
        email: user.email,
        firstName: trimmedFirst,
        lastName: trimmedLast,
        phone: trimmedPhone,
        role: user.role,
        status: user.status,
        profilePhoto: user.profilePhoto,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Could not update profile: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      if (!_useFirebase) {
        return true;
      }

      final user = FirebaseService.auth.currentUser;
      final email = user?.email;
      if (user == null || email == null || email.isEmpty) {
        _error = 'Not signed in.';
        notifyListeners();
        return false;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await user.getIdToken(true);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseAuthError(e, changingPassword: true);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _mapFirebaseAuthError(e, changingPassword: true);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _error = null;

    try {
      if (!_useFirebase) {
        _error = 'Password reset is not available in demo mode.';
        notifyListeners();
        return false;
      }

      await FirebaseService.auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      // Do not reveal whether an account exists.
      if (e.code == 'user-not-found') {
        return true;
      }
      _error = _mapFirebaseAuthError(e, resettingPassword: true);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _mapFirebaseAuthError(e, resettingPassword: true);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (_useFirebase) {
      await FirebaseService.auth.signOut();
    }
    _currentUser = null;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> _loadOrCreateProfile({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      var data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        final firebaseUser = FirebaseService.auth.currentUser;
        final displayName = firebaseUser?.displayName ?? '';
        final nameParts = displayName.split(' ');

        final profileData = {
          'id': userId,
          'email': email ?? firebaseUser?.email ?? '',
          'first_name':
              firstName ?? (nameParts.isNotEmpty ? nameParts.first : ''),
          'last_name': lastName ??
              (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''),
          'phone': phone ?? '',
          'role': 'driver',
          'status': 'pending',
        };

        try {
          await SupabaseService.client.from('profiles').insert(profileData);
        } on PostgrestException catch (e) {
          if (e.code != '23505') rethrow;
        }

        data = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      }

      if (data == null) {
        _error = 'Could not set up your profile. Please try signing in again.';
        _currentUser = null;
        notifyListeners();
        return;
      }

      _currentUser = _profileFromJson(data);
      await _refreshOnboardingStatus(userId);
      _error = null;
      notifyListeners();
    } catch (e) {
      final message = e.toString();
      if (message.contains('profiles') && message.contains('PGRST205')) {
        _error =
            'Database not set up yet. Run supabase/migrations in your Supabase SQL Editor.';
      } else if (message.contains('22P02') ||
          message.contains('invalid input syntax for type uuid')) {
        _error =
            'Database still expects UUID IDs. Run supabase/migrations/004_firebase_auth.sql in the Supabase SQL Editor, then sign in again.';
      } else if (message.contains('42501') ||
          message.contains('permission denied')) {
        _error =
            'Profile access blocked. Run migration 004_firebase_auth.sql and link Firebase under Authentication → Third-party Auth.';
      } else {
        _error = 'Could not load profile: $e';
      }
      _currentUser = null;
      notifyListeners();
    }
  }

  UserProfile _profileFromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _parseRole(json['role'] as String?),
      status: _parseStatus(json['status'] as String?),
      profilePhoto: json['profile_photo'] as String?,
    );
  }

  Future<void> _refreshOnboardingStatus(String userId) async {
    final user = _currentUser;
    if (user == null || user.isAdmin || user.status != UserStatus.pending) {
      _hasCompletedOnboarding = true;
      return;
    }

    if (!_useFirebase) {
      return;
    }

    try {
      final rows = await SupabaseService.client
          .from('driver_documents')
          .select('document_type')
          .eq('driver_id', userId);

      final types = <String>{};
      for (final row in rows as List) {
        final type = (row as Map)['document_type'] as String?;
        if (type != null) types.add(type);
      }
      _hasCompletedOnboarding = types.contains('id') && types.contains('pdp');
    } catch (_) {
      _hasCompletedOnboarding = false;
    }
  }

  UserRole _parseRole(String? role) => switch (role) {
        'admin' => UserRole.admin,
        _ => UserRole.driver,
      };

  UserStatus _parseStatus(String? status) => switch (status) {
        'approved' => UserStatus.approved,
        'rejected' => UserStatus.rejected,
        'suspended' => UserStatus.suspended,
        _ => UserStatus.pending,
      };

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseAuthError(
    Object error, {
    bool changingPassword = false,
    bool resettingPassword = false,
  }) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return changingPassword
              ? 'Current password is incorrect.'
              : 'Incorrect email or password.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Please sign in instead.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few minutes and try again.';
        case 'requires-recent-login':
          return 'Please sign in again before changing your password.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Contact the fleet administrator.';
        case 'missing-email':
          return 'Email is required.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    final lower = error.toString().toLowerCase();
    if (lower.contains('email-already-in-use') ||
        lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('wrong-password') ||
        lower.contains('invalid-credential')) {
      return changingPassword
          ? 'Current password is incorrect.'
          : 'Incorrect email or password.';
    }
    if (lower.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (lower.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (lower.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    if (resettingPassword) {
      return 'Could not send reset email. Please try again.';
    }
    return error.toString();
  }

  UserProfile _demoUserForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.contains('admin')) {
      return const UserProfile(
        id: 'demo-admin',
        email: 'admin@taxifleet.com',
        firstName: 'Fleet',
        lastName: 'Admin',
        phone: '0820000000',
        role: UserRole.admin,
        status: UserStatus.approved,
      );
    }

    if (normalized.contains('pending')) {
      return const UserProfile(
        id: 'demo-pending',
        email: 'pending@driver.com',
        firstName: 'Thabo',
        lastName: 'Mokoena',
        phone: '0711234567',
        role: UserRole.driver,
        status: UserStatus.pending,
      );
    }

    return const UserProfile(
      id: 'demo-driver',
      email: 'driver@taxifleet.com',
      firstName: 'Thabo',
      lastName: 'Mokoena',
      phone: '0711234567',
      role: UserRole.driver,
      status: UserStatus.approved,
    );
  }
}
