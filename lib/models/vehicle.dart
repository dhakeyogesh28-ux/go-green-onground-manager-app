enum VehicleStatus { active, idle, charging, maintenance }

class ReportedIssue {
  final String id;
  final String vehicleId;
  final String type;
  final String description;
  final DateTime timestamp;
  final String? photoPath;
  final String? videoPath;

  ReportedIssue({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.photoPath,
    this.videoPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'type': type,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'photoPath': photoPath,
    'videoPath': videoPath,
  };

  factory ReportedIssue.fromJson(Map<String, dynamic> json) => ReportedIssue(
    id: json['id'],
    vehicleId: json['vehicleId'],
    type: json['type'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
    photoPath: json['photoPath'],
    videoPath: json['videoPath'],
  );
}

class InspectionResult {
  final String vehicleId;
  final Map<String, String> checks;
  final DateTime timestamp;

  InspectionResult({
    required this.vehicleId,
    required this.checks,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'checks': checks,
    'timestamp': timestamp.toIso8601String(),
  };

  factory InspectionResult.fromJson(Map<String, dynamic> json) => InspectionResult(
    vehicleId: json['vehicleId'],
    checks: Map<String, String>.from(json['checks']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class Vehicle {
  final String id;
  final String vehicleNumber;
  final String customerName;
  final String serviceType;
  final VehicleStatus status;
  
  // New Field Ops Data
  bool isVehicleIn; // IN/OUT status
  DateTime? lastServiceDate;
  String? lastServiceType;
  bool serviceAttention; // OK / Attention
  
  double batteryLevel;
  String lastChargeType; // AC / DC
  String chargingHealth;
  
  List<String> toDos;
  Map<String, bool> dailyChecks;
  int inventoryPhotoCount;
  
  bool isInteriorClean;
  
  DateTime? lastInventoryTime;
  
  // Daily Inspection Fields
  DateTime? lastInspectionDate;
  bool isInServicing;
  String? lastChargingType; // 'AC' or 'DC' from last inspection
  int? batteryHealth; // 0-100 from last inspection
  String? servicingStatus; // 'service_ok', 'attention', 'not_applicable'

  DateTime? lastCheckInTime;
  DateTime? lastCheckOutTime;

  // Database fields from crm_vehicles
  final String? registrationNumber;
  final String? make;
  final String? model;
  final String? variant;
  final String? primaryHubId;
  final DateTime? createdAt;
  
  // Stored in daily_checks JSONB
  final String? driverRemark;
  final String? odometerReading;
  final String? ridePurpose;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.customerName,
    required this.serviceType,
    required this.status,
    this.isVehicleIn = true,
    this.lastServiceDate,
    this.lastServiceType,
    this.serviceAttention = false,
    this.batteryLevel = 85.0,
    this.lastChargeType = 'AC',
    this.chargingHealth = 'Good',
    this.toDos = const [],
    this.dailyChecks = const {},
    this.inventoryPhotoCount = 0,
    this.isInteriorClean = true,
    this.lastInventoryTime,
    this.lastInspectionDate,
    this.isInServicing = false,
    this.lastChargingType,
    this.batteryHealth,
    this.servicingStatus,
    this.lastCheckInTime,
    this.lastCheckOutTime,
    this.registrationNumber,
    this.make,
    this.model,
    this.variant,
    this.primaryHubId,
    this.createdAt,
    this.driverRemark,
    this.odometerReading,
    this.ridePurpose,
  });

  String get statusText {
    switch (status) {
      case VehicleStatus.active:
        return 'Active';
      case VehicleStatus.idle:
        return 'Idle';
      case VehicleStatus.charging:
        return 'Charging';
      case VehicleStatus.maintenance:
        return 'Maintenance';
    }
  }

  // Create Vehicle from Supabase JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Robust parsing for daily checks to avoid "Null is not a subtype of bool"
    final rawDailyChecks = json['daily_checks'] ?? json['dailyChecks'];
    final Map<String, bool> parsedDailyChecks = {};
    if (rawDailyChecks is Map) {
      rawDailyChecks.forEach((key, value) {
        parsedDailyChecks[key.toString()] = value == true;
      });
    }

    // Extract driver_remark, odometer_reading, and ride_purpose from daily_checks if they exist there
    final String? driverRemark = rawDailyChecks is Map ? rawDailyChecks['driver_remark']?.toString() : null;
    final String? odometerReading = rawDailyChecks is Map ? rawDailyChecks['odometer_reading']?.toString() : null;
    final String? ridePurpose = rawDailyChecks is Map ? rawDailyChecks['ride_purpose']?.toString() : null;

    // Interior cleaning status can be top level or inside daily checks
    final bool topLevelInteriorClean = (json['is_interior_clean'] ?? json['isInteriorClean']) == true;
    final bool interiorCleanFromMap = parsedDailyChecks['interior_clean'] == true;

    return Vehicle(
      id: (json['vehicle_id'] ?? json['id'] ?? '').toString(),
      vehicleNumber: (json['registration_number'] ?? json['vehicleNumber'] ?? 'N/A').toString(),
      customerName: (json['customer_name'] ?? json['customerName'] ?? 'Unknown').toString(),
      serviceType: (json['service_type'] ?? json['serviceType'] ?? 'General').toString(),
      status: _parseStatus(json['status']),
      isVehicleIn: (json['is_vehicle_in'] ?? json['isVehicleIn'] ?? true) == true,
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.tryParse(json['last_service_date'].toString()) 
          : null,
      lastServiceType: json['last_service_type'] ?? json['lastServiceType'],
      serviceAttention: (json['service_attention'] ?? json['serviceAttention'] ?? false) == true,
      batteryLevel: double.tryParse((json['battery_level'] ?? json['batteryLevel'] ?? 85.0).toString()) ?? 85.0,
      lastChargeType: (json['last_charge_type'] ?? json['lastChargeType'] ?? 'AC').toString(),
      chargingHealth: (json['charging_health'] ?? json['chargingHealth'] ?? 'Good').toString(),
      toDos: json['to_dos'] != null 
          ? List<String>.from(json['to_dos']) 
          : (json['toDos'] != null ? List<String>.from(json['toDos']) : []),
      dailyChecks: parsedDailyChecks,
      inventoryPhotoCount: int.tryParse((json['inventory_photo_count'] ?? json['inventoryPhotoCount'] ?? 0).toString()) ?? 0,
      isInteriorClean: topLevelInteriorClean || interiorCleanFromMap,
      lastInventoryTime: json['last_inventory_time'] != null 
          ? DateTime.tryParse(json['last_inventory_time'].toString()) 
          : null,
      lastInspectionDate: json['last_inspection_date'] != null
          ? DateTime.tryParse(json['last_inspection_date'].toString())
          : null,
      isInServicing: (json['is_in_servicing'] ?? false) == true,
      lastChargingType: json['last_charging_type']?.toString(),
      batteryHealth: int.tryParse(json['battery_health']?.toString() ?? ''),
      servicingStatus: json['servicing_status']?.toString(),
      lastCheckInTime: json['last_check_in_time'] != null ? DateTime.tryParse(json['last_check_in_time'].toString()) : null,
      lastCheckOutTime: json['last_check_out_time'] != null ? DateTime.tryParse(json['last_check_out_time'].toString()) : null,
      registrationNumber: json['registration_number']?.toString(),
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      variant: json['variant']?.toString(),
      primaryHubId: json['primary_hub_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      driverRemark: driverRemark,
      odometerReading: odometerReading,
      ridePurpose: ridePurpose,
    );
  }

  // Convert Vehicle to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': id,
      'registration_number': vehicleNumber,
      'customer_name': customerName,
      'service_type': serviceType,
      'status': status.name,
      'is_vehicle_in': isVehicleIn,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'last_service_type': lastServiceType,
      'service_attention': serviceAttention,
      'battery_level': batteryLevel,
      'last_charge_type': lastChargeType,
      'charging_health': chargingHealth,
      'to_dos': toDos,
      'daily_checks': dailyChecks,
      'inventory_photo_count': inventoryPhotoCount,
      'is_interior_clean': isInteriorClean, // Included for backward compatibility if column is added later
      'last_inventory_time': lastInventoryTime?.toIso8601String(),
      'last_inspection_date': lastInspectionDate?.toIso8601String().split('T')[0],
      'is_in_servicing': isInServicing,
      'last_charging_type': lastChargingType,
      'battery_health': batteryHealth,
      'servicing_status': servicingStatus,
      'last_check_in_time': lastCheckInTime?.toIso8601String(),
      'last_check_out_time': lastCheckOutTime?.toIso8601String(),
      'make': make,
      'model': model,
      'variant': variant,
      'primary_hub_id': primaryHubId,
      'driver_remark': driverRemark,
      'odometer_reading': odometerReading,
      'ride_purpose': ridePurpose,
    };
  }

  static VehicleStatus _parseStatus(dynamic status) {
    if (status == null) return VehicleStatus.idle;
    
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('active')) {
      return VehicleStatus.active;
    } else if (statusStr.contains('charging')) {
      return VehicleStatus.charging;
    } else if (statusStr.contains('maintenance')) {
      return VehicleStatus.maintenance;
    } else if (statusStr.contains('idle')) {
      return VehicleStatus.idle;
    }
    // Legacy status mapping
    else if (statusStr.contains('progress') || statusStr == 'inprogress') {
      return VehicleStatus.active;
    } else if (statusStr.contains('complete') || statusStr.contains('pending')) {
      return VehicleStatus.idle;
    }
    return VehicleStatus.idle;
  }

  // Copy with method for updates
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? customerName,
    String? serviceType,
    VehicleStatus? status,
    bool? isVehicleIn,
    DateTime? lastServiceDate,
    String? lastServiceType,
    bool? serviceAttention,
    double? batteryLevel,
    String? lastChargeType,
    String? chargingHealth,
    List<String>? toDos,
    Map<String, bool>? dailyChecks,
    int? inventoryPhotoCount,
    bool? isInteriorClean,
    DateTime? lastInventoryTime,
    DateTime? lastInspectionDate,
    bool? isInServicing,
    String? lastChargingType,
    int? batteryHealth,
    String? servicingStatus,
    DateTime? lastCheckInTime,
    DateTime? lastCheckOutTime,
    String? driverRemark,
    String? odometerReading,
    String? ridePurpose,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      customerName: customerName ?? this.customerName,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      isVehicleIn: isVehicleIn ?? this.isVehicleIn,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceType: lastServiceType ?? this.lastServiceType,
      serviceAttention: serviceAttention ?? this.serviceAttention,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastChargeType: lastChargeType ?? this.lastChargeType,
      chargingHealth: chargingHealth ?? this.chargingHealth,
      toDos: toDos ?? this.toDos,
      dailyChecks: dailyChecks ?? this.dailyChecks,
      inventoryPhotoCount: inventoryPhotoCount ?? this.inventoryPhotoCount,
      isInteriorClean: isInteriorClean ?? this.isInteriorClean,
      lastInventoryTime: lastInventoryTime ?? this.lastInventoryTime,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      isInServicing: isInServicing ?? this.isInServicing,
      lastChargingType: lastChargingType ?? this.lastChargingType,
      batteryHealth: batteryHealth ?? this.batteryHealth,
      servicingStatus: servicingStatus ?? this.servicingStatus,
      lastCheckInTime: lastCheckInTime ?? this.lastCheckInTime,
      lastCheckOutTime: lastCheckOutTime ?? this.lastCheckOutTime,
      registrationNumber: this.registrationNumber,
      make: this.make,
      model: this.model,
      variant: this.variant,
      primaryHubId: this.primaryHubId,
      createdAt: this.createdAt,
      driverRemark: driverRemark ?? this.driverRemark,
      odometerReading: odometerReading ?? this.odometerReading,
      ridePurpose: ridePurpose ?? this.ridePurpose,
    );
  }
}
