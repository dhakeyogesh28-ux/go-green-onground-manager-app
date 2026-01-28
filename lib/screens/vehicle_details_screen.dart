import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

enum InspectionStatus { auto, ok, attention }

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Vehicle _vehicle; // In simple app, we might check provider, but let's assume we fetch it
  
  // Field Ops State
  bool _isVehicleIn = true;
  bool _isInteriorClean = true;
  final TextEditingController _todoController = TextEditingController();
  List<String> _localTodos = [];
  
  // Vehicle Status Selection
  VehicleStatus? _selectedStatus; // Track user's selection separately
  
  final Map<String, bool?> _dailyChecks = {
    'battery_level': null,
    'charging_cable': null,
    'tyre_condition': null,
    'visible_damage': null,
  };

  // Charging Type Selection (AC or DC)
  String _selectedChargingType = 'AC'; // Default to AC

  // Inspection Data State (Standardized Keys)
  final Map<String, InspectionStatus> _checks = {
    // Battery & HV
    'soh': InspectionStatus.auto,
    'hv_warnings': InspectionStatus.auto,
    // Motor & Drive
    'motor_noise': InspectionStatus.auto,
    'power_delivery': InspectionStatus.auto,
    // Cooling
    'coolant_level': InspectionStatus.auto,
    'cooling_fans': InspectionStatus.auto,
    // 12V
    'twelve_v': InspectionStatus.auto,
    // Brakes & Tires
    'brakes': InspectionStatus.auto,
    'tires': InspectionStatus.auto,
    // Body & Systems
    'exterior': InspectionStatus.auto,
    'interior': InspectionStatus.auto,
    'mechanical': InspectionStatus.auto,
    'electrical': InspectionStatus.auto,
    'infotainment': InspectionStatus.auto,
    'ac': InspectionStatus.auto,
    'seats': InspectionStatus.auto,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load vehicle data
    final provider = context.read<AppProvider>();
    final v = provider.getVehicleById(widget.vehicleId);
    if (v != null) {
      _vehicle = v;
      _isVehicleIn = v.isVehicleIn;
      _isInteriorClean = v.isInteriorClean;
      _localTodos.addAll(v.toDos);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  void _updateStatus(String key, InspectionStatus status) {
    setState(() {
      if (_checks[key] == status) {
        _checks[key] = InspectionStatus.auto;
      } else {
        _checks[key] = status;
      }
    });
  }
  
  void _completeInspection() async {
     final Map<String, String> results = _checks.map((key, value) {
      if (value == InspectionStatus.ok) return MapEntry(key, 'ok');
      if (value == InspectionStatus.attention) return MapEntry(key, 'attention');
      return MapEntry(key, 'auto');
    });

    context.read<AppProvider>().saveInspection(InspectionResult(
          vehicleId: widget.vehicleId,
          checks: results,
          timestamp: DateTime.now(),
        ));
    
    // Update vehicle status to idle (inspection complete)
    try {
      await context.read<AppProvider>().updateVehicleStatus(widget.vehicleId, VehicleStatus.idle);
    } catch (e) {
      debugPrint('Error updating vehicle status: $e');
    }

    context.pushReplacement('/vehicle-summary/${widget.vehicleId}');
  }

  bool get _hasAttention => _checks.values.any((s) => s == InspectionStatus.attention);

  @override
  Widget build(BuildContext context) {
    // Get the latest vehicle data from provider
    final provider = context.watch<AppProvider>();
    final latestVehicle = provider.getVehicleById(widget.vehicleId);
    
    if (latestVehicle == null) {
       return const Scaffold(body: Center(child: Text('Vehicle Not Found')));
    }
    
    // Always use the latest vehicle data from provider
    _vehicle = latestVehicle;
    
    // Debug: Log current vehicle status
    debugPrint('🏗️ Building with vehicle status: ${_vehicle.status.name}, selected: ${_selectedStatus?.name ?? "none"}');

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.vehicleManagement, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryGreen,
          tabs: [
            Tab(text: l10n.overview),
            Tab(text: l10n.dailyCheck),
            Tab(text: l10n.fullScan),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildInOutHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDailyCheckTab(),
                _buildFullScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. IN / OUT Feature
  Widget _buildInOutHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _vehicle.vehicleNumber, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _vehicle.serviceType, 
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              try {
                final newValue = !_isVehicleIn;
                await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                  'is_vehicle_in': newValue,
                });
                setState(() => _isVehicleIn = newValue);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.vehicleMarkedAs(newValue ? "IN" : "OUT")),
                    duration: const Duration(seconds: 1),
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating status: $e')),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isVehicleIn ? const Color(0xFFDCFCE7) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isVehicleIn ? const Color(0xFF166534) : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(_isVehicleIn ? LucideIcons.logIn : LucideIcons.logOut, size: 16, color: _isVehicleIn ? const Color(0xFF166534) : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _isVehicleIn ? l10n.inHubStatus : l10n.outStatus,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _isVehicleIn ? const Color(0xFF166534) : Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Overview (Vehicle Status, Charging, Service)
  Widget _buildOverviewTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Vehicle Status Update Section
          _buildVehicleStatusSection(),
          const SizedBox(height: 20),
          _buildInteriorCleanSection(),
          const SizedBox(height: 20),
          // 3. Charging Cycle Feature
          _buildChargingSection(),
          const SizedBox(height: 20),
          // 2. Servicing Feature
          _buildServiceSection(),
        ],
      ),
    );
  }

  Widget _buildVehicleStatusSection() {
    final l10n = AppLocalizations.of(context)!;
    // Use selected status if user has made a selection, otherwise use current vehicle status
    final currentStatus = _selectedStatus ?? _vehicle.status;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.activity, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.vehicleStatus, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_vehicle.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(context, _vehicle.status).toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(_vehicle.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Status buttons in 2x2 grid
          Row(
            children: [
              Expanded(child: _buildStatusButton(l10n.active, VehicleStatus.active, AppTheme.primaryGreen, currentStatus)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusButton(l10n.idle, VehicleStatus.idle, Colors.orange, currentStatus)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusButton(l10n.charging, VehicleStatus.charging, Colors.blue, currentStatus)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusButton(l10n.maintenance, VehicleStatus.maintenance, Colors.red, currentStatus)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedStatus == null ? null : () async {
                // Store the selected status before clearing
                final statusToUpdate = _selectedStatus!;
                final statusText = _getStatusText(context, statusToUpdate);
                
                try {
                  debugPrint('Updating vehicle ${widget.vehicleId} status to: ${statusToUpdate.name}');
                  
                  // Update with the selected status (handles local update and server sync)
                  await context.read<AppProvider>().updateVehicleStatus(widget.vehicleId, statusToUpdate);
                  
                  debugPrint('Status update completed');
                  
                  // Clear selection - UI will update automatically via context.watch
                  if (mounted) {
                    setState(() {
                      _selectedStatus = null;
                    });
                  
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.updateStatusSuccess(statusText)),
                          ],
                        ),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating vehicle status: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Error updating status: $e')),
                          ],
                        ),
                        backgroundColor: AppTheme.dangerRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedStatus == null ? Colors.grey.shade300 : AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.save, size: 20, color: _selectedStatus == null ? Colors.grey.shade600 : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _selectedStatus == null ? l10n.selectStatus : l10n.updateStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _selectedStatus == null ? Colors.grey.shade600 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteriorCleanSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.armchair, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Interior Cleaning Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isInteriorClean ? AppTheme.primaryGreen : AppTheme.dangerRed).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isInteriorClean ? 'CLEAN' : 'NOT CLEAN',
                  style: TextStyle(
                    color: _isInteriorClean ? AppTheme.primaryGreen : AppTheme.dangerRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCleaningButton('Clean', true, AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCleaningButton('Not Clean', false, AppTheme.dangerRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningButton(String label, bool isClean, Color color) {
    final isSelected = _isInteriorClean == isClean;
    return GestureDetector(
      onTap: () async {
        try {
          // Update the localized daily_checks map to include cleaning status
          final updatedChecks = Map<String, bool>.from(_vehicle?.dailyChecks ?? {});
          updatedChecks['interior_clean'] = isClean;

          await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
            'daily_checks': updatedChecks,
          });
          setState(() {
            _isInteriorClean = isClean;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Interior marked as ${isClean ? "Clean" : "Not Clean"}'),
              backgroundColor: isClean ? AppTheme.successGreen : AppTheme.dangerRed,
              duration: const Duration(seconds: 1),
            ));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating cleaning status: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isClean ? LucideIcons.sparkles : LucideIcons.trash2,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return AppTheme.primaryGreen;
      case VehicleStatus.idle:
        return Colors.orange;
      case VehicleStatus.charging:
        return Colors.blue;
      case VehicleStatus.maintenance:
        return Colors.red;
    }
  }
  
  String _getStatusText(BuildContext context, VehicleStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case VehicleStatus.active:
        return l10n.active;
      case VehicleStatus.idle:
        return l10n.idle;
      case VehicleStatus.charging:
        return l10n.charging;
      case VehicleStatus.maintenance:
        return l10n.maintenance;
    }
  }
  
  Widget _buildStatusButton(String label, VehicleStatus status, Color color, VehicleStatus currentStatus) {
    final isSelected = currentStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.tasksToDo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_localTodos.length}/3', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ..._localTodos.map((todo) => CheckboxListTile(
            title: Text(todo, style: const TextStyle(fontSize: 14)),
            value: false, // In real app, track completion
            onChanged: (val) async {
              try {
                final List<String> updatedTodos = List.from(_localTodos)..remove(todo);
                await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                  'to_dos': updatedTodos,
                });
                setState(() => _localTodos = updatedTodos);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing task: $e')),
                  );
                }
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
          if (_localTodos.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _todoController,
                        decoration: InputDecoration(
                          hintText: l10n.addNewTask,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (val) async {
                          if (val.isNotEmpty) {
                            try {
                              final List<String> updatedTodos = List.from(_localTodos)..add(val);
                              await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                                'to_dos': updatedTodos,
                              });
                              setState(() {
                                _localTodos = updatedTodos;
                                _todoController.clear();
                              });
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error adding task: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primaryGreen),
                    onPressed: () async {
                      final val = _todoController.text;
                      if (val.isNotEmpty) {
                        try {
                          final List<String> updatedTodos = List.from(_localTodos)..add(val);
                          await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                            'to_dos': updatedTodos,
                          });
                          setState(() {
                            _localTodos = updatedTodos;
                            _todoController.clear();
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error adding task: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChargingSection() {
    final l10n = AppLocalizations.of(context)!;
    // Use lastChargingType if available, otherwise fall back to lastChargeType
    final String chargingType = _vehicle.lastChargingType ?? _vehicle.lastChargeType;
    final int? health = _vehicle.batteryHealth;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.chargingCycle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${l10n.health}: ${health != null ? '$health%' : _vehicle.chargingHealth}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoStat(l10n.lastCharging, chargingType, LucideIcons.zap)),
              Expanded(child: _infoStat(l10n.battery, '${_vehicle.batteryLevel.toInt()}%', LucideIcons.battery)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showLogChargingDialog,
              child: Text(l10n.logCharging),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogChargingDialog() async {
    String selectedType = 'AC';
    final TextEditingController batteryController = TextEditingController(
      text: _vehicle.batteryLevel.toInt().toString(),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log Charging Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Charging Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('AC'),
                      value: 'AC',
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('DC'),
                      value: 'DC',
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Battery Level (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: batteryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter battery level (0-100)',
                  suffixText: '%',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final batteryLevel = int.tryParse(batteryController.text);
                if (batteryLevel != null && batteryLevel >= 0 && batteryLevel <= 100) {
                  Navigator.pop(context, {
                    'type': selectedType,
                    'batteryLevel': batteryLevel,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid battery level (0-100)')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
          'last_charging_type': result['type'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Charging logged: ${result['type']} - ${result['batteryLevel']}%'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          
          // Refresh vehicle data
          final provider = context.read<AppProvider>();
          final updatedVehicle = provider.getVehicleById(widget.vehicleId);
          if (updatedVehicle != null) {
            setState(() {
              _vehicle = updatedVehicle;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging charging: $e')),
          );
        }
      }
    }

    batteryController.dispose();
  }

  Widget _buildServiceSection() {
    final l10n = AppLocalizations.of(context)!;
    // Only show if vehicle is in servicing
    if (!_vehicle.isInServicing) {
      return const SizedBox.shrink();
    }
    
    final bool isServiceOk = _vehicle.servicingStatus == 'service_ok';
    final bool needsAttention = _vehicle.servicingStatus == 'attention';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.servicingStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text('${l10n.lastService}: ${_vehicle.lastServiceDate != null ? DateFormat('d MMM y').format(_vehicle.lastServiceDate!) : 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text('${l10n.type}: ${_vehicle.lastServiceType ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statusButton('Service OK', isServiceOk, isServiceOk),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusButton('Attention', needsAttention, needsAttention),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: Daily Check
  Widget _buildDailyCheckTab() {
    final l10n = AppLocalizations.of(context)!;
    final photos = context.watch<AppProvider>().getInventoryPhotos(widget.vehicleId);
    final int photoCount = photos.length;
    final int requiredCount = 9; // Total categories in InventoryPhotosScreen
    final bool allPhotosCaptured = photoCount >= requiredCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dailyInventory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
                const SizedBox(height: 4),
                Text(l10n.tapToToggle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ..._dailyChecks.keys.map((key) => _dailyCheckItem(key)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Structured Photos Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: allPhotosCaptured ? AppTheme.successGreen : Colors.orange.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (allPhotosCaptured ? AppTheme.successGreen : Colors.orange).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        allPhotosCaptured ? LucideIcons.checkCheck : LucideIcons.camera, 
                        color: allPhotosCaptured ? AppTheme.successGreen : Colors.orange, 
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.requiredPhotos, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.titleMedium?.color)),
                          Text(
                            allPhotosCaptured ? l10n.allPhotosCaptured : l10n.captureAnglesDetails,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$photoCount/$requiredCount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: allPhotosCaptured ? AppTheme.successGreen : Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/inventory-photos/${widget.vehicleId}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      allPhotosCaptured ? l10n.reviewPhotos : l10n.capturePhotosNow,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/add-issue/${widget.vehicleId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.dangerRed.withOpacity(0.1) : const Color(0xFFFEF2F2),
              foregroundColor: AppTheme.dangerRed,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 20),
                const SizedBox(width: 12),
                Text(l10n.addIssue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: allPhotosCaptured ? () async {
                 // Save the daily checks to Supabase
                 await context.read<AppProvider>().saveDailyChecks(widget.vehicleId, _dailyChecks);
                 
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inspectionSummary))); // Simplified placeholder
                   _tabController.animateTo(2); // Switch to "Full Scan" section
                 }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                allPhotosCaptured 
                  ? l10n.completeSubmitInventory 
                  : l10n.captureAllPhotosToSubmit, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyCheckItem(String key) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map constant key to localized label
    String label = key;
    if (key == 'battery_level') label = l10n.batteryLevel;
    else if (key == 'charging_cable') label = l10n.chargingCable;
    else if (key == 'tyre_condition') label = l10n.tyreCondition;
    else if (key == 'visible_damage') label = l10n.visibleDamage;

    bool? status = _dailyChecks[key];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: status == true 
              ? AppTheme.successGreen.withOpacity(0.3) 
              : (status == false ? AppTheme.dangerRed.withOpacity(0.3) : Colors.transparent),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 15,
            )
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dailyInspectionButton(
                  label: 'OK',
                  icon: LucideIcons.checkCircle2,
                  color: AppTheme.successGreen,
                  isSelected: status == true,
                  onTap: () {
                    setState(() {
                      _dailyChecks[key] = status == true ? null : true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dailyInspectionButton(
                  label: l10n.attention,
                  icon: LucideIcons.alertCircle,
                  color: AppTheme.dangerRed,
                  isSelected: status == false,
                  onTap: () {
                    setState(() {
                      _dailyChecks[key] = status == false ? null : false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dailyInspectionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15) 
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: Full Scan (Original Quick Inspection)
  Widget _buildFullScanTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           // Top Summary Bar (Integrated into tab)
          _buildSummaryBar(),
          const SizedBox(height: 16),
          // Sections (Standardized with constant keys)
          _buildSection(l10n.batteryHVSystem, ['soh', 'hv_warnings'], LucideIcons.battery),
          _buildChargingTypeSection(),
          _buildSection(l10n.motorDrive, ['motor_noise', 'power_delivery'], LucideIcons.activity),
          _buildSection(l10n.cooling, ['coolant_level', 'cooling_fans'], LucideIcons.thermometer),
          _buildSection(l10n.twelveVSystem, ['twelve_v'], LucideIcons.batteryMedium),
          _buildSection(l10n.brakesTires, ['brakes', 'tires'], LucideIcons.disc),
          _buildSection(l10n.exterior, ['exterior'], LucideIcons.eye),
          _buildSection(l10n.electrical, ['electrical'], LucideIcons.zap),
          _buildSection(l10n.interior, ['interior'], LucideIcons.layout),
          _buildSection(l10n.mechanical, ['mechanical'], LucideIcons.settings),
          _buildSection(l10n.infotainment, ['infotainment'], LucideIcons.monitor),
          _buildSection(l10n.cooling, ['ac'], LucideIcons.thermometer),
          _buildSection(l10n.interior, ['seats'], LucideIcons.armchair),
          
          const SizedBox(height: 24),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // Helpers from previous step...
  Widget _infoStat(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(
          val, 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label, 
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _statusButton(String label, bool isOk, bool isPrimary) {
    final l10n = AppLocalizations.of(context)!;
    // Determine visuals based on state logic if needed, simplify for now
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isOk 
            ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF166534).withOpacity(0.2) : const Color(0xFFDCFCE7)) 
            : (Theme.of(context).brightness == Brightness.dark ? AppTheme.dangerRed.withOpacity(0.2) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOk ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF166534)) : AppTheme.dangerRed)
      ),
      child: Center(
        child: Text(isOk ? l10n.ok : l10n.attention, style: TextStyle(
          color: isOk ? const Color(0xFF166534) : AppTheme.dangerRed,
          fontWeight: FontWeight.bold,
        )),
      ),
    );
  }

  // REUSED: Summary Bar
  Widget _buildSummaryBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _hasAttention 
            ? AppTheme.dangerRed.withOpacity(0.1) 
            : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: _summaryItem(l10n.vehicleVIN, '${_vehicle.vehicleNumber} | ...8241')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _summaryItem(l10n.batterySOH, '94%', highlight: true)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _summaryItem(l10n.faults, _hasAttention ? l10n.yes : l10n.no, 
            color: _hasAttention ? AppTheme.dangerRed : Colors.green)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? color, bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value, 
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? Theme.of(context).textTheme.bodyLarge?.color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildChargingTypeSection() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.zap, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text('Charging', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChargingTypeCard('AC'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChargingTypeCard('DC'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChargingTypeCard(String type) {
    final l10n = AppLocalizations.of(context)!;
    final bool isSelected = _selectedChargingType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChargingType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF166534).withOpacity(0.2) : const Color(0xFFDCFCE7)) 
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF166534)) : Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${type == 'AC' ? l10n.acCharging : l10n.dcCharging}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF166534)) 
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
              color: isSelected ? const Color(0xFF166534) : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildCheckCard(item)),
        ],
      ),
    );
  }

  Widget _buildCheckCard(String key) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map constant key to localized label
    String label = key;
    if (key == 'exterior') label = l10n.exterior; 
    else if (key == 'interior') label = l10n.interior;
    else if (key == 'mechanical') label = l10n.mechanical; 
    else if (key == 'electrical') label = l10n.electrical;
    else if (key == 'infotainment') label = l10n.infotainment;
    else if (key == 'ac') label = l10n.cooling; 
    else if (key == 'seats') label = l10n.seatAdjustments;
    else if (key == 'soh') label = l10n.sohOk;
    else if (key == 'hv_warnings') label = l10n.noHvWarnings;
    else if (key == 'motor_noise') label = l10n.noAbnormalNoise;
    else if (key == 'power_delivery') label = l10n.powerDeliveryNormal;
    else if (key == 'coolant_level') label = l10n.coolantLevelOk;
    else if (key == 'cooling_fans') label = l10n.fansPumpWorking;
    else if (key == 'twelve_v') label = l10n.twelveVbatteryOk;
    else if (key == 'brakes') label = l10n.brakesOk;
    else if (key == 'tires') label = l10n.tireConditionOk;

    final status = _checks[key]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: status == InspectionStatus.attention 
              ? AppTheme.dangerRed.withOpacity(0.3) 
              : (status == InspectionStatus.ok ? AppTheme.successGreen.withOpacity(0.3) : Colors.transparent),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.titleMedium?.color),
                ),
              ),
              if (status == InspectionStatus.auto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(l10n.auto, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _inspectionActionButton(
                  label: 'OK',
                  icon: LucideIcons.checkCircle2,
                  color: AppTheme.successGreen,
                  isSelected: status == InspectionStatus.ok,
                  onTap: () => _updateStatus(key, InspectionStatus.ok),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inspectionActionButton(
                  label: l10n.attention,
                  icon: LucideIcons.alertCircle,
                  color: AppTheme.dangerRed,
                  isSelected: status == InspectionStatus.attention,
                  onTap: () => _updateStatus(key, InspectionStatus.attention),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inspectionActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15) 
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
          ElevatedButton(
            onPressed: () => context.push('/add-issue/${widget.vehicleId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.dangerRed.withOpacity(0.1) : const Color(0xFFFEF2F2),
              foregroundColor: AppTheme.dangerRed,
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 20),
                const SizedBox(width: 12),
                Text(l10n.addIssue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _completeInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasAttention ? AppTheme.dangerRed : AppTheme.successGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: (_hasAttention ? AppTheme.dangerRed : AppTheme.successGreen).withOpacity(0.3),
            ),
            child: Text(l10n.completeInspection, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
