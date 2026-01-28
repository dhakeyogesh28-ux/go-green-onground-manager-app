import 'dart:convert';

class Activity {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String activityType; // 'check_in', 'check_out'
  final String userName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Activity({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.activityType,
    required this.userName,
    required this.timestamp,
    this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and 'activity_id' fields
    final id = json['id']?.toString() ?? json['activity_id']?.toString() ?? '';
    
    // Handle both 'created_at' and 'timestamp' fields
    String timestampStr;
    if (json['created_at'] != null) {
      timestampStr = json['created_at'].toString();
    } else if (json['timestamp'] != null) {
      timestampStr = json['timestamp'].toString();
    } else {
      timestampStr = DateTime.now().toIso8601String();
    }
    
    // Parse metadata - handle JSONB from database
    Map<String, dynamic>? metadata;
    if (json['metadata'] != null) {
      if (json['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(json['metadata']);
      } else if (json['metadata'] is String) {
        // If it's a string, try to parse it as JSON
        try {
          metadata = Map<String, dynamic>.from(jsonDecode(json['metadata']));
        } catch (e) {
          metadata = null;
        }
      }
    }
    
    return Activity(
      id: id,
      vehicleId: json['vehicle_id']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['user_email']?.toString() ?? 'Unknown',
      timestamp: DateTime.parse(timestampStr),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'activity_type': activityType,
      'user_name': userName,
      'created_at': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get activityText {
    switch (activityType) {
      case 'check_in':
        return 'Checked In';
      case 'check_out':
        return 'Checked Out';
      default:
        return activityType;
    }
  }

  bool get isCheckIn => activityType == 'check_in';
  bool get isCheckOut => activityType == 'check_out';
}
