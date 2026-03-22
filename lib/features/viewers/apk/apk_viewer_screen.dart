import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApkViewerScreen extends StatefulWidget {
  final String filePath;

  const ApkViewerScreen({super.key, required this.filePath});

  @override
  State<ApkViewerScreen> createState() => _ApkViewerScreenState();
}

class _ApkViewerScreenState extends State<ApkViewerScreen> {
  Map<String, dynamic>? _apkInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApkInfo();
  }

  Future<void> _loadApkInfo() async {
    try {
      final file = File(widget.filePath);
      final fileSize = await file.length();
      final lastModified = await file.lastModified();

      // For APK, we can show basic file info since parsing APK requires native code
      setState(() {
        _apkInfo = {
          'File Name': widget.filePath.split('/').last,
          'File Size': '${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
          'Last Modified': lastModified.toString(),
          'Path': widget.filePath,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apkInfo = {'Error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.install_mobile),
            onPressed: () => OpenFilex.open(widget.filePath),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apkInfo == null
              ? const Center(child: Text('No information available'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _apkInfo!.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value.toString()),
                    );
                  }).toList(),
                ),
    );
  }
}
