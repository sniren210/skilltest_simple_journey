import 'package:flutter/material.dart';
import '../models/passport_mrz.dart';
import '../models/app_models.dart';
import '../services/ocr_service.dart';
import '../services/biometric_service.dart';
import '../services/nfc_service.dart';
import '../services/permission_service.dart';

/// Main application state provider
class AppProvider extends ChangeNotifier {
  // Services
  final OCRService _ocrService = OCRService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  final NFCService _nfcService = NFCService.instance;
  final PermissionService _permissionService = PermissionService.instance;

  // App state
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Permissions
  Map<String, bool> _permissions = {};

  // Scanned data
  PassportMRZ? _scannedMRZ;
  BiometricResult? _biometricResult;
  NFCData? _nfcData;

  // Current operation status
  String _statusMessage = '';
  bool _isScanning = false;
  bool _isAuthenticating = false;
  bool _isReadingNFC = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get permissions => _permissions;
  PassportMRZ? get scannedMRZ => _scannedMRZ;
  BiometricResult? get biometricResult => _biometricResult;
  NFCData? get nfcData => _nfcData;
  String get statusMessage => _statusMessage;
  bool get isScanning => _isScanning;
  bool get isAuthenticating => _isAuthenticating;
  bool get isReadingNFC => _isReadingNFC;

  bool get hasAllPermissions => _permissions['camera'] == true && _permissions['storage'] == true;

  bool get hasCompleteData => _scannedMRZ != null && _biometricResult?.isAuthenticated == true && _nfcData?.isValid == true;

  /// Initialize the application
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _setError(null);

    try {
      // Initialize services
      await _ocrService.initialize();

      // Check permissions
      await checkPermissions();

      _isInitialized = true;
      _setStatus('Application initialized successfully');
    } catch (e) {
      _setError('Failed to initialize application: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Check and update permissions status
  Future<void> checkPermissions() async {
    try {
      _permissions = await _permissionService.checkAllPermissions();
      notifyListeners();
    } catch (e) {
      _setError('Failed to check permissions: ${e.toString()}');
    }
  }

  /// Request all necessary permissions
  Future<bool> requestPermissions() async {
    _setLoading(true);

    try {
      _permissions = await _permissionService.requestAllPermissions();
      notifyListeners();
      return hasAllPermissions;
    } catch (e) {
      _setError('Failed to request permissions: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start OCR scanning
  void startScanning() {
    _isScanning = true;
    _setStatus('Starting camera for MRZ scanning...');
    notifyListeners();
  }

  /// Stop OCR scanning
  void stopScanning() {
    _isScanning = false;
    _setStatus('Scanning stopped');
    notifyListeners();
  }

  /// Process scanned MRZ data
  void setScannedMRZ(PassportMRZ mrz) {
    _scannedMRZ = mrz;
    _setStatus('MRZ data scanned successfully');
    notifyListeners();
  }

  /// Scan MRZ from image file
  Future<bool> scanMRZ(String imagePath) async {
    _isScanning = true;
    _setStatus('Processing image for MRZ data...');
    notifyListeners();

    try {
      final result = await _ocrService.processImageFile(imagePath);
      _isScanning = false;

      if (result != null) {
        setScannedMRZ(result);
        return true;
      } else {
        _setStatus('No MRZ data found in image');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isScanning = false;
      _setError('Failed to process image: $e');
      notifyListeners();
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    _isAuthenticating = true;
    _setStatus('Starting biometric authentication...');
    notifyListeners();

    try {
      _biometricResult = await _biometricService.authenticate(
        reason: 'Please authenticate to verify your identity',
      );

      if (_biometricResult!.isAuthenticated) {
        _setStatus('Biometric authentication successful');
      } else {
        _setStatus('Biometric authentication failed: ${_biometricResult!.errorMessage}');
      }

      return _biometricResult!.isAuthenticated;
    } catch (e) {
      _setError('Biometric authentication error: ${e.toString()}');
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Authenticate with fingerprint specifically
  Future<bool> authenticateWithFingerprint() async {
    _isAuthenticating = true;
    _setStatus('Place your finger on the sensor...');
    notifyListeners();

    try {
      _biometricResult = await _biometricService.authenticate(
        reason: 'Please authenticate with your fingerprint to continue',
        biometricOnly: true,
      );

      if (_biometricResult!.isAuthenticated) {
        _setStatus('Fingerprint authentication successful');
      } else {
        _setStatus('Fingerprint authentication failed: ${_biometricResult!.errorMessage}');
      }

      return _biometricResult!.isAuthenticated;
    } catch (e) {
      _setError('Fingerprint authentication error: ${e.toString()}');
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Read NFC data from document
  Future<bool> readNFCData() async {
    if (_scannedMRZ == null) {
      _setError('Please scan MRZ data first');
      return false;
    }

    _isReadingNFC = true;
    _setError(null);
    notifyListeners();

    try {
      final result = await _nfcService.startReadingWithRetries(
        documentNumber: _scannedMRZ!.passportNumber,
        dateOfBirth: _scannedMRZ!.dateOfBirth.replaceAll('/', ''),
        expirationDate: _scannedMRZ!.expirationDate.replaceAll('/', ''),
        onStatusUpdate: (status) {
          _setStatus(status);
        },
        onError: (error) {
          _setError(error);
        },
        maxRetries: 2,
        timeout: const Duration(seconds: 45),
      );

      if (result != null) {
        _nfcData = result;
        _setStatus('NFC data read successfully');
        return true;
      } else {
        _setStatus('Failed to read NFC data');
        return false;
      }
    } catch (e) {
      _setError('NFC reading error: ${e.toString()}');
      return false;
    } finally {
      _isReadingNFC = false;
      notifyListeners();
    }
  }

  /// Cancel current NFC reading operation
  Future<void> cancelNFCReading() async {
    if (_isReadingNFC) {
      try {
        await _nfcService.cancelReading();
        _setStatus('NFC reading cancelled');
      } catch (e) {
        _setError('Error cancelling NFC reading: ${e.toString()}');
      } finally {
        _isReadingNFC = false;
        notifyListeners();
      }
    }
  }

  /// Reset all data
  void resetData() {
    _scannedMRZ = null;
    _biometricResult = null;
    _nfcData = null;
    _setStatus('Data reset');
    _setError(null);
  }

  /// Reset all data (alias for resetData)
  void reset() => resetData();

  /// Clear error message
  void clearError() {
    _setError(null);
  }

  /// Check if biometrics are available
  Future<bool> checkBiometricAvailability() async {
    try {
      return await _biometricService.isBiometricAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Check if NFC is available
  Future<bool> checkNFCAvailability() async {
    try {
      return await _nfcService.isNFCAvailable();
    } catch (e) {
      return false;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setStatus(String status) {
    _statusMessage = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
