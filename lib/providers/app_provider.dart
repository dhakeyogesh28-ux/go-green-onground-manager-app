import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/models/vehicle.dart';
import 'package:mobile/models/activity.dart';
import 'package:mobile/models/driver.dart';
import 'package:mobile/services/supabase_service.dart';
import 'package:mobile/services/driver_service.dart';

class AppProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _lastRoute;
  String? get lastRoute => _lastRoute;

  // Theme and Language
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  String _languageCode = 'en';
  String get languageCode => _languageCode;

  // User credentials and hub
  String? _userEmail;
  String? get userEmail => _userEmail;
  String? _selectedHub;
  String? get selectedHub => _selectedHub;
  String? _userName;
  String? get userName => _userName;
  String? _userMobile;
  String? get userMobile => _userMobile;

  // Vehicles from Supabase
  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;
  bool _isLoadingVehicles = false;
  bool get isLoadingVehicles => _isLoadingVehicles;
  String? _vehiclesError;
  String? get vehiclesError => _vehiclesError;

  // Activities
  List<Activity> _activities = [];
  List<Activity> get activities => _activities;
  bool _isLoadingActivities = false;
  bool get isLoadingActivities => _isLoadingActivities;

  // Drivers
  List<Driver> _drivers = [];
  List<Driver> get drivers => _drivers;
  Map<String, String> _driverStatuses = {}; // driverId -> 'Present' or 'Absent'
  Map<String, String> get driverStatuses => _driverStatuses;
  bool _isLoadingDrivers = false;
  bool get isLoadingDrivers => _isLoadingDrivers;
  String? _driversError;
  String? get driversError => _driversError;

  // Shift management
  bool _isShiftActive = false;
  bool get isShiftActive => _isShiftActive;
  DateTime? _shiftStartTime;
  DateTime? get shiftStartTime => _shiftStartTime;
  DateTime? _shiftEndTime;
  DateTime? get shiftEndTime => _shiftEndTime;

  // Local data for offline support
  final List<ReportedIssue> _reportedIssues = [];
  final List<InspectionResult> _inspectionResults = [];
  final Map<String, Map<String, String>> _inventoryPhotos =
      {}; // vehicleId -> category -> path

  // Track maintenance job IDs for the current check-in/check-out session
  // This persists across navigation (unlike screen state)
  final List<String> _currentSessionJobIds = [];
  List<String> get currentSessionJobIds =>
      List.unmodifiable(_currentSessionJobIds);

  // Store complete issue data for the current session (survives navigation)
  // Each issue contains: type, description, photoUrl, videoUrl
  final List<Map<String, dynamic>> _currentSessionIssues = [];
  List<Map<String, dynamic>> get currentSessionIssues =>
      List.unmodifiable(_currentSessionIssues);

  void addSessionJobId(String jobId) {
    if (!_currentSessionJobIds.contains(jobId)) {
      _currentSessionJobIds.add(jobId);
      debugPrint('AppProvider: Added job ID to session: $jobId');
      debugPrint(
        'AppProvider: Current session job IDs: $_currentSessionJobIds',
      );
    }
  }

  /// Add a complete issue to the session (with uploaded URLs)
  void addSessionIssue(Map<String, dynamic> issue) {
    _currentSessionIssues.add(issue);
    debugPrint('AppProvider: Added issue to session: ${issue['type']}');
    debugPrint('AppProvider: Issue photo: ${issue['photoUrl']}');
    debugPrint(
      'AppProvider: Total session issues: ${_currentSessionIssues.length}',
    );
  }

  void clearSessionJobIds() {
    _currentSessionJobIds.clear();
    debugPrint('AppProvider: Cleared session job IDs');
  }

  void clearSessionIssues() {
    _currentSessionIssues.clear();
    debugPrint('AppProvider: Cleared session issues');
  }

  /// Clear all session data (job IDs and issues)
  void clearSessionData() {
    _currentSessionJobIds.clear();
    _currentSessionIssues.clear();
    debugPrint('AppProvider: Cleared all session data');
  }

  // Pending operations queue for offline support
  final List<Map<String, dynamic>> _pendingOperations = [];

  AppProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _lastRoute = prefs.getString('lastRoute');
      _userEmail = prefs.getString('userEmail');
      _selectedHub = prefs.getString('selectedHub');
      _userName = prefs.getString('userName');
      _userMobile = prefs.getString('userMobile');

      // Load Theme and Language
      final themeStr = prefs.getString('themeMode') ?? 'light';
      _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _languageCode = prefs.getString('languageCode') ?? 'en';

      debugPrint('🔄 AppProvider: Loading persisted data...');
      debugPrint('   - isLoggedIn: $_isLoggedIn');
      debugPrint('   - userEmail: $_userEmail');
      debugPrint('   - selectedHub: $_selectedHub');
      debugPrint('   - userName: $_userName');
      debugPrint('   - userMobile: $_userMobile');
      debugPrint('   - lastRoute: $_lastRoute');

      // Load Issues (kept for offline support)
      final issuesJson = prefs.getString('reportedIssues');
      if (issuesJson != null) {
        final List<dynamic> decoded = jsonDecode(issuesJson);
        _reportedIssues.clear();
        _reportedIssues.addAll(decoded.map((i) => ReportedIssue.fromJson(i)));
        debugPrint('   - Loaded ${_reportedIssues.length} issues from storage');
      }

      // Load Inspections (kept for offline support)
      final inspectionsJson = prefs.getString('inspectionResults');
      if (inspectionsJson != null) {
        final List<dynamic> decoded = jsonDecode(inspectionsJson);
        _inspectionResults.clear();
        _inspectionResults.addAll(
          decoded.map((i) => InspectionResult.fromJson(i)),
        );
        debugPrint(
          '   - Loaded ${_inspectionResults.length} inspections from storage',
        );
      }

      // Load Inventory Photos (kept for offline support)
      final photosJson = prefs.getString('inventoryPhotos');
      if (photosJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(photosJson);
        _inventoryPhotos.clear();
        decoded.forEach((vId, categories) {
          _inventoryPhotos[vId] = Map<String, String>.from(categories);
        });
        debugPrint(
          '   - Loaded ${_inventoryPhotos.length} vehicle photo sets from storage',
        );
      }

      // Load pending operations
      final pendingJson = prefs.getString('pendingOperations');
      if (pendingJson != null) {
        final List<dynamic> decoded = jsonDecode(pendingJson);
        _pendingOperations.clear();
        _pendingOperations.addAll(
          decoded.map((op) => Map<String, dynamic>.from(op)),
        );
        debugPrint(
          '   - Loaded ${_pendingOperations.length} pending operations from storage',
        );
      }

      // Load shift data
      _isShiftActive = prefs.getBool('isShiftActive') ?? false;
      final shiftStartStr = prefs.getString('shiftStartTime');
      if (shiftStartStr != null) {
        _shiftStartTime = DateTime.tryParse(shiftStartStr);
      }
      final shiftEndStr = prefs.getString('shiftEndTime');
      if (shiftEndStr != null) {
        _shiftEndTime = DateTime.tryParse(shiftEndStr);
      }
      // Reset shift if it's from a previous day
      if (_shiftStartTime != null) {
        final now = DateTime.now();
        if (_shiftStartTime!.year != now.year ||
            _shiftStartTime!.month != now.month ||
            _shiftStartTime!.day != now.day) {
          _isShiftActive = false;
          _shiftStartTime = null;
          _shiftEndTime = null;
          await prefs.remove('isShiftActive');
          await prefs.remove('shiftStartTime');
          await prefs.remove('shiftEndTime');
          debugPrint('   - Shift data reset (from a previous day)');
        }
      }
      debugPrint('   - isShiftActive: $_isShiftActive');
      debugPrint('   - shiftStartTime: $_shiftStartTime');
      debugPrint('   - shiftEndTime: $_shiftEndTime');

      debugPrint('✅ AppProvider: INITIALIZED. Total data loaded successfully');

      // Load vehicles from Supabase if logged in
      if (_isLoggedIn) {
        debugPrint('🔄 User is logged in, loading vehicles from Supabase...');
        // Force refresh to ensure we get the latest data from database
        await loadVehicles(forceRefresh: true);
        await loadActivities(limit: 20); // Load activities on startup
        await loadDrivers(); // Load drivers on startup
        await _syncPendingOperations();
      }
    } catch (e) {
      debugPrint('❌ AppProvider: Error loading settings: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ==================== VEHICLE MANAGEMENT ====================

  /// Load vehicles from Supabase
  Future<void> loadVehicles({bool forceRefresh = false}) async {
    _isLoadingVehicles = true;
    _vehiclesError = null;
    notifyListeners();

    try {
      debugPrint(
        '🔄 AppProvider: Loading vehicles from Supabase${forceRefresh ? " (forced refresh)" : ""}...',
      );

      // Get vehicles from Supabase, filtered by user's hub (backend filtering)
      final loadedVehicles = await _supabaseService.getVehicles(
        hub: _selectedHub,
      );

      // Additional CLIENT-SIDE filtering to strictly enforce the user's request
      // Nashik -> MH 14 (or MH 15 standard)
      // Pune -> MH 12
      List<Vehicle> filteredVehicles = loadedVehicles;

      if (_selectedHub != null) {
        final hubName = _selectedHub!.toLowerCase();
        debugPrint(
          '🔍 Applying strict client-side filtering for hub: $_selectedHub',
        );

        if (hubName.contains('nashik')) {
          filteredVehicles = loadedVehicles.where((v) {
            final num = v.vehicleNumber.replaceAll(' ', '').toUpperCase();
            // User explicitly asked for MH 14 for Nashik, adding MH 15 for safety as it's the standard code
            return num.startsWith('MH14') || num.startsWith('MH15');
          }).toList();
        }
      }

      // Replace the list
      _vehicles = filteredVehicles;

      if (_selectedHub != null && _selectedHub!.isNotEmpty) {
        debugPrint(
          '✅ AppProvider: Loaded ${_vehicles.length} vehicles for hub: $_selectedHub after strict filtering (Original: ${loadedVehicles.length})',
        );
      } else {
        debugPrint(
          '✅ AppProvider: Loaded ${_vehicles.length} vehicles from Supabase (no hub filter)',
        );
      }

      // Log status distribution for debugging
      final statusCounts = <String, int>{};
      for (var vehicle in _vehicles) {
        final statusName = vehicle.status.name;
        statusCounts[statusName] = (statusCounts[statusName] ?? 0) + 1;
      }
      debugPrint('📊 Vehicle status distribution: $statusCounts');
      final inCount = _vehicles.where((v) => v.isVehicleIn).length;
      final outCount = _vehicles.where((v) => !v.isVehicleIn).length;
      debugPrint('📊 Vehicle In/Out: In=$inCount, Out=$outCount');
    } catch (e) {
      _vehiclesError = e.toString();
      debugPrint('❌ AppProvider: Error loading vehicles: $e');
      // Don't clear vehicles on error - keep existing data
    } finally {
      _isLoadingVehicles = false;
      notifyListeners();
    }
  }

  /// Refresh vehicles (pull-to-refresh)
  Future<void> refreshVehicles() async {
    await loadVehicles(forceRefresh: true);
  }

  /// Get vehicle by ID (from cache or fetch)
  Vehicle? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update vehicle status
  Future<void> updateVehicleStatus(
    String vehicleId,
    VehicleStatus status,
  ) async {
    try {
      debugPrint(
        '🔄 AppProvider: Updating vehicle $vehicleId status to ${status.name}',
      );

      // Save to Supabase FIRST - ensure it's persisted
      final updatedVehicle = await _supabaseService.updateVehicle(vehicleId, {
        'status': status.name,
      });

      // Verify the update was successful
      if (updatedVehicle.status != status) {
        throw Exception(
          'Status update verification failed: expected ${status.name}, got ${updatedVehicle.status.name}',
        );
      }

      debugPrint('✅ AppProvider: Status saved to Supabase successfully');

      // Update local state after successful save
      final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (vehicleIndex != -1) {
        _vehicles[vehicleIndex] = updatedVehicle;
        notifyListeners();
      }

      // Refresh from server to ensure we have the latest data
      await loadVehicles();
      debugPrint(
        '✅ AppProvider: Updated vehicle $vehicleId status to ${status.name} and refreshed',
      );
    } catch (e) {
      debugPrint('❌ AppProvider: Error updating vehicle status: $e');

      // Update local state optimistically for immediate UI feedback
      final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (vehicleIndex != -1) {
        _vehicles[vehicleIndex] = _vehicles[vehicleIndex].copyWith(
          status: status,
        );
        notifyListeners();
      }

      // Queue for offline sync
      await _queueOperation({
        'type': 'update_vehicle',
        'vehicleId': vehicleId,
        'data': {'status': status.name},
      });

      // Re-throw to let UI handle the error
      throw Exception('Failed to save status to database: $e');
    }
  }

  /// Update vehicle check-in status
  Future<void> updateVehicleCheckInStatus(
    String vehicleId,
    bool isCheckedIn,
  ) async {
    try {
      await _supabaseService.updateVehicle(vehicleId, {
        'is_vehicle_in': isCheckedIn,
        'last_check_in_time': isCheckedIn
            ? DateTime.now().toIso8601String()
            : null,
      });
      await loadVehicles(); // Refresh to get updated data
      debugPrint(
        'AppProvider: Updated vehicle $vehicleId check-in status to $isCheckedIn',
      );
    } catch (e) {
      debugPrint('AppProvider: Error updating vehicle check-in status: $e');
      // Queue for offline sync
      await _queueOperation({
        'type': 'update_vehicle',
        'vehicleId': vehicleId,
        'data': {
          'is_vehicle_in': isCheckedIn,
          'last_check_in_time': isCheckedIn
              ? DateTime.now().toIso8601String()
              : null,
        },
      });
    }
  }

  // ==================== ACTIVITY MANAGEMENT ====================

  /// Log a new activity (check-in/check-out)
  Future<void> logActivity(Activity activity) async {
    try {
      // Add hub info to metadata if available and not already present
      final updatedMetadata = Map<String, dynamic>.from(
        activity.metadata ?? {},
      );
      if (updatedMetadata['hub_name'] == null && _selectedHub != null) {
        updatedMetadata['hub_name'] = _selectedHub;
        debugPrint(
          'AppProvider: Injected hub_name into activity: $_selectedHub',
        );
      }

      // Validate that vehicleNumber is not null or empty
      if (activity.vehicleNumber.isEmpty) {
        // Try to get vehicle number from the vehicle list
        final vehicle = getVehicleById(activity.vehicleId);
        if (vehicle != null && vehicle.vehicleNumber.isNotEmpty) {
          // Recreate activity with correct vehicle number and updated metadata
          final correctedActivity = Activity(
            id: activity.id,
            vehicleId: activity.vehicleId,
            vehicleNumber: vehicle.vehicleNumber,
            activityType: activity.activityType,
            userName: activity.userName,
            timestamp: activity.timestamp,
            metadata: updatedMetadata,
          );
          await _supabaseService.createActivity(correctedActivity.toJson());
          debugPrint(
            'AppProvider: Activity logged: ${correctedActivity.activityType} for ${correctedActivity.vehicleNumber}',
          );
          _activities.insert(0, correctedActivity);
        } else {
          throw Exception(
            'Cannot log activity: vehicle_number is required but vehicle ${activity.vehicleId} not found or has no vehicle number',
          );
        }
      } else {
        // Create a new activity object with updated metadata to ensure it's saved correctly
        final finalActivity = Activity(
          id: activity.id,
          vehicleId: activity.vehicleId,
          vehicleNumber: activity.vehicleNumber,
          activityType: activity.activityType,
          userName: activity.userName,
          timestamp: activity.timestamp,
          metadata: updatedMetadata,
        );
        await _supabaseService.createActivity(finalActivity.toJson());
        debugPrint(
          'AppProvider: Activity logged: ${activity.activityType} for ${activity.vehicleNumber}',
        );
        _activities.insert(0, finalActivity);
      }

      // Reload activities from database to ensure we have the latest
      await loadActivities(limit: 20);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppProvider: Error logging activity: $e');
      debugPrint(
        '   Activity details: vehicleId=${activity.vehicleId}, vehicleNumber=${activity.vehicleNumber}, type=${activity.activityType}',
      );
      // Don't add to local cache if it failed - we want to retry
      rethrow; // Re-throw so caller knows it failed
    }
  }

  /// Load recent activities from Supabase
  Future<void> loadActivities({int limit = 20}) async {
    _isLoadingActivities = true;
    notifyListeners();

    try {
      debugPrint(
        '🔄 AppProvider: Loading activities from Supabase (Hub: $_selectedHub)...',
      );
      final data = await _supabaseService.getRecentActivities(
        limit: limit,
        hub: _selectedHub,
      );

      debugPrint(
        '📊 AppProvider: Received ${data.length} activities from service',
      );

      if (data.isEmpty) {
        debugPrint('⚠️ AppProvider: No activities returned from service');
        _activities.clear();
        _isLoadingActivities = false;
        notifyListeners();
        return;
      }

      // Parse activities with error handling
      _activities.clear();
      int successCount = 0;
      int errorCount = 0;

      for (var json in data) {
        try {
          // Debug the raw JSON
          debugPrint(
            '   Parsing activity: activity_type=${json['activity_type']}, vehicle_number=${json['vehicle_number']}',
          );

          final activity = Activity.fromJson(json);

          // Validate the parsed activity
          if (activity.vehicleNumber.isEmpty) {
            debugPrint('   ⚠️ Skipping activity with empty vehicle_number');
            errorCount++;
            continue;
          }

          if (activity.activityType.isEmpty) {
            debugPrint('   ⚠️ Skipping activity with empty activity_type');
            errorCount++;
            continue;
          }

          _activities.add(activity);
          successCount++;
        } catch (e, stackTrace) {
          debugPrint('   ❌ Error parsing activity: $e');
          debugPrint('   Activity data: $json');
          debugPrint('   Stack trace: $stackTrace');
          errorCount++;
        }
      }

      debugPrint(
        '✅ AppProvider: Successfully parsed $successCount activities (${errorCount} errors)',
      );
      debugPrint('   Total activities loaded: ${_activities.length}');

      // Log activity types for debugging
      if (_activities.isNotEmpty) {
        final checkIns = _activities.where((a) => a.isCheckIn).length;
        final checkOuts = _activities.where((a) => a.isCheckOut).length;
        debugPrint('   - Check-ins: $checkIns');
        debugPrint('   - Check-outs: $checkOuts');
      } else {
        debugPrint('   ⚠️ No valid activities after parsing');
      }
      // The notifyListeners() call is already in the finally block,
      // ensuring it's called after all processing, including parsing.
      // No additional notifyListeners() is needed here.
    } catch (e, stackTrace) {
      debugPrint('❌ AppProvider: Error loading activities: $e');
      debugPrint('   Stack trace: $stackTrace');
      _activities.clear(); // Clear on error
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  // ==================== ISSUE MANAGEMENT ====================

  /// Add a reported issue (save to Supabase)
  /// Returns a Map with 'photoUrl' and 'videoUrl' keys for the uploaded media
  Future<Map<String, String?>> addIssue(ReportedIssue issue) async {
    debugPrint(
      'AppProvider: Adding issue for vehicle ${issue.vehicleId}: ${issue.type}',
    );

    String? photoUrl;
    String? videoUrl;

    // Try to upload photos/videos, but don't fail if uploads fail
    // Upload photo if exists
    if (issue.photoPath != null) {
      try {
        debugPrint('AppProvider: Uploading issue photo...');
        final XFile file = XFile(issue.photoPath!);
        Uint8List bytes = await file.readAsBytes();

        // Compress image if it's too large (>2MB)
        if (bytes.length > 2 * 1024 * 1024) {
          debugPrint(
            'AppProvider: Image is ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB, compressing...',
          );
          bytes = await _compressImage(bytes);
          debugPrint(
            'AppProvider: Compressed to ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
          );
        }

        final String fileName =
            'issues/photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoUrl = await _supabaseService.uploadFile(
          fileName,
          bytes,
          'image/jpeg',
        );

        debugPrint('AppProvider: Issue photo uploaded: $photoUrl');
      } catch (e) {
        debugPrint(
          'AppProvider: ⚠️ Photo upload failed, continuing without photo: $e',
        );
        // Don't set photoUrl - issue will be saved without photo
      }
    }

    // Upload video if exists
    if (issue.videoPath != null) {
      try {
        debugPrint('AppProvider: Uploading issue video...');
        final XFile file = XFile(issue.videoPath!);
        final Uint8List bytes = await file.readAsBytes();

        final String fileName =
            'issues/videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
        videoUrl = await _supabaseService.uploadFile(
          fileName,
          bytes,
          'video/mp4',
        );

        debugPrint('AppProvider: Issue video uploaded: $videoUrl');
      } catch (e) {
        debugPrint(
          'AppProvider: ⚠️ Video upload failed, continuing without video: $e',
        );
        // Don't set videoUrl - issue will be saved without video
      }
    }

    // Always try to create maintenance job, even if media uploads failed
    try {
      final result = await _supabaseService.createMaintenanceJob({
        'vehicle_id': issue.vehicleId,
        'job_category': 'issue',
        'issue_type': issue.type,
        'description': issue.description,
        'diagnosis_date': issue.timestamp.toIso8601String(),
        'status': 'pending_diagnosis',
        'photo_url': photoUrl,
        'video_url': videoUrl,
      });

      // Try both possible ID column names
      final jobId = result['job_id']?.toString() ?? result['id']?.toString();
      debugPrint(
        'AppProvider: createMaintenanceJob result keys: ${result.keys.toList()}',
      );
      debugPrint(
        'AppProvider: ✅ Issue saved to Supabase with ID: $jobId (photo: ${photoUrl != null}, video: ${videoUrl != null})',
      );

      // Track job ID in session ONLY if issue has a photo (manual issues only!)
      // Checklist issues don't have photos and shouldn't be tracked
      if (jobId != null && photoUrl != null) {
        addSessionJobId(jobId);
        debugPrint(
          'AppProvider: 📌 Added job ID to session (has photo): $jobId',
        );
      }

      // Store COMPLETE issue data in session ONLY if it has a photo
      // Checklist issues (no photos) go to checklist_issues, not manual_issues
      if (photoUrl != null) {
        addSessionIssue({
          'type': issue.type,
          'description': issue.description,
          'photoUrl': photoUrl,
          'videoUrl': videoUrl,
          'jobId': jobId,
          'timestamp': issue.timestamp.toIso8601String(),
        });
        debugPrint('AppProvider: 📌 Added issue to session (has photo)');
      } else {
        debugPrint(
          'AppProvider: ℹ️ Not adding to session (no photo - checklist item)',
        );
      }

      // Also keep in local cache
      _reportedIssues.add(issue);
      await _persistIssues();

      notifyListeners();

      // Return the uploaded URLs AND the job ID
      return {'photoUrl': photoUrl, 'videoUrl': videoUrl, 'jobId': jobId};
    } catch (e) {
      debugPrint('AppProvider: ❌ Error saving issue to database: $e');

      // Save locally and queue for sync
      _reportedIssues.add(issue);
      await _persistIssues();

      await _queueOperation({'type': 'create_issue', 'issue': issue.toJson()});

      notifyListeners();
      rethrow; // Re-throw so AddIssueScreen knows it failed
    }
  }

  /// Compress image to reduce file size
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('Failed to decode image, returning original');
        return imageBytes;
      }

      // Resize if too large (max 1920px on longest side)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1920) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 1920);
        } else {
          resized = img.copyResize(image, height: 1920);
        }
      }

      // Compress with quality 85
      final compressed = img.encodeJpg(resized, quality: 85);

      // If still too large, reduce quality further
      if (compressed.length > 2 * 1024 * 1024) {
        debugPrint('Still too large, reducing quality to 70');
        return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
      }

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageBytes; // Return original if compression fails
    }
  }

  /// Upload media for manual issues and save to mobile_maintenance_jobs
  Future<void> uploadManualIssueMedia(List<Map<String, dynamic>> issues) async {
    for (var i = 0; i < issues.length; i++) {
      final issue = issues[i];
      String? photoUrl;
      String? videoUrl;

      // Upload Photo if exists
      if (issue['photoPath'] != null && issue['photoUrl'] == null) {
        try {
          final String path = issue['photoPath'];
          final XFile file = XFile(path);
          final Uint8List bytes = await file.readAsBytes();

          final String fileName =
              'issues/photos/${DateTime.now().millisecondsSinceEpoch}_${i}.jpg';
          photoUrl = await _supabaseService.uploadFile(
            fileName,
            bytes,
            'image/jpeg',
          );

          issues[i]['photoUrl'] = photoUrl;
          debugPrint('AppProvider: Manual issue photo uploaded: $photoUrl');
        } catch (e) {
          debugPrint('AppProvider: Error uploading manual issue photo: $e');
        }
      } else {
        photoUrl = issue['photoUrl'];
      }

      // Upload Video if exists
      if (issue['videoPath'] != null && issue['videoUrl'] == null) {
        try {
          final String path = issue['videoPath'];
          final XFile file = XFile(path);
          final Uint8List bytes = await file.readAsBytes();

          final String fileName =
              'issues/videos/${DateTime.now().millisecondsSinceEpoch}_${i}.mp4';
          videoUrl = await _supabaseService.uploadFile(
            fileName,
            bytes,
            'video/mp4',
          );

          issues[i]['videoUrl'] = videoUrl;
          debugPrint('AppProvider: Manual issue video uploaded: $videoUrl');
        } catch (e) {
          debugPrint('AppProvider: Error uploading manual issue video: $e');
        }
      } else {
        videoUrl = issue['videoUrl'];
      }

      // Save manual issue to mobile_maintenance_jobs table so it appears in admin app
      if (issue['vehicleId'] != null || issue['vehicle_id'] != null) {
        try {
          final vehicleId = issue['vehicleId'] ?? issue['vehicle_id'];
          final issueType = issue['type']?.toString() ?? 'Manual Issue';
          final description =
              issue['description']?.toString() ?? 'Manual issue reported';

          await _supabaseService.createMaintenanceJob({
            'vehicle_id': vehicleId,
            'job_category': 'issue',
            'issue_type': issueType,
            'description': description,
            'diagnosis_date': DateTime.now().toIso8601String(),
            'status': 'pending_diagnosis',
            'photo_url': photoUrl,
            'video_url': videoUrl,
          });

          debugPrint(
            'AppProvider: ✅ Manual issue saved to mobile_maintenance_jobs: $issueType (photo: ${photoUrl != null})',
          );
        } catch (e) {
          debugPrint(
            'AppProvider: ❌ Error saving manual issue to database: $e',
          );
        }
      }
    }
  }

  /// Upload media for manual issues ONLY (does NOT save to mobile_maintenance_jobs)
  /// Returns the updated issues list with photo/video URLs for storing in mobile_inventory_records
  Future<List<Map<String, dynamic>>> uploadManualIssueMediaOnly(
    List<Map<String, dynamic>> issues,
  ) async {
    debugPrint('=== uploadManualIssueMediaOnly CALLED ===');
    debugPrint('Input issues count: ${issues.length}');
    for (var i = 0; i < issues.length; i++) {
      debugPrint('  Issue $i: ${issues[i]}');
    }

    final List<Map<String, dynamic>> updatedIssues = [];

    for (var i = 0; i < issues.length; i++) {
      final issue = Map<String, dynamic>.from(issues[i]);
      String? photoUrl;
      String? videoUrl;

      debugPrint(
        'Processing issue $i: type=${issue['type']}, photoPath=${issue['photoPath']}, photoUrl=${issue['photoUrl']}',
      );

      // Upload Photo if exists
      if (issue['photoPath'] != null && issue['photoUrl'] == null) {
        try {
          final String path = issue['photoPath'];
          debugPrint('  Uploading photo from path: $path');
          final XFile file = XFile(path);
          final Uint8List bytes = await file.readAsBytes();

          final String fileName =
              'issues/photos/${DateTime.now().millisecondsSinceEpoch}_${i}.jpg';
          photoUrl = await _supabaseService.uploadFile(
            fileName,
            bytes,
            'image/jpeg',
          );

          issue['photoUrl'] = photoUrl;
          debugPrint('  ✅ Photo uploaded: $photoUrl');
        } catch (e) {
          debugPrint('  ❌ Error uploading photo: $e');
        }
      } else if (issue['photoUrl'] != null) {
        photoUrl = issue['photoUrl'];
        debugPrint('  Using existing photoUrl: $photoUrl');
      } else {
        debugPrint('  No photo to upload (photoPath is null)');
      }

      // Upload Video if exists
      if (issue['videoPath'] != null && issue['videoUrl'] == null) {
        try {
          final String path = issue['videoPath'];
          debugPrint('  Uploading video from path: $path');
          final XFile file = XFile(path);
          final Uint8List bytes = await file.readAsBytes();

          final String fileName =
              'issues/videos/${DateTime.now().millisecondsSinceEpoch}_${i}.mp4';
          videoUrl = await _supabaseService.uploadFile(
            fileName,
            bytes,
            'video/mp4',
          );

          issue['videoUrl'] = videoUrl;
          debugPrint('  ✅ Video uploaded: $videoUrl');
        } catch (e) {
          debugPrint('  ❌ Error uploading video: $e');
        }
      } else if (issue['videoUrl'] != null) {
        videoUrl = issue['videoUrl'];
        debugPrint('  Using existing videoUrl: $videoUrl');
      }

      // Add the updated issue with URLs to the result list
      final updatedIssue = {
        'type': issue['type']?.toString() ?? 'Issue',
        'description': issue['description']?.toString() ?? '',
        'photoUrl': photoUrl,
        'videoUrl': videoUrl,
      };
      updatedIssues.add(updatedIssue);
      debugPrint('  Added to result: $updatedIssue');
    }

    debugPrint('=== uploadManualIssueMediaOnly RESULT ===');
    debugPrint('Output issues count: ${updatedIssues.length}');
    for (var i = 0; i < updatedIssues.length; i++) {
      debugPrint('  Result $i: ${updatedIssues[i]}');
    }

    return updatedIssues;
  }

  /// Get issues for a vehicle (from Supabase)
  Future<List<Map<String, dynamic>>> getIssuesForVehicle(
    String vehicleId,
  ) async {
    try {
      return await _supabaseService.getMaintenanceJobs(vehicleId);
    } catch (e) {
      debugPrint('AppProvider: Error fetching issues: $e');
      // Fallback to local cache
      return _reportedIssues
          .where((i) => i.vehicleId == vehicleId)
          .map((i) => i.toJson())
          .toList();
    }
  }

  /// Remove an issue
  Future<void> removeIssue(String issueId) async {
    debugPrint('AppProvider: Removing issue $issueId');

    try {
      await _supabaseService.deleteMaintenanceJob(issueId);
      _reportedIssues.removeWhere((i) => i.id == issueId);
      await _persistIssues();
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error removing issue: $e');

      // Queue for offline sync
      await _queueOperation({'type': 'delete_issue', 'issueId': issueId});
    }
  }

  // ==================== INSPECTION MANAGEMENT ====================

  /// Save inspection result
  Future<void> saveInspection(InspectionResult result) async {
    try {
      // Save to Supabase
      await _supabaseService.createDailyInventory({
        'vehicle_id': result.vehicleId,
        'check_date': result.timestamp.toIso8601String(),
        'status': 'completed',
        'notes': jsonEncode(result.checks),
      });

      // Update summary data on crm_vehicles for admin panel
      await _supabaseService.updateVehicle(result.vehicleId, {
        'last_full_scan': result.checks,
        'last_inventory_time': result.timestamp.toIso8601String(),
      });

      debugPrint(
        'AppProvider: Full Scan saved to Supabase and summary updated',
      );

      // Also keep in local cache
      _inspectionResults.removeWhere((r) => r.vehicleId == result.vehicleId);
      _inspectionResults.add(result);
      await _persistInspections();

      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error saving inspection: $e');

      // Save locally and queue for sync
      _inspectionResults.removeWhere((r) => r.vehicleId == result.vehicleId);
      _inspectionResults.add(result);
      await _persistInspections();

      await _queueOperation({
        'type': 'create_inspection',
        'inspection': result.toJson(),
      });

      notifyListeners();
    }
  }

  Future<void> updateVehicleSummary(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint(
        '🔄 AppProvider: Updating vehicle summary for $vehicleId with data: $data',
      );

      // Save to Supabase FIRST - ensure it's persisted
      final updatedVehicle = await _supabaseService.updateVehicle(
        vehicleId,
        data,
      );

      debugPrint(
        '✅ AppProvider: Vehicle summary saved to Supabase successfully',
      );
      debugPrint('   Updated fields: ${data.keys.join(", ")}');

      // Update local vehicle state to reflect changes immediately
      final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (vehicleIndex != -1) {
        _vehicles[vehicleIndex] = updatedVehicle;
        debugPrint('✅ AppProvider: Local vehicle state updated for $vehicleId');
        debugPrint('   is_vehicle_in: ${updatedVehicle.isVehicleIn}');
      }

      notifyListeners();

      // Force a refresh from database to ensure we have the latest data
      await loadVehicles();
      debugPrint(
        '✅ AppProvider: Vehicle summary updated and refreshed from database',
      );
    } catch (e) {
      debugPrint('❌ AppProvider: Error updating vehicle summary: $e');
      debugPrint('   Vehicle ID: $vehicleId');
      debugPrint('   Data attempted: $data');

      // Update local state optimistically for immediate UI feedback
      final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (vehicleIndex != -1) {
        try {
          final currentJson = _vehicles[vehicleIndex].toJson();
          data.forEach((key, value) {
            currentJson[key] = value;
          });
          _vehicles[vehicleIndex] = Vehicle.fromJson(currentJson);
          notifyListeners();
          debugPrint('   ✅ Local state updated optimistically');
        } catch (innerE) {
          debugPrint(
            '   ⚠️ Could not update local state optimistically: $innerE',
          );
        }
      }

      // Queue for offline sync
      await _queueOperation({
        'type': 'update_vehicle_summary',
        'vehicleId': vehicleId,
        'data': data,
      });

      rethrow;
    }
  }

  Future<void> saveDailyChecks(
    String vehicleId,
    Map<String, bool?> checks,
  ) async {
    try {
      final Map<String, bool> cleanedChecks = {};
      checks.forEach((key, value) {
        if (value != null) cleanedChecks[key] = value;
      });

      await updateVehicleSummary(vehicleId, {
        'daily_checks': cleanedChecks,
        'last_inventory_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('AppProvider: Error saving daily checks: $e');
      rethrow;
    }
  }

  InspectionResult? getInspectionForVehicle(String vehicleId) {
    try {
      return _inspectionResults.firstWhere((r) => r.vehicleId == vehicleId);
    } catch (e) {
      return null;
    }
  }

  // ==================== INVENTORY PHOTOS ====================

  // ==================== DRIVER MANAGEMENT ====================

  Future<void> loadDrivers() async {
    if (_isLoadingDrivers) return;

    _isLoadingDrivers = true;
    _driversError = null;
    notifyListeners();

    try {
      if (_selectedHub == null) {
        _drivers = await DriverService.searchDrivers('');
      } else {
        _drivers = await DriverService.getDriversByHub(_selectedHub!);
        // Also fetch statuses
        _driverStatuses = await DriverService.getDriverStatuses(_selectedHub!);
      }
      debugPrint(
        '✅ AppProvider: Loaded ${_drivers.length} drivers and ${_driverStatuses.length} statuses',
      );
    } catch (e) {
      debugPrint('❌ AppProvider: Error loading drivers: $e');
      _driversError = e.toString();
    } finally {
      _isLoadingDrivers = false;
      notifyListeners();
    }
  }

  Future<void> addDriver(Driver driver) async {
    try {
      debugPrint('🔄 AppProvider: Adding new driver ${driver.name}');
      final newDriver = await DriverService.createDriver(driver);

      // Update local state
      _drivers.add(newDriver);
      _drivers.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      debugPrint('✅ AppProvider: Driver added and state updated');
    } catch (e) {
      debugPrint('❌ AppProvider: Error adding driver: $e');
      rethrow;
    }
  }

  /// Update an existing driver
  Future<void> updateDriver(Driver driver) async {
    try {
      final updatedDriver = await DriverService.updateDriver(driver);
      final index = _drivers.indexWhere((d) => d.id == driver.id);
      if (index != -1) {
        _drivers[index] = updatedDriver;
        _drivers.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ AppProvider: Error updating driver: $e');
      rethrow;
    }
  }

  /// Remove a driver
  Future<void> removeDriver(String driverId) async {
    try {
      await DriverService.deleteDriver(driverId);
      _drivers.removeWhere((d) => d.id == driverId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppProvider: Error removing driver: $e');
      rethrow;
    }
  }

  Future<String?> setInventoryPhoto(
    String vehicleId,
    String category,
    String path,
  ) async {
    if (!_inventoryPhotos.containsKey(vehicleId)) {
      _inventoryPhotos[vehicleId] = {};
    }
    _inventoryPhotos[vehicleId]![category] = path;
    await _persistPhotos();

    String? photoUrl;
    try {
      // 1. Read bytes from photo path
      final XFile file = XFile(path);
      final Uint8List bytes = await file.readAsBytes();

      // 2. Upload to Supabase Storage
      final String fileName =
          'inventory/${vehicleId}/${category}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      photoUrl = await _supabaseService.uploadFile(
        fileName,
        bytes,
        'image/jpeg',
      );

      // 3. Save photo record to mobile_inventory_photos table
      await _supabaseService.saveInventoryPhoto(
        vehicleId: vehicleId,
        category: category,
        photoUrl: photoUrl,
      );

      // 4. Update the summary count on crm_vehicles
      final photoCount = _inventoryPhotos[vehicleId]?.length ?? 0;
      await _supabaseService.updateVehicle(vehicleId, {
        'inventory_photo_count': photoCount,
        'last_inventory_time': DateTime.now().toIso8601String(),
      });

      debugPrint(
        'AppProvider: Inventory photo uploaded and count updated for $vehicleId: $photoCount',
      );
    } catch (e) {
      debugPrint('AppProvider: Error during photo upload/sync: $e');
      rethrow; // Rethrow to allow UI to handle
    }

    notifyListeners();
    return photoUrl;
  }

  Map<String, String> getInventoryPhotos(String vehicleId) {
    return _inventoryPhotos[vehicleId] ?? {};
  }

  Future<void> removeInventoryPhoto(String vehicleId, String category) async {
    if (_inventoryPhotos.containsKey(vehicleId)) {
      _inventoryPhotos[vehicleId]!.remove(category);
      await _persistPhotos();
      notifyListeners();
    }
  }

  Future<void> clearInventoryPhotos(String vehicleId) async {
    _inventoryPhotos.remove(vehicleId);
    await _persistPhotos();
    notifyListeners();
  }

  // ==================== OFFLINE SUPPORT ====================

  Future<void> _queueOperation(Map<String, dynamic> operation) async {
    _pendingOperations.add({
      ...operation,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingOperations', jsonEncode(_pendingOperations));

    debugPrint(
      'AppProvider: Queued operation for offline sync: ${operation['type']}',
    );
  }

  Future<void> _syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    debugPrint(
      'AppProvider: Syncing ${_pendingOperations.length} pending operations',
    );

    final List<Map<String, dynamic>> failedOps = [];

    for (final op in _pendingOperations) {
      try {
        switch (op['type']) {
          case 'update_vehicle':
          case 'update_vehicle_summary':
            await _supabaseService.updateVehicle(op['vehicleId'], op['data']);
            break;
          case 'create_issue':
            final issue = ReportedIssue.fromJson(op['issue']);
            await _supabaseService.createMaintenanceJob({
              'vehicle_id': issue.vehicleId,
              'job_category': 'issue',
              'issue_type': issue.type,
              'description': issue.description,
              'diagnosis_date': issue.timestamp.toIso8601String(),
              'status': 'pending_diagnosis',
            });
            break;
          case 'delete_issue':
            await _supabaseService.deleteMaintenanceJob(op['issueId']);
            break;
          case 'create_inspection':
            final inspection = InspectionResult.fromJson(op['inspection']);
            await _supabaseService.createDailyInventory({
              'vehicle_id': inspection.vehicleId,
              'check_date': inspection.timestamp.toIso8601String(),
              'status': 'completed',
              'notes': jsonEncode(inspection.checks),
            });

            // Also update crm_vehicles summary
            final Map<String, bool> dailyChecks = {};
            inspection.checks.forEach((key, value) {
              dailyChecks[key] =
                  value == 'ok' || value == 'yes' || value == 'true';
            });

            await _supabaseService.updateVehicle(inspection.vehicleId, {
              'daily_checks': dailyChecks,
              'last_inventory_time': inspection.timestamp.toIso8601String(),
            });
            break;
        }
        debugPrint('AppProvider: Synced operation: ${op['type']}');
      } catch (e) {
        debugPrint(
          'AppProvider: Failed to sync operation: ${op['type']}, error: $e',
        );
        failedOps.add(op);
      }
    }

    _pendingOperations.clear();
    _pendingOperations.addAll(failedOps);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingOperations', jsonEncode(_pendingOperations));

    if (failedOps.isEmpty) {
      debugPrint('AppProvider: All pending operations synced successfully');
    } else {
      debugPrint('AppProvider: ${failedOps.length} operations failed to sync');
    }
  }

  // ==================== PERSISTENCE ====================

  Future<void> _persistIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_reportedIssues.map((i) => i.toJson()).toList());
    await prefs.setString('reportedIssues', json);
  }

  Future<void> _persistInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_inspectionResults.map((i) => i.toJson()).toList());
    await prefs.setString('inspectionResults', json);
  }

  Future<void> _persistPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventoryPhotos', jsonEncode(_inventoryPhotos));
  }

  // ==================== ROUTE MANAGEMENT ====================

  Future<void> setLastRoute(String route) async {
    if (_lastRoute == route) return;
    if (route == '/login') return;

    debugPrint('AppProvider: SAVING ROUTE: $route');
    _lastRoute = route;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastRoute', route);
  }

  Future<void> clearLastRoute() async {
    debugPrint('AppProvider: CLEARING ROUTE');
    _lastRoute = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastRoute');
  }

  // ==================== AUTH ====================

  /// Validate login credentials against database
  Future<Map<String, dynamic>?> validateLogin(
    String email,
    String password,
    String hub,
  ) async {
    try {
      debugPrint('🔐 validateLogin called:');
      debugPrint('   Email: $email');
      debugPrint('   Selected Hub: $hub');

      final user = await _supabaseService.authenticateUser(email, password);

      if (user == null) {
        debugPrint('❌ Login failed: Invalid credentials or user not found');
        return null;
      }

      // Check if hub matches (case-sensitive comparison!)
      final dbHub = user['hub']?.toString() ?? '';
      debugPrint('📍 Comparing hubs:');
      debugPrint('   DB Hub: "$dbHub"');
      debugPrint('   Selected Hub: "$hub"');
      debugPrint('   Match: ${dbHub == hub}');

      if (dbHub != hub) {
        debugPrint('❌ Login failed: Hub mismatch!');
        debugPrint('   User\'s hub in database is "$dbHub"');
        debugPrint('   But selected hub is "$hub"');
        debugPrint('   These must match EXACTLY (case-sensitive)');
        return null;
      }

      debugPrint(
        '✅ Login validation successful for ${user['email']} at ${user['hub']}',
      );
      return user;
    } catch (e) {
      debugPrint('❌ Login validation error: $e');
      return null;
    }
  }

  Future<void> login(Map<String, dynamic> userData) async {
    final email = userData['email'] as String;
    final hub = userData['hub'] as String;
    final fullName = userData['full_name'] as String?;
    final mobile = userData['mobile'] as String?;

    debugPrint('🔐 AppProvider: LOGIN ACTION TRIGGERED for $email at $hub');
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);
    await prefs.setString('selectedHub', hub);
    if (fullName != null) {
      await prefs.setString('userName', fullName);
    }
    if (mobile != null) {
      await prefs.setString('userMobile', mobile);
    }

    debugPrint('💾 AppProvider: User data saved to SharedPreferences:');
    debugPrint('   - isLoggedIn: true');
    debugPrint('   - userEmail: $email');
    debugPrint('   - selectedHub: $hub');
    debugPrint('   - userName: $fullName');
    debugPrint('   - userMobile: $mobile');

    _isLoggedIn = true;
    _userEmail = email;
    _selectedHub = hub;
    _userName = fullName;
    _userMobile = mobile;

    debugPrint('✅ AppProvider: Login state updated. Notifying listeners...');

    // Load vehicles after login - force refresh to get latest data
    await loadVehicles(forceRefresh: true);
    await _syncPendingOperations();

    notifyListeners();
  }

  static const List<String> availableHubs = [
    'Nashik',
    'Pune Hinjewadi',
    'Pune Kharadi',
  ];

  Future<void> setSelectedHub(String hub) async {
    debugPrint('🔄 AppProvider: Changing hub to $hub');
    _selectedHub = hub;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedHub', hub);

    notifyListeners();

    // Reload vehicles for the new hub
    await loadVehicles(forceRefresh: true);
    // Reload activities (activities might also be hub-specific in the future)
    await loadActivities(limit: 20);

    debugPrint('✅ AppProvider: Hub changed and data reloaded for $hub');
  }

  /// Update user profile (name and mobile)
  Future<void> updateUserProfile({String? fullName, String? mobile}) async {
    try {
      debugPrint('🔄 AppProvider: Updating user profile...');

      if (_userEmail == null) {
        throw Exception('User email is required to update profile');
      }

      // Update in database
      await _supabaseService.updateUserProfile(
        email: _userEmail!,
        fullName: fullName,
        mobile: mobile,
      );

      // Update local state
      final prefs = await SharedPreferences.getInstance();

      if (fullName != null) {
        _userName = fullName;
        await prefs.setString('userName', fullName);
        debugPrint('   - Updated userName: $fullName');
      }

      if (mobile != null) {
        _userMobile = mobile;
        await prefs.setString('userMobile', mobile);
        debugPrint('   - Updated userMobile: $mobile');
      }

      debugPrint('✅ AppProvider: Profile updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppProvider: Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    debugPrint('AppProvider: LOGOUT ACTION TRIGGERED');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _isLoggedIn = false;

    // Clear user data
    _userEmail = null;
    _selectedHub = null;
    _userName = null;

    // Clear data on logout
    _vehicles.clear();
    _reportedIssues.clear();
    _inspectionResults.clear();
    _inventoryPhotos.clear();
    _pendingOperations.clear();

    // Clear shift data
    _isShiftActive = false;
    _shiftStartTime = null;
    _shiftEndTime = null;

    await prefs.remove('userEmail');
    await prefs.remove('selectedHub');
    await prefs.remove('userName');
    await prefs.remove('reportedIssues');
    await prefs.remove('inspectionResults');
    await prefs.remove('inventoryPhotos');
    await prefs.remove('pendingOperations');
    await prefs.remove('lastRoute');
    await prefs.remove('isShiftActive');
    await prefs.remove('shiftStartTime');
    await prefs.remove('shiftEndTime');
    _lastRoute = null;

    debugPrint(
      'AppProvider: isLoggedIn set to false and PERSISTED. Notifying listeners...',
    );
    notifyListeners();
  }

  // ==================== SETTINGS ====================

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    notifyListeners();
  }

  // ==================== SHIFT MANAGEMENT ====================

  /// Start a new shift
  Future<void> startShift() async {
    final now = DateTime.now();
    _isShiftActive = true;
    _shiftStartTime = now;
    _shiftEndTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isShiftActive', true);
    await prefs.setString('shiftStartTime', now.toIso8601String());
    await prefs.remove('shiftEndTime');

    debugPrint('✅ AppProvider: Shift started at $now');
    notifyListeners();
  }

  /// End the current shift
  Future<void> endShift() async {
    final now = DateTime.now();
    _isShiftActive = false;
    _shiftEndTime = now;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isShiftActive', false);
    await prefs.setString('shiftEndTime', now.toIso8601String());

    debugPrint('✅ AppProvider: Shift ended at $now');
    notifyListeners();
  }

  /// Get formatted shift duration
  String get shiftDuration {
    if (_shiftStartTime == null) return '--';
    final end = _isShiftActive
        ? DateTime.now()
        : (_shiftEndTime ?? DateTime.now());
    final diff = end.difference(_shiftStartTime!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // ==================== CONSTANTS ====================

  static const List<String> issueTypes = [
    'Battery Drain',
    'Charging Failure',
    'Motor Noise',
    'Brake Squeal',
    'Tire Pressure',
    'Coolant Leak',
    'AC Not Cooling',
    '12V Battery Low',
  ];
}
