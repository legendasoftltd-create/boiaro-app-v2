import 'package:flutter/material.dart';

class SpeechPlayerBar extends StatelessWidget {
  final VoidCallback? onShuffleToggle;
  final VoidCallback? onSettings;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onStop;
  final bool isShuffleOn;
  final bool isPlaying;
  final Color backgroundColor;
  final Color iconColor;

  const SpeechPlayerBar({
    Key? key,
    this.onShuffleToggle,
    this.onSettings,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
    this.onStop,
    this.isShuffleOn = false,
    this.isPlaying = false,
    this.backgroundColor = const Color(0xFFB8B8B8),
    this.iconColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.shuffle,
            onPressed: onShuffleToggle,
            iconColor: isShuffleOn ? Colors.blue : iconColor,
          ),
          _ControlButton(
            icon: Icons.settings,
            onPressed: onSettings,
            iconColor: iconColor,
          ),
          _ControlButton(
            icon: Icons.skip_previous,
            onPressed: onPrevious,
            iconColor: iconColor,
          ),
          _ControlButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: onPlayPause,
            iconColor: iconColor,
          ),
          _ControlButton(
            icon: Icons.skip_next,
            onPressed: onNext,
            iconColor: iconColor,
          ),
          _ControlButton(
            icon: Icons.stop,
            onPressed: onStop,
            iconColor: iconColor,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: iconColor,
      iconSize: 28,
      splashRadius: 24,
    );
  }
}
