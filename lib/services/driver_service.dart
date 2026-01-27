import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/models/driver.dart';
import 'package:mobile/models/driver_attendance.dart';

class DriverService {
  // Get Supabase client
  static final SupabaseClient _client = Supabase.instance.client;

  /// Helper to get hub ID from name if it's not a UUID
  static Future<String?> _resolveHubId(String hub) async {
    if (hub.isEmpty) return null;
    
    // Check if it's already a UUID (basic check)
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (uuidRegex.hasMatch(hub)) return hub;

    try {
      debugPrint('🔍 Looking up hub ID for name: $hub');
      final response = await _client
          .from('hubs')
          .select('hub_id')
          .ilike('hub_name', hub)
          .maybeSingle();
      
      if (response != null) {
        return response['hub_id'];
      }
    } catch (e) {
      debugPrint('⚠️ Error resolving hub ID: $e');
    }
    return null;
  }

  /// Search for drivers by name, phone, or license
  static Future<List<Driver>> searchDrivers(String query, {String? hubId}) async {
    try {
      debugPrint('🔍 Searching drivers with query: $query');
      
      var queryBuilder = _client
          .from('drivers')
          .select('*')
          .eq('is_active', true);
      
      // Filter by hub if provided
      if (hubId != null && hubId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('hub_id', hubId);
      }
      
      // Search by name or phone number
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'driver_name.ilike.%$query%,phone_number.ilike.%$query%,license_number.ilike.%$query%'
        );
      }
      
      final response = await queryBuilder
          .order('driver_name', ascending: true)
          .limit(20);
      
      final drivers = (response as List)
          .map((json) => Driver.fromJson(json))
          .toList();
      
      debugPrint('✅ Found ${drivers.length} drivers');
      return drivers;
    } catch (e) {
      debugPrint('❌ Error searching drivers: $e');
      return [];
    }
  }

  /// Get all active drivers for a hub
  static Future<List<Driver>> getDriversByHub(String hubId) async {
    try {
      debugPrint('🔍 Fetching drivers for hub: $hubId');
      
      // Resolve hub name to ID if necessary
      final resolvedHubId = await _resolveHubId(hubId);
      if (resolvedHubId == null && hubId.isNotEmpty) {
        debugPrint('⚠️ Could not resolve hub: $hubId');
        return [];
      }
      
      final response = await _client
          .from('drivers')
          .select('*')
          .eq('hub_id', resolvedHubId ?? '')
          .eq('is_active', true)
          .order('driver_name', ascending: true);
      
      final drivers = (response as List)
          .map((json) => Driver.fromJson(json))
          .toList();
      
      debugPrint('✅ Found ${drivers.length} drivers for hub');
      return drivers;
    } catch (e) {
      debugPrint('❌ Error fetching drivers by hub: $e');
      return [];
    }
  }

  /// Get a specific driver by ID
  static Future<Driver?> getDriverById(String driverId) async {
    try {
      final response = await _client
          .from('drivers')
          .select('*')
          .eq('driver_id', driverId)
          .maybeSingle();
      
      if (response == null) return null;
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching driver: $e');
      return null;
    }
  }

  /// Mark driver attendance (check-in or check-out)
  static Future<DriverAttendance?> markAttendance({
    required String driverId,
    required String vehicleId,
    required String activityType, // 'check_in' or 'check_out'
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📝 Marking driver attendance: $driverId for vehicle: $vehicleId');
      
      final attendanceData = {
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'activity_type': activityType,
        'timestamp': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
        if (metadata != null) 'metadata': metadata,
      };
      
      final response = await _client
          .from('driver_attendance')
          .insert(attendanceData)
          .select('*')
          .single();
      
      debugPrint('✅ Driver attendance marked successfully');
      return DriverAttendance.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error marking driver attendance: $e');
      // Don't throw, just return null to allow the process to continue
      return null;
    }
  }

  /// Get driver attendance history
  static Future<List<DriverAttendance>> getDriverAttendance({
    String? driverId,
    String? vehicleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('driver_attendance')
          .select('*');
      
      if (driverId != null) {
        query = query.eq('driver_id', driverId);
      }
      
      if (vehicleId != null) {
        query = query.eq('vehicle_id', vehicleId);
      }
      
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }
      
      final response = await query
          .order('timestamp', ascending: false)
          .limit(100);
      
      return (response as List)
          .map((json) => DriverAttendance.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching driver attendance: $e');
      return [];
    }
  }

  /// Get the last driver assigned to a vehicle
  static Future<Driver?> getLastAssignedDriver(String vehicleId) async {
    try {
      final response = await _client
          .from('driver_attendance')
          .select('driver_id')
          .eq('vehicle_id', vehicleId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      
      final driverId = response['driver_id'];
      return await getDriverById(driverId);
    } catch (e) {
      debugPrint('❌ Error fetching last assigned driver: $e');
      return null;
    }
  }

  /// Create a new driver
  static Future<Driver> createDriver(Driver driver) async {
    try {
      debugPrint('📝 Creating new driver: ${driver.name}');
      
      final data = driver.toJson();
      
      // Resolve hub ID if it's a name
      if (driver.hubId != null) {
        final resolvedHubId = await _resolveHubId(driver.hubId!);
        if (resolvedHubId != null) {
          data['hub_id'] = resolvedHubId;
        } else {
          // If it can't be resolved, remove it to avoid UUID error
          data.remove('hub_id');
        }
      }
      
      // Remove driver_id if it's empty to let database generate it
      if (driver.id.isEmpty) {
        data.remove('driver_id');
      }
      
      final response = await _client
          .from('drivers')
          .insert(data)
          .select('*')
          .single();
      
      debugPrint('✅ Driver created successfully');
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating driver: $e');
      throw Exception('Error creating driver: $e');
    }
  }

  /// Update an existing driver
  static Future<Driver> updateDriver(Driver driver) async {
    try {
      debugPrint('🔄 Updating driver: ${driver.id}');
      
      final data = driver.toJson();
      
      // Resolve hub ID if it's a name
      if (driver.hubId != null) {
        final resolvedHubId = await _resolveHubId(driver.hubId!);
        if (resolvedHubId != null) {
          data['hub_id'] = resolvedHubId;
        } else {
          // If it can't be resolved, remove it to avoid UUID error
          data.remove('hub_id');
        }
      }

      // driver_id is primary key, don't update it but use it for filtering
      data.remove('driver_id');
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('drivers')
          .update(data)
          .eq('driver_id', driver.id)
          .select('*')
          .single();
          
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error updating driver: $e');
      throw Exception('Error updating driver: $e');
    }
  }

  /// Delete a driver
  static Future<void> deleteDriver(String driverId) async {
    try {
      debugPrint('🗑️ Deleting driver: $driverId');
      
      await _client
          .from('drivers')
          .delete()
          .eq('driver_id', driverId);
          
      debugPrint('✅ Driver deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting driver: $e');
      throw Exception('Error deleting driver: $e');
    }
  }
}
