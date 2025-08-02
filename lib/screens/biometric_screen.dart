import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  
  bool _isBiometricAvailable = false;
  bool _isChecking = true;
  String _statusMessage = 'Checking biometric availability...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final appProvider = context.read<AppProvider>();
    
    try {
      final isAvailable = await appProvider.checkBiometricAvailability();
      
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isChecking = false;
        _statusMessage = isAvailable
            ? 'Place your finger on the sensor to authenticate'
            : 'Biometric authentication is not available on this device';
      });
    } catch (e) {
      setState(() {
        _isBiometricAvailable = false;
        _isChecking = false;
        _statusMessage = 'Error checking biometric availability: $e';
      });
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    if (!_isBiometricAvailable) return;

    setState(() {
      _statusMessage = 'Authenticating...';
    });

    _scanController.forward();

    final appProvider = context.read<AppProvider>();
    final success = await appProvider.authenticateWithFingerprint();

    _scanController.reset();

    if (success && mounted) {
      _showSuccessDialog();
    } else {
      setState(() {
        _statusMessage = appProvider.biometricResult?.errorMessage ?? 
                        'Authentication failed. Please try again.';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(child: Text('Authentication Successful')),
          ],
        ),
        content: const Text(
          'Your fingerprint has been verified successfully. You can now proceed to the next step.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _statusMessage = 'Place your finger on the sensor to authenticate';
              });
            },
            child: const Text('Authenticate Again'),
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
        title: const Text('Fingerprint Authentication'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                // Status message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: _isBiometricAvailable && !_isChecking
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: _isBiometricAvailable && !_isChecking
                          ? AppColors.info
                          : AppColors.warning,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isChecking
                            ? Icons.hourglass_empty
                            : _isBiometricAvailable
                                ? Icons.info
                                : Icons.warning,
                        color: _isBiometricAvailable && !_isChecking
                            ? AppColors.info
                            : AppColors.warning,
                      ),
                      const SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingXL),
                
                // Main content
                Expanded(
                  child: _isChecking
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: AppConstants.paddingL),
                              Text(
                                'Checking biometric capabilities...',
                                style: AppTextStyles.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : _isBiometricAvailable
                          ? _buildFingerprintScanner(appProvider)
                          : _buildUnavailableView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFingerprintScanner(AppProvider appProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fingerprint icon with animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: appProvider.isAuthenticating ? 1.0 : _pulseAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  
                  // Inner circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  
                  // Fingerprint icon
                  Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: appProvider.isAuthenticating
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                  
                  // Scanning animation
                  if (appProvider.isAuthenticating)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(200, 200),
                          painter: _ScanningLinePainter(_scanAnimation.value),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: AppConstants.paddingXL),
        
        // Status text
        Text(
          appProvider.isAuthenticating
              ? 'Scanning...'
              : 'Touch the fingerprint sensor',
          style: AppTextStyles.headline3,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.paddingM),
        
        // Subtitle
        Text(
          appProvider.isAuthenticating
              ? 'Keep your finger on the sensor'
              : 'Place your finger on the sensor and hold still',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
                const SizedBox(height: AppConstants.paddingXL),        // Authenticate button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: appProvider.isAuthenticating
                ? null
                : _authenticateWithFingerprint,
            icon: appProvider.isAuthenticating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.fingerprint),
            label: Text(
              appProvider.isAuthenticating
                  ? 'Authenticating...'
                  : 'Start Authentication',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 80,
          color: AppColors.error,
        ),
        const SizedBox(height: AppConstants.paddingL),
        Text(
          'Biometric Unavailable',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Text(
          'This device does not support biometric authentication or no biometric data is enrolled.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingXL),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ),
      ],
    );
  }
}

class _ScanningLinePainter extends CustomPainter {
  final double progress;

  _ScanningLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw scanning line that moves around the circle
    final startAngle = progress * 2 * 3.14159;
    final sweepAngle = 0.5; // Quarter circle

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
