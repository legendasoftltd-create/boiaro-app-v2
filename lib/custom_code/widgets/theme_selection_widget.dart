// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '/providers/pdf_viewer_provider.dart';
// import '/flutter_flow/flutter_flow_theme.dart';
// import '/custom_code/widgets/loading_dots_widget.dart';
// import '/custom_code/widgets/pdf_viewer_helpers.dart';

// class ThemeBrightnessWidget extends StatefulWidget {
//   const ThemeBrightnessWidget({Key? key}) : super(key: key);

//   @override
//   State<ThemeBrightnessWidget> createState() => _ThemeBrightnessWidgetState();
// }

// class _ThemeBrightnessWidgetState extends State<ThemeBrightnessWidget> {
//   ValueNotifier<double>? _localBrightness;
//   bool _isDragging = false;

//   @override
//   void dispose() {
//     _localBrightness?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Selector<PdfViewerProvider, (double, AppThemeMode, bool, bool)>(
//       selector: (_, p) => (p.currentBrightness, p.currentThemeMode, p.isChangingBrightness, p.isChangingTheme),
//       builder: (context, data, child) {
//         final theme = FlutterFlowTheme.of(context);
//         final providerBrightness = data.$1;
//         final themeMode = data.$2;
//         final isChangingBrightness = data.$3;
//         final isChangingTheme = data.$4;
//         final isLoading = isChangingBrightness || isChangingTheme;
        
//         // Initialize ValueNotifier on first build
//         _localBrightness ??= ValueNotifier<double>(providerBrightness);
        
//         // Sync local value with provider only when not dragging and provider changed externally
//         if (!_isDragging && (_localBrightness!.value - providerBrightness).abs() > 0.01) {
//           _localBrightness!.value = providerBrightness;
//         }

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           child: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 200),
//             child: isLoading
//                 ? SizedBox(
//                     key: const ValueKey('loading'),
//                     height: 60,
//                     child: Center(
//                       child: LoadingDotsWidget(
//                         color: theme.primary,
//                         size: 6.0,
//                       ),
//                     ),
//                   )
//                 : Column(
//                     key: const ValueKey('content'),
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Brightness Slider Row
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                         child: Row(
//                           children: [
//                             Icon(Icons.wb_sunny_outlined, color: theme.primary, size: 22),
//                             Expanded(
//                               child: ValueListenableBuilder<double>(
//                                 valueListenable: _localBrightness!,
//                                 builder: (context, brightness, child) {
//                                   return SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 3.0,
//                                       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
//                                       overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
//                                     ),
//                                     child: Slider(
//                                       value: brightness,
//                                       onChanged: (value) {
//                                         // Update local value for smooth dragging - no provider updates
//                                         _isDragging = true;
//                                         _localBrightness!.value = value;
//                                       },
//                                       onChangeEnd: (value) {
//                                         // Apply change only when user releases - actually change screen brightness
//                                         _isDragging = false;
//                                         final provider = context.read<PdfViewerProvider>();
//                                         PdfViewerHelpers.setBrightness(provider, value);
//                                         // Sync will happen automatically on next build
//                                       },
//                                       activeColor: theme.primary,
//                                       inactiveColor: theme.alternate,
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                             Icon(Icons.wb_sunny_rounded, color: theme.primary, size: 22),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       // Theme Selection Row
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildThemeOption(
//                             context,
//                             context.read<PdfViewerProvider>(),
//                             0,
//                             AppThemeMode.light,
//                             themeMode == AppThemeMode.light,
//                             Colors.white,
//                           ),
//                           const SizedBox(width: 12),
//                           _buildThemeOption(
//                             context,
//                             context.read<PdfViewerProvider>(),
//                             1,
//                             AppThemeMode.sepia,
//                             themeMode == AppThemeMode.sepia,
//                             const Color(0xFFF5DEB3),
//                           ),
//                           const SizedBox(width: 12),
//                           _buildThemeOption(
//                             context,
//                             context.read<PdfViewerProvider>(),
//                             2,
//                             AppThemeMode.dark,
//                             themeMode == AppThemeMode.dark,
//                             Colors.black,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       // Theme labels
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildThemeLabel(context, 'Light', themeMode == AppThemeMode.light),
//                           const SizedBox(width: 32),
//                           _buildThemeLabel(context, 'Sepia', themeMode == AppThemeMode.sepia),
//                           const SizedBox(width: 32),
//                           _buildThemeLabel(context, 'Dark', themeMode == AppThemeMode.dark),
//                         ],
//                       ),
//                     ],
//                   ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildThemeOption(
//     BuildContext context,
//     PdfViewerProvider provider,
//     int index,
//     AppThemeMode mode,
//     bool isSelected,
//     Color color,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         provider.setThemeMode(mode);
//       },
//       child: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: color,
//           border: Border.all(
//             color: isSelected
//                 ? FlutterFlowTheme.of(context).primary
//                 : FlutterFlowTheme.of(context).alternate,
//             width: isSelected ? 2.5 : 1.5,
//           ),
//         ),
//         child: isSelected
//             ? Icon(
//                 Icons.check,
//                 color: mode == AppThemeMode.dark ? Colors.white : Colors.black,
//                 size: 22,
//               )
//             : null,
//       ),
//     );
//   }

//   Widget _buildThemeLabel(BuildContext context, String label, bool isSelected) {
//     final theme = FlutterFlowTheme.of(context);
//     return Text(
//       label,
//       style: theme.bodySmall.override(
//         fontFamily: 'SF Pro Display',
//         color: isSelected ? theme.primary : theme.secondaryText,
//         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//       ),
//     );
//   }
// }