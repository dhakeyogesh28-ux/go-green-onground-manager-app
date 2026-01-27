import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/models/driver.dart';
import 'package:mobile/services/driver_service.dart';
import 'package:mobile/theme.dart';

class DriverAssignmentSection extends StatefulWidget {
  final String? vehicleId;
  final String? hubId;
  final String title;
  final Function(Driver?) onDriverSelected;
  final Driver? initialDriver;

  const DriverAssignmentSection({
    super.key,
    this.vehicleId,
    this.hubId,
    this.title = 'Assigned Driver',
    required this.onDriverSelected,
    this.initialDriver,
  });

  @override
  State<DriverAssignmentSection> createState() => _DriverAssignmentSectionState();
}

class _DriverAssignmentSectionState extends State<DriverAssignmentSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Driver> _searchResults = [];
  Driver? _selectedDriver;
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDriver = widget.initialDriver;
    
    // Load last assigned driver if vehicle ID is provided
    if (widget.vehicleId != null && _selectedDriver == null) {
      _loadLastAssignedDriver();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLastAssignedDriver() async {
    if (widget.vehicleId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final driver = await DriverService.getLastAssignedDriver(widget.vehicleId!);
      if (driver != null && mounted) {
        setState(() {
          _selectedDriver = driver;
          _isLoading = false;
        });
        widget.onDriverSelected(driver);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchDrivers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await DriverService.searchDrivers(
        query,
        hubId: widget.hubId,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching drivers: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _selectDriver(Driver driver) {
    setState(() {
      _selectedDriver = driver;
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    widget.onDriverSelected(driver);
  }

  void _clearSelection() {
    setState(() {
      _selectedDriver = null;
      _searchController.clear();
      _searchResults = [];
      _isSearching = false;
    });
    widget.onDriverSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            const Icon(
              LucideIcons.userCheck,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected Driver Display or Search Bar
        if (_selectedDriver != null)
          _buildSelectedDriverCard()
        else
          _buildSearchBar(),

        // Search Results
        if (_isSearching && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResults(),
        ],

        // No results message
        if (_isSearching && _searchResults.isEmpty && !_isLoading) ...[
          const SizedBox(height: 8),
          _buildNoResults(),
        ],

        // Loading indicator
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _searchDrivers,
      decoration: InputDecoration(
        hintText: 'Search driver by name, phone, or license...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF9CA3AF)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(LucideIcons.x, color: Color(0xFF9CA3AF)),
                onPressed: () {
                  _searchController.clear();
                  _searchDrivers('');
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildSelectedDriverCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successGreen),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.userCheck,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDriver!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_selectedDriver!.phoneNumber != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.phone,
                        size: 12,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedDriver!.phoneNumber!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_selectedDriver!.licenseNumber != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.creditCard,
                        size: 12,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'License: ${_selectedDriver!.licenseNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Color(0xFF6B7280)),
            onPressed: _clearSelection,
            tooltip: 'Remove driver',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final driver = _searchResults[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            title: Text(
              driver.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (driver.phoneNumber != null)
                  Text(
                    driver.phoneNumber!,
                    style: const TextStyle(fontSize: 12),
                  ),
                if (driver.licenseNumber != null)
                  Text(
                    'License: ${driver.licenseNumber}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
              ],
            ),
            trailing: const Icon(
              LucideIcons.chevronRight,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            onTap: () => _selectDriver(driver),
          );
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.searchX,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No drivers found. Try a different search term.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
