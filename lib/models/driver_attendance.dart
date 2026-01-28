class DriverAttendance {
  final String? id;
  final String driverId;
  final String vehicleId;
  final String activityType; // 'check_in' or 'check_out'
  final DateTime timestamp;
  final String? notes;
  final Map<String, dynamic>? metadata;

  DriverAttendance({
    this.id,
    required this.driverId,
    required this.vehicleId,
    required this.activityType,
    required this.timestamp,
    this.notes,
    this.metadata,
  });

  factory DriverAttendance.fromJson(Map<String, dynamic> json) {
    return DriverAttendance(
      id: json['attendance_id'] ?? json['id'],
      driverId: json['driver_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      activityType: json['activity_type'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      notes: json['notes'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'attendance_id': id,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'activity_type': activityType,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'DriverAttendance(driverId: $driverId, vehicleId: $vehicleId, type: $activityType)';
  }
}
