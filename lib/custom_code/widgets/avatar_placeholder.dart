import 'package:flutter/material.dart';

class AvatarPlaceholder extends StatelessWidget {
  final String name;
  final double size;
  final double? fontSize;

  const AvatarPlaceholder({
    Key? key,
    required this.name,
    required this.size,
    this.fontSize,
  }) : super(key: key);

  Color _getColorForName(String name) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4D96FF),
      const Color(0xFF6BCB77),
      const Color(0xFFFFD93D),
      const Color(0xFF9E77ED),
      const Color(0xFFFF8B3D),
      const Color(0xFF38BDF8),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold<int>(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }

  String _getFirstLetter(String name) {
    if (name.trim().isEmpty) return 'U';
    final trimmed = name.trim();
    return trimmed.characters.isNotEmpty 
        ? trimmed.characters.first.toUpperCase() 
        : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = _getFirstLetter(name);
    final bgColor = _getColorForName(name);
    final calculatedFontSize = fontSize ?? (size * 0.45);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: TextStyle(
          color: Colors.white,
          fontSize: calculatedFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Display',
        ),
      ),
    );
  }
}
