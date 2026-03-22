import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String filePath;

  const AudioPlayerScreen({super.key, required this.filePath});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerController? _playerController;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(AudioPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentFilePath = widget.filePath;
      });

      // Dispose previous controller
      if (_playerController != null) {
        _playerController!.dispose();
      }

      // Set audio source
      await _audioPlayer.setFilePath(widget.filePath);

      // Initialize waveform controller
      _playerController = PlayerController();

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Prepare waveform
      await _playerController!.preparePlayer(
        path: widget.filePath,
        shouldExtractWaveform: true,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
              'Failed to load audio',
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

    return Column(
      children: [
        // Waveform visualization
        if (_playerController != null)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: AudioFileWaveforms(
                size: Size(MediaQuery.of(context).size.width, 200),
                playerController: _playerController!,
                waveformType: WaveformType.fitWidth,
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  liveWaveColor: Theme.of(context).colorScheme.primary,
                  spacing: 6,
                  showSeekLine: true,
                  seekLineColor: Theme.of(context).colorScheme.secondary,
                  seekLineThickness: 2,
                ),
              ),
            ),
          ),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress bar
              Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),

              // Time display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position)),
                    Text(_formatDuration(_duration)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 32,
                    onPressed: () {
                      final newPosition =
                          _position - const Duration(seconds: 10);
                      _audioPlayer.seek(newPosition < Duration.zero
                          ? Duration.zero
                          : newPosition);
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 48,
                    onPressed: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 32,
                    onPressed: () {
                      final newPosition =
                          _position + const Duration(seconds: 10);
                      _audioPlayer.seek(
                          newPosition > _duration ? _duration : newPosition);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Playback speed
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => _audioPlayer.setSpeed(speed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _audioPlayer.speed == speed
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: _audioPlayer.speed == speed
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: Text('${speed}x'),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
