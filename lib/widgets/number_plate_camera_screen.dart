import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../theme.dart';

class NumberPlateCameraScreen extends StatefulWidget {
  const NumberPlateCameraScreen({super.key});

  @override
  State<NumberPlateCameraScreen> createState() => _NumberPlateCameraScreenState();
}

class _NumberPlateCameraScreenState extends State<NumberPlateCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  String _detectedText = '';
  bool _plateDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

  Future<void> _captureAndProcess() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      
      // Process image with ML Kit Text Recognition
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extract and validate plate number
      String? plateNumber = _extractPlateNumber(recognizedText.text);
      
      if (plateNumber != null && mounted) {
        // Return the detected plate number
        Navigator.pop(context, plateNumber);
      } else {
        if (mounted) {
          setState(() {
            _detectedText = 'No valid plate number detected. Please try again.';
            _plateDetected = false;
          });
        }
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
          _isProcessing = false;
        });
      }
    }
  }

  String? _extractPlateNumber(String text) {
    // Remove whitespace and convert to uppercase
    String cleanText = text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    
    // Indian plate format: 2 letters + 2 digits + 1-2 letters + 4 digits
    // Examples: MH12AB1234, DL01CA9999, KA03MH6789
    RegExp platePattern = RegExp(r'[A-Z]{2}\d{2}[A-Z]{1,2}\d{4}');
    
    Match? match = platePattern.firstMatch(cleanText);
    if (match != null) {
      return match.group(0);
    }
    
    // Try alternate patterns
    // Format with spaces: MH 12 AB 1234
    String textWithSpaces = text.toUpperCase();
    RegExp spacePattern = RegExp(r'[A-Z]{2}\s*\d{2}\s*[A-Z]{1,2}\s*\d{4}');
    Match? spaceMatch = spacePattern.firstMatch(textWithSpaces);
    if (spaceMatch != null) {
      return spaceMatch.group(0)!.replaceAll(RegExp(r'\s+'), '');
    }
    
    return null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
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

                // Number Plate Outline Guide
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.width * 0.25,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _plateDetected ? AppTheme.successGreen : Colors.white,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomPaint(
                        painter: PlateGuidePainter(
                          color: _plateDetected ? AppTheme.successGreen : Colors.white,
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
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scan Number Plate',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Align the plate within the frame',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_detectedText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _detectedText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Capture button
                          GestureDetector(
                            onTap: _isProcessing ? null : _captureAndProcess,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: _isProcessing
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

// Number plate guide painter
class PlateGuidePainter extends CustomPainter {
  final Color color;

  PlateGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw corner markers
    const cornerSize = 20.0;
    
    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerSize), paint);
    
    // Top-right
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    
    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
