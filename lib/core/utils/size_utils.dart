import 'dart:math' as math;

class SizeUtils {
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes < 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final unitIndex = (math.log(bytes) / math.log(1024)).floor();

    final size = bytes / math.pow(1024, unitIndex);
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  static double bytesToKB(int bytes) => bytes / 1024.0;
  static double bytesToMB(int bytes) => bytes / (1024.0 * 1024.0);
  static double bytesToGB(int bytes) => bytes / (1024.0 * 1024.0 * 1024.0);

  static int kbToBytes(double kb) => (kb * 1024).round();
  static int mbToBytes(double mb) => (mb * 1024 * 1024).round();
  static int gbToBytes(double gb) => (gb * 1024 * 1024 * 1024).round();

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds.toString().padLeft(2, '0')}s';
    }
  }

  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  static String formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static double getAspectRatio(int width, int height) {
    return width / height;
  }

  static Size calculateThumbnailSize(
    int originalWidth,
    int originalHeight,
    double maxWidth,
    double maxHeight,
  ) {
    final aspectRatio = originalWidth / originalHeight;

    double newWidth, newHeight;

    if (originalWidth / maxWidth > originalHeight / maxHeight) {
      // Width is the limiting factor
      newWidth = maxWidth;
      newHeight = maxWidth / aspectRatio;
    } else {
      // Height is the limiting factor
      newHeight = maxHeight;
      newWidth = maxHeight * aspectRatio;
    }

    return Size(newWidth, newHeight);
  }

  static int calculateGridColumns(double screenWidth,
      {double itemWidth = 120.0, double spacing = 16.0}) {
    final availableWidth = screenWidth - (spacing * 2); // Account for padding
    return (availableWidth / (itemWidth + spacing)).floor().clamp(1, 10);
  }

  static double getResponsiveSize(
    double screenSize,
    double smallSize,
    double mediumSize,
    double largeSize,
  ) {
    if (screenSize < 600) {
      return smallSize;
    } else if (screenSize < 900) {
      return mediumSize;
    } else {
      return largeSize;
    }
  }

  static int clampInt(int value, int min, int max) {
    return value.clamp(min, max);
  }

  static double clampDouble(double value, double min, double max) {
    return value.clamp(min, max);
  }
}

class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);
}
