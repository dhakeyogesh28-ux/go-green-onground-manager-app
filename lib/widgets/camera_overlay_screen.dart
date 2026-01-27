import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../theme.dart';

class CameraOverlayScreen extends StatefulWidget {
  final String categoryId;
  final String categoryLabel;
  final Function(String) onPhotoTaken;

  const CameraOverlayScreen({
    super.key,
    required this.categoryId,
    required this.categoryLabel,
    required this.onPhotoTaken,
  });

  @override
  State<CameraOverlayScreen> createState() => _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends State<CameraOverlayScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;

  // Category-specific instructions
  Map<String, String> get _instructions => {
    'exterior_front': 'Align the front of the vehicle within the frame',
    'exterior_rear': 'Align the rear of the vehicle within the frame',
    'exterior_left': 'Rotate your phone to landscape mode and capture the left side',
    'exterior_right': 'Rotate your phone to landscape mode and capture the right side',
    'dents_scratches': 'Focus on any dents, scratches, or damage',
    'interior_cabin': 'Capture the interior cabin',
    'dikki_trunk': 'Capture the trunk/dikki interior',
    'tool_kit': 'Capture the tool kit contents',
    'valuables_check': 'Capture any valuables or important items',
    'additional_photos': 'Capture any additional details',
  };

  String get _instruction => _instructions[widget.categoryId] ?? 'Position the subject within the frame';

  bool get _shouldShowVehicleOutline {
    return widget.categoryId.startsWith('exterior_');
  }

