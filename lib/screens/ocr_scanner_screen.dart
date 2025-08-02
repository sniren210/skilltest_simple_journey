import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class OCRScannerScreen extends StatefulWidget {
  const OCRScannerScreen({super.key});

  @override
  State<OCRScannerScreen> createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Position document MRZ in the frame';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      setState(() {
        _statusMessage = 'Processing image for MRZ data...';
      });

      final appProvider = context.read<AppProvider>();
      final success = await appProvider.scanMRZ(image.path);
      
      if (success && mounted) {
        // Show success dialog
        _showSuccessDialog(appProvider.scannedMRZ!);
      } else {
        setState(() {
          _statusMessage = 'No MRZ data found. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error processing image: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(dynamic mrzData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(child: Text('MRZ Scanned Successfully')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document Number: ${mrzData.passportNumber}'),
            Text('Name: ${mrzData.surname}, ${mrzData.givenNames}'),
            Text('Nationality: ${mrzData.nationality}'),
            Text('Date of Birth: ${mrzData.dateOfBirth}'),
            Text('Expiration: ${mrzData.expirationDate}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _statusMessage = 'Position document MRZ in the frame';
              });
            },
            child: const Text('Scan Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Passport MRZ'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingM),
            color: AppColors.primary.withOpacity(0.1),
            child: Text(
              _statusMessage,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          
          // Camera preview
          Expanded(
            child: _isInitialized
                ? Stack(
                    children: [
                      // Camera preview
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CameraPreview(_cameraController!),
                      ),
                      
                      // Overlay
                      CustomPaint(
                        painter: _ScannerOverlayPainter(),
                        size: Size.infinite,
                      ),
                      
                      // Instructions
                      Positioned(
                        top: AppConstants.paddingL,
                        left: AppConstants.paddingL,
                        right: AppConstants.paddingL,
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.paddingM),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          child: const Text(
                            'Position the passport MRZ (bottom text lines) within the frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      // Processing overlay
                      if (_isProcessing)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: AppConstants.paddingM),
                                Text(
                                  'Processing...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppConstants.paddingL),
                        Text(
                          _statusMessage,
                          style: AppTextStyles.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                // Capture button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isInitialized && !_isProcessing
                        ? _captureAndProcess
                        : null,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isProcessing ? 'Processing...' : 'Capture & Scan'),
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingM),
                
                // Help text
                Text(
                  'Ensure good lighting and hold the camera steady',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.scannerOverlay
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = AppColors.scannerFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cornerPaint = Paint()
      ..color = AppColors.scannerCorner
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Calculate frame dimensions (for MRZ scanning - wider rectangle)
    const frameAspectRatio = 4.0; // Wider for MRZ
    final frameHeight = size.height * 0.2;
    final frameWidth = frameHeight * frameAspectRatio;
    
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);

    // Draw overlay (everything except the frame)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw frame border
    canvas.drawRect(frameRect, framePaint);

    // Draw corner indicators
    const cornerLength = 20.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(frameLeft, frameTop + cornerLength),
      Offset(frameLeft, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop),
      Offset(frameLeft + cornerLength, frameTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(frameLeft + frameWidth - cornerLength, frameTop),
      Offset(frameLeft + frameWidth, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop),
      Offset(frameLeft + frameWidth, frameTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameHeight - cornerLength),
      Offset(frameLeft, frameTop + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameHeight),
      Offset(frameLeft + cornerLength, frameTop + frameHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(frameLeft + frameWidth - cornerLength, frameTop + frameHeight),
      Offset(frameLeft + frameWidth, frameTop + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop + frameHeight - cornerLength),
      Offset(frameLeft + frameWidth, frameTop + frameHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
