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
        if (!_isDragging &&
            (_localFontSize!.value - providerFontSize).abs() > 0.01) {
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
                            Icon(Icons.text_fields,
                                color: theme.primary, size: 20),
                            Expanded(
                              child: ValueListenableBuilder<double>(
                                valueListenable: _localFontSize!,
                                builder: (context, fontSize, child) {
                                  return SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3.0,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6.0),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 8.0),
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
                                        final provider =
                                            context.read<PdfViewerProvider>();
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
                            Icon(Icons.text_fields_outlined,
                                color: theme.primary, size: 23),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Font Selection Row
                      Selector<PdfViewerProvider, String>(
                        selector: (_, p) => p.epubFontFamily,
                        builder: (context, currentFontFamily, child) {
                          final provider = context.read<PdfViewerProvider>();

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildFontOption(
                                  context,
                                  provider,
                                  'SF Pro Display',
                                  'Default Font',
                                  currentFontFamily == 'SF Pro Display',
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _buildFontOption(
                                  context,
                                  provider,
                                  'AdorshoLipi',
                                  'আদর্শলিপি',
                                  currentFontFamily == 'AdorshoLipi',
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _buildFontOption(
                                  context,
                                  provider,
                                  'LikhanNormal',
                                  'লিখন',
                                  currentFontFamily == 'LikhanNormal',
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _buildFontOption(
                                  context,
                                  provider,
                                  'Nikosh',
                                  'Nikosh',
                                  currentFontFamily == 'Nikosh',
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _buildFontOption(
                                  context,
                                  provider,
                                  'NotoSerifBengali',
                                  'Noto Sans',
                                  currentFontFamily == 'NotoSerifBengali',
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _buildFontOption(
                                  context,
                                  provider,
                                  'SolaimanLipi',
                                  'SolaimanLipi',
                                  currentFontFamily == 'SolaimanLipi',
                                  theme,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFontOption(
    BuildContext context,
    PdfViewerProvider provider,
    String fontFamily,
    String label,
    bool isSelected,
    FlutterFlowTheme theme,
  ) {
    return GestureDetector(
      onTap: () {
        provider.setEpubFontFamily(fontFamily);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        // decoration: BoxDecoration(
        //   color: isSelected
        //       ? theme.primary.withOpacity(0.1)
        //       : Colors.transparent,
        //   borderRadius: BorderRadius.circular(8),
        //   border: Border.all(
        //     color: isSelected
        //         ? theme.primary
        //         : theme.alternate.withOpacity(0.3),
        //     width: isSelected ? 1.5 : 1,
        //   ),
        // ),
        child: Text(
          label,
          style: theme.bodySmall.override(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.primary : theme.secondaryText,
          ),
        ),
      ),
    );
  }
}
