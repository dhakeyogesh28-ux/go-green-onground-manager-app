import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static SupabaseClient get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase must be initialized before use. Error: $e');
    }
  }

  /// Get notifications for a user
  /// This fetches from mobile_activities table and formats them as notifications
  Future<List<Map<String, dynamic>>> getNotifications({
    String? userEmail,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔔 Fetching notifications...');
      
      // Fetch recent activities
      final response = await _client
          .from('mobile_activities')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      
      final activities = List<Map<String, dynamic>>.from(response);
      debugPrint('📊 Fetched ${activities.length} activities');
      
      // Transform activities into notifications
      final notifications = activities.map((activity) {
        final activityType = activity['activity_type']?.toString().toLowerCase() ?? '';
        final vehicleNumber = activity['vehicle_number'] ?? 'Unknown Vehicle';
        final userName = activity['user_name'] ?? 'User';
        final timestamp = activity['created_at'] ?? activity['timestamp'];
        
        String title = '';
        String message = '';
        String type = 'info';
        
        if (activityType == 'check_in') {
          title = 'Vehicle Checked In';
          message = '$vehicleNumber checked in by $userName';
          type = 'assignment';
        } else if (activityType == 'check_out') {
          title = 'Vehicle Checked Out';
          message = '$vehicleNumber checked out by $userName';
          type = 'update';
        } else {
          title = 'Activity Update';
          message = '$activityType for $vehicleNumber';
          type = 'info';
        }
        
        return {
          'id': activity['activity_id'] ?? activity['id'],
          'type': type,
          'title': title,
          'message': message,
          'timestamp': timestamp,
          'isRead': false, // You can add a read status field to the database if needed
        };
      }).toList();
      
      debugPrint('✅ Transformed ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get maintenance job notifications
  Future<List<Map<String, dynamic>>> getMaintenanceNotifications({
    int limit = 10,
  }) async {
    try {
      debugPrint('🔧 Fetching maintenance notifications...');
      
      final response = await _client
          .from('mobile_maintenance_jobs')
          .select('*, crm_vehicles(vehicle_number)')
          .order('created_at', ascending: false)
          .limit(limit);
      
      final jobs = List<Map<String, dynamic>>.from(response);
      debugPrint('📊 Fetched ${jobs.length} maintenance jobs');
      
      final notifications = jobs.map((job) {
        final vehicleNumber = job['crm_vehicles']?['vehicle_number'] ?? 'Unknown Vehicle';
        final issueType = job['issue_type'] ?? 'Issue';
        final status = job['status'] ?? 'pending';
        final timestamp = job['created_at'];
        
        return {
          'id': job['job_id'],
          'type': 'maintenance',
          'title': 'Maintenance Issue',
          'message': '$issueType reported for $vehicleNumber - Status: $status',
          'timestamp': timestamp,
          'isRead': false,
        };
      }).toList();
      
      debugPrint('✅ Transformed ${notifications.length} maintenance notifications');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error fetching maintenance notifications: $e');
      return [];
    }
  }

  /// Get all notifications (activities + maintenance)
  Future<List<Map<String, dynamic>>> getAllNotifications({
    String? userEmail,
    int limit = 20,
  }) async {
    try {
      final activityNotifications = await getNotifications(
        userEmail: userEmail,
        limit: limit ~/ 2,
      );
      
      final maintenanceNotifications = await getMaintenanceNotifications(
        limit: limit ~/ 2,
      );
      
      // Combine and sort by timestamp
      final allNotifications = [
        ...activityNotifications,
        ...maintenanceNotifications,
      ];
      
      allNotifications.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime); // Most recent first
      });
      
      return allNotifications.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error fetching all notifications: $e');
      return [];
    }
  }

  /// Format timestamp to relative time (e.g., "2 hours ago")
  static String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
