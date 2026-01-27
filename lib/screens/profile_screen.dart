import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/vehicle.dart';
import '../theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final userEmail = appProvider.userEmail ?? 'user@example.com';
    final userHub = appProvider.selectedHub ?? 'Unknown Hub';
    final userName = appProvider.userName;
    
    // Use full name from database if available, otherwise extract from email
    final String displayName;
    if (userName != null && userName.isNotEmpty) {
      displayName = userName;
    } else {
      final emailUsername = userEmail.split('@').first;
      displayName = emailUsername.split('.').map((part) => 
        part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1)
      ).join(' ');
    }
    
    // Get initials from display name or email
    final String initials;
    if (userName != null && userName.isNotEmpty) {
      final nameParts = userName.split(' ');
      if (nameParts.length >= 2) {
        initials = nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else {
        initials = userName.substring(0, userName.length >= 2 ? 2 : 1).toUpperCase();
      }
    } else {
      final emailUsername = userEmail.split('@').first;
      initials = emailUsername.length >= 2 
        ? emailUsername.substring(0, 2).toUpperCase()
        : emailUsername.substring(0, 1).toUpperCase();
    }

    // Calculate real task statistics from vehicles
    final vehicles = appProvider.vehicles;
    final active = vehicles.where((v) => v.status == VehicleStatus.active).length;
    final charging = vehicles.where((v) => v.status == VehicleStatus.charging).length;
    final maintenance = vehicles.where((v) => v.status == VehicleStatus.maintenance).length;
    final idle = vehicles.where((v) => v.status == VehicleStatus.idle).length;
    
    final userData = {
      'name': displayName,
      'role': 'On-Ground Manager',
      'email': userEmail,
      'location': userHub,
      'active': active,
      'charging': charging,
      'maintenance': maintenance,
      'idle': idle
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  color: AppTheme.primaryBlue,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage your account',
                        style: TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
                      ),
                    ],
                  ),
                ),
                // Overlapping Profile Card
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['name'] as String,
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold, 
                                      color: Theme.of(context).textTheme.titleLarge?.color
                                    ),
                                  ),
                                  Text(
                                    userData['role'] as String,
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 36,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const EditProfileScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(LucideIcons.settings, size: 14),
                                      label: const Text('Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                        side: BorderSide(color: Theme.of(context).dividerColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildContactItem(context, LucideIcons.mail, 'Email', userData['email'] as String),
                        _buildContactItem(context, LucideIcons.mapPin, 'Hub Location', userData['location'] as String, isLast: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Padding for the overlapping card + stats card
            const SizedBox(height: 300), 
            
            // Task Statistics Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Statistics',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).textTheme.titleLarge?.color
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatPod(context, 'Active', userData['active'].toString(), const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
                        _buildStatPod(context, 'Charging', userData['charging'].toString(), const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatPod(context, 'Idle', userData['idle'].toString(), const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
                        _buildStatPod(context, 'Maintenance', userData['maintenance'].toString(), const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => context.read<AppProvider>().logout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.logOut, size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.05) 
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPod(BuildContext context, String label, String value, Color bgColor, Color textColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? textColor.withOpacity(0.15) : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: textColor.withOpacity(0.3), width: 1) : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? textColor.withOpacity(0.9) : textColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w500, 
                color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6B7280)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
