enum UserRole { admin, driver }

enum UserStatus { pending, approved, rejected, suspended }

enum ExpenseType { fuel, maintenance, repair, other }

enum DriverDayStatus { active, completed }

enum DocumentType { id, pdp }

enum DocumentStatus { pending, approved, rejected }

enum ActivityCategory { checkIn, fuel, maintenance, other }

class ActivityEvent {
  const ActivityEvent({
    required this.title,
    required this.timeLabel,
    required this.category,
  });

  final String title;
  final String timeLabel;
  final ActivityCategory category;
}

class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.driverId,
    required this.documentType,
    required this.filePath,
    this.status = DocumentStatus.pending,
    this.uploadedAt,
    this.rejectionReason,
  });

  final String id;
  final String driverId;
  final DocumentType documentType;
  final String filePath;
  final DocumentStatus status;
  final DateTime? uploadedAt;
  final String? rejectionReason;

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      documentType: _parseDocumentType(json['document_type'] as String?),
      filePath: json['file_path'] as String,
      status: _parseDocumentStatus(json['status'] as String?),
      uploadedAt: _parseDateTime(json['uploaded_at']),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.status,
    this.profilePhoto,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final UserRole role;
  final UserStatus status;
  final String? profilePhoto;

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : email;
  String get avatarLetter {
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    if (lastName.isNotEmpty) return lastName[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
  bool get isAdmin => role == UserRole.admin;
  bool get isApprovedDriver => role == UserRole.driver && status == UserStatus.approved;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _parseUserRole(json['role'] as String?),
      status: _parseUserStatus(json['status'] as String?),
      profilePhoto: json['profile_photo'] as String?,
    );
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    this.year,
    this.color,
  });

  final String id;
  final String registrationNumber;
  final String make;
  final String model;
  final int? year;
  final String? color;

  String get displayName => '$make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      registrationNumber: json['registration_number'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int?,
      color: json['color'] as String?,
    );
  }
}

class DriverDay {
  const DriverDay({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.date,
    this.startedAt,
    this.endedAt,
    this.startingOdometer,
    this.endingOdometer,
    this.distanceKm = 0,
    this.totalEarnings = 0,
    this.notes,
    this.status = DriverDayStatus.active,
    this.fuelTotal = 0,
    this.expenseTotal = 0,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final DateTime date;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? startingOdometer;
  final int? endingOdometer;

  /// Kilometres recorded from GPS during this day.
  final double distanceKm;
  final double totalEarnings;
  final String? notes;
  final DriverDayStatus status;
  final double fuelTotal;
  final double expenseTotal;

  double get net => totalEarnings - fuelTotal - expenseTotal;

  factory DriverDay.fromJson(
    Map<String, dynamic> json, {
    double fuelTotal = 0,
    double expenseTotal = 0,
  }) {
    return DriverDay(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      date: _parseDate(json['date'] as String),
      startedAt: _parseDateTime(json['started_at']),
      endedAt: _parseDateTime(json['ended_at']),
      startingOdometer: json['starting_odometer'] as int?,
      endingOdometer: json['ending_odometer'] as int?,
      distanceKm: _parseAmount(json['distance_km']),
      totalEarnings: _parseAmount(json['total_earnings']),
      notes: json['notes'] as String?,
      status: _parseDriverDayStatus(json['status'] as String?),
      fuelTotal: fuelTotal,
      expenseTotal: expenseTotal,
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.driverDayId,
    required this.type,
    required this.amount,
    this.description,
    this.receiptPath,
  });

  final String id;
  final String driverDayId;
  final ExpenseType type;
  final double amount;
  final String? description;
  final String? receiptPath;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      driverDayId: json['driver_day_id'] as String,
      type: _parseExpenseType(json['type'] as String?),
      amount: _parseAmount(json['amount']),
      description: json['description'] as String?,
      receiptPath: json['receipt_path'] as String?,
    );
  }
}

/// Driver day with admin list metadata.
class AdminDriverDay {
  const AdminDriverDay({
    required this.day,
    required this.driverName,
    required this.vehicleLabel,
  });

  final DriverDay day;
  final String driverName;
  final String vehicleLabel;
}

/// Expense with admin list metadata.
class AdminExpense {
  const AdminExpense({
    required this.expense,
    required this.driverName,
    required this.dayDate,
  });

  final Expense expense;
  final String driverName;
  final DateTime dayDate;
}

class PeriodReport {
  const PeriodReport({
    required this.label,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.dayCount,
    required this.expenseCount,
  });

  final String label;
  final double totalEarnings;
  final double totalExpenses;
  final int dayCount;
  final int expenseCount;

  double get net => totalEarnings - totalExpenses;
}

class FleetSummary {
  const FleetSummary({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.pendingDrivers,
    required this.suspendedDrivers,
    required this.todayEarnings,
    required this.todayExpenses,
  });

  final int totalDrivers;
  final int activeDrivers;
  final int pendingDrivers;
  final int suspendedDrivers;
  final double todayEarnings;
  final double todayExpenses;

  double get todayNet => todayEarnings - todayExpenses;
}

UserRole _parseUserRole(String? role) => switch (role) {
      'admin' => UserRole.admin,
      _ => UserRole.driver,
    };

UserStatus _parseUserStatus(String? status) => switch (status) {
      'approved' => UserStatus.approved,
      'rejected' => UserStatus.rejected,
      'suspended' => UserStatus.suspended,
      _ => UserStatus.pending,
    };

ExpenseType _parseExpenseType(String? type) => switch (type) {
      'maintenance' => ExpenseType.maintenance,
      'repair' => ExpenseType.repair,
      'other' => ExpenseType.other,
      _ => ExpenseType.fuel,
    };

DriverDayStatus _parseDriverDayStatus(String? status) => switch (status) {
      'completed' => DriverDayStatus.completed,
      _ => DriverDayStatus.active,
    };

DocumentType _parseDocumentType(String? type) => switch (type) {
      'pdp' => DocumentType.pdp,
      _ => DocumentType.id,
    };

DocumentStatus _parseDocumentStatus(String? status) => switch (status) {
      'approved' => DocumentStatus.approved,
      'rejected' => DocumentStatus.rejected,
      _ => DocumentStatus.pending,
    };

double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime _parseDate(String value) => DateTime.parse(value);

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.parse(value as String);
}
