import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class ThemeBrightnessWidget extends StatelessWidget {
  const ThemeBrightnessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerProvider>(
      builder: (context, provider, child) {
        final theme = FlutterFlowTheme.of(context);
        final brightness = provider.currentBrightness;
        final themeMode = provider.currentThemeMode;
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme & Brightness',
                    style: theme.titleMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      provider.setShowThemeSelectionWidget(false);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Brightness Slider Row
              Row(
                children: [
                  Icon(Icons.wb_sunny, color: theme.primary),
                  Expanded(
                    child: Slider(
                      value: brightness,
                      onChanged: (value) {
                        provider.setCurrentBrightness(value);
                      },
                      activeColor: theme.primary,
                      inactiveColor: theme.alternate,
                    ),
                  ),
                  Icon(Icons.nightlight_round, color: theme.primary),
                ],
              ),
              
              const SizedBox(height: 24),
              
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
                  const SizedBox(width: 16),
                  _buildThemeOption(
                    context,
                    provider,
                    1,
                    AppThemeMode.sepia,
                    themeMode == AppThemeMode.sepia,
                    const Color(0xFFF5DEB3),
                  ),
                  const SizedBox(width: 16),
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
              const SizedBox(height: 8),
              // Theme labels
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildThemeLabel(context, 'Light', themeMode == AppThemeMode.light),
                  const SizedBox(width: 40),
                  _buildThemeLabel(context, 'Sepia', themeMode == AppThemeMode.sepia),
                  const SizedBox(width: 40),
                  _buildThemeLabel(context, 'Dark', themeMode == AppThemeMode.dark),
                ],
              ),
            ],
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: mode == AppThemeMode.dark ? Colors.white : Colors.black,
                size: 28,
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