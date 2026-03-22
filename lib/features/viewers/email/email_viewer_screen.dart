import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class EmailViewerScreen extends StatefulWidget {
  final String filePath;

  const EmailViewerScreen({super.key, required this.filePath});

  @override
  State<EmailViewerScreen> createState() => _EmailViewerScreenState();
}

class _EmailViewerScreenState extends State<EmailViewerScreen> {
  String? _content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    try {
      final file = File(widget.filePath);
      final content = await file.readAsString();
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'Error loading email: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(widget.filePath),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_content ?? 'No content'),
            ),
    );
  }
}
