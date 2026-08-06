import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/radio/radio_station.dart';
import '../../services/radio/radio_audio_player_service.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/internationalization.dart';

class StationPlayerPageWidget extends StatefulWidget {
  static const String routeName = 'StationPlayerPage';
  static const String routePath = '/stationPlayer';

  final RadioStation station;

  const StationPlayerPageWidget({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<StationPlayerPageWidget> createState() => _StationPlayerPageWidgetState();
}

class _StationPlayerPageWidgetState extends State<StationPlayerPageWidget> {
  final RadioAudioPlayerService _playerService = RadioAudioPlayerService();

  @override
  void initState() {
    super.initState();
    _playerService.addListener(_onPlayerStateChanged);
    
    // Auto-play the chosen station stream on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerService.playStation(widget.station);
    });
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerService.isPlaying;
    final isLoading = _playerService.isLoading;
    final hasQuality = widget.station.hasQualityOptions;
    
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: FlutterFlowTheme.of(context).primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Now Playing',
            bnText: 'এখন বাজছে',
          ),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Animated Artwork Display
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAnimatedArtwork(isPlaying, isLoading),
                  ),
                ),
              ),

              // 2. Station Information
              Column(
                children: [
                  Text(
                    widget.station.name,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.station.description ?? '24/7 Live Stream',
                    style: TextStyle(
                      fontSize: 14,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Equalizer / Waveform Indicator when playing
                  if (isPlaying && !isLoading)
                    const WaveformIndicator()
                  else if (isLoading)
                    Text(
                      FFLocalizations.of(context).getVariableText(
                        enText: 'Connecting to stream...',
                        bnText: 'সংযুক্ত হচ্ছে...',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orangeAccent,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      FFLocalizations.of(context).getVariableText(
                        enText: 'Stream Paused',
                        bnText: 'বন্ধ রয়েছে',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                    ),
                ],
              ),

              // 3. Audio Volume Control
              _buildVolumeControl(),

              // 4. Core Media Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        _playerService.pause();
                      } else {
                        _playerService.playStation(widget.station);
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            FlutterFlowTheme.of(context).primary,
                            FlutterFlowTheme.of(context).primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              // 5. Quality Selection Row (Optional if hasQualityOptions)
              if (hasQuality)
                _buildQualitySelector()
              else
                const SizedBox(height: 48), // Spacer to maintain layout alignment
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedArtwork(bool isPlaying, bool isLoading) {
    Widget artworkChild = Container(
      color: FlutterFlowTheme.of(context).secondaryBackground,
      child: widget.station.artworkUrl != null
          ? Image.network(
              widget.station.artworkUrl!,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.radio, size: 80, color: Colors.white30),
            )
          :  Icon(Icons.radio, size: 80, color:FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.3)),
    );

    // Apply rotation animation if playing and not loading
    if (isPlaying && !isLoading) {
      artworkChild = artworkChild
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 15.seconds);
    }

    return artworkChild;
  }

  Widget _buildVolumeControl() {
    final currentVolume = _playerService.player.volume;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(Icons.volume_mute, color: FlutterFlowTheme.of(context).secondaryText, size: 20),
          Expanded(
            child: Slider(
              value: currentVolume,
              onChanged: (volume) {
                _playerService.player.setVolume(volume);
                setState(() {});
              },
              activeColor: FlutterFlowTheme.of(context).primary,
              inactiveColor: FlutterFlowTheme.of(context).alternate,
            ),
          ),
          Icon(Icons.volume_up, color: FlutterFlowTheme.of(context).secondaryText, size: 20),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Column(
      children: [
        Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Stream Quality',
            bnText: 'স্ট্রীম কোয়ালিটি',
          ),
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: FlutterFlowTheme.of(context).secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQualityChip(StreamQuality.high, 'High'),
            const SizedBox(width: 8),
            _buildQualityChip(StreamQuality.medium, 'Medium'),
            const SizedBox(width: 8),
            _buildQualityChip(StreamQuality.low, 'Low'),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityChip(StreamQuality quality, String label) {
    final isSelected = _playerService.selectedQuality == quality;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : FlutterFlowTheme.of(context).secondaryText,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: FlutterFlowTheme.of(context).primary,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      onSelected: (selected) {
        if (selected) {
          _playerService.setQuality(quality);
        }
      },
    );
  }
}

class WaveformIndicator extends StatelessWidget {
  const WaveformIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          width: 4,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scaleY(
           begin: 0.2,
           end: 1.0,
           duration: Duration(milliseconds: 300 + (index * 80)),
           curve: Curves.easeInOut,
         );
      }),
    );
  }
}
