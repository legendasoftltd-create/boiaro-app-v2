import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/custom_code/widgets/loading_dots_widget.dart';

class ThemeBrightnessWidget extends StatefulWidget {
  const ThemeBrightnessWidget({Key? key}) : super(key: key);

  @override
  State<ThemeBrightnessWidget> createState() => _ThemeBrightnessWidgetState();
}

class _ThemeBrightnessWidgetState extends State<ThemeBrightnessWidget> {
  double? _localBrightness;

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerProvider>(
      builder: (context, provider, child) {
        final theme = FlutterFlowTheme.of(context);
        final providerBrightness = provider.currentBrightness;
        final themeMode = provider.currentThemeMode;
        
        // Sync local value with provider when not dragging and provider changed
        if (_localBrightness == null || (!provider.isChangingBrightness && (_localBrightness! - providerBrightness).abs() > 0.01)) {
          _localBrightness = providerBrightness;
        }
        
        final brightness = _localBrightness ?? providerBrightness;
        
        final isChangingBrightness = provider.isChangingBrightness;
        final isChangingTheme = provider.isChangingTheme;
        final isLoading = isChangingBrightness || isChangingTheme;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 60,
                    child: Center(
                      child: LoadingDotsWidget(
                        color: theme.primary,
                        size: 6.0,
                      ),
                    ),
                  )
                : Column(
                    key: const ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brightness Slider Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined, color: theme.primary, size: 22),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.0,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                                ),
                                child: Slider(
                                  value: brightness,
                                  onChanged: (value) {
                                    // Update local state for smooth dragging
                                    setState(() {
                                      _localBrightness = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    // Apply change only when user releases
                                    provider.setCurrentBrightness(value);
                                    setState(() {
                                      _localBrightness = null; // Reset to sync with provider
                                    });
                                  },
                                  activeColor: theme.primary,
                                  inactiveColor: theme.alternate,
                                ),
                              ),
                            ),
                            Icon(Icons.wb_sunny_rounded, color: theme.primary, size: 22),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Theme Selection Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildThemeOption(
                            context,
                            provider,
                            0,
                            AppThemeMode.light,
                            themeMode == AppThemeMode.light,
                            Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _buildThemeOption(
                            context,
                            provider,
                            1,
                            AppThemeMode.sepia,
                            themeMode == AppThemeMode.sepia,
                            const Color(0xFFF5DEB3),
                          ),
                          const SizedBox(width: 12),
                          _buildThemeOption(
                            context,
                            provider,
                            2,
                            AppThemeMode.dark,
                            themeMode == AppThemeMode.dark,
                            Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Theme labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildThemeLabel(context, 'Light', themeMode == AppThemeMode.light),
                          const SizedBox(width: 32),
                          _buildThemeLabel(context, 'Sepia', themeMode == AppThemeMode.sepia),
                          const SizedBox(width: 32),
                          _buildThemeLabel(context, 'Dark', themeMode == AppThemeMode.dark),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    PdfViewerProvider provider,
    int index,
    AppThemeMode mode,
    bool isSelected,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        provider.setThemeMode(mode);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: mode == AppThemeMode.dark ? Colors.white : Colors.black,
                size: 22,
              )
            : null,
      ),
    );
  }

  Widget _buildThemeLabel(BuildContext context, String label, bool isSelected) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      label,
      style: theme.bodySmall.override(
        fontFamily: 'SF Pro Display',
        color: isSelected ? theme.primary : theme.secondaryText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}