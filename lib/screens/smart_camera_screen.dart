import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import '../theme.dart';

class SmartCameraScreen extends StatefulWidget {
  final String categoryId;
  final String categoryLabel;
  final List<Map<String, dynamic>> existingPhotos;

  const SmartCameraScreen({
    super.key,
    required this.categoryId,
    required this.categoryLabel,
    this.existingPhotos = const [],
  });

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen> {
  CameraController? _controller;
  ObjectDetector? _objectDetector;
  bool _isBusy = false;
  String _message = 'Align the vehicle';
  bool _isObjectDetected = false;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _initialize();
  }

  void _setOrientation() {
    if (widget.categoryId == 'ext_left' || widget.categoryId == 'ext_right') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeDetector();

    await _controller?.initialize();
    if (!mounted) return;

    _controller?.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _initializeDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _getRotation(_cameras[0].sensorOrientation),
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    try {
      final objects = await _objectDetector?.processImage(inputImage);
      if (objects != null && objects.isNotEmpty) {
        bool vehicleFound = false;
        for (final obj in objects) {
          // ML Kit categorizes objects. 'Transportation' or 'Vehicle' might be there.
          if (obj.labels.any((l) => l.text.toLowerCase().contains('vehicle') || l.text.toLowerCase().contains('car'))) {
            vehicleFound = true;
            break;
          }
        }
        setState(() {
          _isObjectDetected = vehicleFound;
          _message = vehicleFound ? 'Vehicle Detected! Hold steady...' : 'Vehicle not detected';
        });
      } else {
        setState(() {
          _isObjectDetected = false;
          _message = 'Vehicle not detected';
        });
      }
    } catch (e) {
      debugPrint('Error detecting objects: $e');
    }

    _isBusy = false;
  }

