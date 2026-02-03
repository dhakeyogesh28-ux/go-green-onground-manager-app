import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/providers/app_provider.dart';
import 'package:mobile/models/vehicle.dart';
import 'package:mobile/models/activity.dart';
import 'package:mobile/models/driver.dart';
import '../theme.dart';
import '../widgets/camera_overlay_screen.dart';
import '../widgets/number_plate_camera_screen.dart';
import '../widgets/driver_assignment_section.dart';
import '../services/challan_service.dart';
import '../services/driver_service.dart';
import 'package:mobile/l10n/app_localizations.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Vehicle? _selectedVehicle;
  Driver? _selectedDriver;
  String? _ridePurpose; // 'B2B' or 'B2C'
  String? _selectedChargingType;
  int _consecutiveACCharges = 0;
  int _consecutiveDCCharges = 0;
  // Changed to tri-state: null = unchecked, true = OK, false = Issue
  final Map<String, bool?> _inspectionChecklist = {};
  final Map<String, String?> _inventoryPhotos = {};
  final List<Map<String, dynamic>> _reportedIssues = [];
  bool _isSearching = true;
  bool _hasLaunchedScanner = false;
  bool _isInteriorClean = true;

  // Inventory photo categories
  final List<Map<String, dynamic>> _photoCategories = [
    {
      'id': 'exterior_front',
      'label': 'Exterior: Front View',
      'icon': LucideIcons.car,
    },
    {
      'id': 'exterior_rear',
      'label': 'Exterior: Rear View',
      'icon': LucideIcons.car,
    },
    {
      'id': 'exterior_left',
      'label': 'Exterior: Left Side',
      'icon': LucideIcons.car,
    },
    {
      'id': 'exterior_right',
      'label': 'Exterior: Right Side',
      'icon': LucideIcons.car,
    },
    {'id': 'odometer', 'label': 'Odometer Photo', 'icon': LucideIcons.gauge},
    {'id': 'stepney_tyre', 'label': 'Stepney Tyre', 'icon': LucideIcons.disc},
    {'id': 'umbrella', 'label': 'Umbrella', 'icon': LucideIcons.umbrella},
    {
      'id': 'engine_compartment',
      'label': 'Engine Compartment',
      'icon': LucideIcons.container,
    },
    {
      'id': 'corner_view_1',
      'label': 'Corner View 1',
      'icon': LucideIcons.maximize,
    },
    {
      'id': 'corner_view_2',
      'label': 'Corner View 2',
      'icon': LucideIcons.maximize,
    },
    {
      'id': 'corner_view_3',
      'label': 'Corner View 3',
      'icon': LucideIcons.maximize,
    },
    {
      'id': 'corner_view_4',
      'label': 'Corner View 4',
      'icon': LucideIcons.maximize,
    },
    {
      'id': 'dents_scratches',
      'label': 'Dents & Scratches',
      'icon': LucideIcons.scan,
    },
    {
      'id': 'interior_cabin',
      'label': 'Interior / Cabin',
      'icon': LucideIcons.armchair,
    },
    {
      'id': 'dikki_trunk',
      'label': 'Dikki / Trunk',
      'icon': LucideIcons.package,
    },
    {'id': 'tool_kit', 'label': 'Tool Kit', 'icon': LucideIcons.wrench},
    {
      'id': 'valuables_check',
      'label': 'Valuables Check',
      'icon': LucideIcons.briefcase,
    },
  ];

  final List<String> _additionalPhotos = [];

  // EV-Specific Inspection sections
  final Map<String, List<Map<String, String>>> _inspectionSections = {
    'Exterior': [
      {'id': 'wiper_water_spray', 'label': 'Wiper Water Spray'},
      {'id': 'headlight', 'label': 'Headlight'},
      {'id': 'taillight', 'label': 'Taillight'},
      {'id': 'tyres', 'label': 'Tyres'},
      {'id': 'stepney_tyre', 'label': 'Stepney Tyre'},
    ],
  };

  @override
  void initState() {
    super.initState();

    // Initialize checklist with null (unchecked)
    _inspectionSections.forEach((section, items) {
      for (var item in items) {
        _inspectionChecklist[item['id']!] = null;
      }
    });
    // Initialize photo slots
    for (var category in _photoCategories) {
      _inventoryPhotos[category['id']!] = null;
    }
    // Auto-launch number plate scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLaunchedScanner) {
        _launchPlateScanner();
      }
    });
  }

  Future<void> _launchPlateScanner() async {
    if (_hasLaunchedScanner) return;

    setState(() {
      _hasLaunchedScanner = true;
    });

    final String? plateNumber = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const NumberPlateCameraScreen()),
    );

    if (plateNumber != null && mounted) {
      // Set search text and search for vehicle
      _searchController.text = plateNumber;
      _searchVehicle(plateNumber);
    }
  }

  void _searchVehicle(String plateNumber) async {
    final appProvider = context.read<AppProvider>();
    final vehicles = appProvider.vehicles;

    final foundVehicle = vehicles.firstWhere(
      (v) => v.vehicleNumber.toUpperCase() == plateNumber.toUpperCase(),
      orElse: () => vehicles.first, // Fallback
    );

    if (foundVehicle.vehicleNumber.toUpperCase() == plateNumber.toUpperCase()) {
      setState(() {
        _selectedVehicle = foundVehicle;
        _isSearching = false;
        // Load DC charge count from vehicle metadata (optional field)
        try {
          _consecutiveACCharges =
              foundVehicle.toJson()['consecutive_ac_charges'] ?? 0;
        } catch (e) {
          _consecutiveACCharges = 0;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle ${foundVehicle.vehicleNumber} found!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      // Check for challans
      _checkChallans(plateNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle not found. Please search manually.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
    }
  }

  Future<void> _checkChallans(String vehicleNumber) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking for traffic challans...'),
          duration: Duration(seconds: 2),
        ),
      );

      final challanResponse = await ChallanService.checkChallans(vehicleNumber);

      if (mounted && challanResponse.hasChallans) {
        _showChallanAlert(challanResponse);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ No pending challans found'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check challans: $e'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
    }
  }

  void _showChallanAlert(ChallanResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppTheme.dangerRed),
            const SizedBox(width: 12),
            const Text('Traffic Challans Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Challans',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${response.challanCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '₹${response.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (response.challans.isNotEmpty) const SizedBox(height: 16),
            if (response.challans.isNotEmpty)
              const Text(
                'Challan Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            if (response.challans.isNotEmpty) const SizedBox(height: 8),
            ...response.challans
                .take(3)
                .map(
                  (challan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challan.violation,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${challan.amount.toStringAsFixed(0)} • ${challan.date}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, Proceed Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  List<Vehicle> _getFilteredVehicles(List<Vehicle> allVehicles) {
    if (_searchController.text.isEmpty) {
      return allVehicles;
    }

    final query = _searchController.text.toLowerCase();
    return allVehicles.where((vehicle) {
      return vehicle.vehicleNumber.toLowerCase().contains(query) ||
          vehicle.customerName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _capturePhoto(
    String categoryId, {
    bool autoAdvance = true,
  }) async {
    // Find the category to get its label
    final category = _photoCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'id': categoryId, 'label': 'Photo'},
    );

    try {
      // Navigate to camera overlay screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraOverlayScreen(
            categoryId: categoryId,
            categoryLabel: category['label'] as String,
            onPhotoTaken: (String photoPath) {
              setState(() {
                if (categoryId == 'additional_photos') {
                  _additionalPhotos.add(photoPath);
                } else {
                  _inventoryPhotos[categoryId] = photoPath;
                }
              });

              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category['label']} captured successfully'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }

              // Auto-advance to next uncaptured photo (only for required photos)
              if (autoAdvance && mounted) {
                _autoAdvanceToNextPhoto(categoryId);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _autoAdvanceToNextPhoto(String currentCategoryId) {
    // Find the current category index
    final currentIndex = _photoCategories.indexWhere(
      (cat) => cat['id'] == currentCategoryId,
    );

    if (currentIndex == -1) return;

    // Find the next uncaptured required photo
    for (int i = currentIndex + 1; i < _photoCategories.length; i++) {
      final nextCategory = _photoCategories[i];
      final categoryId = nextCategory['id'] as String;
      final isOptional = nextCategory['isOptional'] == true;
      final isCaptured = _inventoryPhotos[categoryId] != null;

      // Skip if already captured
      if (isCaptured) continue;

      // For required photos, auto-advance immediately
      // For optional photos, don't auto-advance (let user choose)
      if (!isOptional) {
        // Small delay to let the UI update
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _capturePhoto(categoryId, autoAdvance: true);
          }
        });
        return;
      }
    }

    // If we reach here, all required photos are captured
    // Check if there are any optional photos left
    final hasUncapturedOptional = _photoCategories.any((cat) {
      final id = cat['id'] as String;
      final isOptional = cat['isOptional'] == true;
      final isCaptured = _inventoryPhotos[id] != null;
      return isOptional && !isCaptured;
    });

    if (hasUncapturedOptional && mounted) {
      // Show message that required photos are done
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All required photos captured! You can add optional photos if needed.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToAddIssue() async {
    if (_selectedVehicle == null) return;

    final result = await context.push('/add-issue/${_selectedVehicle!.id}');

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _reportedIssues.add(<String, dynamic>{
          'type': result['type'] as String,
          'description': result['description'] as String,
          'photoPath': result['photoPath'] as String?,
          'videoPath': result['videoPath'] as String?,
        });
      });
    }
  }

  Future<void> _updateChargeCount() async {
    if (_selectedVehicle == null || _selectedChargingType == null) return;

    try {
      final provider = context.read<AppProvider>();

      if (_selectedChargingType == 'ac') {
        _consecutiveACCharges++;
        _consecutiveDCCharges = 0;
        await provider.updateVehicleSummary(_selectedVehicle!.id, {
          'consecutive_ac_charges': _consecutiveACCharges,
          'consecutive_dc_charges': 0,
        });
      } else if (_selectedChargingType == 'dc') {
        _consecutiveDCCharges++;
        _consecutiveACCharges = 0;
        await provider.updateVehicleSummary(_selectedVehicle!.id, {
          'consecutive_dc_charges': _consecutiveDCCharges,
          'consecutive_ac_charges': 0,
        });
      }
    } catch (e) {
      debugPrint('Warning: Could not update charge count: $e');
    }
  }

  Future<void> _handleCheckOut() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
    }

    // Validate charging type selection
    if (_selectedChargingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a charging type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    try {
      debugPrint(
        '🚗 Starting check-out process for ${_selectedVehicle!.vehicleNumber}',
      );

      // 1. Update charge counter
      await _updateChargeCount();

      // 2. Save inspection checklist to database
      final Map<String, dynamic> cleanedChecklist = {};
      final List<String> issueItems = []; // Track items marked as Issue

      _inspectionChecklist.forEach((key, value) {
        if (value != null) {
          cleanedChecklist[key] = value;
          // If value is false, it means "Issue" was selected
          if (value == false) {
            // Find the label for this item
            String? itemLabel;
            for (var section in _inspectionSections.values) {
              for (var item in section) {
                if (item['id'] == key) {
                  itemLabel = item['label'];
                  break;
                }
              }
              if (itemLabel != null) break;
            }
            if (itemLabel != null) {
              issueItems.add(itemLabel);
            }
          }
        }
      });

      // 3. Create maintenance jobs for items marked as "Issue"
      if (issueItems.isNotEmpty) {
        debugPrint(
          '⚠️ Creating maintenance jobs for ${issueItems.length} issues...',
        );

        for (var issueLabel in issueItems) {
          try {
            await provider.addIssue(
              ReportedIssue(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    '_' +
                    issueLabel.hashCode.toString(),
                vehicleId: _selectedVehicle!.id,
                type: 'Inspection Issue',
                description:
                    'Issue detected during check-out inspection: $issueLabel',
                timestamp: DateTime.now(),
              ),
            );

            debugPrint('✅ Created maintenance job for: $issueLabel');
          } catch (e) {
            debugPrint(
              'Warning: Could not create maintenance job for $issueLabel: $e',
            );
            // Continue with other issues even if one fails
          }
        }

        // Show notification to user about issues reported
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${issueItems.length} issue(s) reported to admin'),
              backgroundColor: AppTheme.warningOrange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // 4. Save inventory photos to Supabase Storage and database
      debugPrint('📸 Saving ${_inventoryPhotos.length} inventory photos...');
      for (var entry in _inventoryPhotos.entries) {
        if (entry.value != null) {
          try {
            await provider.setInventoryPhoto(
              _selectedVehicle!.id,
              entry.key,
              entry.value!,
            );
          } catch (e) {
            debugPrint('Warning: Could not save photo ${entry.key}: $e');
          }
        }
      }

      // Save additional photos
      debugPrint('📸 Saving ${_additionalPhotos.length} additional photos...');
      for (int i = 0; i < _additionalPhotos.length; i++) {
        try {
          await provider.setInventoryPhoto(
            _selectedVehicle!.id,
            'additional_photo_$i',
            _additionalPhotos[i],
          );
        } catch (e) {
          debugPrint('Warning: Could not save additional photo $i: $e');
        }
      }

      // 5. Update vehicle data in database - THIS MUST COMPLETE SUCCESSFULLY
      debugPrint('💾 Updating vehicle data in database...');

      // Store interior cleaning status and odometer within daily_checks map to avoid missing column error
      cleanedChecklist['interior_clean'] = _isInteriorClean;
      cleanedChecklist['odometer_reading'] = _odometerController.text.trim();
      cleanedChecklist['ride_purpose'] = _ridePurpose;

      try {
        await provider.updateVehicleSummary(_selectedVehicle!.id, {
          'is_vehicle_in': false,
          'status': issueItems.isNotEmpty
              ? 'maintenance'
              : 'active', // Set to maintenance if issues found
          'last_charge_type': _selectedChargingType?.toUpperCase() ?? 'AC',
          'last_charging_type': _selectedChargingType?.toUpperCase() ?? 'AC',
          'daily_checks': cleanedChecklist,
          'last_inventory_time': DateTime.now().toIso8601String(),
          'last_inspection_date': DateTime.now().toIso8601String().split(
            'T',
          )[0],
          'service_attention':
              issueItems.isNotEmpty, // Flag for attention if issues found
          'last_check_out_time': DateTime.now()
              .toIso8601String(), // Track check-out time
        });
        debugPrint('✅ Vehicle data saved to database successfully');
      } catch (e) {
        debugPrint('❌ CRITICAL: Failed to save vehicle data to database: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save data: $e. Please try again.'),
              backgroundColor: AppTheme.dangerRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        rethrow; // Stop the process if data save fails
      }

      // 6. Mark driver attendance if driver is selected
      if (_selectedDriver != null) {
        try {
          await DriverService.markAttendance(
            driverId: _selectedDriver!.id,
            vehicleId: _selectedVehicle!.id,
            activityType: 'check_out',
            metadata: {
              'vehicle_number': _selectedVehicle!.vehicleNumber,
              'driver_name': _selectedDriver!.name,
              'charging_type': 'AC',
              'issues_reported': issueItems.length,
            },
          );
        } catch (e) {
          debugPrint('Warning: Could not mark driver attendance: $e');
          // Continue with check-out even if attendance marking fails
        }
      }

      // 7. Log activity - ensure vehicleNumber is not null/empty
      final vehicleNumber = _selectedVehicle!.vehicleNumber;
      if (vehicleNumber.isEmpty) {
        throw Exception(
          'Cannot log activity: vehicle number is empty for vehicle ${_selectedVehicle!.id}',
        );
      }

      try {
        // Upload manual issue media if any
        if (_reportedIssues.isNotEmpty) {
          try {
            await provider.uploadManualIssueMedia(_reportedIssues);
            debugPrint('✅ Manual issue media uploaded successfully');
          } catch (e) {
            debugPrint('⚠️ Warning: Failed to upload manual issue media: $e');
          }
        }

        await provider.logActivity(
          Activity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            vehicleId: _selectedVehicle!.id,
            vehicleNumber: vehicleNumber,
            activityType: 'check_out',
            userName: provider.userName ?? provider.userEmail ?? 'Unknown',
            timestamp: DateTime.now(),
            metadata: {
              'charging_type': _selectedChargingType ?? 'AC',
              'consecutive_ac_charges': _consecutiveACCharges,
              'consecutive_dc_charges': _consecutiveDCCharges,
              'inspection_items_checked': cleanedChecklist.length,
              'photos_captured':
                  _inventoryPhotos.values.where((v) => v != null).length +
                  _additionalPhotos.length,
              'additional_photos_count': _additionalPhotos.length,
              'issues_reported': issueItems.length + _reportedIssues.length,
              'issue_details': issueItems,
              'manual_issues': _reportedIssues,
              'odometer_reading': _odometerController.text.trim(),
              'ride_purpose': _ridePurpose,
              'interior_clean': _isInteriorClean,
              'daily_checks': cleanedChecklist,
              if (_selectedDriver != null) 'driver_id': _selectedDriver!.id,
              if (_selectedDriver != null) 'driver_name': _selectedDriver!.name,
            },
          ),
        );
        debugPrint('✅ Activity logged successfully');
      } catch (e) {
        debugPrint('⚠️ Warning: Could not log activity: $e');
        // Don't fail the entire check-out if activity logging fails
        // The vehicle data is already saved
      }

      // 8. Show success immediately and navigate back
      debugPrint('✅ Check-out completed successfully - all data saved');
      if (issueItems.isNotEmpty) {
        debugPrint('⚠️ Admin notified about ${issueItems.length} issue(s)');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedVehicle!.vehicleNumber} checked out successfully',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        context.pop();
        
        // Refresh data in background (don't await - let it run asynchronously)
        debugPrint('🔄 Refreshing vehicles and activities in background...');
        provider.loadVehicles(forceRefresh: true).then((_) {
          debugPrint('✅ Vehicles refreshed');
        }).catchError((e) {
          debugPrint('⚠️ Background refresh failed: $e');
        });
        provider.loadActivities(limit: 20).then((_) {
          debugPrint('✅ Activities refreshed');
        }).catchError((e) {
          debugPrint('⚠️ Background activity refresh failed: $e');
        });
      }
    } catch (e) {
      debugPrint('❌ Error during check-out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during check-out: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allVehicles = provider.vehicles;
    final filteredVehicles = _getFilteredVehicles(allVehicles);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.x,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Check Out Vehicle',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Vehicle
                  _buildSectionTitle('Search Vehicle'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by vehicle name or license plate...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),

                  if (_isSearching && _selectedVehicle == null) ...[
                    const SizedBox(height: 16),
                    ...filteredVehicles.map(
                      (vehicle) => _buildVehicleCard(vehicle),
                    ),
                  ],

                  if (_selectedVehicle != null) ...[
                    const SizedBox(height: 24),
                    _buildSelectedVehicle(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Purpose of Ride'),
                    const SizedBox(height: 12),
                    _buildRidePurposeSection(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Odometer Reading'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter current odometer reading...',
                        prefixIcon: const Icon(
                          LucideIcons.gauge,
                          color: Color(0xFF9CA3AF),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    DriverAssignmentSection(
                      title: 'Assign Driver',
                      vehicleId: _selectedVehicle!.id,
                      hubId: provider.selectedHub,
                      onDriverSelected: (driver) {
                        setState(() {
                          _selectedDriver = driver;
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildRequiredInventoryPhotosSection(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Inspection Checklist'),
                    const SizedBox(height: 12),
                    _buildStaticInspectionChecklist(),


                    const SizedBox(height: 24),
                    _buildSectionTitle('Interior Cleaning Status'),
                    const SizedBox(height: 12),
                    _buildInteriorCleaningSelection(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Charging Type'),
                    const SizedBox(height: 12),
                    _buildChargingTypeSelection(),

                    if (_reportedIssues.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Reported Issues'),
                      const SizedBox(height: 12),
                      _buildIssuesSection(),
                    ],

                    const SizedBox(height: 24),
                    _buildAddIssueButton(),
                  ],
                ],
              ),
            ),
          ),

          if (_selectedVehicle != null) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicle = vehicle;
          _isSearching = false;
          // Load AC and DC charge count from vehicle metadata
          try {
            final json = _selectedVehicle!.toJson();
            _consecutiveACCharges = json['consecutive_ac_charges'] ?? 0;
            _consecutiveDCCharges = json['consecutive_dc_charges'] ?? 0;
          } catch (e) {
            _consecutiveACCharges = 0;
            _consecutiveDCCharges = 0;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/vehicle_placeholder.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.vehicleNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.make ??
                        vehicle.model ??
                        vehicle.customerName ??
                        'Unknown',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedVehicle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle2, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedVehicle!.vehicleNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedVehicle!.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedVehicle = null;
                _isSearching = true;
              });
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInspectionChecklist() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: _inspectionSections.entries.map((entry) {
          final sectionTitle = entry.key;
          final items = entry.value;
          final isFirstSection = sectionTitle == _inspectionSections.keys.first;
          final isLastSection = sectionTitle == _inspectionSections.keys.last;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: isFirstSection
                        ? const Radius.circular(12)
                        : Radius.zero,
                    topRight: isFirstSection
                        ? const Radius.circular(12)
                        : Radius.zero,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clipboardCheck,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((item) {
                final id = item['id']!;
                final label = item['label']!;
                final value = _inspectionChecklist[id];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: value == null
                        ? Colors.white
                        : value
                        ? AppTheme.successGreen.withOpacity(0.05)
                        : AppTheme.dangerRed.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // OK Button
                      _compactCheckButton(
                        icon: LucideIcons.check,
                        label: 'OK',
                        isSelected: value == true,
                        color: AppTheme.successGreen,
                        onTap: () {
                          setState(() {
                            _inspectionChecklist[id] = value == true
                                ? null
                                : true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Issue Button
                      _compactCheckButton(
                        icon: LucideIcons.x,
                        label: 'Issue',
                        isSelected: value == false,
                        color: AppTheme.dangerRed,
                        onTap: () {
                          setState(() {
                            _inspectionChecklist[id] = value == false
                                ? null
                                : false;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              if (!isLastSection) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _compactCheckButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRidePurposeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPurposeButton('B2B', LucideIcons.briefcase)),
            const SizedBox(width: 12),
            Expanded(child: _buildPurposeButton('B2C', LucideIcons.user)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPurposeButton('Periodic Service', LucideIcons.wrench)),
            const SizedBox(width: 12),
            Expanded(child: _buildPurposeButton('Station Shifting', LucideIcons.refreshCw)),
          ],
        ),
      ],
    );
  }

  Widget _buildPurposeButton(String purpose, IconData icon) {
    final isSelected = _ridePurpose == purpose;

    return InkWell(
      onTap: () {
        setState(() {
          _ridePurpose = isSelected ? null : purpose;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              purpose,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargingTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _consecutiveACCharges >= 5
                ? "Your next charging is DC"
                : "Your next charging is AC",
            style: TextStyle(
              fontSize: 14,
              color: _consecutiveACCharges >= 5 ? Colors.red : Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildChargingTypeCard('AC Charging', 'ac')),
            const SizedBox(width: 12),
            Expanded(child: _buildChargingTypeCard('DC Fast Charging', 'dc')),
          ],
        ),
        if (_consecutiveACCharges >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Note: It's recommended to do DC charging after every 5 AC charges for better battery health.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChargingTypeCard(String label, String type) {
    final isSelected = _selectedChargingType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedChargingType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  LucideIcons.zap,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : const Color(0xFF6B7280),
                  size: 32,
                ),
                if (type == 'ac')
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _consecutiveACCharges >= 5
                            ? Colors.red
                            : Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_consecutiveACCharges/5',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (type == 'dc')
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_consecutiveDCCharges',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected
                    ? AppTheme.primaryGreen
                    : const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteriorCleaningSelection() {
    return Row(
      children: [
        Expanded(child: _buildCleaningStatusCard('Clean', true)),
        const SizedBox(width: 12),
        Expanded(child: _buildCleaningStatusCard('Not Clean', false)),
      ],
    );
  }

  Widget _buildCleaningStatusCard(String label, bool isClean) {
    final isSelected = _isInteriorClean == isClean;

    return InkWell(
      onTap: () {
        setState(() {
          _isInteriorClean = isClean;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isClean
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : AppTheme.dangerRed.withOpacity(0.1))
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? (isClean ? AppTheme.primaryGreen : AppTheme.dangerRed)
                    : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isClean ? LucideIcons.sparkles : LucideIcons.trash2,
              color:
                  isSelected
                      ? (isClean ? AppTheme.primaryGreen : AppTheme.dangerRed)
                      : const Color(0xFF6B7280),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color:
                    isSelected
                        ? (isClean ? AppTheme.primaryGreen : AppTheme.dangerRed)
                        : const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryPhotos() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Adjusted for image preview
      ),
      itemCount: _photoCategories.length,
      itemBuilder: (context, index) {
        final category = _photoCategories[index];
        final photoPath = _inventoryPhotos[category['id']];
        final isCaptured = photoPath != null;
        final isOptional = category['isOptional'] == true;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo preview or icon
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Show captured image or placeholder icon
                    if (isCaptured && photoPath != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: kIsWeb
                            ? Image.network(photoPath, fit: BoxFit.cover)
                            : Image.file(
                                File(photoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      category['icon'] as IconData,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                      )
                    else
                      Container(
                        color: isOptional
                            ? Colors.orange.withOpacity(0.05)
                            : const Color(0xFFF3F4F6),
                        child: Center(
                          child: Icon(
                            category['icon'] as IconData,
                            color: isOptional
                                ? Colors.orange.withOpacity(0.5)
                                : const Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        ),
                      ),
                    // Captured badge
                    if (isCaptured)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Category label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  category['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCaptured
                        ? AppTheme.successGreen
                        : const Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Action buttons
              if (isCaptured)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      // Delete button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _inventoryPhotos[category['id']!] = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${category['label']} deleted'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: AppTheme.dangerRed,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Recapture button
                      Expanded(
                        child: InkWell(
                          onTap: () => _capturePhoto(
                            category['id']!,
                            autoAdvance: false,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              color: AppTheme.primaryBlue,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _capturePhoto(category['id']!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOptional
                            ? Colors.orange.withOpacity(0.1)
                            : const Color(0xFFEFF6FF),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        isOptional ? 'Add Photo' : 'Capture',
                        style: TextStyle(
                          color: isOptional
                              ? Colors.orange
                              : AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIssuesSection() {
    return Column(
      children: [
        ..._reportedIssues.map(
          (issue) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: AppTheme.dangerRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue['type']!.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                      Text(
                        issue['description']!.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () {
                    setState(() {
                      _reportedIssues.remove(issue);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredInventoryPhotosSection() {
    final requiredPhotos = _photoCategories
        .where((cat) => cat['isOptional'] != true)
        .toList();
    final photoCapturedCount = requiredPhotos
        .where((cat) => _inventoryPhotos[cat['id']] != null)
        .length;
    final totalPhotos = requiredPhotos.length;
    final allPhotosCaptured = photoCapturedCount == totalPhotos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allPhotosCaptured
              ? AppTheme.successGreen
              : Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching vehicle management design
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (allPhotosCaptured
                              ? AppTheme.successGreen
                              : Colors.orange)
                          .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allPhotosCaptured
                      ? LucideIcons.checkCheck
                      : LucideIcons.camera,
                  color: allPhotosCaptured
                      ? AppTheme.successGreen
                      : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      allPhotosCaptured
                          ? 'All required photos captured'
                          : 'Capture all angles & details',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '$photoCapturedCount/$totalPhotos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: allPhotosCaptured
                      ? AppTheme.successGreen
                      : Colors.orange,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Photo Grid
          _buildInventoryPhotos(),

          // Additional Photos Section (Nested)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildAdditionalPhotosSection(),
        ],
      ),
    );
  }

  Widget _buildAdditionalPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.image,
              color: AppTheme.primaryBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Additional Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (_additionalPhotos.isNotEmpty)
              Text(
                '${_additionalPhotos.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        if (_additionalPhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: _additionalPhotos.length,
            itemBuilder: (context, index) {
              final photoPath = _additionalPhotos[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: kIsWeb
                                ? Image.network(photoPath, fit: BoxFit.cover)
                                : Image.file(
                                    File(photoPath),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => setState(
                                () => _additionalPhotos.removeAt(index),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Additional',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _capturePhoto('additional_photos'),
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add Additional Photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
              foregroundColor: AppTheme.primaryBlue,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddIssueButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dangerRed.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToAddIssue,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.dangerRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.alertCircle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Issue',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _handleCheckOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Check Out Vehicle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
