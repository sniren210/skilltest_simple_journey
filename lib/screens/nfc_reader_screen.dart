import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class NFCReaderScreen extends StatefulWidget {
  const NFCReaderScreen({super.key});

  @override
  State<NFCReaderScreen> createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _waveController;
  late AnimationController _scanController;
  late Animation<double> _waveAnimation;
  late Animation<double> _scanAnimation;
  
  bool _isNFCAvailable = false;
  bool _isChecking = true;
  String _statusMessage = 'Checking NFC availability...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _checkNFCAvailability();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _waveController.stop();
        _scanController.stop();
        break;
      case AppLifecycleState.resumed:
        if (_isNFCAvailable && !_isChecking && mounted) {
          _waveController.repeat();
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    // Only start wave animation when NFC is available and not reading
  }

  @override
  void dispose() {
    // Cancel any ongoing NFC reading
    final appProvider = context.read<AppProvider>();
    if (appProvider.isReadingNFC) {
      appProvider.cancelNFCReading();
    }
    
    WidgetsBinding.instance.removeObserver(this);
    _waveController.stop();
    _scanController.stop();
    _waveController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _checkNFCAvailability() async {
    final appProvider = context.read<AppProvider>();
    
    try {
      final isAvailable = await appProvider.checkNFCAvailability();
      
      setState(() {
        _isNFCAvailable = isAvailable;
        _isChecking = false;
        _statusMessage = isAvailable
            ? 'Hold your device near the document to read NFC data'
            : 'NFC is not available on this device';
      });

      // Start wave animation only when NFC is available
      if (isAvailable && mounted) {
        _waveController.repeat();
      }
    } catch (e) {
      setState(() {
        _isNFCAvailable = false;
        _isChecking = false;
        _statusMessage = 'Error checking NFC availability: $e';
      });
    }
  }

  Future<void> _startNFCReading() async {
    if (!_isNFCAvailable) return;

    final appProvider = context.read<AppProvider>();
    
    setState(() {
      _statusMessage = 'Starting NFC reading...';
    });

    // Stop wave animation and start scan animation
    _waveController.stop();
    _scanController.forward();

    try {
      final success = await appProvider.readNFCData();

      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        setState(() {
          _statusMessage = appProvider.errorMessage ?? 'Failed to read NFC data. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error during NFC reading: ${e.toString()}';
        });
      }
    } finally {
      // Reset scan animation and restart wave animation
      if (mounted) {
        _scanController.reset();
        if (_isNFCAvailable && !appProvider.isReadingNFC) {
          _waveController.repeat();
        }
      }
    }
  }

  Future<void> _cancelNFCReading() async {
    final appProvider = context.read<AppProvider>();
    
    if (appProvider.isReadingNFC) {
      setState(() {
        _statusMessage = 'Cancelling NFC reading...';
      });
      
      await appProvider.cancelNFCReading();
      
      if (mounted) {
        _scanController.reset();
        if (_isNFCAvailable) {
          _waveController.repeat();
        }
        setState(() {
          _statusMessage = 'NFC reading cancelled. Try again when ready.';
        });
      }
    }
  }

  void _showSuccessDialog() {
    final appProvider = context.read<AppProvider>();
    final nfcData = appProvider.nfcData;
    
    // Stop all animations when showing dialog
    _waveController.stop();
    _scanController.reset();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(child: Text('NFC Data Read Successfully')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDataRow('Document Number', nfcData?.documentNumber ?? 'N/A'),
              _buildDataRow('Date of Birth', nfcData?.dateOfBirth ?? 'N/A'),
              _buildDataRow('Expiration Date', nfcData?.expirationDate ?? 'N/A'),
              _buildDataRow('Data Groups', '${nfcData?.dataGroups.length ?? 0} found'),
              _buildDataRow('Validity', nfcData?.isValid == true ? 'Valid' : 'Invalid'),
              _buildDataRow('Read Time', nfcData?.readAt.toString().split(' ')[1].substring(0, 8) ?? 'N/A'),
              
              if (nfcData?.dataGroups.isNotEmpty == true) ...[
                const SizedBox(height: AppConstants.paddingM),
                const Divider(),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  'Available Data Groups:',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                ...nfcData!.dataGroups.keys.map((key) => Padding(
                  padding: const EdgeInsets.only(left: AppConstants.paddingS),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        _getDataGroupDescription(key),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _statusMessage = 'Hold your device near the document to read NFC data';
              });
              // Restart wave animation for another read
              if (_isNFCAvailable && mounted) {
                _waveController.repeat();
              }
            },
            child: const Text('Read Again'),
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

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getDataGroupDescription(String dataGroup) {
    switch (dataGroup) {
      case 'DG1':
        return 'Machine Readable Zone';
      case 'DG2':
        return 'Facial Image';
      case 'DG3':
        return 'Fingerprint Data';
      case 'DG4':
        return 'Iris Data';
      case 'DG7':
        return 'Signature Image';
      case 'DG11':
        return 'Additional Personal Data';
      case 'DG12':
        return 'Additional Document Data';
      default:
        return dataGroup;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Document Reader'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                // Status message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: _isNFCAvailable && !_isChecking
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: _isNFCAvailable && !_isChecking
                          ? AppColors.info
                          : AppColors.warning,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isChecking
                            ? Icons.hourglass_empty
                            : _isNFCAvailable
                                ? Icons.info
                                : Icons.warning,
                        color: _isNFCAvailable && !_isChecking
                            ? AppColors.info
                            : AppColors.warning,
                      ),
                      const SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: Text(
                          appProvider.isReadingNFC
                              ? appProvider.statusMessage
                              : _statusMessage,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingXL),
                
                // Main content
                _isChecking
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppConstants.paddingL),
                            Text(
                              'Checking NFC capabilities...',
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : _isNFCAvailable
                        ? _buildNFCReader(appProvider)
                        : _buildUnavailableView(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNFCReader(AppProvider appProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // NFC icon with animation
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Animated wave circles
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      final delay = i * 0.3;
                      final animationValue = (_waveAnimation.value + delay) % 1.0;
                      
                      return Container(
                        width: 100 + (animationValue * 100),
                        height: 100 + ( 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(1.0 - animationValue),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                
                // Center NFC icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appProvider.isReadingNFC
                        ? AppColors.warning.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.2),
                    border: Border.all(
                      color: appProvider.isReadingNFC
                          ? AppColors.warning
                          : AppColors.primary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.nfc,
                    size: 60,
                    color: appProvider.isReadingNFC
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
                
                // Scanning animation overlay
                if (appProvider.isReadingNFC)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(140, 140),
                        painter: _NFCScanningPainter(_scanAnimation.value),
                      );
                    },
                  ),
              ],
            );
          },
        ),
        
        const SizedBox(height: AppConstants.paddingXL),
        
        // Instructions
        Text(
          appProvider.isReadingNFC
              ? 'Reading NFC data...'
              : 'Hold device near document',
          style: AppTextStyles.headline3,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.paddingM),
        
        Text(
          appProvider.isReadingNFC
              ? 'Keep the device steady and close to the document'
              : 'Position the back of your device near the document\'s NFC chip',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.paddingXL),
        
        // Document information
        if (appProvider.scannedMRZ != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Information',
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text('Document: ${appProvider.scannedMRZ!.passportNumber}'),
                  Text('DOB: ${appProvider.scannedMRZ!.dateOfBirth}'),
                  Text('Exp: ${appProvider.scannedMRZ!.expirationDate}'),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: AppConstants.paddingXL),
        
        // Action buttons
        if (appProvider.isReadingNFC)
          Column(
            children: [
              // Cancel button during reading
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelNFCReading,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Reading'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              // Status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    'Reading in progress...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          // Start reading button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: appProvider.scannedMRZ != null
                  ? _startNFCReading
                  : null,
              icon: const Icon(Icons.nfc),
              label: const Text('Start NFC Reading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingM),
              ),
            ),
          ),
        
        // Additional info for disabled state
        if (!appProvider.isReadingNFC && appProvider.scannedMRZ == null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingM),
            child: Text(
              'Please scan MRZ data first',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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
          Icons.nfc_outlined,
          size: 80,
          color: AppColors.error,
        ),
        const SizedBox(height: AppConstants.paddingL),
        Text(
          'NFC Unavailable',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Text(
          'This device does not support NFC or NFC is disabled. Please enable NFC in your device settings.',
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

class _NFCScanningPainter extends CustomPainter {
  final double progress;

  _NFCScanningPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Draw scanning arc that sweeps around
    final startAngle = progress * 2 * 3.14159;
    final sweepAngle = 1.0; // Half circle

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Draw inner scanning lines
    final innerRadius = radius * 0.7;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + 0.5,
      sweepAngle * 0.8,
      false,
      paint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