  bool get _isLandscapeCategory {
    return widget.categoryId == 'exterior_left' || widget.categoryId == 'exterior_right';
  }

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _initializeCamera();
  }

  void _setOrientation() {
    if (_isLandscapeCategory) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      
      if (mounted) {
        widget.onPhotoTaken(photo.path);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      setState(() {
        _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      });
      await _controller!.setFlashMode(_flashMode);
    } catch (e) {
      // Flash not supported
    }
  }

  @override
  void dispose() {
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isInitialized || _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Live Camera Preview
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),

                // Vehicle Outline Overlay (if applicable)
                if (_shouldShowVehicleOutline)
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * (_isLandscapeCategory ? 0.85 : 0.95),
                        height: MediaQuery.of(context).size.width * (_isLandscapeCategory ? 0.5 : 0.8),
                        child: CustomPaint(
                          painter: VehicleOutlinePainter(
                            categoryId: widget.categoryId,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Top instruction bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.x, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.categoryLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _instruction,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Corner frame markers
                ...List.generate(4, (index) {
                  final isTop = index < 2;
                  final isLeft = index % 2 == 0;
                  return Positioned(
                    top: isTop ? 100 : null,
                    bottom: isTop ? null : 100,
                    left: isLeft ? 40 : null,
                    right: isLeft ? null : 40,
                    child: CustomPaint(
                      size: const Size(40, 40),
                      painter: CornerMarkerPainter(
                        isTop: isTop,
                        isLeft: isLeft,
                      ),
                    ),
                  );
                }),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Flash toggle
                          IconButton(
                            icon: Icon(
                              _flashMode == FlashMode.off ? LucideIcons.zap : LucideIcons.zapOff,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _toggleFlash,
                          ),
                          
                          // Capture button
                          GestureDetector(
                            onTap: _isCapturing ? null : _capturePhoto,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: _isCapturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Placeholder for symmetry
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Corner marker painter
class CornerMarkerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  CornerMarkerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    if (isTop && isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Vehicle outline painter (optimized for mobile portrait screens)
class VehicleOutlinePainter extends CustomPainter {
  final String categoryId;

  VehicleOutlinePainter({required this.categoryId});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Check if portrait or landscape
    final isPortrait = size.height > size.width;

    if (categoryId == 'exterior_front') {
      _drawFrontCar(canvas, size, paint, isPortrait);
    } else if (categoryId == 'exterior_rear') {
      _drawRearCar(canvas, size, paint, isPortrait);
    } else if (categoryId == 'exterior_left' || categoryId == 'exterior_right') {
      _drawSideCar(canvas, size, paint, isPortrait);
    }
  }

  void _drawFrontCar(Canvas canvas, Size size, Paint paint, bool isPortrait) {
    final w = size.width;
    final h = size.height;
    
    // Optimized for mobile portrait - wider and centered vertically
    final centerY = h * 0.5;
    final carWidth = w * 0.75; // Wider for mobile
    final carHeight = h * 0.25; // Shorter for mobile
    
    final path = Path();
    
    // Roof & Windshield (Curvy)
    path.moveTo(w * 0.25, centerY - carHeight * 0.6);
    path.quadraticBezierTo(w * 0.5, centerY - carHeight * 0.8, w * 0.75, centerY - carHeight * 0.6);
    path.quadraticBezierTo(w * 0.85, centerY - carHeight * 0.2, w * 0.85, centerY);
    path.lineTo(w * 0.15, centerY);
    path.quadraticBezierTo(w * 0.15, centerY - carHeight * 0.2, w * 0.25, centerY - carHeight * 0.6);

    // Main Body/Grille Area
    path.moveTo(w * 0.1, centerY);
    path.quadraticBezierTo(w * 0.1, centerY + carHeight * 0.8, w * 0.2, centerY + carHeight * 0.8);
    path.lineTo(w * 0.8, centerY + carHeight * 0.8);
    path.quadraticBezierTo(w * 0.9, centerY + carHeight * 0.8, w * 0.9, centerY);
    path.close();

    canvas.drawPath(path, paint);

    // Stylish Headlights
    final leftLight = Path()
      ..moveTo(w * 0.15, centerY + carHeight * 0.2)
      ..quadraticBezierTo(w * 0.25, centerY + carHeight * 0.1, w * 0.3, centerY + carHeight * 0.4)
      ..quadraticBezierTo(w * 0.2, centerY + carHeight * 0.5, w * 0.15, centerY + carHeight * 0.2);
    canvas.drawPath(leftLight, paint);

    final rightLight = Path()
      ..moveTo(w * 0.85, centerY + carHeight * 0.2)
      ..quadraticBezierTo(w * 0.75, centerY + carHeight * 0.1, w * 0.7, centerY + carHeight * 0.4)
      ..quadraticBezierTo(w * 0.8, centerY + carHeight * 0.5, w * 0.85, centerY + carHeight * 0.2);
    canvas.drawPath(rightLight, paint);
    
    // Modern Grille
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, centerY + carHeight * 0.5),
          width: w * 0.35,
          height: carHeight * 0.3,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  void _drawRearCar(Canvas canvas, Size size, Paint paint, bool isPortrait) {
    final w = size.width;
    final h = size.height;
    
    // Optimized for mobile portrait
    final centerY = h * 0.5;
    final carWidth = w * 0.75;
    final carHeight = h * 0.25;
    
    final path = Path();

    // Rear Roof & Window
    path.moveTo(w * 0.25, centerY - carHeight * 0.6);
    path.quadraticBezierTo(w * 0.5, centerY - carHeight * 0.7, w * 0.75, centerY - carHeight * 0.6);
    path.quadraticBezierTo(w * 0.85, centerY - carHeight * 0.2, w * 0.85, centerY);
    path.lineTo(w * 0.15, centerY);
    path.quadraticBezierTo(w * 0.15, centerY - carHeight * 0.2, w * 0.25, centerY - carHeight * 0.6);

    // Boot Area
    path.moveTo(w * 0.1, centerY);
    path.quadraticBezierTo(w * 0.1, centerY + carHeight * 0.8, w * 0.2, centerY + carHeight * 0.8);
    path.lineTo(w * 0.8, centerY + carHeight * 0.8);
    path.quadraticBezierTo(w * 0.9, centerY + carHeight * 0.8, w * 0.9, centerY);
    path.close();

    canvas.drawPath(path, paint);

    // Sleek Tail lights
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, centerY + carHeight * 0.15, w * 0.18, carHeight * 0.25),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.7, centerY + carHeight * 0.15, w * 0.18, carHeight * 0.25),
        const Radius.circular(4),
      ),
      paint,
    );
    
    // Number Plate Area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, centerY + carHeight * 0.45),
          width: w * 0.22,
          height: carHeight * 0.3,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawSideCar(Canvas canvas, Size size, Paint paint, bool isPortrait) {
    final w = size.width;
    final h = size.height;
    
    // Optimized for mobile portrait - horizontal car profile
    final centerY = h * 0.5;
    final carHeight = h * 0.3;
    
    final path = Path();

    // Side profile optimized for mobile
    path.moveTo(w * 0.05, centerY + carHeight * 0.5);
    // Front bumper
    path.quadraticBezierTo(w * 0.05, centerY + carHeight * 0.2, w * 0.12, centerY + carHeight * 0.1);
    // Hood
    path.lineTo(w * 0.28, centerY + carHeight * 0.1);
    // Windshield
    path.lineTo(w * 0.42, centerY - carHeight * 0.3);
    // Roof
    path.lineTo(w * 0.72, centerY - carHeight * 0.3);
    // Rear windshield
    path.lineTo(w * 0.85, centerY + carHeight * 0.1);
    // Trunk
    path.quadraticBezierTo(w * 0.95, centerY + carHeight * 0.1, w * 0.95, centerY + carHeight * 0.5);
    // Rear bumper
    path.lineTo(w * 0.95, centerY + carHeight * 0.7);
    // Underbody with wheel arches
    path.lineTo(w * 0.85, centerY + carHeight * 0.7);
    path.arcToPoint(Offset(w * 0.68, centerY + carHeight * 0.7), radius: const Radius.circular(35), clockwise: false);
    path.lineTo(w * 0.38, centerY + carHeight * 0.7);
    path.arcToPoint(Offset(w * 0.21, centerY + carHeight * 0.7), radius: const Radius.circular(35), clockwise: false);
    path.lineTo(w * 0.05, centerY + carHeight * 0.7);
    path.close();

    canvas.drawPath(path, paint);

    // Windows
    final windowPath = Path()
      ..moveTo(w * 0.35, centerY + carHeight * 0.15)
      ..lineTo(w * 0.45, centerY - carHeight * 0.2)
      ..lineTo(w * 0.68, centerY - carHeight * 0.2)
      ..lineTo(w * 0.78, centerY + carHeight * 0.15)
      ..close();
    canvas.drawPath(windowPath, paint);

    // B-pillar
    canvas.drawLine(
      Offset(w * 0.54, centerY + carHeight * 0.15),
      Offset(w * 0.54, centerY + carHeight * 0.7),
      paint,
    );
    
    // Door handles
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, centerY + carHeight * 0.35, w * 0.06, carHeight * 0.08),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.62, centerY + carHeight * 0.35, w * 0.06, carHeight * 0.08),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
