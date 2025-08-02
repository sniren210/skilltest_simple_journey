import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'ocr_scanner_screen.dart';
import 'biometric_screen.dart';
import 'nfc_reader_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the app when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (!appProvider.isInitialized) {
            return const _LoadingView();
          }

          if (!appProvider.hasAllPermissions) {
            return _PermissionView(appProvider: appProvider);
          }

          return _MainContent(appProvider: appProvider);
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppConstants.paddingL),
          Text('Initializing application...', style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  final AppProvider appProvider;

  const _PermissionView({required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security,
            size: 80,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            'Permissions Required',
            style: AppTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'This app requires camera and storage permissions to function properly.',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingXL),

          // Permission status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                children: [
                  _PermissionItem(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    subtitle: 'Required for scanning documents',
                    granted: appProvider.permissions['camera'] ?? false,
                  ),
                  const Divider(),
                  _PermissionItem(
                    icon: Icons.storage,
                    title: 'Storage',
                    subtitle: 'Required for saving scanned images',
                    granted: appProvider.permissions['storage'] ?? false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingXL),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: appProvider.isLoading ? null : () => appProvider.requestPermissions(),
              child: appProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Grant Permissions'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: granted ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? AppColors.success : AppColors.error,
        ),
      ],
    );
  }
}

class _MainContent extends StatelessWidget {
  final AppProvider appProvider;

  const _MainContent({required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          if (appProvider.statusMessage.isNotEmpty)
            Card(
              color: AppColors.info.withOpacity(0.1),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.info),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: Text(
                        appProvider.statusMessage,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (appProvider.statusMessage.isNotEmpty) const SizedBox(height: AppConstants.paddingL),

          // Error card
          if (appProvider.errorMessage != null)
            Card(
              color: AppColors.error.withOpacity(0.1),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.error),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: Text(
                        appProvider.errorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: appProvider.clearError,
                    ),
                  ],
                ),
              ),
            ),

          if (appProvider.errorMessage != null) const SizedBox(height: AppConstants.paddingL),

          // Process steps
          Text(
            'Document Verification Process',
            style: AppTextStyles.headline2,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'Complete all three steps to verify your identity document.',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Step 1: OCR Scanning
          _ProcessStep(
            stepNumber: 1,
            title: 'Scan Document MRZ',
            subtitle: 'Use camera to scan passport machine readable zone',
            icon: Icons.document_scanner,
            isCompleted: appProvider.scannedMRZ != null,
            isActive: appProvider.scannedMRZ == null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OCRScannerScreen()),
            ),
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Step 2: Biometric Authentication
          _ProcessStep(
            stepNumber: 2,
            title: 'Fingerprint Authentication',
            subtitle: 'Verify your identity using biometrics',
            icon: Icons.fingerprint,
            isCompleted: appProvider.biometricResult?.isAuthenticated == true,
            isActive: appProvider.scannedMRZ != null && appProvider.biometricResult?.isAuthenticated != true,
            onTap: appProvider.scannedMRZ != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BiometricScreen()),
                    )
                : null,
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Step 3: NFC Reading
          _ProcessStep(
            stepNumber: 3,
            title: 'NFC Data Reading',
            subtitle: 'Read document data using NFC',
            icon: Icons.nfc,
            isCompleted: appProvider.nfcData?.isValid == true,
            isActive: appProvider.scannedMRZ != null && appProvider.biometricResult?.isAuthenticated == true && appProvider.nfcData?.isValid != true,
            onTap: appProvider.scannedMRZ != null && appProvider.biometricResult?.isAuthenticated == true
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NFCReaderScreen()),
                    )
                : null,
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // View Results button
          if (appProvider.hasCompleteData)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResultsScreen()),
                ),
                icon: const Icon(Icons.visibility),
                label: const Text('View Results'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),

          // Reset button
          if (appProvider.scannedMRZ != null || appProvider.biometricResult != null || appProvider.nfcData != null)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.paddingM),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    appProvider.resetData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Over'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback? onTap;

  const _ProcessStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (isCompleted) return AppColors.success;
      if (isActive) return AppColors.primary;
      return AppColors.textSecondary;
    }

    return Card(
      color: isCompleted
          ? AppColors.success.withOpacity(0.1)
          : isActive
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: getColor(),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: isCompleted ? const Icon(Icons.check, color: Colors.white) : Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step $stepNumber: $title',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: getColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isActive && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: getColor(),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
