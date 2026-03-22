enum FileCategory {
  pdf,
  document,
  image,
  video,
  audio,
  archive,
  code,
  text,
  ebook,
  email,
  apk,
  folder,
  unknown,
}

extension FileCategoryExtension on FileCategory {
  String get displayName {
    switch (this) {
      case FileCategory.pdf:
        return 'PDF';
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
      case FileCategory.folder:
        return 'Folder';
      case FileCategory.unknown:
        return 'Unknown';
    }
  }
}
