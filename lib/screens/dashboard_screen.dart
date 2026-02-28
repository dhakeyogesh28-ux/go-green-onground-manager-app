import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'package:mobile/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  VehicleStatus? _selectedStatus; // null means "All"

  @override
  void initState() {
    super.initState();
    // Load vehicles when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.vehicles.isEmpty && !provider.isLoadingVehicles) {
        provider.loadVehicles();
      }
      // Load activities
      provider.loadActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<AppProvider>().refreshVehicles();
    await context.read<AppProvider>().loadActivities();
  }

  List<Vehicle> _filterVehicles(List<Vehicle> vehicles) {
    var filtered = vehicles;

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((v) => v.status == _selectedStatus).toList();
    }

    // Filter by search query
    if (_searchQuery.isEmpty) return filtered;

    return filtered.where((vehicle) {
      final query = _searchQuery.toLowerCase();
      return vehicle.vehicleNumber.toLowerCase().contains(query) ||
          vehicle.customerName.toLowerCase().contains(query);
    }).toList();
  }

  int _getStatusCount(List<Vehicle> vehicles, VehicleStatus? status) {
    if (status == null) return vehicles.length; // All
    return vehicles.where((v) => v.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context)!;
    final allVehicles = provider.vehicles;
    final vehicles = _filterVehicles(allVehicles);
    final isLoading = provider.isLoadingVehicles;
    final error = provider.vehiclesError;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1F2937),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                LucideIcons.search,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Colors.white),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.user, color: Colors.white),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      drawer: const _DashboardDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Blue Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    color: AppTheme.primaryGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboard,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.vehicleManagementOverview,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDBEAFE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shift Management Section
                  _buildShiftSection(context, provider),
                  // Overview Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildOverviewCard(
                              l10n.out,
                              '${(allVehicles ?? []).where((v) => !v.isVehicleIn).length}',
                              l10n.vehiclesCheckedOut,
                              Colors.orange,
                              LucideIcons.logOut,
                              () => context.push('/check-out'),
                              l10n.checkOut,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOverviewCard(
                              l10n.totalVehicles,
                              '${(allVehicles ?? []).length}',
                              l10n.totalVehiclesAssigned,
                              Colors.blue,
                              LucideIcons.package,
                              null,
                              null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOverviewCard(
                              l10n.inHub,
                              '${(allVehicles ?? []).where((v) => v.isVehicleIn).length}',
                              l10n.vehiclesCheckedIn,
                              Colors.green,
                              LucideIcons.logIn,
                              () => context.push('/check-in'),
                              l10n.checkIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Activity Section - Table Format
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.recentActivity,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.refreshCw, size: 18),
                              onPressed: () async {
                                await provider.loadActivities(limit: 20);
                              },
                              tooltip: 'Refresh activities',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (provider.isLoadingActivities)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (provider.activities.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 40,
                              dataRowHeight: 56,
                              columnSpacing: 16,
                              horizontalMargin: 12,
                              headingTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                              columns: [
                                DataColumn(label: Text(l10n.vehicle)),
                                DataColumn(label: Text(l10n.user)),
                                DataColumn(label: Text(l10n.action)),
                                DataColumn(label: Text(l10n.time)),
                                DataColumn(label: Text(l10n.battery)),
                                DataColumn(label: Text(l10n.charging)),
                              ],
                              rows: provider.activities.take(4).map((activity) {
                                final isCheckIn = activity.isCheckIn;
                                final statusColor = isCheckIn
                                    ? Colors.green
                                    : Colors.orange;
                                final batteryPercent =
                                    activity.metadata?['battery_percentage'];
                                final chargingType =
                                    activity.metadata?['charging_type'];

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          activity.vehicleNumber,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.user,
                                              size: 12,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF9CA3AF)
                                                  : const Color(0xFF6B7280),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                activity.userName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          activity.activityText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          _formatTimestamp(activity.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              LucideIcons.battery,
                                              size: 12,
                                              color: Color(0xFF3B82F6),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                batteryPercent != null
                                                    ? '$batteryPercent%'
                                                    : 'N/A',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.zap,
                                              size: 12,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF9CA3AF)
                                                  : const Color(0xFF6B7280),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                chargingType?.toUpperCase() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                l10n.noRecentActivity,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Assigned Vehicles Section Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      l10n.assignedVehicles,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),

                  // Status Filter Tabs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusTab(
                            l10n.all,
                            _getStatusCount(allVehicles, null),
                            null,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusTab(
                            l10n.active,
                            _getStatusCount(allVehicles, VehicleStatus.active),
                            VehicleStatus.active,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusTab(
                            l10n.charging,
                            _getStatusCount(
                              allVehicles,
                              VehicleStatus.charging,
                            ),
                            VehicleStatus.charging,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusTab(
                            l10n.idle,
                            _getStatusCount(allVehicles, VehicleStatus.idle),
                            VehicleStatus.idle,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusTab(
                            l10n.maintenance,
                            _getStatusCount(
                              allVehicles,
                              VehicleStatus.maintenance,
                            ),
                            VehicleStatus.maintenance,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vehicle List
                  error != null
                      ? _ErrorView(error: error, onRetry: _onRefresh)
                      : isLoading && allVehicles.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : vehicles.isEmpty
                      ? _searchQuery.isNotEmpty
                            ? _NoSearchResults(
                                onClear: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : _EmptyView(onRefresh: _onRefresh)
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: vehicles.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _VehicleCard(vehicle: vehicles[index]),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSection(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String _formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final amPm = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
        border: Border.all(
          color: provider.isShiftActive
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: provider.isShiftActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: provider.isShiftActive
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : (provider.shiftEndTime != null
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  provider.isShiftActive
                      ? LucideIcons.clock
                      : (provider.shiftEndTime != null
                            ? LucideIcons.checkCircle
                            : LucideIcons.play),
                  color: provider.isShiftActive
                      ? AppTheme.primaryGreen
                      : (provider.shiftEndTime != null
                            ? Colors.grey
                            : Colors.orange),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.isShiftActive
                          ? 'Shift In Progress'
                          : (provider.shiftEndTime != null
                                ? 'Shift Completed'
                                : 'Shift Not Started'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    if (provider.isShiftActive &&
                        provider.shiftStartTime != null)
                      Text(
                        'Started at ${_formatTime(provider.shiftStartTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    if (!provider.isShiftActive &&
                        provider.shiftEndTime != null)
                      Text(
                        '${_formatTime(provider.shiftStartTime)} — ${_formatTime(provider.shiftEndTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                  ],
                ),
              ),
              // Duration chip for active/completed shift
              if (provider.shiftStartTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: provider.isShiftActive
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.timer,
                        size: 14,
                        color: provider.isShiftActive
                            ? AppTheme.primaryGreen
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.shiftDuration,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: provider.isShiftActive
                              ? AppTheme.primaryGreen
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Action button
          SizedBox(
            width: double.infinity,
            child: provider.isShiftActive
                ? ElevatedButton.icon(
                    onPressed: () =>
                        _showEndShiftConfirmation(context, provider),
                    icon: const Icon(LucideIcons.logOut, size: 18),
                    label: const Text(
                      'End Shift',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  )
                : (provider.shiftEndTime != null
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            await provider.startShift();
                          },
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: const Text(
                            'Start New Shift',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () async {
                            await provider.startShift();
                          },
                          icon: const Icon(LucideIcons.play, size: 18),
                          label: const Text(
                            'Start Shift',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        )),
          ),
        ],
      ),
    );
  }

  void _showEndShiftConfirmation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.alertCircle,
                  color: Colors.red.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'End Shift',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to end your shift?',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (provider.shiftStartTime != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.timer,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Shift duration: ${provider.shiftDuration}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await provider.endShift();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(
    String title,
    String count,
    String subtitle,
    Color color,
    IconData icon,
    VoidCallback? onTap,
    String? buttonText,
  ) {
    final cardContent = Container(
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).textTheme.titleLarge?.color?.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    // If card has onTap, wrap in InkWell to make entire card clickable
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildStatusTab(String label, int count, VehicleStatus? status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF374151)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.textDark),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    LucideIcons.user,
                    size: 30,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.userName ?? provider.userEmail ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              LucideIcons.layoutDashboard,
              color: AppTheme.primaryGreen,
            ),
            title: Text(l10n.dashboard),
            selected: true,
            selectedTileColor: AppTheme.primaryGreen.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/vehicle_placeholder.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(LucideIcons.car, color: AppTheme.primaryGreen),
            ),
            title: Text(l10n.allVehicles),
            onTap: () {
              Navigator.pop(context);
              context.push('/hub');
            },
          ),
          ListTile(
            leading: const Icon(
              LucideIcons.users,
              color: AppTheme.primaryGreen,
            ),
            title: const Text('Drivers'),
            onTap: () {
              Navigator.pop(context);
              context.push('/drivers');
            },
          ),

          ListTile(
            leading: const Icon(
              LucideIcons.settings,
              color: AppTheme.textLight,
            ),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: AppTheme.dangerRed),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: AppTheme.dangerRed),
            ),
            onTap: () async {
              Navigator.pop(context);
              await provider.logout();
            },
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final VoidCallback onClear;
  const _NoSearchResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.searchX, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No vehicles found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onClear,
            icon: const Icon(LucideIcons.x),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/vehicle_placeholder.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(LucideIcons.car, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicles in ${provider.selectedHub ?? "hub"}',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load vehicles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatefulWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  String? _driverRemark;
  bool _isLoadingRemark = false;

  @override
  void initState() {
    super.initState();
    // Only fetch remark if vehicle is in garage (checked in)
    if (widget.vehicle.isVehicleIn) {
      _fetchDriverRemark();
    }
  }

  @override
  void didUpdateWidget(_VehicleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if vehicle changed or if vehicle just got checked in
    if (oldWidget.vehicle.id != widget.vehicle.id ||
        (widget.vehicle.isVehicleIn && !oldWidget.vehicle.isVehicleIn)) {
      if (widget.vehicle.isVehicleIn) {
        _fetchDriverRemark();
      } else {
        setState(() {
          _driverRemark = null;
        });
      }
    }
  }

  Future<void> _fetchDriverRemark() async {
    // DISABLED: service_remarks table doesn't have required columns (remark_type, is_active, created_by)
    // To enable, run this SQL in Supabase:
    // ALTER TABLE service_remarks ADD COLUMN IF NOT EXISTS remark_type TEXT;
    // ALTER TABLE service_remarks ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    // ALTER TABLE service_remarks ADD COLUMN IF NOT EXISTS created_by TEXT;

    // For now, just return without fetching
    return;

    /* Original code - uncomment when table has required columns:
    if (_isLoadingRemark) return;

    setState(() {
      _isLoadingRemark = true;
    });

    try {
      final remark = await SupabaseService().getLatestDriverRemark(
        widget.vehicle.id,
      );
      if (mounted) {
        setState(() {
          _driverRemark = remark?['remark'] as String?;
          _isLoadingRemark = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching driver remark: $e');
      if (mounted) {
        setState(() {
          _isLoadingRemark = false;
        });
      }
    }
    */
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () => context.push('/vehicle/${widget.vehicle.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/vehicle_placeholder.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              LucideIcons.car,
                              size: 32,
                              color: AppTheme.primaryGreen.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.vehicle.vehicleNumber,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  widget.vehicle.status,
                                ).withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(
                                    widget.vehicle.status,
                                  ).withAlpha(50),
                                ),
                              ),
                              child: Text(
                                _getStatusText(context, widget.vehicle.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(widget.vehicle.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.vehicle.customerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          () {
                            final makeModel =
                                '${widget.vehicle.make ?? ""} ${widget.vehicle.model ?? ""}'
                                    .trim();
                            // Show Make/Model if available
                            if (makeModel.isNotEmpty) return makeModel;

                            // Otherwise show service type (e.g. "General") from DB
                            return widget.vehicle.serviceType;
                          }(),
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color ??
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: Colors.grey),
                ],
              ),
              // Driver remark section - show only when vehicle is in garage and has a remark
              if (widget.vehicle.isVehicleIn &&
                  _driverRemark != null &&
                  _driverRemark!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.messageSquare,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver Remark',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _driverRemark!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
