import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'smart_camera_screen.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class InventoryPhotosScreen extends StatefulWidget {
  final String vehicleId;
  const InventoryPhotosScreen({super.key, required this.vehicleId});

  @override
  State<InventoryPhotosScreen> createState() => _InventoryPhotosScreenState();
}

class _InventoryPhotosScreenState extends State<InventoryPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _additionalPhotos = [];
  
  final List<Map<String, String>> categories = [
    {'id': 'ext_front', 'label': 'Exterior: Front View', 'icon': 'car'},
    {'id': 'ext_rear', 'label': 'Exterior: Rear View', 'icon': 'car'},
    {'id': 'ext_left', 'label': 'Exterior: Left Side', 'icon': 'car'},
    {'id': 'ext_right', 'label': 'Exterior: Right Side', 'icon': 'car'},
    {'id': 'dents', 'label': 'Dents & Scratches', 'icon': 'scan'},
    {'id': 'interior', 'label': 'Interior / Cabin', 'icon': 'armchair'},
    {'id': 'dikki', 'label': 'Dikki / Trunk', 'icon': 'shopping-bag'},
    {'id': 'tools', 'label': 'Tool Kit', 'icon': 'wrench'},
    {'id': 'valuables', 'label': 'Valuables Check', 'icon': 'briefcase'},
  ];

  @override
  void initState() {
    super.initState();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    // Standard image_picker lost data recovery is less relevant with custom camera
    // but we can leave it or remove it. Let's remove to stay clean.
  }

  Future<void> _capture(int index) async {
    if (index >= categories.length) return;
    final category = categories[index];
    
    // Prepare existing photos for the filmstrip
    final photosMap = context.read<AppProvider>().getInventoryPhotos(widget.vehicleId);
    final List<Map<String, dynamic>> existingPhotos = [];
    
    for (var cat in categories) {
      if (photosMap.containsKey(cat['id'])) {
        existingPhotos.add({
          'path': photosMap[cat['id']],
          'label': cat['label'],
        });
      }
    }

    try {
      final String? path = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => SmartCameraScreen(
            categoryId: category['id']!,
            categoryLabel: category['label']!,
            existingPhotos: existingPhotos,
          ),
        ),
      );
      
      if (path != null) {
        if (!mounted) return;
        
        // Show loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syncing photo to dashboard...'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Save photo
        await context.read<AppProvider>().setInventoryPhoto(
          widget.vehicleId, 
          category['id']!, 
          path
        );

        // Auto move to next photo if available
        if (mounted && index + 1 < categories.length) {
          // Add a small delay for better transition feel
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _capture(index + 1);
          });
        } else if (mounted && index + 1 == categories.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All photos captured successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto(Map<String, String> category) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: Text('Are you sure you want to remove the photo for ${category['label']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await context.read<AppProvider>().removeInventoryPhoto(widget.vehicleId, category['id']!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo removed for ${category['label']}')),
      );
    }
  }

  Future<void> _showAdditionalPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Additional Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.camera, color: AppTheme.primaryBlue),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture'),
              onTap: () {
                Navigator.pop(context);
                _captureAdditionalPhoto();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.image, color: AppTheme.successGreen),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select multiple photos'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAdditionalPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _additionalPhotos.add(photo.path);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo added successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing additional photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      
      if (photos.isNotEmpty) {
        setState(() {
          _additionalPhotos.addAll(photos.map((p) => p.path));
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${photos.length} photo(s) added successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeAdditionalPhoto(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to remove this additional photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _additionalPhotos.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo removed')),
        );
      }
    }
  }

  bool get _isAllDone {
    final photos = context.watch<AppProvider>().getInventoryPhotos(widget.vehicleId);
    return categories.every((cat) => photos.containsKey(cat['id']));
  }

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<AppProvider>().getInventoryPhotos(widget.vehicleId);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Inventory Photos', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                const Icon(LucideIcons.info, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All 9 photos are compulsory for this report.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                      if (photos.length < categories.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () => _capture(photos.length), // Start from first missing
                            icon: const Icon(LucideIcons.play, size: 16),
                            label: const Text('Start Capture Flow'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${photos.length}/${categories.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length + 1, // +1 for additional photos box
              itemBuilder: (context, index) {
                if (index < categories.length) {
                  final cat = categories[index];
                  final photoPath = photos[cat['id']];
                  return _buildPhotoCard(index, cat, photoPath);
                } else {
                  // Additional photos box
                  return _buildAdditionalPhotosCard();
                }
              },
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index, Map<String, String> cat, String? path) {
    final bool hasPhoto = path != null;
    
    return InkWell(
      onTap: () => _capture(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPhoto ? AppTheme.successGreen : Theme.of(context).dividerColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                kIsWeb 
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(cat['icon']!), color: AppTheme.primaryBlue, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        cat['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).textTheme.titleMedium?.color
                        ),
                      ),
                    ),
                  ],
                ),
              if (hasPhoto)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => _removePhoto(cat),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(LucideIcons.trash2, color: AppTheme.dangerRed, size: 14),
                    ),
                  ),
                ),
              if (hasPhoto)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: (hasPhoto ? AppTheme.successGreen : AppTheme.primaryBlue).withOpacity(0.1),
                  child: Text(
                    hasPhoto ? 'Retake' : 'Capture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: hasPhoto ? AppTheme.successGreen : AppTheme.primaryBlue
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalPhotosCard() {
    return InkWell(
      onTap: _additionalPhotos.isEmpty 
          ? _showAdditionalPhotoOptions 
          : _showAdditionalPhotosDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _additionalPhotos.isNotEmpty ? AppTheme.warningOrange : Theme.of(context).dividerColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: AppTheme.warningOrange, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Additional Photos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).textTheme.titleMedium?.color
                      ),
                    ),
                  ),
                  if (_additionalPhotos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_additionalPhotos.length} photo(s)',
                        style: const TextStyle(fontSize: 10, color: AppTheme.warningOrange, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              if (_additionalPhotos.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_additionalPhotos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  child: Text(
                    _additionalPhotos.isEmpty ? 'Add Photos' : 'View All',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.warningOrange
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdditionalPhotosDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Additional Photos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _additionalPhotos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  _additionalPhotos[index],
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_additionalPhotos[index]),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _removeAdditionalPhoto(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.trash2,
                                color: AppTheme.dangerRed,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAdditionalPhotoOptions();
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add More Photos'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final bool done = _isAllDone;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: done ? () => context.pop() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              done ? 'Verify & Apply' : 'Capture all photos to proceed',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'car': return LucideIcons.car;
      case 'scan': return LucideIcons.scan;
      case 'armchair': return LucideIcons.armchair;
      case 'shopping-bag': return LucideIcons.shoppingBag;
      case 'wrench': return LucideIcons.wrench;
      case 'briefcase': return LucideIcons.briefcase;
      default: return LucideIcons.camera;
    }
  }
}
