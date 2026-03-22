import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class ChecksumUtils {
  static Future<String> calculateMD5(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to calculate MD5: $e');
    }
  }

  static Future<String> calculateSHA256(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to calculate SHA256: $e');
    }
  }

  static Future<String> calculateSHA1(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha1.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to calculate SHA1: $e');
    }
  }

  static Future<String> calculateCRC32(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final crc32 = Crc32();
      crc32.add(bytes);
      return crc32.toRadixString(16).padLeft(8, '0').toUpperCase();
    } catch (e) {
      throw Exception('Failed to calculate CRC32: $e');
    }
  }

  static Future<bool> compareMD5(String filePath1, String filePath2) async {
    try {
      final md51 = await calculateMD5(filePath1);
      final md52 = await calculateMD5(filePath2);
      return md51 == md52;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyFileIntegrity(
      String filePath, String expectedChecksum) async {
    try {
      final actualChecksum = await calculateMD5(filePath);
      return actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  static String formatChecksum(String checksum) {
    // Format checksum in groups of 4 characters for better readability
    final buffer = StringBuffer();
    for (int i = 0; i < checksum.length; i += 4) {
      buffer.write(checksum.substring(
          i, (i + 4 > checksum.length ? checksum.length : i + 4)));
      if (i + 4 < checksum.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString().trim().toUpperCase();
  }

  static Future<Map<String, String>> calculateMultipleChecksums(
    List<String> filePaths,
    String algorithm, // 'md5', 'sha256', 'sha1', 'crc32'
  ) async {
    final Map<String, String> checksums = {};

    for (final filePath in filePaths) {
      try {
        String checksum;
        switch (algorithm.toLowerCase()) {
          case 'md5':
            checksum = await calculateMD5(filePath);
            break;
          case 'sha256':
            checksum = await calculateSHA256(filePath);
            break;
          case 'sha1':
            checksum = await calculateSHA1(filePath);
            break;
          case 'crc32':
            checksum = await calculateCRC32(filePath);
            break;
          default:
            checksum = await calculateMD5(filePath); // Default to MD5
        }
        checksums[filePath] = checksum;
      } catch (e) {
        checksums[filePath] = 'Error: $e';
      }
    }

    return checksums;
  }
}

class Crc32 {
  int _crc = 0xFFFFFFFF;

  void add(List<int> bytes) {
    for (final byte in bytes) {
      _crc = _updateByte(_crc, byte);
    }
  }

  int _updateByte(int crc, int byte) {
    crc ^= byte & 0xFF;
    for (int i = 0; i < 8; i++) {
      if (crc & 0x01 != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
    return crc;
  }

  String toRadixString(int radix) {
    return (_crc ^ 0xFFFFFFFF).toRadixString(radix).toUpperCase();
  }
}
