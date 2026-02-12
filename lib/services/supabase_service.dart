import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';

class SupabaseService {
  // Get Supabase client (lazy initialization)
  static SupabaseClient get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase must be initialized before use. Error: $e');
    }
  }

  // Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  // ==================== VEHICLES ====================

  /// Fetch vehicles from the database, optionally filtered by hub
  Future<List<Vehicle>> getVehicles({String? hub}) async {
    try {
      String? hubId;

      // If hub name is provided, look up the hub UUID
      if (hub != null && hub.isNotEmpty) {
        debugPrint('🔍 Looking up hub ID for: $hub');
        try {
          final hubResponse = await _client
              .from('hub')
              .select('hub_id, name')
              .ilike('name', hub)
              .maybeSingle();

          if (hubResponse != null) {
            hubId = hubResponse['hub_id'];
            debugPrint(
              '✅ Found hub ID: $hubId for hub: ${hubResponse['name']}',
            );
          } else {
            debugPrint('⚠️ No hub found with name: $hub');
            // Strict filtering: If hub was requested but not found, return empty list
            return [];
          }
        } catch (e) {
          debugPrint('⚠️ Error looking up hub: $e');
          return [];
        }
      }

      // Build query
      var query = _client.from('crm_vehicles').select('*');

      // Filter by hub ID if found (it should be found if we are here and hub was not null)
      if (hubId != null) {
        debugPrint('🔍 Filtering vehicles by hub_id: $hubId');
        query = query.eq('primary_hub_id', hubId);
      }

      final response = await query.order('created_at', ascending: false);
      final vehicles = (response as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      debugPrint('📊 Query returned ${vehicles.length} vehicles');

      return vehicles;
    } catch (e) {
      debugPrint('❌ Error fetching vehicles: $e');
      throw Exception('Error fetching vehicles: $e');
    }
  }

  /// Get a specific vehicle by ID
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .maybeSingle();

      if (response == null) return null;
      return Vehicle.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching vehicle: $e');
      return null;
    }
  }

  /// Update vehicle status or other fields
  Future<Vehicle> updateVehicle(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    debugPrint('🔄 Updating vehicle $vehicleId with data: $data');

    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
        final response = await _client
            .from('crm_vehicles')
            .update(data)
            .eq('vehicle_id', vehicleId)
            .select('*')
            .maybeSingle();

        if (response == null) {
          throw Exception(
            'Vehicle not found or update denied for ID: $vehicleId',
          );
        }

        debugPrint('✅ Update response: $response');
        debugPrint('📊 Status in response: ${response['status']}');

        final updatedVehicle = Vehicle.fromJson(response);
        debugPrint('🚗 Parsed vehicle status: ${updatedVehicle.status.name}');

        return updatedVehicle;
      } catch (e) {
        debugPrint('⚠️ Attempt $attempts failed: $e');
        if (attempts >= 3) rethrow;
        await Future.delayed(
          Duration(seconds: attempts * 2),
        ); // Exponential backoff
      }
    }
    throw Exception('Failed to update vehicle after 3 attempts');
  }

  // ==================== MAINTENANCE JOBS / ISSUES ====================

  /// Create a new maintenance job (reported issue)
  Future<Map<String, dynamic>> createMaintenanceJob(
    Map<String, dynamic> data,
  ) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
        final response = await _client
            .from('mobile_maintenance_jobs')
            .insert(data)
            .select('*')
            .single();

        debugPrint('📋 createMaintenanceJob response: $response');
        debugPrint('   Keys: ${response.keys.toList()}');
        return response;
      } catch (e) {
        debugPrint('⚠️ Create maintenance job attempt $attempts failed: $e');
        if (attempts >= 3)
          throw Exception('Error creating maintenance job: $e');
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Failed to create maintenance job after 3 attempts');
  }

  /// Get maintenance jobs for a specific vehicle
  Future<List<Map<String, dynamic>>> getMaintenanceJobs(
    String vehicleId,
  ) async {
    try {
      final response = await _client
          .from('mobile_maintenance_jobs')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('diagnosis_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching maintenance jobs: $e');
      return [];
    }
  }

  /// Get a single maintenance job by ID
  Future<Map<String, dynamic>?> getMaintenanceJobById(String jobId) async {
    try {
      final response = await _client
          .from('mobile_maintenance_jobs')
          .select('*')
          .eq('job_id', jobId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching maintenance job $jobId: $e');
      return null;
    }
  }

  /// Delete a maintenance job
  Future<void> deleteMaintenanceJob(String jobId) async {
    try {
      await _client
          .from('mobile_maintenance_jobs')
          .delete()
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Error deleting maintenance job: $e');
    }
  }

  /// Link maintenance jobs to an inventory record
  /// This updates the inventory_record_id field for the given job IDs
  Future<void> linkJobsToInventoryRecord(
    List<String> jobIds,
    String inventoryRecordId,
  ) async {
    if (jobIds.isEmpty) return;

    try {
      for (final jobId in jobIds) {
        await _client
            .from('mobile_maintenance_jobs')
            .update({'inventory_record_id': inventoryRecordId})
            .eq('job_id', jobId);
      }
      debugPrint(
        '✅ Linked ${jobIds.length} jobs to inventory record $inventoryRecordId',
      );
    } catch (e) {
      debugPrint('Error linking jobs to inventory record: $e');
      // Don't throw - this is not critical
    }
  }

  // ==================== DAILY INVENTORY ====================

  /// Create a daily inventory check record
  Future<Map<String, dynamic>> createDailyInventory(
    Map<String, dynamic> data,
  ) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
        final response = await _client
            .from('mobile_daily_inventory')
            .insert(data)
            .select('*')
            .single();

        return response;
      } catch (e) {
        debugPrint('⚠️ Create daily inventory attempt $attempts failed: $e');
        if (attempts >= 3) {
          debugPrint('Error creating daily inventory: $e');
          throw Exception('Error creating daily inventory: $e');
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Failed to create daily inventory');
  }

  /// Get daily inventory for a vehicle
  Future<List<Map<String, dynamic>>> getDailyInventory(String vehicleId) async {
    try {
      final response = await _client
          .from('mobile_daily_inventory')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('check_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching daily inventory: $e');
      return [];
    }
  }

  // ==================== INVENTORY RECORDS ====================

  /// Create an inventory record (for inventory_in and inventory_out tracking)
  Future<Map<String, dynamic>> createInventoryRecord(
    Map<String, dynamic> data,
  ) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
        debugPrint(
          '📋 Creating inventory record (attempt $attempts): ${data['inventory_type']} for vehicle ${data['vehicle_id']}',
        );

        final response = await _client
            .from('mobile_inventory_records')
            .insert(data)
            .select('*')
            .single();

        debugPrint('✅ Inventory record created: ${response['id']}');
        return response;
      } catch (e) {
        debugPrint('⚠️ Create inventory record attempt $attempts failed: $e');
        if (attempts >= 3) {
          debugPrint('❌ Error creating inventory record: $e');
          throw Exception('Error creating inventory record: $e');
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Failed to create inventory record');
  }

  /// Get inventory records for a vehicle
  Future<List<Map<String, dynamic>>> getInventoryRecords(
    String vehicleId, {
    String? inventoryType, // 'inventory_in' or 'inventory_out' or null for all
  }) async {
    try {
      var query = _client
          .from('mobile_inventory_records')
          .select('*')
          .eq('vehicle_id', vehicleId);

      if (inventoryType != null) {
        query = query.eq('inventory_type', inventoryType);
      }

      final response = await query.order('check_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching inventory records: $e');
      return [];
    }
  }

  // ==================== STORAGE ====================

  /// Upload a file to Supabase Storage
  Future<String> uploadFile(
    String path,
    Uint8List bytes,
    String mimeType,
  ) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
        debugPrint(
          '📤 Upload attempt $attempts for $path (${bytes.length} bytes)',
        );

        // Use longer timeout for videos (120s) vs images (60s)
        final isVideo = mimeType.startsWith('video/');
        final timeoutDuration = isVideo
            ? const Duration(seconds: 120)
            : const Duration(seconds: 60);

        // Add timeout to prevent indefinite hangs
        await _client.storage
            .from('vehicle-documents')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            )
            .timeout(
              timeoutDuration,
              onTimeout: () {
                throw Exception(
                  'Upload timeout: File upload took longer than ${timeoutDuration.inSeconds} seconds',
                );
              },
            );

        final url = getPublicUrl(path);
        debugPrint('✅ Upload successful: $url');
        return url;
      } catch (e) {
        debugPrint('⚠️ Upload attempt $attempts failed: $e');

        // Check if it's a bucket not found error
        if (e.toString().contains('Bucket not found') ||
            e.toString().contains('404') ||
            (e is StorageException && e.statusCode?.toString() == '404')) {
          throw Exception(
            'Storage bucket "vehicle-documents" not found. '
            'Please create the bucket in your Supabase Storage settings.',
          );
        }
        // Check if it's an RLS policy violation (403 Unauthorized)
        if (e.toString().contains('row-level security policy') ||
            e.toString().contains('violates row-level security') ||
            e.toString().contains('403') ||
            (e is StorageException && e.statusCode?.toString() == '403')) {
          throw Exception(
            'Storage upload denied: Row-Level Security (RLS) policy violation. '
            'Please configure Storage policies in Supabase.',
          );
        }

        // Retry on timeout or network errors
        if (attempts >= 3) {
          throw Exception('Error uploading file after 3 attempts: $e');
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Failed to upload file after 3 attempts');
  }

  /// Get public URL for a file in storage
  String getPublicUrl(String path) {
    return _client.storage.from('vehicle-documents').getPublicUrl(path);
  }

  /// Save inventory photo record to database
  Future<void> saveInventoryPhoto({
    required String vehicleId,
    required String category,
    required String photoUrl,
    String? inventoryId,
  }) async {
    try {
      await _client.from('mobile_inventory_photos').insert({
        'vehicle_id': vehicleId,
        'category': category,
        'photo_url': photoUrl,
        if (inventoryId != null) 'inventory_id': inventoryId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving inventory photo record: $e');
      throw Exception('Error saving inventory photo record: $e');
    }
  }

  /// Get inventory photos for a vehicle
  Future<List<Map<String, dynamic>>> getInventoryPhotos(
    String vehicleId,
  ) async {
    try {
      final response = await _client
          .from('mobile_inventory_photos')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching inventory photos: $e');
      return [];
    }
  }

  // ==================== SERVICE SCHEDULES ====================

  /// Create a service schedule
  Future<Map<String, dynamic>> createServiceSchedule(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('service_schedule')
          .insert(data)
          .select('*')
          .single();

      return response;
    } catch (e) {
      throw Exception('Error creating service schedule: $e');
    }
  }

  /// Get service schedules for a vehicle
  Future<List<Map<String, dynamic>>> getServiceSchedules(
    String vehicleId,
  ) async {
    try {
      final response = await _client
          .from('service_schedule')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching service schedules: $e');
      return [];
    }
  }

  // ==================== OFFLINE QUEUE ====================

  /// Save pending operation to offline queue
  Future<void> savePendingOperation(Map<String, dynamic> operation) async {
    try {
      // Store in a local table or SharedPreferences for offline support
      // This will be synced when connection is restored
      debugPrint('Saving pending operation: $operation');
      // Implementation depends on offline strategy
    } catch (e) {
      debugPrint('Error saving pending operation: $e');
    }
  }

  // ==================== ACTIVITIES ====================

  /// Create a new activity (check-in/check-out)
  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> data) async {
    try {
      // Validate required fields
      if (data['vehicle_number'] == null ||
          data['vehicle_number'].toString().isEmpty) {
        throw Exception('vehicle_number is required but was null or empty');
      }
      if (data['vehicle_id'] == null || data['vehicle_id'].toString().isEmpty) {
        throw Exception('vehicle_id is required but was null or empty');
      }
      if (data['activity_type'] == null ||
          data['activity_type'].toString().isEmpty) {
        throw Exception('activity_type is required but was null or empty');
      }

      debugPrint(
        '🔄 Creating activity: vehicle_number=${data['vehicle_number']}, type=${data['activity_type']}',
      );

      // Ensure timestamp is set
      if (data['created_at'] == null && data['timestamp'] == null) {
        data['created_at'] = DateTime.now().toIso8601String();
      }
      if (data['timestamp'] == null) {
        data['timestamp'] =
            data['created_at'] ?? DateTime.now().toIso8601String();
      }

      // Remove 'id' field if present - database uses 'activity_id' as primary key
      final insertData = Map<String, dynamic>.from(data);
      insertData.remove(
        'id',
      ); // Don't send 'id', let database generate 'activity_id'

      int attempts = 0;
      while (attempts < 3) {
        try {
          attempts++;
          final response = await _client
              .from('mobile_activities')
              .insert(insertData)
              .select('*')
              .single();

          debugPrint(
            '✅ Activity created successfully: activity_id=${response['activity_id']}, type=${response['activity_type']}',
          );
          return response;
        } catch (e) {
          debugPrint('⚠️ Create activity attempt $attempts failed: $e');
          if (attempts >= 3) rethrow;
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }
      throw Exception('Failed to create activity after 3 attempts');
    } catch (e) {
      debugPrint('❌ Error creating activity: $e');
      debugPrint('   Data attempted: $data');
      throw Exception('Error creating activity: $e');
    }
  }

  /// Get recent activities (check-in and check-out only), optionally filtered by hub
  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 20,
    String? hub,
  }) async {
    try {
      debugPrint('🔄 Fetching recent activities (check-in/check-out only)...');

      String? hubId;

      // If hub name is provided, look up the hub UUID
      if (hub != null && hub.isNotEmpty && hub != 'All Hubs') {
        debugPrint('🔍 Looking up hub ID for activity filter: $hub');
        try {
          final hubResponse = await _client
              .from('hub')
              .select('hub_id')
              .ilike('name', hub)
              .maybeSingle();

          if (hubResponse != null) {
            hubId = hubResponse['hub_id'];
            debugPrint('✅ Found hub ID for activity filter: $hubId');
          }
        } catch (e) {
          debugPrint('⚠️ Error looking up hub for activity filter: $e');
        }
      }

      // Build query with table join to filter by hub
      // Use !inner to filter the main table based on the join
      var query = _client
          .from('mobile_activities')
          .select('*, crm_vehicles!inner(primary_hub_id)');

      if (hubId != null) {
        debugPrint('🔍 Filtering activities by vehicle primary_hub_id: $hubId');
        query = query.eq('crm_vehicles.primary_hub_id', hubId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit * 2); // Fetch more to account for filtering

      final allActivities = List<Map<String, dynamic>>.from(response);
      debugPrint(
        '📊 Fetched ${allActivities.length} total activities from database',
      );

      // Filter for check-in and check-out only
      final filtered = allActivities
          .where((a) {
            final type = a['activity_type']?.toString().toLowerCase() ?? '';
            return type == 'check_in' || type == 'check_out';
          })
          .take(limit)
          .toList();

      debugPrint('✅ Found ${filtered.length} check-in/check-out activities');

      return filtered;
    } catch (e) {
      debugPrint('❌ Error fetching activities: $e');
      return [];
    }
  }

  // ==================== HEALTH CHECK ====================

  /// Check if Supabase connection is working
  Future<bool> checkConnection() async {
    try {
      await _client.from('crm_vehicles').select('vehicle_id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Supabase connection check failed: $e');
      return false;
    }
  }

  // ==================== AUTHENTICATION ====================

  /// Authenticate user with email and password
  Future<Map<String, dynamic>?> authenticateUser(
    String email,
    String password,
  ) async {
    try {
      debugPrint('🔐 Attempting to authenticate: $email');

      // First check if user exists at all (regardless of password)
      final userCheck = await _client
          .from('users')
          .select('email, hub, is_active')
          .eq('email', email)
          .maybeSingle();

      if (userCheck == null) {
        debugPrint('❌ AUTH FAILED: No user found with email: $email');
        debugPrint('   Please check if the user exists in the "users" table');
        return null;
      }

      debugPrint('📧 User found: ${userCheck['email']}');
      debugPrint('   Hub in DB: ${userCheck['hub']}');
      debugPrint('   Is Active: ${userCheck['is_active']}');

      if (userCheck['is_active'] != true) {
        debugPrint('❌ AUTH FAILED: User is inactive (is_active = false)');
        return null;
      }

      // Now check with password
      final response = await _client
          .from('users')
          .select('*')
          .eq('email', email)
          .eq('password', password)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ User authenticated successfully!');
        debugPrint('   Email: ${response['email']}');
        debugPrint('   Hub: ${response['hub']}');
        debugPrint('   Full Name: ${response['full_name']}');
      } else {
        debugPrint('❌ AUTH FAILED: Password incorrect for user: $email');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error authenticating user: $e');
      return null;
    }
  }

  /// Update user profile (full name and mobile)
  Future<void> updateUserProfile({
    required String email,
    String? fullName,
    String? mobile,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (fullName != null) {
        updateData['full_name'] = fullName;
      }

      if (mobile != null) {
        updateData['mobile'] = mobile;
      }

      if (updateData.isEmpty) {
        debugPrint('No data to update');
        return;
      }

      await _client.from('users').update(updateData).eq('email', email);

      debugPrint('User profile updated successfully for: $email');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Error updating user profile: $e');
    }
  }

  // ==================== SERVICE REMARKS (DRIVER REMARKS) ====================

  /// Save driver remark to service_remarks table
  Future<Map<String, dynamic>> saveDriverRemark({
    required String vehicleId,
    required String remark,
    required String remarkType,
    String? userName,
  }) async {
    try {
      debugPrint('💬 Saving driver remark for vehicle: $vehicleId');

      final data = {
        'vehicle_id': vehicleId,
        'remark': remark,
        'remark_type':
            remarkType, // 'driver' for driver remarks, 'admin' for admin remarks
        'created_by': userName ?? 'Unknown',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true, // Mark as active/visible
      };

      int attempts = 0;
      while (attempts < 3) {
        try {
          attempts++;
          final response = await _client
              .from('service_remarks')
              .insert(data)
              .select('*')
              .single();

          debugPrint('✅ Driver remark saved successfully: ${response['id']}');
          return response;
        } catch (e) {
          debugPrint('⚠️ Save driver remark attempt $attempts failed: $e');
          if (attempts >= 3) rethrow;
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }
      throw Exception('Failed to save driver remark after 3 attempts');
    } catch (e) {
      debugPrint('❌ Error saving driver remark: $e');
      throw Exception('Error saving driver remark: $e');
    }
  }

  /// Get driver remarks for a vehicle (only active ones, for vehicles in garage)
  Future<List<Map<String, dynamic>>> getDriverRemarks(
    String vehicleId, {
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('🔄 Fetching driver remarks for vehicle: $vehicleId');

      var query = _client
          .from('service_remarks')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .eq('remark_type', 'driver');

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      final remarks = List<Map<String, dynamic>>.from(response);
      debugPrint('✅ Found ${remarks.length} driver remarks for vehicle');

      return remarks;
    } catch (e) {
      debugPrint('❌ Error fetching driver remarks: $e');
      return [];
    }
  }

  /// Get the latest driver remark for a vehicle (for display on garage card)
  Future<Map<String, dynamic>?> getLatestDriverRemark(String vehicleId) async {
    try {
      final response = await _client
          .from('service_remarks')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .eq('remark_type', 'driver')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ Found latest driver remark for vehicle $vehicleId');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error fetching latest driver remark: $e');
      return null;
    }
  }

  /// Deactivate driver remarks for a vehicle (call when vehicle is checked out)
  Future<void> deactivateDriverRemarks(String vehicleId) async {
    try {
      debugPrint('🔄 Deactivating driver remarks for vehicle: $vehicleId');

      await _client
          .from('service_remarks')
          .update({'is_active': false})
          .eq('vehicle_id', vehicleId)
          .eq('remark_type', 'driver')
          .eq('is_active', true);

      debugPrint('✅ Driver remarks deactivated for vehicle $vehicleId');
    } catch (e) {
      debugPrint('⚠️ Error deactivating driver remarks: $e');
      // Don't throw - this is not critical
    }
  }
}
