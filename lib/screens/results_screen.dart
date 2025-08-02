import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          IconButton(
            onPressed: () => _shareResults(context),
            icon: const Icon(Icons.share),
            tooltip: 'Share Results',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(appProvider),
                
                const SizedBox(height: AppConstants.paddingL),
                
                // MRZ data card
                if (appProvider.scannedMRZ != null)
                  _buildMRZCard(appProvider),
                
                const SizedBox(height: AppConstants.paddingL),
                
                // Biometric result card
                if (appProvider.biometricResult != null)
                  _buildBiometricCard(appProvider),
                
                const SizedBox(height: AppConstants.paddingL),
                
                // NFC data card
                if (appProvider.nfcData != null)
                  _buildNFCCard(appProvider),
                
                const SizedBox(height: AppConstants.paddingXL),
                
                // Action buttons
                _buildActionButtons(context, appProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(AppProvider appProvider) {
    final completedSteps = [
      if (appProvider.scannedMRZ != null) 'MRZ Scan',
      if (appProvider.biometricResult != null) 'Biometric',
      if (appProvider.nfcData != null) 'NFC Reading',
    ];

    final totalSteps = 3;
    final progress = completedSteps.length / totalSteps;
    final isComplete = completedSteps.length == totalSteps;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.info,
                  color: isComplete ? AppColors.success : AppColors.warning,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Text(
                  isComplete ? 'Verification Complete' : 'Verification in Progress',
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.success : AppColors.warning,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingS),
            
            Text(
              '${completedSteps.length} of $totalSteps steps completed',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            if (completedSteps.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingM),
              Wrap(
                spacing: 8,
                children: completedSteps.map((step) => Chip(
                  label: Text(step),
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  side: BorderSide(color: AppColors.success),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMRZCard(AppProvider appProvider) {
    final mrz = appProvider.scannedMRZ!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.document_scanner,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Text(
                  'Passport MRZ Data',
                  style: AppTextStyles.headline4,
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            _buildDataRow('Passport Number', mrz.passportNumber),
            _buildDataRow('Document Type', mrz.documentType),
            _buildDataRow('Country Code', mrz.countryCode),
            _buildDataRow('Surname', mrz.surname),
            _buildDataRow('Given Names', mrz.givenNames),
            _buildDataRow('Nationality', mrz.nationality),
            _buildDataRow('Date of Birth', mrz.dateOfBirth),
            _buildDataRow('Sex', mrz.sex),
            _buildDataRow('Expiration Date', mrz.expirationDate),
            _buildDataRow('Personal Number', mrz.personalNumber.isNotEmpty ? mrz.personalNumber : 'N/A'),
            
            const SizedBox(height: AppConstants.paddingM),
            
            Row(
              children: [
                Icon(
                  mrz.isValid ? Icons.verified : Icons.error,
                  color: mrz.isValid ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  mrz.isValid ? 'Valid MRZ' : 'Invalid MRZ',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: mrz.isValid ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricCard(AppProvider appProvider) {
    final biometric = appProvider.biometricResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fingerprint,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Text(
                  'Biometric Authentication',
                  style: AppTextStyles.headline4,
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            _buildDataRow('Status', biometric.isSuccess ? 'Authenticated' : 'Failed'),
            _buildDataRow('Authentication Type', biometric.biometricType),
            _buildDataRow('Timestamp', _formatDateTime(biometric.timestamp)),
            
            if (biometric.errorMessage != null && biometric.errorMessage!.isNotEmpty)
              _buildDataRow('Error', biometric.errorMessage!),
            
            const SizedBox(height: AppConstants.paddingM),
            
            Row(
              children: [
                Icon(
                  biometric.isSuccess ? Icons.verified : Icons.error,
                  color: biometric.isSuccess ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  biometric.isSuccess ? 'Authentication Successful' : 'Authentication Failed',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: biometric.isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFCCard(AppProvider appProvider) {
    final nfc = appProvider.nfcData!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.nfc,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Text(
                  'NFC Document Data',
                  style: AppTextStyles.headline4,
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            _buildDataRow('Document Number', nfc.documentNumber),
            _buildDataRow('Date of Birth', nfc.dateOfBirth),
            _buildDataRow('Expiration Date', nfc.expirationDate),
            _buildDataRow('Data Groups Found', nfc.dataGroups.length.toString()),
            _buildDataRow('Read Timestamp', _formatDateTime(nfc.readTimestamp)),
            
            if (nfc.dataGroups.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingM),
              Text(
                'Data Groups:',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: AppConstants.paddingS),
              Wrap(
                spacing: 8,
                children: nfc.dataGroups.keys.map((group) => Chip(
                  label: Text('DG$group'),
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  side: BorderSide(color: AppColors.info),
                )).toList(),
              ),
            ],
            
            const SizedBox(height: AppConstants.paddingM),
            
            Row(
              children: [
                Icon(
                  nfc.isValid ? Icons.verified : Icons.error,
                  color: nfc.isValid ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  nfc.isValid ? 'Valid NFC Data' : 'Invalid NFC Data',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: nfc.isValid ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppProvider appProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDataComparison(context, appProvider),
            icon: const Icon(Icons.compare),
            label: const Text('Compare Data'),
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingM),
        
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _resetAndRestart(context, appProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Start New Verification'),
          ),
        ),
      ],
    );
  }

  void _showDataComparison(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Comparison'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appProvider.scannedMRZ != null && appProvider.nfcData != null) ...[
                const Text('Document Number:'),
                _buildComparisonRow(
                  'MRZ',
                  appProvider.scannedMRZ!.passportNumber,
                  'NFC',
                  appProvider.nfcData!.documentNumber,
                ),
                const SizedBox(height: 8),
                const Text('Date of Birth:'),
                _buildComparisonRow(
                  'MRZ',
                  appProvider.scannedMRZ!.dateOfBirth,
                  'NFC',
                  appProvider.nfcData!.dateOfBirth,
                ),
                const SizedBox(height: 8),
                const Text('Expiration Date:'),
                _buildComparisonRow(
                  'MRZ',
                  appProvider.scannedMRZ!.expirationDate,
                  'NFC',
                  appProvider.nfcData!.expirationDate,
                ),
              ] else
                const Text('Not enough data for comparison'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String source1, String value1, String source2, String value2) {
    final isMatch = value1 == value2;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMatch ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isMatch ? AppColors.success : AppColors.error,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('$source1: $value1'),
              const Spacer(),
              Icon(
                isMatch ? Icons.check : Icons.close,
                color: isMatch ? AppColors.success : AppColors.error,
                size: 16,
              ),
            ],
          ),
          Row(
            children: [
              Text('$source2: $value2'),
            ],
          ),
        ],
      ),
    );
  }

  void _shareResults(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportData(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAsJSON(context, appProvider);
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAsCSV(context, appProvider);
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportAsJSON(BuildContext context, AppProvider appProvider) {
    // In a real app, this would save the file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported as JSON (simulated)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportAsCSV(BuildContext context, AppProvider appProvider) {
    // In a real app, this would save the file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported as CSV (simulated)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetAndRestart(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Verification'),
        content: const Text('This will clear all current data and start a new verification process. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appProvider.reset();
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go back to home
            },
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