  InputImageRotation _getRotation(int rotation) {
    switch (rotation) {
      case 0: return InputImageRotation.rotation0deg;
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      context.pop(image.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _controller?.dispose();
    _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          _buildOverlay(),
          _buildTopBar(),
          _buildThumbnailStrip(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  static const Map<String, String> _guidelines = {
    'ext_front': 'Align the front of the vehicle within the frame. Ensure headlights and grill are visible.',
    'ext_rear': 'Align the rear of the vehicle within the frame. Ensure number plate and tail lights are visible.',
    'ext_left': 'Capture the full left side of the vehicle. Keep the car centered.',
    'ext_right': 'Capture the full right side of the vehicle. Keep the car centered.',
    'dents': 'Get a close-up photo of the damaged area. Use good lighting for clarity.',
    'interior': 'Capture the dashboard and front seats. Ensure the cabin is tidy.',
    'dikki': 'Open the trunk and capture the interior space clearly.',
    'tools': 'Show all tools clearly arranged in their case or the trunk.',
    'valuables': 'Capture any personal items or valuable equipment left in the vehicle.',
  };

  Widget _buildOverlay() {
    final String guideline = _guidelines[widget.categoryId] ?? 'Align the object within the frame';
    final bool isLandscapeCategory = widget.categoryId == 'ext_left' || widget.categoryId == 'ext_right';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: Stack(
        children: [
          // Top Guideline Area
          Positioned(
            top: isLandscapeCategory ? 40 : 100,
            left: 24,
            right: 24,
            child: Column(
              children: [
                const Icon(LucideIcons.info, color: Colors.white, size: 24),
                const SizedBox(height: 12),
                Text(
                  guideline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
              ],
            ),
          ),
          
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Silhouette Layer
                SizedBox(
                  width: MediaQuery.of(context).size.width * (isLandscapeCategory ? 0.8 : 0.9),
                  height: MediaQuery.of(context).size.width * (isLandscapeCategory ? 0.4 : 0.7),
                  child: CustomPaint(
                    painter: SilhouettePainter(
                      categoryId: widget.categoryId,
                      color: _isObjectDetected ? AppTheme.successGreen : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                
                // Focus Corners
                _buildCorners(isLandscapeCategory),

                if (_isObjectDetected)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Perfect! Hold steady',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorners(bool isLandscape) {
    const double cornerSize = 40;
    const double cornerWidth = 3;
    final Color cornerColor = _isObjectDetected ? AppTheme.successGreen : Colors.white.withOpacity(0.8);

    return SizedBox(
      width: (MediaQuery.of(context).size.width * (isLandscape ? 0.8 : 0.9)) + 4,
      height: (MediaQuery.of(context).size.width * (isLandscape ? 0.4 : 0.7)) + 4,
      child: Stack(
        children: [
          _buildCorner(top: 0, left: 0, width: cornerSize, height: cornerWidth, color: cornerColor),
          _buildCorner(top: 0, left: 0, width: cornerWidth, height: cornerSize, color: cornerColor),
          _buildCorner(top: 0, right: 0, width: cornerSize, height: cornerWidth, color: cornerColor),
          _buildCorner(top: 0, right: 0, width: cornerWidth, height: cornerSize, color: cornerColor),
          _buildCorner(bottom: 0, left: 0, width: cornerSize, height: cornerWidth, color: cornerColor),
          _buildCorner(bottom: 0, left: 0, width: cornerWidth, height: cornerSize, color: cornerColor),
          _buildCorner(bottom: 0, right: 0, width: cornerSize, height: cornerWidth, color: cornerColor),
          _buildCorner(bottom: 0, right: 0, width: cornerWidth, height: cornerSize, color: cornerColor),
        ],
      ),
    );
  }

  Widget _buildCorner({double? top, double? left, double? right, double? bottom, required double width, required double height, required Color color}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  Widget _buildTopBar() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            Text(
              widget.categoryLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 48), // Spacer to center the title
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    if (widget.existingPhotos.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 140, // Just above the bottom bar
      left: 0,
      right: 0,
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: widget.existingPhotos.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final photo = widget.existingPhotos[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: kIsWeb 
                        ? Image.network(
                            photo['path'],
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(photo['path']),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                if (photo['label'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      photo['label'],
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 64),
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(LucideIcons.zap, color: Colors.white),
                onPressed: () {
                  // Flash control logic
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SilhouettePainter extends CustomPainter {
  final String categoryId;
  final Color color;

  SilhouettePainter({required this.categoryId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Add a subtle glow effect
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final w = size.width;
    final h = size.height;

    switch (categoryId) {
      case 'ext_front':
        _drawFrontCar(canvas, size, shadowPaint);
        _drawFrontCar(canvas, size, paint);
        break;
      case 'ext_rear':
        _drawRearCar(canvas, size, shadowPaint);
        _drawRearCar(canvas, size, paint);
        break;
      case 'ext_left':
      case 'ext_right':
        _drawSideCar(canvas, size, shadowPaint);
        _drawSideCar(canvas, size, paint);
        break;
      case 'interior':
        _drawDashboard(canvas, size, shadowPaint);
        _drawDashboard(canvas, size, paint);
        break;
      case 'dikki':
        _drawTrunk(canvas, size, shadowPaint);
        _drawTrunk(canvas, size, paint);
        break;
      default:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(30)), shadowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(30)), paint);
    }
  }

  void _drawFrontCar(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    
    // Roof & Windshield (Curvy)
    path.moveTo(w * 0.3, h * 0.35);
    path.quadraticBezierTo(w * 0.5, h * 0.3, w * 0.7, h * 0.35);
    path.quadraticBezierTo(w * 0.85, h * 0.6, w * 0.85, h * 0.65);
    path.lineTo(w * 0.15, h * 0.65);
    path.quadraticBezierTo(w * 0.15, h * 0.6, w * 0.3, h * 0.35);

    // Main Body/Grille Area
    path.moveTo(w * 0.1, h * 0.65);
    path.quadraticBezierTo(w * 0.1, h * 0.85, w * 0.2, h * 0.85);
    path.lineTo(w * 0.8, h * 0.85);
    path.quadraticBezierTo(w * 0.9, h * 0.85, w * 0.9, h * 0.65);
    path.close();

    canvas.drawPath(path, paint);

    // Stylish Headlights
    final leftLight = Path()
      ..moveTo(w * 0.15, h * 0.7)
      ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.3, h * 0.75)
      ..quadraticBezierTo(w * 0.2, h * 0.78, w * 0.15, h * 0.7);
    canvas.drawPath(leftLight, paint);

    final rightLight = Path()
      ..moveTo(w * 0.85, h * 0.7)
      ..quadraticBezierTo(w * 0.75, h * 0.68, w * 0.7, h * 0.75)
      ..quadraticBezierTo(w * 0.8, h * 0.78, w * 0.85, h * 0.7);
    canvas.drawPath(rightLight, paint);
    
    // Modern Grille
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, h * 0.76), width: w * 0.35, height: h * 0.08), const Radius.circular(8)), paint);
  }

  void _drawRearCar(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Rear Roof & Window
    path.moveTo(w * 0.25, h * 0.35);
    path.quadraticBezierTo(w * 0.5, h * 0.32, w * 0.75, h * 0.35);
    path.quadraticBezierTo(w * 0.85, h * 0.6, w * 0.85, h * 0.65);
    path.lineTo(w * 0.15, h * 0.65);
    path.quadraticBezierTo(w * 0.15, h * 0.6, w * 0.25, h * 0.35);

    // Boot Area
    path.moveTo(w * 0.1, h * 0.65);
    path.quadraticBezierTo(w * 0.1, h * 0.85, w * 0.2, h * 0.85);
    path.lineTo(w * 0.8, h * 0.85);
    path.quadraticBezierTo(w * 0.9, h * 0.85, w * 0.9, h * 0.65);
    path.close();

    canvas.drawPath(path, paint);

    // Sleek Tail lights
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.68, w * 0.18, h * 0.06), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.7, h * 0.68, w * 0.18, h * 0.06), const Radius.circular(4)), paint);
    
    // Number Plate Area
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, h * 0.75), width: w * 0.22, height: h * 0.07), const Radius.circular(4)), paint);
  }

  void _drawSideCar(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Elongated Side Profile for Landscape
    path.moveTo(w * 0.05, h * 0.65);
    // Lower front
    path.quadraticBezierTo(w * 0.05, h * 0.5, w * 0.15, h * 0.45);
    // Hood
    path.lineTo(w * 0.3, h * 0.45);
    // Windshield
    path.lineTo(w * 0.45, h * 0.25);
    // Roof
    path.lineTo(w * 0.75, h * 0.25);
    // Rear Windshield
    path.lineTo(w * 0.85, h * 0.45);
    // Trunk
    path.quadraticBezierTo(w * 0.95, h * 0.45, w * 0.95, h * 0.65);
    // Rear Bumper
    path.lineTo(w * 0.95, h * 0.8);
    // Underbody with Wheel Arches
    path.lineTo(w * 0.85, h * 0.8);
    path.arcToPoint(Offset(w * 0.65, h * 0.8), radius: const Radius.circular(40), clockwise: false);
    path.lineTo(w * 0.35, h * 0.8);
    path.arcToPoint(Offset(w * 0.15, h * 0.8), radius: const Radius.circular(40), clockwise: false);
    path.lineTo(w * 0.05, h * 0.8);
    path.close();

    canvas.drawPath(path, paint);

    // Modern Windows
    final windowPath = Path()
      ..moveTo(w * 0.35, h * 0.48)
      ..lineTo(w * 0.48, h * 0.3)
      ..lineTo(w * 0.72, h * 0.3)
      ..lineTo(w * 0.8, h * 0.48)
      ..close();
    canvas.drawPath(windowPath, paint);

    // Details for "Smart" look
    canvas.drawLine(Offset(w * 0.52, h * 0.48), Offset(w * 0.52, h * 0.8), paint); // B-pillar
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.55, w * 0.05, h * 0.015), const Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.62, h * 0.55, w * 0.05, h * 0.015), const Radius.circular(2)), paint);
  }

  void _drawDashboard(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Panoramic Windshield View
    path.moveTo(0, h * 0.3);
    path.cubicTo(w * 0.2, h * 0.2, w * 0.8, h * 0.2, w, h * 0.3);
    
    // Fluid Dashboard Curve
    path.moveTo(0, h * 0.6);
    path.quadraticBezierTo(w * 0.2, h * 0.5, w * 0.5, h * 0.55);
    path.quadraticBezierTo(w * 0.8, h * 0.5, w, h * 0.6);
    
    canvas.drawPath(path, paint);

    // Smart Steering Wheel
    final wheelPath = Path();
    wheelPath.addOval(Rect.fromCenter(center: Offset(w * 0.3, h * 0.75), width: w * 0.35, height: w * 0.35));
    canvas.drawPath(wheelPath, paint);
    canvas.drawCircle(Offset(w * 0.3, h * 0.75), w * 0.05, paint); // Horn plate
    
    // Tech Console / Screen
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.52, h * 0.62, w * 0.25, h * 0.22), const Radius.circular(12)), paint);
  }

  void _drawTrunk(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Stylized Trunk Opening
    path.moveTo(w * 0.2, h * 0.25);
    path.quadraticBezierTo(w * 0.5, h * 0.15, w * 0.8, h * 0.25);
    path.quadraticBezierTo(w * 0.9, h * 0.5, w * 0.9, h * 0.75);
    path.quadraticBezierTo(w * 0.5, h * 0.85, w * 0.1, h * 0.75);
    path.quadraticBezierTo(w * 0.1, h * 0.5, w * 0.2, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);

    // Inner loading lip
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.72, w * 0.5, h * 0.05), const Radius.circular(10)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
