import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../models/vehicle.dart';
import '../theme.dart';

class VehicleSummaryScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleSummaryScreen({super.key, required this.vehicleId});

  @override
  State<VehicleSummaryScreen> createState() => _VehicleSummaryScreenState();
}

class _VehicleSummaryScreenState extends State<VehicleSummaryScreen> {
  List<Map<String, dynamic>> _issues = [];
  bool _isLoadingIssues = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    final provider = context.read<AppProvider>();
    final issues = await provider.getIssuesForVehicle(widget.vehicleId);
    setState(() {
      _issues = issues;
      _isLoadingIssues = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vehicle = provider.getVehicleById(widget.vehicleId);
    final inspection = provider.getInspectionForVehicle(widget.vehicleId);

    if (vehicle == null) {
      return const Scaffold(body: Center(child: Text('Vehicle not found')));
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.inspectionSummary, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.home, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Info Card
            _buildVehicleHeader(vehicle),
            const SizedBox(height: 24),

            // Inspection Checklist Results
            if (inspection != null) ...[
              Text(l10n.inspectionChecklist, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildChecklistResults(inspection),
              const SizedBox(height: 32),
            ],

            // Reported Issues
            Text(l10n.reportedIssues, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isLoadingIssues)
              const Center(child: CircularProgressIndicator())
            else if (_issues.isEmpty)
              _buildEmptyIssues()
            else
              ..._issues.map((issueData) {
                // Convert Map to ReportedIssue for display
                final issue = ReportedIssue(
                  id: issueData['job_id'] ?? issueData['id'] ?? '',
                  vehicleId: widget.vehicleId,
                  type: issueData['issue_type'] ?? issueData['type'] ?? 'Unknown',
                  description: issueData['description'] ?? '',
                  timestamp: issueData['diagnosis_date'] != null 
                      ? DateTime.parse(issueData['diagnosis_date'])
                      : DateTime.now(),
                  photoPath: issueData['photo_url'],
                  videoPath: issueData['video_url'],
                );
                return _buildIssueCard(context, issue);
              }),
            
            const SizedBox(height: 48),
            
            // Done Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(l10n.backToDashboard, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeader(Vehicle vehicle) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), 
            blurRadius: 10
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
                Text(vehicle.vehicleNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(vehicle.customerName, style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistResults(InspectionResult inspection) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: inspection.checks.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final entry = inspection.checks.entries.elementAt(index);
          final isOk = entry.value == 'ok';
          return ListTile(
            dense: true,
            title: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: Icon(
              isOk ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
              color: isOk ? Colors.green : Colors.orange,
              size: 20,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIssueCard(BuildContext context, ReportedIssue issue) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasMedia = issue.photoPath != null || issue.videoPath != null;
    
    return InkWell(
      onTap: () => _showIssueDetails(context, issue),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.dangerRed.withOpacity(0.1) 
            : const Color(0xFFFEF2F2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppTheme.dangerRed, size: 18),
                      const SizedBox(width: 8),
                      Text(issue.type, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                    ],
                  ),
                  if (hasMedia)
                    Icon(issue.photoPath != null ? LucideIcons.image : LucideIcons.video, color: AppTheme.dangerRed, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                issue.description, 
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF7F1D1D))
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   Text(l10n.viewDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                  const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.dangerRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIssueDetails(BuildContext context, ReportedIssue issue) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: AppTheme.dangerRed, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      issue.type, 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppTheme.dangerRed),
                  onPressed: () => _confirmDelete(context, issue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported on ${issue.timestamp.hour}:${issue.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 32),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(issue.description, style: const TextStyle(fontSize: 15, color: Color(0xFF374151), height: 1.5)),
            const SizedBox(height: 24),
            if (issue.photoPath != null) ...[
              const Text('Photo Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(issue.photoPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else if (issue.videoPath != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.video, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(l10n.videoCaptured, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l10n.playbackAvailable, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.close, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _confirmDelete(BuildContext context, ReportedIssue issue) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteIssueTitle),
          content: Text(l10n.deleteIssueConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
          TextButton(
            onPressed: () async {
              await context.read<AppProvider>().removeIssue(issue.id);
              if (dialogContext.mounted) Navigator.pop(dialogContext); // Close dialog
              if (context.mounted) Navigator.pop(context); // Close bottom sheet
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.issueRemoved)),
                );
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
    );
  }

  Widget _buildEmptyIssues() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.05) 
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.none),
      ),
      child: Center(
        child: Text(AppLocalizations.of(context)!.noIssuesReported, style: const TextStyle(color: Color(0xFF9CA3AF))),
      ),
    );
  }
}
