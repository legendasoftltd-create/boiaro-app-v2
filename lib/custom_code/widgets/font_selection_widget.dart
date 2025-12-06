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
  ValueNotifier<double>? _localFontSize;
  bool _isDragging = false;

  @override
  void dispose() {
    _localFontSize?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PdfViewerProvider, (double, bool)>(
      selector: (_, p) => (p.epubFontSize, p.isChangingFont),
      builder: (context, data, child) {
        final theme = FlutterFlowTheme.of(context);
        final providerFontSize = data.$1;
        final isChangingFont = data.$2;
        
        // Initialize ValueNotifier on first build
        _localFontSize ??= ValueNotifier<double>(providerFontSize);
        
        // Sync local value with provider only when not dragging and provider changed externally
        if (!_isDragging && (_localFontSize!.value - providerFontSize).abs() > 0.01) {
          _localFontSize!.value = providerFontSize;
        }

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
                              child: ValueListenableBuilder<double>(
                                valueListenable: _localFontSize!,
                                builder: (context, fontSize, child) {
                                  return SliderTheme(
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
                                        // Update local value for smooth dragging - no provider updates
                                        _isDragging = true;
                                        _localFontSize!.value = value;
                                      },
                                      onChangeEnd: (value) {
                                        // Apply change only when user releases
                                        _isDragging = false;
                                        final provider = context.read<PdfViewerProvider>();
                                        provider.setEpubFontSize(value);
                                        // Sync will happen automatically on next build
                                      },
                                      activeColor: theme.primary,
                                      inactiveColor: theme.alternate,
                                    ),
                                  );
                                },
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

