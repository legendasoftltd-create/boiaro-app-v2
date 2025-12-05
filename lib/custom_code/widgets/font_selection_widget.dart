import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/custom_code/widgets/loading_dots_widget.dart';

class FontSelectionWidget extends StatefulWidget {
  const FontSelectionWidget({Key? key}) : super(key: key);

  @override
  State<FontSelectionWidget> createState() => _FontSelectionWidgetState();
}

class _FontSelectionWidgetState extends State<FontSelectionWidget> {
  double? _localFontSize;

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerProvider>(
      builder: (context, provider, child) {
        final theme = FlutterFlowTheme.of(context);
        final providerFontSize = provider.epubFontSize;
        
        // Sync local value with provider when not dragging and provider changed
        if (_localFontSize == null || (!provider.isChangingFont && (_localFontSize! - providerFontSize).abs() > 0.01)) {
          _localFontSize = providerFontSize;
        }
        
        final fontSize = _localFontSize ?? providerFontSize;
        final isChangingFont = provider.isChangingFont;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isChangingFont
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
                      // Font Size Slider Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Icon(Icons.text_fields, color: theme.primary, size: 20),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.0,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
                                ),
                                child: Slider(
                                  value: fontSize,
                                  min: 12.0,
                                  max: 32.0,
                                  // divisions: 20,
                                  onChanged: (value) {
                                    // Update local state for smooth dragging
                                    setState(() {
                                      _localFontSize = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    // Apply change only when user releases
                                    provider.setEpubFontSize(value);
                                    setState(() {
                                      _localFontSize = null; // Reset to sync with provider
                                    });
                                  },
                                  activeColor: theme.primary,
                                  inactiveColor: theme.alternate,
                                ),
                              ),
                            ),
                            Icon(Icons.text_fields_outlined, color: theme.primary, size: 23),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Font Selection Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Default Font',
                            style: theme.bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'আদর্শলিপি',
                            style: theme.bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: theme.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'অনি',
                            style: theme.bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: theme.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'বাংলা',
                            style: theme.bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: theme.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'লিখন',
                            style: theme.bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

