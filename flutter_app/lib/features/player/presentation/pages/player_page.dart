import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/video_controls_overlay.dart';
import '../widgets/episode_selector_sheet.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final String episodeId;
  final String animeId;
  final int episodeNumber;

  const PlayerPage({
    super.key,
    required this.episodeId,
    required this.animeId,
    required this.episodeNumber,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLandscape = false;
  double _currentPosition = 0;
  double _totalDuration = 1440; // 24 minutes in seconds
  double _volume = 1.0;
  double _brightness = 1.0;
  String _selectedQuality = '1080p';
  String _selectedLanguage = 'Hindi';
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

    // Auto-hide controls
    _startControlsTimer();
  }

  void _startControlsTimer() {
    Future.delayed(Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
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
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startControlsTimer();
    }
  }

  void _seekTo(double position) {
    setState(() => _currentPosition = position.clamp(0, _totalDuration));
  }

  void _skipForward() {
    _seekTo(_currentPosition + 10);
  }

  void _skipBackward() {
    _seekTo(_currentPosition - 10);
  }

  void _skipIntro() {
    _seekTo(_currentPosition + 90); // Skip 90 seconds
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
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
          }
        },
        onHorizontalDragUpdate: (details) {
          if (_isLocked) return;
          // Seek gesture
          final seekAmount = details.delta.dx * 0.5;
          _seekTo(_currentPosition + seekAmount);
        },
        child: Stack(
          children: [
            // Video Area (placeholder)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_rounded,
                      size: 80,
                      color: AppTheme.textHint.withOpacity(0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Video Player',
                      style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Episode ${widget.episodeNumber}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buffering indicator
            if (_isBuffering)
              Center(
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
                onQualitySelect: () => _showQualitySheet(),
                onLanguageSelect: () => _showLanguageSheet(),
                onEpisodeSelect: () => _showEpisodeSheet(),
                formatDuration: _formatDuration,
              ),

            // Brightness indicator
            if (_brightness != 1.0)
              Positioned(
                left: 30,
                top: MediaQuery.of(context).size.height / 2 - 30,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.brightness_6, color: Colors.white, size: 24),
                      SizedBox(height: 8),
                      Text(
                        '${(_brightness * 100).toInt()}%',
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
                  padding: EdgeInsets.all(12),
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
                      SizedBox(height: 8),
                      Text(
                        '${(_volume * 100).toInt()}%',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQualitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Quality',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              ...['1080p', '720p', '480p', '360p'].map((quality) {
                final isSelected = quality == _selectedQuality;
                return ListTile(
                  title: Text(quality, style: TextStyle(color: AppTheme.textPrimary)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedQuality = quality);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              ...['Hindi', 'English', 'Japanese', 'Chinese'].map((language) {
                final isSelected = language == _selectedLanguage;
                return ListTile(
                  title: Text(language, style: TextStyle(color: AppTheme.textPrimary)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedLanguage = language);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showEpisodeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EpisodeSelectorSheet(
          currentEpisode: widget.episodeNumber,
          totalEpisodes: 156,
          onEpisodeSelect: (episode) {
            Navigator.pop(context);
            // Navigate to new episode
          },
        );
      },
    );
  }
}
