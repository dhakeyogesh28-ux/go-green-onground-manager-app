import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class UploadPhotosScreen extends StatefulWidget {
  final String vehicleId;
  const UploadPhotosScreen({super.key, required this.vehicleId});
  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource s) async {
    final XFile? image = await _picker.pickImage(source: s);
    if (image != null) setState(() => _photos.add(image));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photos'), leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => context.pop())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _btn('Camera', LucideIcons.camera, () => _pick(ImageSource.camera))),
            const SizedBox(width: 12),
            Expanded(child: _btn('Gallery', LucideIcons.image, () => _pick(ImageSource.gallery))),
          ]),
          const SizedBox(height: 24),
          if (_photos.isEmpty) const Center(child: Text('No photos yet', style: TextStyle(color: Colors.grey)))
          else ..._photos.map((p) => ListTile(leading: const Icon(LucideIcons.image), title: Text(p.name))),
          const SizedBox(height: 24),
          if (_photos.isNotEmpty) ElevatedButton(onPressed: () => context.pop(), child: Text('Upload ${_photos.length} Photos')),
        ],
      ),
    );
  }

  Widget _btn(String l, IconData i, VoidCallback t) {
    return InkWell(onTap: t, child: Container(height: 100, decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryBlue), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: AppTheme.primaryBlue), Text(l, style: const TextStyle(color: AppTheme.primaryBlue))])));
  }
}
