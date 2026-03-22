import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../constants/supported_formats.dart';
import '../constants/file_category.dart';

class FileUtils {
  static bool isHidden(String fileName) {
    return fileName.startsWith('.') && !fileName.startsWith('./');
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileSizeFormatted(int bytes) {
    if (bytes < 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int digitGroups =
        (bytes == 0) ? 0 : (math.log(bytes) / math.log(1024)).floor();

    return '${(bytes / math.pow(1024, digitGroups)).toStringAsFixed(digitGroups == 0 ? 0 : 1)} ${units[digitGroups]}';
  }

  static String getFileTypeDisplayName(String filePath) {
    final extension = getFileExtension(filePath);
    final category = SupportedFormats.getCategoryFromExtension(extension);

    if (category == null) {
      return 'Unknown File';
    }

    switch (category!) {
      case FileCategory.pdf:
        return 'PDF Document';
      case FileCategory.document:
        return 'Document';
      case FileCategory.image:
        return 'Image';
      case FileCategory.video:
        return 'Video';
      case FileCategory.audio:
        return 'Audio';
      case FileCategory.archive:
        return 'Archive';
      case FileCategory.code:
        return 'Code';
      case FileCategory.text:
        return 'Text';
      case FileCategory.ebook:
        return 'eBook';
      case FileCategory.email:
        return 'Email';
      case FileCategory.apk:
        return 'APK';
      default:
        return 'File';
    }
  }

  static String getMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    if (extension.isEmpty) return 'application/octet-stream';

    // Try to get MIME type from extension
    final mimeType = lookupMimeType(extension);
    return mimeType ?? 'application/octet-stream';
  }

  static bool isImageFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.image;
  }

  static bool isVideoFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.video;
  }

  static bool isAudioFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.audio;
  }

  static bool isPdfFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.pdf;
  }

  static bool isDocumentFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.document || category == FileCategory.pdf;
  }

  static bool isArchiveFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.archive;
  }

  static bool isCodeFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.code;
  }

  static bool isTextFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.text;
  }

  static bool isHtmlFile(String filePath) {
    final extension = getFileExtension(filePath);
    return extension == '.html' || extension == '.htm';
  }

  static bool isEbookFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.ebook;
  }

  static bool isEmailFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.email;
  }

  static bool isApkFile(String filePath) {
    final category =
        SupportedFormats.getCategoryFromExtension(getFileExtension(filePath));
    return category == FileCategory.apk;
  }

  static bool isWordFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.doc', '.docx', '.docm', '.dot', '.dotx', '.dotm', '.odt', '.rtf']
        .contains(extension);
  }

  static bool isExcelFile(String filePath) {
    final extension = getFileExtension(filePath);
    return [
      '.xls',
      '.xlsx',
      '.xlsm',
      '.xlt',
      '.xltx',
      '.xltm',
      '.csv',
      '.tsv',
      '.psv',
      '.ssv'
    ].contains(extension);
  }

  static bool isPowerPointFile(String filePath) {
    final extension = getFileExtension(filePath);
    return [
      '.ppt',
      '.pptx',
      '.pptm',
      '.pps',
      '.ppsx',
      '.ppsm',
      '.pot',
      '.potx',
      '.potm',
      '.odp'
    ].contains(extension);
  }

  static bool isDirectory(String path) {
    return FileSystemEntity.isDirectorySync(path);
  }

  static bool isFile(String path) {
    return FileSystemEntity.isFileSync(path);
  }

  static Future<bool> exists(String path) async {
    return await File(path).exists();
  }

  static String formatTimestamp(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<DateTime?> getLastModified(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.lastModified();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<DateTime?> getCreated(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.stat().then((stat) => stat.changed);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static String getParentDirectory(String filePath) {
    return path.dirname(filePath);
  }

  static String joinPaths(String path1, String path2) {
    return path.join(path1, path2);
  }

  static String normalizePath(String pathString) {
    return path.normalize(pathString);
  }

  static bool isSamePath(String path1, String path2) {
    return normalizePath(path1) == normalizePath(path2);
  }

  static String getRelativePath(String fullPath, String basePath) {
    return path.relative(fullPath, from: basePath);
  }

  static Future<bool> hasWritePermission(String directoryPath) async {
    try {
      final testFile = File(path.join(directoryPath, '.filevault_test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasReadPermission(String path) async {
    try {
      final testFile = File(path);
      if (await testFile.exists()) {
        await testFile.readAsString();
        return true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static String sanitizeFileName(String fileName) {
    // Remove invalid characters for file names
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return fileName.replaceAll(invalidChars, '_');
  }

  static bool isValidFileName(String fileName) {
    if (fileName.isEmpty) return false;

    // Check for reserved names
    final reservedNames = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9'
    ];

    final nameWithoutExtension = path.basenameWithoutExtension(fileName);
    if (reservedNames.contains(nameWithoutExtension.toUpperCase())) {
      return false;
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return !invalidChars.hasMatch(fileName);
  }

  static String getUniqueFileName(String directory, String fileName) {
    final basePath =
        path.join(directory, path.basenameWithoutExtension(fileName));
    final extension = path.extension(fileName);
    int counter = 1;

    String newFileName = fileName;
    while (File(path.join(directory, newFileName)).existsSync()) {
      newFileName = '${basePath}_$counter$extension';
      counter++;
    }

    return newFileName;
  }

  static Future<void> copyFile(
      String sourcePath, String destinationPath) async {
    try {
      await File(sourcePath).copy(destinationPath);
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }

  static Future<void> moveFile(
      String sourcePath, String destinationPath) async {
    try {
      await File(sourcePath).rename(destinationPath);
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }

  static Future<void> deleteFile(String filePath) async {
    try {
      await File(filePath).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  static Future<void> createDirectory(String path) async {
    try {
      await Directory(path).create(recursive: true);
    } catch (e) {
      throw Exception('Failed to create directory: $e');
    }
  }

  static Future<void> deleteDirectory(String path,
      {bool recursive = false}) async {
    try {
      await Directory(path).delete(recursive: recursive);
    } catch (e) {
      throw Exception('Failed to delete directory: $e');
    }
  }

  static Future<List<String>> listDirectory(String dirPath,
      {bool includeHidden = false}) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return [];
      }

      final entities = await dir.list().toList();
      final List<String> result = [];

      for (final entity in entities) {
        final fileName = path.basename(entity.path);
        if (!includeHidden && isHidden(fileName)) {
          continue;
        }
        result.add(fileName);
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  static Future<int> getDirectoryItemCount(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return 0;
      }

      final entities = await dir.list().toList();
      return entities.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> isDirectoryEmpty(String path) async {
    return await getDirectoryItemCount(path) == 0;
  }
}
