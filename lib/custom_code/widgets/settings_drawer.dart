import 'package:a_i_ebook_app/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/pdf_viewer_provider.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({
    Key? key,
    this.onAutoScrollSettingsChanged,
  }) : super(key: key);

  final VoidCallback? onAutoScrollSettingsChanged;

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  // ValueNotifiers for smooth slider dragging without rebuilds
  ValueNotifier<double>? _localLineSpacing;
  ValueNotifier<double>? _localAutoScrollInterval;
  ValueNotifier<double>? _localAutoScrollSpeed;
  ValueNotifier<double>? _localBlueLightFilter;
  
  // Track dragging state to prevent sync during drag
  bool _isDraggingLineSpacing = false;
  bool _isDraggingAutoScrollInterval = false;
  bool _isDraggingAutoScrollSpeed = false;
  bool _isDraggingBlueLightFilter = false;
  
  // Expandable section states (local only, no provider needed)
  ValueNotifier<bool> _expandedLineSpacing = ValueNotifier<bool>(true);
  ValueNotifier<bool> _expandedAutoScroll = ValueNotifier<bool>(true);
  ValueNotifier<bool> _expandedScreenLight = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _localLineSpacing?.dispose();
    _localAutoScrollInterval?.dispose();
    _localAutoScrollSpeed?.dispose();
    _localBlueLightFilter?.dispose();
    _expandedLineSpacing.dispose();
    _expandedAutoScroll.dispose();
    _expandedScreenLight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'সেটিংস',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Scroll Mode (Justified Alignment)
            Selector<PdfViewerProvider, bool>(
              selector: (_, p) => p.isJustified,
              builder: (context, isJustified, child) {
                final provider = context.read<PdfViewerProvider>();
                return _buildCheckOption(
                  'স্ক্রল মোড',
                  isJustified,
                  (val) => provider.setIsJustified(val),
                );
              },
            ),
            
            const Divider(height: 1),
            
            // Auto Scroll Section
            _buildExpandableSection(
              title: 'অটো স্ক্রল',
              expandedNotifier: _expandedAutoScroll,
              children: [
                const SizedBox(height: 8),
                Selector<PdfViewerProvider, double>(
                  selector: (_, p) => p.autoScrollInterval,
                  builder: (context, providerValue, child) {
                    _localAutoScrollInterval ??= ValueNotifier<double>(providerValue);
                    if (!_isDraggingAutoScrollInterval && 
                        (_localAutoScrollInterval!.value - providerValue).abs() > 0.1) {
                      _localAutoScrollInterval!.value = providerValue;
                    }
                    return _buildSlider(
                      label: 'নির্দিষ্ট সময় পর পর অটো স্ক্রল করুন',
                      valueNotifier: _localAutoScrollInterval!,
                      min: 0.0,
                      max: 60.0,
                      unit: 's',
                      onChanged: (val) {
                        _isDraggingAutoScrollInterval = true;
                        _localAutoScrollInterval!.value = val;
                      },
                      onChangeEnd: (val) {
                        _isDraggingAutoScrollInterval = false;
                        context.read<PdfViewerProvider>().setAutoScrollInterval(val);
                        
                        // If interval is set > 0, disable continuous scroll
                        if (val > 0) {
                          context.read<PdfViewerProvider>().setAutoScrollSpeed(0.0);
                        }
                        
                        // Notify parent to restart auto-scroll
                        widget.onAutoScrollSettingsChanged?.call();
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                Selector<PdfViewerProvider, double>(
                  selector: (_, p) => p.autoScrollSpeed,
                  builder: (context, providerValue, child) {
                    _localAutoScrollSpeed ??= ValueNotifier<double>(providerValue);
                    if (!_isDraggingAutoScrollSpeed && 
                        (_localAutoScrollSpeed!.value - providerValue).abs() > 0.1) {
                      _localAutoScrollSpeed!.value = providerValue;
                    }
                    return _buildSlider(
                      label: 'অবিচ্ছিন্নভাবে অটো স্ক্রল করুন',
                      valueNotifier: _localAutoScrollSpeed!,
                      min: 0.0,
                      max: 100.0,
                      unit: '%',
                      onChanged: (val) {
                        _isDraggingAutoScrollSpeed = true;
                        _localAutoScrollSpeed!.value = val;
                      },
                      onChangeEnd: (val) {
                        _isDraggingAutoScrollSpeed = false;
                        context.read<PdfViewerProvider>().setAutoScrollSpeed(val);
                        
                        // If speed is set > 0, disable interval scroll
                        if (val > 0) {
                          context.read<PdfViewerProvider>().setAutoScrollInterval(0.0);
                        }
                        
                        // Notify parent to restart auto-scroll
                        widget.onAutoScrollSettingsChanged?.call();
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Volume buttons for page change
                Selector<PdfViewerProvider, bool>(
                  selector: (_, p) => p.useVolumeButtons,
                  builder: (context, useVolumeButtons, child) {
                    final provider = context.read<PdfViewerProvider>();
                    return _buildCheckOption(
                      'পৃষ্ঠা পরিবর্তন করতে ভলিউম বাটন ব্যবহার করুন',
                      useVolumeButtons,
                      (val) => provider.setUseVolumeButtons(val),
                    );
                  },
                ),
                
                // Swipe for brightness
                Selector<PdfViewerProvider, bool>(
                  selector: (_, p) => p.enableSwipeBrightness,
                  builder: (context, enableSwipe, child) {
                    final provider = context.read<PdfViewerProvider>();
                    return _buildCheckOption(
                      'স্ক্রিনের উজ্জ্বলতা ঠিক করতে স্ক্রিনের বাম প্রান্ত সোয়াইপ করুন',
                      enableSwipe,
                      (val) => provider.setEnableSwipeBrightness(val),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Blue Light Filter
                Selector<PdfViewerProvider, double>(
                  selector: (_, p) => p.blueLightFilter,
                  builder: (context, providerValue, child) {
                    _localBlueLightFilter ??= ValueNotifier<double>(providerValue);
                    if (!_isDraggingBlueLightFilter && 
                        (_localBlueLightFilter!.value - providerValue).abs() > 0.1) {
                      _localBlueLightFilter!.value = providerValue;
                    }
                    return _buildSlider(
                      label: 'ব্লু লাইট ফিল্টার',
                      valueNotifier: _localBlueLightFilter!,
                      min: 0.0,
                      max: 100.0,
                      unit: '%',
                      onChanged: (val) {
                        _isDraggingBlueLightFilter = true;
                        _localBlueLightFilter!.value = val;
                      },
                      onChangeEnd: (val) {
                        _isDraggingBlueLightFilter = false;
                        context.read<PdfViewerProvider>().setBlueLightFilter(val);
                      },
                    );
                  },
                ),
              ],
            ),
            
            const Divider(height: 1),
            
            // Screen Light Time Section
            _buildExpandableSection(
              title: 'স্ক্রিনে আলোর সময় ঠিক করুন',
              expandedNotifier: _expandedScreenLight,
              children: [
                Selector<PdfViewerProvider, int>(
                  selector: (_, p) => p.screenLightTime,
                  builder: (context, selectedTime, child) {
                    final provider = context.read<PdfViewerProvider>();
                    return Column(
                      children: [
                        _buildTimeOption('৫ মিনিট', 5, selectedTime, provider),
                        _buildTimeOption('১০ মিনিট', 10, selectedTime, provider),
                        _buildTimeOption('১৫ মিনিট', 15, selectedTime, provider),
                        _buildTimeOption('স্ক্রিনশট নিন', 0, selectedTime, provider),
                      ],
                    );
                  },
                ),
              ],
            ),
            
            const Divider(height: 1),
            
            // Justified Alignment
            Selector<PdfViewerProvider, bool>(
              selector: (_, p) => p.isJustified,
              builder: (context, isJustified, child) {
                final provider = context.read<PdfViewerProvider>();
                return _buildCheckOption(
                  'Justified Alignment',
                  isJustified,
                  (val) => provider.setIsJustified(val),
                );
              },
            ),
            
            const Divider(height: 1),
            
            // Line Spacing Section
            _buildExpandableSection(
              title: 'লাইন ব্যবধান',
              expandedNotifier: _expandedLineSpacing,
              children: [
                Selector<PdfViewerProvider, double>(
                  selector: (_, p) => p.epubLineHeight,
                  builder: (context, providerValue, child) {
                    // Convert line height (1.0-2.5) to percentage (0-100) for display
                    final lineSpacingPercent = ((providerValue - 1.0) / 1.5 * 100).clamp(0.0, 100.0);
                    _localLineSpacing ??= ValueNotifier<double>(lineSpacingPercent);
                    if (!_isDraggingLineSpacing && 
                        (_localLineSpacing!.value - lineSpacingPercent).abs() > 0.1) {
                      _localLineSpacing!.value = lineSpacingPercent;
                    }
                    return _buildSlider(
                      valueNotifier: _localLineSpacing!,
                      min: 0.0,
                      max: 100.0,
                      unit: '%',
                      onChanged: (val) {
                        _isDraggingLineSpacing = true;
                        _localLineSpacing!.value = val;
                      },
                      onChangeEnd: (val) {
                        _isDraggingLineSpacing = false;
                        // Convert percentage back to line height (1.0-2.5)
                        final lineHeight = 1.0 + (val / 100.0 * 1.5);
                        context.read<PdfViewerProvider>().setEpubLineHeight(lineHeight.clamp(1.0, 2.5));
                      },
                    );
                  },
                ),
              ],
            ),
            
            const Divider(height: 1),
            
            // Hyphenation
            Selector<PdfViewerProvider, bool>(
              selector: (_, p) => p.hyphenation,
              builder: (context, hyphenation, child) {
                final provider = context.read<PdfViewerProvider>();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildCheckOption(
                    'Hyphenation',
                    hyphenation,
                    (val) => provider.setHyphenation(val),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required ValueNotifier<bool> expandedNotifier,
    required List<Widget> children,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: expandedNotifier,
      builder: (context, expanded, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => expandedNotifier.value = !expandedNotifier.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: expanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCheckOption(
    String label,
    bool checked,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOption(
    String label,
    int minutes,
    int selectedTime,
    PdfViewerProvider provider,
  ) {
    final isSelected = selectedTime == minutes;
    return InkWell(
      onTap: () => provider.setScreenLightTime(minutes),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    String? label,
    required ValueNotifier<double> valueNotifier,
    required double min,
    required double max,
    String? unit,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null || unit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (label != null)
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    // Text(
                    //   '${value.round()}${unit ?? ''}',
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     color: Colors.grey[600],
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                  ],
                ),
              ),
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    '${value.round()}${unit ?? ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                // const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.grey),
                  onPressed: () {
                    if (value > min) {
                      final newValue = (value - 1).clamp(min, max);
                      onChanged(newValue);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFFCD34D),
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: const Color(0xFFFCD34D),
                      overlayColor: const Color(0xFFFCD34D).withOpacity(0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      onChanged: onChanged,
                      onChangeEnd: onChangeEnd,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.grey),
                  onPressed: () {
                    if (value < max) {
                      final newValue = (value + 1).clamp(min, max);
                      onChanged(newValue);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
