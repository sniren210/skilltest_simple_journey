import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import '../models/app_models.dart';

/// Service for handling biometric authentication operations
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  static BiometricService get instance => _instance;
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  BiometricService._internal();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      return isAvailable && canCheckBiometrics;
    } catch (e) {
      print('BiometricService.isBiometricAvailable error: $e');
      return false;
    }
  }

  /// Get the list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (!await isBiometricAvailable()) {
        return [];
      }
      
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('BiometricService.getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Authenticate using available biometric methods
  Future<BiometricResult> authenticate({
    required String reason,
    bool biometricOnly = false,
    Duration? timeout,
  }) async {
    try {
      // Check availability first
      if (!await isBiometricAvailable()) {
        return BiometricResult.failure(
          'unknown',
          'Biometric authentication is not available on this device',
        );
      }

      // Get available biometrics
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricResult.failure(
          'unknown',
          'No biometric methods are enrolled on this device',
        );
      }

      // Configure authentication options
      final AuthenticationOptions authOptions = AuthenticationOptions(
        biometricOnly: biometricOnly,
        stickyAuth: true,
      );

      // Configure platform-specific messages
      final List<AuthMessages> authMessages = [
        const AndroidAuthMessages(
          signInTitle: 'Biometric Authentication',
          biometricHint: 'Verify your identity',
          biometricNotRecognized: 'Biometric not recognized, try again',
          biometricSuccess: 'Biometric authentication successful',
          cancelButton: 'Cancel',
          deviceCredentialsRequiredTitle: 'Device Credentials Required',
          deviceCredentialsSetupDescription: 'Please set up device credentials',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription: 'Please set up biometric authentication',
        ),
        const IOSAuthMessages(
          lockOut: 'Please enable biometric authentication',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription: 'Please set up biometric authentication',
          cancelButton: 'Cancel',
        ),
      ];

      // Perform authentication with timeout
      late bool didAuthenticate;
      
      if (timeout != null) {
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: reason,
          options: authOptions,
          authMessages: authMessages,
        ).timeout(
          timeout,
          onTimeout: () => false,
        );
      } else {
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: reason,
          options: authOptions,
          authMessages: authMessages,
        );
      }

      if (didAuthenticate) {
        final primaryBiometric = _getPrimaryBiometricType(availableBiometrics);
        return BiometricResult.success(primaryBiometric.toString());
      } else {
        return BiometricResult.failure(
          'unknown',
          'Authentication was cancelled or failed',
        );
      }

    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } on TimeoutException {
      return BiometricResult.failure(
        'timeout',
        'Authentication timed out. Please try again.',
      );
    } catch (e) {
      print('BiometricService.authenticate error: $e');
      return BiometricResult.failure(
        'unknown',
        'An unexpected error occurred during authentication',
      );
    }
  }

  /// Get primary biometric type from available list
  BiometricType _getPrimaryBiometricType(List<BiometricType> available) {
    // Prioritize fingerprint, then face, then others
    if (available.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (available.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (available.contains(BiometricType.iris)) {
      return BiometricType.iris;
    } else {
      return available.first;
    }
  }

  /// Handle platform-specific exceptions
  BiometricResult _handlePlatformException(PlatformException e) {
    print('BiometricService.PlatformException: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'NotAvailable':
        return BiometricResult.failure(
          'not_available',
          'Biometric authentication is not available on this device',
        );
      case 'NotEnrolled':
        return BiometricResult.failure(
          'not_enrolled',
          'No biometric credentials are enrolled on this device',
        );
      case 'PasscodeNotSet':
        return BiometricResult.failure(
          'passcode_not_set',
          'Please set up a passcode or PIN on your device first',
        );
      case 'UserCancel':
      case 'UserFallback':
        return BiometricResult.failure(
          'user_cancel',
          'Authentication was cancelled by user',
        );
      case 'AuthenticationFailed':
        return BiometricResult.failure(
          'auth_failed',
          'Authentication failed. Please try again.',
        );
      case 'LockedOut':
        return BiometricResult.failure(
          'locked_out',
          'Too many failed attempts. Please try again later.',
        );
      case 'PermanentlyLockedOut':
        return BiometricResult.failure(
          'permanently_locked',
          'Biometric authentication is permanently locked. Please use device credentials.',
        );
      default:
        return BiometricResult.failure(
          'unknown',
          'Biometric authentication error: ${e.message ?? 'Unknown error'}',
        );
    }
  }
}