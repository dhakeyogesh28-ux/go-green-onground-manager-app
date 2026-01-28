import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../models/vehicle.dart';
import '../theme.dart';

class AddIssueScreen extends StatefulWidget {
  final String vehicleId;
  const AddIssueScreen({super.key, required this.vehicleId});

  @override
  State<AddIssueScreen> createState() => _AddIssueScreenState();
}

class _AddIssueScreenState extends State<AddIssueScreen> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  int _charCount = 0;
  final ImagePicker _picker = ImagePicker();
  String? _capturedPhotoPath;
  String? _capturedVideoPath;

  @override
  void initState() {
    super.initState();
    _descController.addListener(() {
      setState(() {
        _charCount = _descController.text.length;
      });
      _saveDraft();
    });
    _typeController.addListener(_saveDraft);
    _checkLostData();
    _loadDraft();
  }

  Future<void> _checkLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        if (response.type == RetrieveType.video) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recovered video: ${response.file!.name}')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recovered image: ${response.file!.name}')),
          );
        }
      });
    } else {
      debugPrint('Lost data error: ${response.exception?.code}');
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftType = prefs.getString('draft_type_${widget.vehicleId}');
    final draftDesc = prefs.getString('draft_desc_${widget.vehicleId}');

    if (draftType != null || draftDesc != null) {
      setState(() {
        if (draftType != null) _typeController.text = draftType;
        if (draftDesc != null) _descController.text = draftDesc;
      });
      debugPrint('AddIssueScreen: [DRAFT] Recovered draft for vehicle ${widget.vehicleId}');
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_type_${widget.vehicleId}', _typeController.text);
    await prefs.setString('draft_desc_${widget.vehicleId}', _descController.text);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_type_${widget.vehicleId}');
    await prefs.remove('draft_desc_${widget.vehicleId}');
    debugPrint('AddIssueScreen: [DRAFT] Cleared');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool isVideo, ImageSource source) async {
    try {
      if (isVideo) {
        final XFile? video = await _picker.pickVideo(source: source);
        if (video != null) {
          setState(() {
            _capturedVideoPath = video.path;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video captured: ${video.name}')),
          );
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _capturedPhotoPath = image.path;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image captured: ${image.name}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing ${isVideo ? 'video' : 'camera'}: $e')),
      );
    }
  }

  void _showSourcePicker(bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Source for ${isVideo ? 'Video' : 'Photo'}',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceOption(
                    'Camera',
                    LucideIcons.camera,
                    () {
                      Navigator.pop(context);
                      _pickMedia(isVideo, ImageSource.camera);
                    },
                  ),
                  _sourceOption(
                    'Gallery',
                    LucideIcons.image,
                    () {
                      Navigator.pop(context);
                      _pickMedia(isVideo, ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Issue', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Issue Type'),
            const SizedBox(height: 8),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _typeController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                const options = AppProvider.issueTypes;
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return options.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (val) => _typeController.text = val,
                  decoration: _inputDecoration('Select or type issue type'),
                );
              },
              onSelected: (String selection) {
                _typeController.text = selection;
              },
            ),
            const SizedBox(height: 24),
            _buildLabel('Issue Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration('Enter detailed description of the issue...')
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 8),
            Text(
              '$_charCount/500 characters', 
              style: TextStyle(
                fontSize: 12, 
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Upload photo and video'),
            const SizedBox(height: 12),
            Row(
              children: [
                _uploadButton('Photo', LucideIcons.camera, () => _showSourcePicker(false)),
                const SizedBox(width: 24),
                _uploadButton('Video', LucideIcons.video, () => _showSourcePicker(true)),
              ],
            ),
            if (_capturedPhotoPath != null || _capturedVideoPath != null) ...[
              const SizedBox(height: 24),
              _buildLabel('Selected Media'),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_capturedPhotoPath != null)
                      _buildMediaThumbnail(
                        File(_capturedPhotoPath!), 
                        false, 
                        () => setState(() => _capturedPhotoPath = null)
                      ),
                    if (_capturedVideoPath != null)
                      _buildMediaThumbnail(
                        File(_capturedVideoPath!), 
                        true, 
                        () => setState(() => _capturedVideoPath = null)
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: (_typeController.text.isNotEmpty && _descController.text.isNotEmpty)
                    ? () async {
                        await context.read<AppProvider>().addIssue(ReportedIssue(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              vehicleId: widget.vehicleId,
                              type: _typeController.text,
                              description: _descController.text,
                              timestamp: DateTime.now(),
                              photoPath: _capturedPhotoPath,
                              videoPath: _capturedVideoPath,
                            ));
                        await _clearDraft();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Issue reported successfully')),
                        );
                        debugPrint('AddIssueScreen: [REPORT] Back to details...');
                        Navigator.of(context).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.dangerRed.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 24),
                    SizedBox(width: 12),
                    Text('Report Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15, 
        fontWeight: FontWeight.bold, 
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1),
      ),
    );
  }

  Widget _uploadButton(String label, IconData icon, VoidCallback onTap) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: TextStyle(
              fontSize: 13, 
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563), 
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMediaThumbnail(File file, bool isVideo, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isVideo
                ? Container(
                    color: Colors.black12,
                    child: const Icon(LucideIcons.video, color: Colors.grey),
                  )
                : Image.file(file, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Icon(LucideIcons.x, size: 14, color: AppTheme.dangerRed),
              ),
            ),
          ),
          if (isVideo)
            const Center(
              child: Icon(LucideIcons.play, color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }
}
