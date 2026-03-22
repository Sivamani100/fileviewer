import 'package:flutter/material.dart';

class EpubViewerScreen extends StatelessWidget {
  final String filePath;

  const EpubViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Reader'),
      ),
      body: const Center(
        child: Text('EPUB viewer temporarily disabled'),
      ),
    );
  }
}
