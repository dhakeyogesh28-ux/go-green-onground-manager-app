import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../models/vehicle.dart';
import '../theme.dart';
import 'package:mobile/l10n/app_localizations.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<AppProvider>().refreshVehicles();
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 14
            ),
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: Icon(
                LucideIcons.search,
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                size: 20
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, color: Color(0xFF6B7280), size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppTheme.primaryBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.hub, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      _searchQuery.isNotEmpty
                          ? '${vehicles.length} vehicle(s) found'
                          : allVehicles.isEmpty && !isLoading 
                              ? 'No vehicles in hub' 
                              : 'Manage hub vehicles',
                      style: const TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
                    ),
                  ],
                ),
              ),
            ),
            // Status Filter Tabs
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusTab(l10n.all, _getStatusCount(allVehicles, null), null),
                      const SizedBox(width: 8),
                      _buildStatusTab(l10n.active, _getStatusCount(allVehicles, VehicleStatus.active), VehicleStatus.active),
                      const SizedBox(width: 8),
                      _buildStatusTab(l10n.charging, _getStatusCount(allVehicles, VehicleStatus.charging), VehicleStatus.charging),
                      const SizedBox(width: 8),
                      _buildStatusTab(l10n.idle, _getStatusCount(allVehicles, VehicleStatus.idle), VehicleStatus.idle),
                      const SizedBox(width: 8),
                      _buildStatusTab(l10n.maintenance, _getStatusCount(allVehicles, VehicleStatus.maintenance), VehicleStatus.maintenance),
                    ],
                  ),
                ),
              ),
            ),
            if (error != null)
              SliverFillRemaining(
                child: _ErrorView(error: error, onRetry: _onRefresh),
              )
            else if (isLoading && allVehicles.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vehicles.isEmpty)
              SliverFillRemaining(
                child: _searchQuery.isNotEmpty
                    ? _NoSearchResults(onClear: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      })
                    : _EmptyView(onRefresh: _onRefresh),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final vehicle = vehicles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VehicleCard(vehicle: vehicle),
                      );
                    },
                    childCount: vehicles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
              ? AppTheme.primaryBlue 
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
          const Text('No vehicles found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Try a different search term', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/vehicle_placeholder.png', width: 120, height: 120),
          const SizedBox(height: 16),
          const Text('No vehicles in hub', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
            const Text('Failed to load vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
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

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active: return Colors.green;
      case VehicleStatus.idle: return Colors.orange;
      case VehicleStatus.charging: return Colors.blue;
      case VehicleStatus.maintenance: return Colors.red;
    }
  }

  String _getStatusText(BuildContext context, VehicleStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case VehicleStatus.active: return l10n.active;
      case VehicleStatus.idle: return l10n.idle;
      case VehicleStatus.charging: return l10n.charging;
      case VehicleStatus.maintenance: return l10n.maintenance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/vehicle/${vehicle.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Image.asset(
                  'assets/images/vehicle_placeholder.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vehicle.vehicleNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color
                          )
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(vehicle.status).withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(vehicle.status).withAlpha(50)),
                          ),
                          child: Text(_getStatusText(context, vehicle.status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(vehicle.status))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color
                      )
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.serviceType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey
                      )
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
