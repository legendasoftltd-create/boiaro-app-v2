import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/tts_service.dart';

/// A bottom-sheet style TTS control panel.
/// Usage: show via [TtsBottomPanel.show(context, bookId: ..., paragraphs: ...)].
class TtsBottomPanel extends StatefulWidget {
  final String bookId;
  final List<String> paragraphs;
  final int initialParagraphIndex;

  const TtsBottomPanel({
    super.key,
    required this.bookId,
    required this.paragraphs,
    this.initialParagraphIndex = 0,
  });

  /// Shows the TTS panel as a persistent bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String bookId,
    required List<String> paragraphs,
    int initialParagraphIndex = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TtsBottomPanel(
        bookId: bookId,
        paragraphs: paragraphs,
        initialParagraphIndex: initialParagraphIndex,
      ),
    );
  }

  @override
  State<TtsBottomPanel> createState() => _TtsBottomPanelState();
}

class _TtsBottomPanelState extends State<TtsBottomPanel> {
  late int _paragraphIndex;
  bool _accessLoaded = false;
  bool _unlocking = false;
  String? _unlockError;

  @override
  void initState() {
    super.initState();
    _paragraphIndex = widget.initialParagraphIndex;
    final svc = TtsService.instance;
    // Fetch voices & check access in parallel
    Future.wait([
      if (svc.voices.isEmpty) svc.fetchVoices(),
      svc.checkAccess(widget.bookId),
    ]).then((_) {
      if (mounted) setState(() => _accessLoaded = true);
    });
  }

  Future<void> _playCurrentParagraph() async {
    if (_paragraphIndex >= widget.paragraphs.length) return;
    final text = widget.paragraphs[_paragraphIndex];
    await TtsService.instance.speak(
      text: text,
      bookId: widget.bookId,
      paragraphIndex: _paragraphIndex,
    );
  }

  Future<void> _unlock() async {
    setState(() {
      _unlocking = true;
      _unlockError = null;
    });
    final err = await TtsService.instance.unlockWithCoins(widget.bookId);
    setState(() {
      _unlocking = false;
      _unlockError = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: TtsService.instance,
      child: Consumer<TtsService>(
        builder: (context, svc, _) {
          return Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(),
                _buildHeader(svc),
                const Divider(height: 1),
                _buildModeSwitch(svc),
                if (svc.mode == TtsMode.premium) ...[
                  _buildPremiumSection(svc),
                ],
                _buildSpeedRow(svc),
                _buildParagraphNav(svc),
                _buildPlaybackControls(svc),
                if (svc.error != null) _buildError(svc.error!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader(TtsService svc) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.record_voice_over_rounded,
                color: FlutterFlowTheme.of(context).primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Listen to Book',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
              ),
            ),
            IconButton(
              onPressed: () async {
                await svc.stop();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close_rounded),
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ],
        ),
      );

  Widget _buildModeSwitch(TtsService svc) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: '📱 Device',
                sublabel: 'Free · System voice',
                selected: svc.mode == TtsMode.device,
                onTap: () => svc.setMode(TtsMode.device),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeButton(
                label: '✨ Premium AI',
                sublabel: 'Natural Bengali voice',
                selected: svc.mode == TtsMode.premium,
                onTap: () => svc.setMode(TtsMode.premium),
              ),
            ),
          ],
        ),
      );

  Widget _buildPremiumSection(TtsService svc) {
    final access = svc.accessInfo;
    if (!_accessLoaded || access == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Needs unlock
    if (!access.unlocked && access.accessType == 'paid') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔒 Premium AI Voice',
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock natural AI voice for ${access.coinPrice} coins\n'
                'Your balance: ${access.walletBalance} coins',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              if (_unlockError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _unlockError!,
                  style: FlutterFlowTheme.of(context)
                      .bodySmall
                      .override(color: Colors.red),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _unlocking ? null : _unlock,
                  icon: _unlocking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(_unlocking
                      ? 'Unlocking…'
                      : 'Unlock for ${access.coinPrice} coins'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Voice picker
    if (svc.voices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voice',
              style: FlutterFlowTheme.of(context)
                  .bodySmall
                  .override(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: svc.voices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final v = svc.voices[i];
                final selected = svc.selectedVoice?.id == v.id;
                return GestureDetector(
                  onTap: () => svc.selectVoice(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).alternate,
                      ),
                    ),
                    child: Text(
                      v.label,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            color: selected
                                ? Colors.white
                                : FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSpeedRow(TtsService svc) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Row(
          children: [
            Text('Speed',
                style: FlutterFlowTheme.of(context)
                    .bodySmall
                    .override(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('${(svc.speechRate * 2).toStringAsFixed(1)}×',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.w700,
                    )),
            Expanded(
              child: Slider(
                value: svc.speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                activeColor: FlutterFlowTheme.of(context).primary,
                onChanged: (v) => svc.setSpeechRate(v),
              ),
            ),
          ],
        ),
      );

  Widget _buildParagraphNav(TtsService svc) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Text(
              'Paragraph ${_paragraphIndex + 1} / ${widget.paragraphs.length}',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const Spacer(),
            _NavBtn(
              icon: Icons.skip_previous_rounded,
              enabled: _paragraphIndex > 0,
              onTap: () {
                setState(() => _paragraphIndex--);
                if (svc.isPlaying) _playCurrentParagraph();
              },
            ),
            const SizedBox(width: 8),
            _NavBtn(
              icon: Icons.skip_next_rounded,
              enabled: _paragraphIndex < widget.paragraphs.length - 1,
              onTap: () {
                setState(() => _paragraphIndex++);
                if (svc.isPlaying) _playCurrentParagraph();
              },
            ),
          ],
        ),
      );

  Widget _buildPlaybackControls(TtsService svc) {
    final canPlay = svc.mode == TtsMode.device ||
        (svc.accessInfo?.unlocked == true ||
            svc.accessInfo?.accessType == 'free');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (svc.isLoading)
            const SizedBox(
              width: 56,
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            GestureDetector(
              onTap: canPlay
                  ? () {
                      if (svc.isPlaying) {
                        svc.stop();
                      } else {
                        _playCurrentParagraph();
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canPlay
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.grey.shade300,
                  boxShadow: canPlay
                      ? [
                          BoxShadow(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  svc.isPlaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Text(
          msg,
          style: FlutterFlowTheme.of(context)
              .bodySmall
              .override(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1)
              : FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon,
          color: enabled
              ? FlutterFlowTheme.of(context).primaryText
              : Colors.grey.shade300),
      iconSize: 28,
    );
  }
}
