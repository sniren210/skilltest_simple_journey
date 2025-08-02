import 'package:permission_handler/permission_handler.dart';

/// Service for managing app permissions
class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();

  PermissionService._();

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  /// Request storage permission (for saving scanned images)
  Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.photos.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    try {
      final status = await Permission.photos.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking storage permission: $e');
      return false;
    }
  }

  /// Request all necessary permissions for the app
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    // Camera permission
    results['camera'] = await requestCameraPermission();

    // Storage permission
    results['storage'] = await requestStoragePermission();

    return results;
  }

  /// Check all app permissions status
  Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    results['camera'] = await hasCameraPermission();
    results['storage'] = await hasStoragePermission();

    return results;
  }

  /// Open app settings for manual permission management
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Get user-friendly permission status message
  String getPermissionStatusMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable in settings.';
      default:
        return 'Unknown permission status';
    }
  }
}
