import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HtmlViewerScreen extends ConsumerStatefulWidget {
  final String filePath;

  const HtmlViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends ConsumerState<HtmlViewerScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _error;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          File(widget.filePath).uri.pathSegments.last,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
        bottom: _isLoading && _progress > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load HTML',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _webViewController?.reload(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return InAppWebView(
      initialFile: widget.filePath,
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          useOnLoadResource: true,
          javaScriptEnabled: true,
          supportZoom: true,
          useOnDownloadStart: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      },
      onLoadStop: (controller, url) {
        setState(() {
          _isLoading = false;
        });
      },
      onLoadError: (controller, url, code, message) {
        setState(() {
          _error = message;
          _isLoading = false;
        });
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          _progress = progress / 100.0;
        });
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url;
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          // Allow navigation to external URLs
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.ALLOW;
      },
    );
  }
}
