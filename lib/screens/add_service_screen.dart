import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class AddServiceScreen extends StatefulWidget {
  final String vehicleId;
  const AddServiceScreen({super.key, required this.vehicleId});
  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _serviceStatus;
  int _charCount = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _descController.addListener(() {
      setState(() {
        _charCount = _descController.text.length;
      });
    });
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
        await _picker.pickVideo(source: source);
      } else {
        await _picker.pickImage(source: source);
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _showSourcePicker(bool isVideo) {
    showModalBottomSheet(
      context: context,
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
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
            _buildLabel('Service Type'),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                const options = ['Oil Change', 'Brake Service', 'Tire Rotation', 'General Checkup'];
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return options.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Synchronize our _typeController with the internal Autocomplete controller
                if (_typeController.text != controller.text && _typeController.text.isEmpty) {
                  // Initialize if needed
                }
                
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration('Select or type service type').copyWith(
                    suffixIcon: const Icon(LucideIcons.chevronDown, size: 18, color: Colors.grey),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _typeController.text = value;
                    });
                  },
                );
              },
              onSelected: (String selection) {
                setState(() {
                  _typeController.text = selection;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildLabel('Service Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration('Enter detailed description of the service...')
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 8),
            Text('$_charCount/500 characters', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
            const SizedBox(height: 24),
            _buildLabel('Service Status'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Select status'),
              items: ['Pending', 'In Progress', 'Completed']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _serviceStatus = v),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: (_typeController.text.isNotEmpty && _serviceStatus != null && _descController.text.isNotEmpty)
                    ? () => context.pop()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA8D5A2), // Match green from image
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFA8D5A2).withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.check, size: 24),
                    SizedBox(width: 12),
                    Text('Save Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1),
      ),
    );
  }

  Widget _uploadButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
