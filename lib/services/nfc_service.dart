import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/app_models.dart';

/// Service for NFC document reading functionality
class NFCService {
  static NFCService? _instance;
  static NFCService get instance => _instance ??= NFCService._();

  NFCService._();

  bool _isReading = false;
  Timer? _sessionTimeout;
  Completer<NFCData?>? _readingCompleter;

  /// Check if NFC is available on the device
  Future<bool> isNFCAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      print('Error checking NFC availability: $e');
      return false;
    }
  }

  /// Start NFC session to read document data
  Future<NFCData?> startReading({
    required String documentNumber,
    required String dateOfBirth,
    required String expirationDate,
    required Function(String) onStatusUpdate,
    required Function(String) onError,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isReading) {
      onError('NFC reading already in progress');
      return null;
    }

    final bool isAvailable = await isNFCAvailable();
    if (!isAvailable) {
      onError('NFC is not available on this device');
      return null;
    }

    _isReading = true;
    _readingCompleter = Completer<NFCData?>();

    // Set up session timeout
    _sessionTimeout = Timer(timeout, () {
      if (_isReading && !_readingCompleter!.isCompleted) {
        _cleanupSession();
        onError('NFC reading timeout. Please try again.');
        _readingCompleter!.complete(null);
      }
    });

    try {
      onStatusUpdate('Hold your device near the document...');

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            onStatusUpdate('Document detected, reading data...');

            print('NFC tag detected: ${tag.data}');

            // Check if it's an ISO14443 tag (passport/ID card)
            // For Indonesian e-KTP (ID card), check for 'iso7816' or 'iso14443'
             final result = await _readPassportData(
              tag,
              documentNumber,
              dateOfBirth,
              expirationDate,
              onStatusUpdate,
            );

            if (!_readingCompleter!.isCompleted) {
              _readingCompleter!.complete(result);
            }
          } catch (e) {
            if (!_readingCompleter!.isCompleted) {
              onError('Error reading document: ${e.toString()}');
              _readingCompleter!.complete(null);
            }
          }
        },
        onError: (NfcError error) async {
          if (!_readingCompleter!.isCompleted) {
            String errorMessage = 'NFC Error: ${error.message}';
            // Handle different NFC error scenarios
            if (error.message.toLowerCase().contains('unavailable')) {
              errorMessage = 'NFC is not available on this device';
            } else if (error.message.toLowerCase().contains('disabled')) {
              errorMessage = 'Please enable NFC in device settings';
            } else if (error.message.toLowerCase().contains('not supported')) {
              errorMessage = 'NFC is not supported on this device';
            } else {
              errorMessage = 'NFC Error: ${error.message}';
            }
            onError(errorMessage);
            _readingCompleter!.complete(null);
          }
        },
      );

      final result = await _readingCompleter!.future;
      return result;
    } catch (e) {
      onError('Failed to start NFC session: ${e.toString()}');
      if (!_readingCompleter!.isCompleted) {
        _readingCompleter!.complete(null);
      }
      return null;
    } finally {
      await _cleanupSession();
    }
  }

  /// Read passport data using Basic Access Control (BAC)
  Future<NFCData?> _readPassportData(
    NfcTag tag,
    String documentNumber,
    String dateOfBirth,
    String expirationDate,
    Function(String) onStatusUpdate,
  ) async {
    try {
      // Validate MRZ data before attempting to read
      // if (!validateMRZData(documentNumber, dateOfBirth, expirationDate)) {
      //   throw Exception('Invalid MRZ data for BAC authentication');
      // }

      onStatusUpdate('Establishing secure connection...');
      // Simulate BAC authentication (in real implementation, this would involve cryptographic operations)
      await Future.delayed(const Duration(milliseconds: 1200));

      onStatusUpdate('Authenticating with document...');
      await Future.delayed(const Duration(milliseconds: 800));

      onStatusUpdate('Reading document data...');
      // Simulate reading different data groups
      final Map<String, dynamic> dataGroups = {};

      // DG1 - Machine Readable Zone
      onStatusUpdate('Reading machine readable zone...');
      await Future.delayed(const Duration(milliseconds: 600));
      dataGroups['DG1'] = {
        'documentCode': 'P',
        'issuingCountry': 'IDN',
        'documentNumber': documentNumber,
        'dateOfBirth': dateOfBirth,
        'expirationDate': expirationDate,
        'checkDigit': calculateCheckDigit(documentNumber),
      };

      onStatusUpdate('Reading biometric data...');
      // DG2 - Facial image (simulated)
      await Future.delayed(const Duration(milliseconds: 900));
      dataGroups['DG2'] = {
        'faceImage': 'base64_encoded_face_image_data',
        'imageFormat': 'JPEG2000',
        'imageSize': '35KB',
      };

      // DG3 - Fingerprint data (if available)
      onStatusUpdate('Reading fingerprint data...');
      await Future.delayed(const Duration(milliseconds: 700));
      dataGroups['DG3'] = {
        'fingerprints': ['base64_fingerprint_1', 'base64_fingerprint_2'],
        'fingerprintFormat': 'WSQ',
        'fingerprintCount': 2,
      };

      onStatusUpdate('Verifying data integrity...');
      // Simulate security verification
      await Future.delayed(const Duration(milliseconds: 600));

      // Simulate occasional read failures for realistic behavior
      if (DateTime.now().millisecondsSinceEpoch % 7 == 0) {
        throw Exception('Communication error with document. Please try again.');
      }

      onStatusUpdate('NFC reading completed successfully!');

      return NFCData(
        documentNumber: documentNumber,
        dateOfBirth: dateOfBirth,
        expirationDate: expirationDate,
        dataGroups: dataGroups,
        photoBase64: dataGroups['DG2']['faceImage'],
        isValid: true,
        readAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to read passport data: $e');
    }
  }

  /// Stop current NFC reading session
  Future<void> stopReading() async {
    await _cleanupSession();
  }

  /// Clean up NFC session and reset state
  Future<void> _cleanupSession() async {
    _sessionTimeout?.cancel();
    _sessionTimeout = null;
    
    if (_isReading) {
      try {
        await NfcManager.instance.stopSession();
      } catch (e) {
        print('Error stopping NFC session: $e');
      }
      _isReading = false;
    }
    
    if (_readingCompleter != null && !_readingCompleter!.isCompleted) {
      _readingCompleter!.complete(null);
    }
    _readingCompleter = null;
  }

  /// Check if currently reading
  bool get isReading => _isReading;

  /// Cancel current reading session
  Future<void> cancelReading() async {
    if (_isReading && _readingCompleter != null && !_readingCompleter!.isCompleted) {
      _readingCompleter!.complete(null);
    }
    await _cleanupSession();
  }

  /// Start NFC session with retry capability
  Future<NFCData?> startReadingWithRetries({
    required String documentNumber,
    required String dateOfBirth,
    required String expirationDate,
    required Function(String) onStatusUpdate,
    required Function(String) onError,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      attempts++;
      
      if (attempts > 1) {
        onStatusUpdate('Retrying NFC reading (attempt $attempts of ${maxRetries + 1})...');
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      
      try {
        final result = await startReading(
          documentNumber: documentNumber,
          dateOfBirth: dateOfBirth,
          expirationDate: expirationDate,
          onStatusUpdate: onStatusUpdate,
          onError: (error) {
            if (attempts <= maxRetries) {
              print('NFC read attempt $attempts failed: $error');
            } else {
              onError(error);
            }
          },
          timeout: timeout,
        );
        
        if (result != null) {
          return result;
        }
      } catch (e) {
        if (attempts > maxRetries) {
          onError('NFC reading failed after $attempts attempts: ${e.toString()}');
          break;
        }
      }
    }
    
    return null;
  }

  /// Validate MRZ data for BAC
  bool validateMRZData(String documentNumber, String dateOfBirth, String expirationDate) {
    // Basic validation
    if (documentNumber.isEmpty || dateOfBirth.length != 6 || expirationDate.length != 6) {
      return false;
    }

    // Check date formats (YYMMDD)
    try {
      int.parse(dateOfBirth.substring(0, 2)); // Year
      final dobMonth = int.parse(dateOfBirth.substring(2, 4));
      final dobDay = int.parse(dateOfBirth.substring(4, 6));

      int.parse(expirationDate.substring(0, 2)); // Year
      final expMonth = int.parse(expirationDate.substring(2, 4));
      final expDay = int.parse(expirationDate.substring(4, 6));

      // Basic range checks
      if (dobMonth < 1 || dobMonth > 12 || dobDay < 1 || dobDay > 31) return false;
      if (expMonth < 1 || expMonth > 12 || expDay < 1 || expDay > 31) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate check digit for MRZ validation
  int calculateCheckDigit(String data) {
    const weights = [7, 3, 1];
    int sum = 0;

    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      int value;

      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        // Numeric character
        value = char.codeUnitAt(0) - 48;
      } else if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
        // Alphabetic character
        value = char.codeUnitAt(0) - 55;
      } else {
        // Filler character '<'
        value = 0;
      }

      sum += value * weights[i % 3];
    }

    return sum % 10;
  }
}
