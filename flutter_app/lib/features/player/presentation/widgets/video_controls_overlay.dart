import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class VideoControlsOverlay extends StatelessWidget {
  final bool isPlaying;
  final double currentPosition;
  final double totalDuration;
  final double volume;
  final double brightness;
  final String selectedQuality;
  final String selectedLanguage;
  final bool isLocked;
  final int episodeNumber;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipIntro;
  final VoidCallback onToggleOrientation;
  final VoidCallback onToggleLock;
  final VoidCallback onBack;
  final VoidCallback onQualitySelect;
  final VoidCallback onLanguageSelect;
  final VoidCallback onEpisodeSelect;
  final String Function(double) formatDuration;

  const VideoControlsOverlay({
    super.key,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.volume,
    required this.brightness,
    required this.selectedQuality,
    required this.selectedLanguage,
    required this.isLocked,
    required this.episodeNumber,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSkipForward,
    required this.onSkipBackward,
    required this.onSkipIntro,
    required this.onToggleOrientation,
    required this.onToggleLock,
    required this.onBack,
    required this.onQualitySelect,
    required this.onLanguageSelect,
    required this.onEpisodeSelect,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: [0, 0.3, 0.7, 1],
        ),
      ),
      child: Column(
        children: [
          // Top Bar
          _buildTopBar(),

          Spacer(),

          // Center Controls
          if (!isLocked) _buildCenterControls(),

          Spacer(),

          // Bottom Bar
          _buildBottomBar(context),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 200));
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: onBack,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Episode $episodeNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Lock button
            IconButton(
              icon: Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onToggleLock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Episode
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
          onPressed: () {},
        ),

        SizedBox(width: 20),

        // Rewind 10s
        IconButton(
          icon: Icon(Icons.replay_10_rounded, color: Colors.white, size: 40),
          onPressed: onSkipBackward,
        ),

        SizedBox(width: 20),

        // Play/Pause
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        SizedBox(width: 20),

        // Forward 10s
        IconButton(
          icon: Icon(Icons.forward_10_rounded, color: Colors.white, size: 40),
          onPressed: onSkipForward,
        ),

        SizedBox(width: 20),

        // Next Episode
        IconButton(
          icon: Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Progress Bar
            Row(
              children: [
                Text(
                  formatDuration(currentPosition),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: currentPosition.clamp(0, totalDuration),
                      min: 0,
                      max: totalDuration,
                      onChanged: onSeek,
                    ),
                  ),
                ),
                Text(
                  formatDuration(totalDuration),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),

            // Control Buttons
            if (!isLocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side
                  Row(
                    children: [
                      // Quality
                      _buildControlButton(
                        label: selectedQuality,
                        icon: Icons.high_quality,
                        onTap: onQualitySelect,
                      ),
                      SizedBox(width: 12),
                      // Language
                      _buildControlButton(
                        label: selectedLanguage,
                        icon: Icons.translate,
                        onTap: onLanguageSelect,
                      ),
                    ],
                  ),

                  // Right side
                  Row(
                    children: [
                      // Skip Intro
                      _buildControlButton(
                        label: 'Skip Intro',
                        icon: Icons.fast_forward,
                        onTap: onSkipIntro,
                      ),
                      SizedBox(width: 12),
                      // Episodes
                      _buildControlButton(
                        label: 'Episodes',
                        icon: Icons.list,
                        onTap: onEpisodeSelect,
                      ),
                      SizedBox(width: 12),
                      // Orientation
                      _buildControlButton(
                        icon: _isLandscape()
                            ? Icons.screen_rotation
                            : Icons.screen_lock_rotation,
                        onTap: onToggleOrientation,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _isLandscape() {
    return true; // Simplified for this example
  }

  Widget _buildControlButton({
    String? label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label != null) ...[
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
