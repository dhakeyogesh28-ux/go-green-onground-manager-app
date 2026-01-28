class DailyInspection {
  final String id;
  final String vehicleId;
  final DateTime inspectionDate;
  final DateTime? completedAt;
  
  // Photos
  final Map<String, String> inventoryPhotos; // category_id -> photo_path
  final List<String> additionalPhotos;
  
  // Servicing
  final String? servicingStatus; // 'service_ok', 'attention', 'not_applicable'
  final String? servicingNotes;
  
  // Charging
  final String? lastChargingType; // 'AC' or 'DC'
  final int? batteryHealth; // 0-100
  
  // Metadata
  final String? inspectorId;
  final String? inspectorName;
  final String? inspectorEmail;
  final String? hub;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyInspection({
    required this.id,
    required this.vehicleId,
    required this.inspectionDate,
    this.completedAt,
    this.inventoryPhotos = const {},
    this.additionalPhotos = const [],
    this.servicingStatus,
    this.servicingNotes,
    this.lastChargingType,
    this.batteryHealth,
    this.inspectorId,
    this.inspectorName,
    this.inspectorEmail,
    this.hub,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyInspection.fromJson(Map<String, dynamic> json) {
    return DailyInspection(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      inspectionDate: DateTime.parse(json['inspection_date'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      inventoryPhotos: json['inventory_photos'] != null
          ? Map<String, String>.from(json['inventory_photos'] as Map)
          : {},
      additionalPhotos: json['additional_photos'] != null
          ? List<String>.from(json['additional_photos'] as List)
          : [],
      servicingStatus: json['servicing_status'] as String?,
      servicingNotes: json['servicing_notes'] as String?,
      lastChargingType: json['last_charging_type'] as String?,
      batteryHealth: json['battery_health'] as int?,
      inspectorId: json['inspector_id'] as String?,
      inspectorName: json['inspector_name'] as String?,
      inspectorEmail: json['inspector_email'] as String?,
      hub: json['hub'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'inspection_date': inspectionDate.toIso8601String().split('T')[0],
      'completed_at': completedAt?.toIso8601String(),
      'inventory_photos': inventoryPhotos,
      'additional_photos': additionalPhotos,
      'servicing_status': servicingStatus,
      'servicing_notes': servicingNotes,
      'last_charging_type': lastChargingType,
      'battery_health': batteryHealth,
      'inspector_id': inspectorId,
      'inspector_name': inspectorName,
      'inspector_email': inspectorEmail,
      'hub': hub,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyInspection copyWith({
    String? id,
    String? vehicleId,
    DateTime? inspectionDate,
    DateTime? completedAt,
    Map<String, String>? inventoryPhotos,
    List<String>? additionalPhotos,
    String? servicingStatus,
    String? servicingNotes,
    String? lastChargingType,
    int? batteryHealth,
    String? inspectorId,
    String? inspectorName,
    String? inspectorEmail,
    String? hub,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyInspection(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      completedAt: completedAt ?? this.completedAt,
      inventoryPhotos: inventoryPhotos ?? this.inventoryPhotos,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
      servicingStatus: servicingStatus ?? this.servicingStatus,
      servicingNotes: servicingNotes ?? this.servicingNotes,
      lastChargingType: lastChargingType ?? this.lastChargingType,
      batteryHealth: batteryHealth ?? this.batteryHealth,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorEmail: inspectorEmail ?? this.inspectorEmail,
      hub: hub ?? this.hub,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCompleted => completedAt != null;
  
  bool get needsAttention => servicingStatus == 'attention';
}
