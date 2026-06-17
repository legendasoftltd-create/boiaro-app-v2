// import 'package:flutter/material.dart';
// import 'package:flutter_html/flutter_html.dart';

// /// Extension to handle text-indent on paragraphs
// /// This ensures only the first line is indented, not the entire paragraph
// class EpubTextIndentExtension extends HtmlExtension {
//   @override
//   Set<String> get supportedTags => {"p"};

//   @override
//   bool matches(ExtensionContext context) {
//     // Check if paragraph has text-indent in style
//     final style = context.attributes['style'] ?? '';
//     return style.toLowerCase().contains('text-indent');
//   }

//   @override
//   InlineSpan build(ExtensionContext context) {
//     final style = context.attributes['style'] ?? '';
//     final element = context.element;
    
//     if (element == null) return const TextSpan(text: '');
    
//     // Extract text-indent value
//     final indentMatch = RegExp(r'text-indent\s*:\s*([^;]+)', caseSensitive: false).firstMatch(style);
//     if (indentMatch == null) {
//       return const TextSpan(text: '');
//     }
    
//     final indentValue = indentMatch.group(1)?.trim() ?? '';
//     final indentPx = _parseIndentValue(indentValue);
    
//     if (indentPx == null || indentPx <= 0) {
//       return const TextSpan(text: '');
//     }
    
//     // Get paragraph text content
//     final text = element.text;
//     if (text.isEmpty) return const TextSpan(text: '');
    
//     // Get text style from context
//     final textStyle = context.style?.generateTextStyle() ?? const TextStyle();
    
//     // Build RichText with first-line indentation
//     return WidgetSpan(
//       alignment: PlaceholderAlignment.baseline,
//       baseline: TextBaseline.alphabetic,
//       child: _FirstLineIndentWidget(
//         indent: indentPx,
//         text: text,
//         textStyle: textStyle,
//       ),
//     );
//   }
  
//   double? _parseIndentValue(String value) {
//     final trimmed = value.trim();
//     final match = RegExp(r'([\d.]+)(\w*)').firstMatch(trimmed);
//     if (match == null) return null;
    
//     final number = double.tryParse(match.group(1) ?? '');
//     if (number == null) return null;
    
//     final unit = match.group(2)?.toLowerCase() ?? 'px';
    
//     switch (unit) {
//       case 'px':
//         return number;
//       case 'em':
//         // Assume 1em = 16px (will be scaled by font size in context)
//         return number * 16.0;
//       case 'pt':
//         return number * 1.333;
//       default:
//         return number;
//     }
//   }
// }

// /// Widget that applies text-indent to first line only
// class _FirstLineIndentWidget extends StatelessWidget {
//   final double indent;
//   final String text;
//   final TextStyle textStyle;
  
//   const _FirstLineIndentWidget({
//     required this.indent,
//     required this.text,
//     required this.textStyle,
//   });
  
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final maxWidth = constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity;
//         final availableWidth = maxWidth - indent;
        
//         // Create a TextPainter to find where first line breaks
//         final textPainter = TextPainter(
//           text: TextSpan(text: text, style: textStyle),
//           textDirection: TextDirection.ltr,
//           maxLines: null,
//         );
        
//         textPainter.layout(maxWidth: availableWidth);
        
//         // Get line metrics to find first line break
//         final lineMetrics = textPainter.computeLineMetrics();
//         int firstLineEnd = text.length;
        
//         if (lineMetrics.isNotEmpty) {
//           // Find the character position at the end of first line
//           final firstLineHeight = lineMetrics[0].height;
          
//           // Binary search for the break point
//           int low = 0;
//           int high = text.length;
//           while (low < high) {
//             final mid = (low + high) ~/ 2;
//             final testText = text.substring(0, mid);
//             final testPainter = TextPainter(
//               text: TextSpan(text: testText, style: textStyle),
//               textDirection: TextDirection.ltr,
//             );
//             testPainter.layout(maxWidth: availableWidth);
            
//             if (testPainter.size.height <= firstLineHeight * 1.1) {
//               low = mid + 1;
//             } else {
//               high = mid;
//             }
//           }
//           firstLineEnd = low - 1;
//         }
        
//         // Split text
//         final firstLine = text.substring(0, firstLineEnd.clamp(0, text.length));
//         final restOfText = text.substring(firstLineEnd.clamp(0, text.length));
        
//         // Build RichText with first line indented
//         return RichText(
//           text: TextSpan(
//             style: textStyle,
//             children: [
//               // First line with indentation
//               WidgetSpan(
//                 child: Padding(
//                   padding: EdgeInsets.only(left: indent),
//                   child: Text(firstLine, style: textStyle),
//                 ),
//               ),
//               // Rest without indentation
//               if (restOfText.isNotEmpty)
//                 TextSpan(text: restOfText),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

