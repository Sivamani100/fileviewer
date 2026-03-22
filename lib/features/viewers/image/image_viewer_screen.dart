import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const ImageViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Viewer'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share image
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              // Show image info
            },
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: FileImage(File(widget.filePath)),
        loadingBuilder: (context, imageChunk) {
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64),
                const SizedBox(height: 16),
                Text('Failed to load image'),
                const SizedBox(height: 8),
                Text(error.toString()),
              ],
            ),
          );
        },
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered,
        heroAttributes: const PhotoViewHeroAttributes(
          tag: 'image_hero',
        ),
        onTapUp: (context, details, controller) {
          // Zoom in
        },
        onTapDown: (context, details, controller) {
          // Zoom out
        },
        enableRotation: true,
        gaplessPlayback: false,
      ),
    );
  }
}
