import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String filePath;

  const VideoPlayerScreen({super.key, required this.filePath});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  // VideoPlayerController? _videoPlayerController;
  // ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    // _videoPlayerController?.dispose();
    // _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    // Video player temporarily disabled due to plugin compatibility issues with Android SDK 36
    setState(() {
      _isLoading = false;
      _error =
          'Video player is currently not available. Please check back later.';
    });
  }

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
          // Video player controls temporarily disabled
          /*
          if (_chewieController != null) ...[
            IconButton(
              icon: Icon(
                _videoPlayerController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  _videoPlayerController!.value.isPlaying
                      ? _videoPlayerController!.pause()
                      : _videoPlayerController!.play();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () {
                _videoPlayerController!.seekTo(Duration.zero);
              },
            ),
          ],
          */
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializePlayer,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
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
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Video player temporarily disabled
    return const Center(
      child: Text('Video player is currently not available.'),
    );
  }
}
