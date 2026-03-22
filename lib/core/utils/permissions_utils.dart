import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionsUtils {
  /// Request file access permissions
  static Future<bool> requestFilePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final status = await Permission.storage.request();

      if (status.isDenied) {
        return false;
      } else if (status.isPermanentlyDenied) {
        // Permission is permanently denied, open app settings
        openAppSettings();
        return false;
      }

      // For Android 13+, also request MANAGE_EXTERNAL_STORAGE
      final manageStatus = await Permission.manageExternalStorage.request();

      if (manageStatus.isDenied) {
        return false;
      } else if (manageStatus.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if file permissions are granted
  static Future<bool> hasFilePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final storageStatus = await Permission.storage.status;
      final manageStatus = await Permission.manageExternalStorage.status;

      return storageStatus.isGranted && manageStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request permissions and handle denial
  static Future<bool> requestFilePermissionsWithFallback() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        return await requestFilePermissions();
      }

      if (status.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
