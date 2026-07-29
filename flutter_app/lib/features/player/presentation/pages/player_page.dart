import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/video_controls_overlay.dart';

/// Built-in **offline** player. Streaming was removed from the app —
/// this player only plays episodes the user has already downloaded to
/// their device (see Downloads page / "DHS Anime" folder).
class PlayerPage extends ConsumerStatefulWidget {
  final String episodeId;
  final String animeId;
  final int episodeNumber;
  final String? filePath;
  final String? title;

  const PlayerPage({
    super.key,
    required this.episodeId,
    required this.animeId,
    required this.episodeNumber,
    this.filePath,
    this.title,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  BetterPlayerController? _controller;
  Timer? _controlsTimer;
  bool _progressListenerAttached = false;

  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLandscape = false;
  bool _fileMissing = false;
  double _currentPosition = 0;
  double _totalDuration = 0;
  double _volume = 1.0;
  double _brightness = 1.0;
  final String _selectedQuality = 'Offline';
  String _selectedLanguage = 'Downloaded';
  bool _isLocked = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _isLandscape = true;

    _initPlayer();
    _startControlsTimer();
  }

  Future<void> _initPlayer() async {
    final path = widget.filePath ?? '';

    // Only local files are playable — if the file is gone, show a
    // friendly fallback instead of a broken stream screen.
    if (path.isEmpty || !File(path).existsSync()) {
      setState(() => _fileMissing = true);
      return;
    }

    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        allowedScreenSleep: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false, // custom overlay below
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        path,
      ),
    );

    controller.addEventsListener(_onPlayerEvent);

    setState(() {
      _controller = controller;
      _isPlaying = true;
      _selectedLanguage = widget.title?.isNotEmpty == true
          ? widget.title!
          : 'Episode ${widget.episodeNumber}';
    });
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    // Attach the progress listener once the underlying controller exists
    if (!(_progressListenerAttached)) {
      final videoController = _controller?.videoPlayerController;
      if (videoController != null) {
        videoController.addListener(_onVideoProgress);
        _progressListenerAttached = true;
      }
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      setState(() => _isPlaying = false);
    }
  }

  void _onVideoProgress() {
    final value = _controller?.videoPlayerController?.value;
    if (value == null || !mounted) return;

    setState(() {
      _currentPosition = value.position.inMilliseconds / 1000;
      final duration = value.duration?.inMilliseconds ?? 0;
      if (duration > 0) _totalDuration = duration / 1000;
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;

    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      controller.play();
      _startControlsTimer();
    } else {
      controller.pause();
    }
  }

  void _seekTo(double position) {
    final clamped = position.clamp(0, _totalDuration);
    _controller?.seekTo(Duration(milliseconds: (clamped * 1000).toInt()));
    setState(() => _currentPosition = clamped);
  }

  void _skipForward() => _seekTo(_currentPosition + 10);
  void _skipBackward() => _seekTo(_currentPosition - 10);
  void _skipIntro() => _seekTo(_currentPosition + 90); // Skip 90 seconds

  void _setVolume(double volume) {
    _controller?.setVolume(volume);
  }

  void _toggleOrientation() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() => _isLandscape = !_isLandscape);
  }

  void _showFixedForLocalToast(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is fixed for downloaded files'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _fileMissing ? _buildMissingFileView() : _buildPlayerView(),
    );
  }

  /// Shown when the episode has not been downloaded (anymore).
  Widget _buildMissingFileView() {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_for_offline_outlined,
                  size: 80,
                  color: AppTheme.textHint.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Episode not downloaded',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Streaming is not available. Download the episode to your "DHS Anime" folder and watch it here, offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/downloads'),
                  icon: const Icon(Icons.download_outlined, size: 20),
                  label: const Text('Go to Downloads'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerView() {
    return GestureDetector(
      onTap: () {
        if (!_isLocked) {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startControlsTimer();
        }
      },
      onDoubleTapDown: (details) {
        if (_isLocked) return;
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < screenWidth / 3) {
          _skipBackward();
        } else if (details.localPosition.dx > screenWidth * 2 / 3) {
          _skipForward();
        } else {
          _togglePlay();
        }
      },
      onVerticalDragUpdate: (details) {
        if (_isLocked) return;
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < screenWidth / 2) {
          // Left side - Brightness
          setState(() {
            _brightness = (_brightness - details.delta.dy / 200).clamp(0.0, 1.0);
          });
        } else {
          // Right side - Volume
          setState(() {
            _volume = (_volume - details.delta.dy / 200).clamp(0.0, 1.0);
          });
          _setVolume(_volume);
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_isLocked) return;
        final seekAmount = details.delta.dx * 0.5;
        _seekTo(_currentPosition + seekAmount);
      },
      child: Stack(
        children: [
          // Local video
          Center(
            child: _controller != null
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _controller!),
                  )
                : const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
          ),

          // Buffering indicator
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),

          // Controls Overlay
          if (_showControls)
            VideoControlsOverlay(
              isPlaying: _isPlaying,
              currentPosition: _currentPosition,
              totalDuration: _totalDuration,
              volume: _volume,
              brightness: _brightness,
              selectedQuality: _selectedQuality,
              selectedLanguage: _selectedLanguage,
              isLocked: _isLocked,
              episodeNumber: widget.episodeNumber,
              onPlayPause: _togglePlay,
              onSeek: _seekTo,
              onSkipForward: _skipForward,
              onSkipBackward: _skipBackward,
              onSkipIntro: _skipIntro,
              onToggleOrientation: _toggleOrientation,
              onToggleLock: () => setState(() => _isLocked = !_isLocked),
              onBack: () => context.pop(),
              onQualitySelect: () => _showFixedForLocalToast('Quality'),
              onLanguageSelect: () => _showFixedForLocalToast('Audio'),
              onEpisodeSelect: () => context.go('/downloads'),
              formatDuration: _formatDuration,
            ),

          // Brightness indicator
          if (_brightness != 1.0)
            Positioned(
              left: 30,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.brightness_6, color: Colors.white, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      '${(_brightness * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Volume indicator
          if (_volume != 1.0)
            Positioned(
              right: 30,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _volume == 0 ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_volume * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
