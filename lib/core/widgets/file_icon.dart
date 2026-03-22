import 'package:flutter/material.dart';
import '../constants/file_category.dart';
import '../constants/supported_formats.dart';
import '../utils/file_utils.dart';

class FileIcon extends StatelessWidget {
  final String filePath;
  final double size;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;

  const FileIcon({
    super.key,
    required this.filePath,
    this.size = 40.0,
    this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final extension = FileUtils.getFileExtension(filePath);
    final category = SupportedFormats.getCategoryFromExtension(extension);
    final iconColor = color ?? _getCategoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getIconData(category),
          color: iconColor,
          size: size * 0.7,
        ),
      ),
    );
  }

  IconData _getIconData(FileCategory? category) {
    switch (category) {
      case FileCategory.pdf:
        return Icons.picture_as_pdf;
      case FileCategory.document:
        return Icons.description;
      case FileCategory.image:
        return Icons.image;
      case FileCategory.video:
        return Icons.videocam;
      case FileCategory.audio:
        return Icons.audiotrack;
      case FileCategory.archive:
        return Icons.archive;
      case FileCategory.code:
        return Icons.code;
      case FileCategory.text:
        return Icons.text_snippet;
      case FileCategory.ebook:
        return Icons.book;
      case FileCategory.email:
        return Icons.email;
      case FileCategory.apk:
        return Icons.android;
      case FileCategory.folder:
        return Icons.folder;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getCategoryColor(FileCategory? category) {
    switch (category) {
      case FileCategory.pdf:
        return const Color(0xFFE53935);
      case FileCategory.document:
        return const Color(0xFF1565C0);
      case FileCategory.image:
        return const Color(0xFF6A1B9A);
      case FileCategory.video:
        return const Color(0xFF00695C);
      case FileCategory.audio:
        return const Color(0xFFAD1457);
      case FileCategory.archive:
        return const Color(0xFFF9A825);
      case FileCategory.code:
        return const Color(0xFF37474F);
      case FileCategory.text:
        return const Color(0xFF37474F);
      case FileCategory.ebook:
        return const Color(0xFF283593);
      case FileCategory.email:
        return const Color(0xFF00838F);
      case FileCategory.apk:
        return const Color(0xFF388E3C);
      case FileCategory.folder:
        return const Color(0xFFF57F17);
      default:
        return const Color(0xFF757575);
    }
  }
}
