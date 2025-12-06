import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:html/parser.dart' as html_parser;
import '/flutter_flow/flutter_flow_theme.dart';
import '/providers/pdf_viewer_provider.dart';
import 'package:a_i_ebook_app/custom_code/extensions/epub_image_extension.dart';
import 'package:a_i_ebook_app/custom_code/extensions/epub_text_indent_extension.dart';

/// Comprehensive HTML Parser Widget
/// Handles all HTML tags with proper styling and rendering
class HtmlParserWidget extends StatelessWidget {
  final String htmlContent;
  final double fontSize;
  final double lineHeight;
  final AppThemeMode themeMode;
  final epubx.EpubBook? epubBook;
  final String fontFamily;

  const HtmlParserWidget({
    Key? key,
    required this.htmlContent,
    required this.fontSize,
    required this.lineHeight,
    required this.themeMode,
    this.epubBook,
    this.fontFamily = 'SF Pro Display',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle empty or null content
    if (htmlContent.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Preprocess HTML: Remove XML declaration and DOCTYPE, extract body with attributes
    // This handles full HTML documents while preserving body styles like text-align
    String htmlToProcess = htmlContent;
    
    // Check if this is a full HTML document
    final hasXmlDeclaration = htmlContent.trim().startsWith('<?xml');
    final hasDoctype = htmlContent.contains('<!DOCTYPE') || htmlContent.contains('<!doctype');
    final hasHtmlStructure = htmlContent.contains('<html') && htmlContent.contains('<body');
    
    if (hasHtmlStructure) {
      try {
        // Remove XML declaration if present
        if (hasXmlDeclaration) {
          final xmlEnd = htmlContent.indexOf('?>');
          if (xmlEnd != -1) {
            htmlToProcess = htmlContent.substring(xmlEnd + 2).trim();
          }
        }
        
        // Remove DOCTYPE if present
        if (hasDoctype) {
          final doctypeEnd = htmlToProcess.indexOf('>', htmlToProcess.indexOf('<!DOCTYPE') == -1 
              ? htmlToProcess.indexOf('<!doctype') 
              : htmlToProcess.indexOf('<!DOCTYPE'));
          if (doctypeEnd != -1) {
            htmlToProcess = htmlToProcess.substring(doctypeEnd + 1).trim();
          }
        }
        
        // Parse and extract body content, wrap in div with body styles
        // flutter_html doesn't handle standalone <body> tags well, so we use a div instead
        try {
          final document = html_parser.parse(htmlToProcess);
          final body = document.querySelector('body');
          if (body != null) {
            final bodyContent = body.innerHtml;
            
            // Only extract if body has content
            if (bodyContent.trim().isNotEmpty) {
              // Extract body styles and apply to a wrapper div
              final bodyStyle = body.attributes['style'] ?? '';
              
              // Add word-break CSS for Bengali and complex scripts
              // This prevents words from breaking in the middle
              final wordBreakStyle = 'word-break: normal; overflow-wrap: break-word;';
              
              if (bodyStyle.isNotEmpty) {
                // Append word-break styles to existing body styles
                final combinedStyle = bodyStyle.endsWith(';') 
                    ? '$bodyStyle $wordBreakStyle'
                    : '$bodyStyle; $wordBreakStyle';
                // Wrap content in div with body's style
                htmlToProcess = '<div style="$combinedStyle">$bodyContent</div>';
              } else {
                // No body styles, add word-break styles
                htmlToProcess = '<div style="$wordBreakStyle">$bodyContent</div>';
              }
              
              debugPrint('Body extracted successfully. Content length: ${bodyContent.length}, Final HTML length: ${htmlToProcess.length}');
            } else {
              debugPrint('Warning: Body content is empty');
            }
          } else {
            debugPrint('Warning: Body tag not found in HTML');
          }
        } catch (e) {
          debugPrint('Error extracting body: $e');
          // Keep original htmlToProcess if extraction fails
        }
      } catch (e) {
        debugPrint('Error preprocessing HTML: $e');
        // If parsing fails, try to at least remove XML/DOCTYPE
        if (hasXmlDeclaration) {
          final xmlEnd = htmlContent.indexOf('?>');
          if (xmlEnd != -1) {
            htmlToProcess = htmlContent.substring(xmlEnd + 2).trim();
          }
        }
        if (hasDoctype && htmlToProcess.contains('<!DOCTYPE')) {
          final doctypeEnd = htmlToProcess.indexOf('>', htmlToProcess.indexOf('<!DOCTYPE'));
          if (doctypeEnd != -1) {
            htmlToProcess = htmlToProcess.substring(doctypeEnd + 1).trim();
          }
        }
      }
    }
    
    // Debug: Log what we're processing
    if (htmlToProcess != htmlContent) {
      debugPrint('Extracted body from full HTML document. Body length: ${htmlToProcess.length}');
      debugPrint('Body preview: ${htmlToProcess.length > 200 ? htmlToProcess.substring(0, 200) : htmlToProcess}');
    }
    
    final (bgColor, txtColor) = _getThemeColors();
    final cssStyles = _parseCssFromHtml(htmlToProcess);
    
    // Preprocess HTML to convert inline-block indentation spans to padding
    final htmlWithIndentation = _convertInlineBlockIndentation(htmlToProcess, fontSize);
    
    // Preprocess HTML to apply CSS classes as inline styles
    final processedHtml = _applyCssClassesToHtml(
      htmlWithIndentation, 
      cssStyles, 
      fontSize,
      baseLineHeight: lineHeight,
    );

    // Debug: Log processed HTML
    debugPrint('Processed HTML length: ${processedHtml.length}');
    if (processedHtml.length > 200) {
      debugPrint('Processed HTML preview: ${processedHtml.substring(0, 200)}...');
    } else {
      debugPrint('Processed HTML: $processedHtml');
    }

    // Ensure processed HTML is not empty
    if (processedHtml.isEmpty || processedHtml.trim().isEmpty) {
      debugPrint('Warning: Processed HTML is empty after processing.');
      debugPrint('Original length: ${htmlContent.length}, htmlToProcess length: ${htmlToProcess.length}');
      debugPrint('htmlToProcess preview: ${htmlToProcess.length > 300 ? htmlToProcess.substring(0, 300) : htmlToProcess}');
      // Return original HTML if processing removed everything
      return Html(
        data: htmlContent,
        style: _buildHtmlStyles(context, fontSize, lineHeight, txtColor, bgColor, cssStyles),
        extensions: _buildExtensions(context),
      );
    }

    // Wrap in error boundary to catch rendering errors
    return Builder(
      builder: (context) {
        try {
          // Ensure we have valid HTML to render
          final htmlToRender = processedHtml.trim().isNotEmpty ? processedHtml : htmlToProcess;
          
          if (htmlToRender.trim().isEmpty) {
            debugPrint('Error: All HTML processing resulted in empty content');
            return Center(
              child: Text(
                'No content to display',
                style: TextStyle(color: txtColor),
              ),
            );
          }
          
          debugPrint('Rendering HTML widget with ${htmlToRender.length} characters');
          debugPrint('HTML to render preview: ${htmlToRender.length > 300 ? htmlToRender.substring(0, 300) : htmlToRender}');
          
          return Html(
            data: htmlToRender,
            style: _buildHtmlStyles(context, fontSize, lineHeight, txtColor, bgColor, cssStyles),
            extensions: _buildExtensions(context),
          );
        } catch (e, stackTrace) {
          debugPrint('Error rendering HTML: $e');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('Processed HTML length: ${processedHtml.length}');
          debugPrint('htmlToProcess length: ${htmlToProcess.length}');
          debugPrint('Original HTML length: ${htmlContent.length}');
          debugPrint('Processed HTML preview: ${processedHtml.length > 200 ? processedHtml.substring(0, 200) : processedHtml}');
          
          // Fallback: try rendering htmlToProcess (before CSS processing)
          try {
            if (htmlToProcess.trim().isNotEmpty) {
              return Html(
                data: htmlToProcess,
                style: _buildHtmlStyles(context, fontSize, lineHeight, txtColor, bgColor, cssStyles),
                extensions: _buildExtensions(context),
              );
            }
          } catch (e2) {
            debugPrint('Error rendering htmlToProcess: $e2');
          }
          
          // Final fallback: try rendering original HTML
          try {
            return Html(
              data: htmlContent,
              style: _buildHtmlStyles(context, fontSize, lineHeight, txtColor, bgColor, cssStyles),
              extensions: _buildExtensions(context),
            );
          } catch (e3) {
            debugPrint('Error rendering fallback HTML: $e3');
            return Center(
              child: Text(
                'Error rendering content',
                style: TextStyle(color: txtColor),
              ),
            );
          }
        }
      },
    );
  }

  /// Get theme colors based on theme mode
  (Color, Color) _getThemeColors() {
    Color bgColor;
    Color txtColor;
    
    switch (themeMode) {
      case AppThemeMode.light:
        bgColor = Colors.white;
        txtColor = Colors.black;
        break;
      case AppThemeMode.dark:
        bgColor = Colors.black;
        txtColor = Colors.white;
        break;
      case AppThemeMode.sepia:
        bgColor = const Color(0xFFF5DEB3);
        txtColor = Colors.black;
        break;
    }
    
    return (bgColor, txtColor);
  }

  /// Build comprehensive HTML styles for all tags
  Map<String, Style> _buildHtmlStyles(
    BuildContext context,
    double fontSize,
    double lineHeight,
    Color txtColor,
    Color bgColor,
    Map<String, Map<String, String>> cssStyles,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final styles = <String, Style>{};
    
    // Add base tag styles
    styles.addAll({
      // Document structure
      "html": Style(
        fontSize: FontSize(fontSize),
        color: txtColor,
        backgroundColor: bgColor,
      ),
      "body": Style(
        fontFamily: fontFamily,
        fontSize: FontSize(fontSize),
        letterSpacing: 0.3,
        lineHeight: LineHeight.em(lineHeight),
        textAlign: TextAlign.justify,
        color: txtColor,
        backgroundColor: bgColor,
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        // Add word-break handling for Bengali and complex scripts
        // This prevents words from breaking in the middle
      ),
      "div": Style(
        color: txtColor,
        // Don't set margin - allow inline styles (like text-align) to work
        // margin: Margins.only(bottom: 8),
      ),
      "span": Style(
        color: txtColor,
        fontSize: FontSize(fontSize),
        lineHeight: LineHeight.em(lineHeight),
      ),
      "section": Style(
        color: txtColor,
        margin: Margins.only(bottom: 16),
      ),
      "article": Style(
        color: txtColor,
        margin: Margins.only(bottom: 16),
      ),
      "header": Style(
        color: txtColor,
        margin: Margins.only(bottom: 16),
      ),
      "footer": Style(
        color: txtColor,
        margin: Margins.only(top: 16),
      ),
      "nav": Style(
        color: txtColor,
      ),
      "main": Style(
        color: txtColor,
      ),
      "aside": Style(
        color: txtColor,
        fontStyle: FontStyle.italic,
      ),

      // Headings
      "h1": Style(
        fontSize: FontSize(fontSize * 1.8),
        fontWeight: FontWeight.bold,
        color: txtColor,
        margin: Margins.only(bottom: 16, top: 24),
      ),
      "h2": Style(
        fontSize: FontSize(fontSize * 1.6),
        fontWeight: FontWeight.bold,
        color: txtColor,
        margin: Margins.only(bottom: 14, top: 20),
      ),
      "h3": Style(
        fontSize: FontSize(fontSize * 1.4),
        fontWeight: FontWeight.bold,
        color: txtColor,
        margin: Margins.only(bottom: 12, top: 18),
      ),
      "h4": Style(
        fontSize: FontSize(fontSize * 1.2),
        fontWeight: FontWeight.bold,
        color: txtColor,
        margin: Margins.only(bottom: 10, top: 16),
      ),
      "h5": Style(
        fontSize: FontSize(fontSize * 1.1),
        fontWeight: FontWeight.bold,
        color: txtColor,
        margin: Margins.only(bottom: 8, top: 14),
      ),
      "h6": Style(
        fontSize: FontSize(fontSize),
        fontWeight: FontWeight.bold,
        color: txtColor,
        margin: Margins.only(bottom: 6, top: 12),
      ),

      // Text formatting
      "p": Style(
        margin: Margins.only(bottom: 12),
        // Don't set padding to zero - allow inline styles to work
        // padding: HtmlPaddings.zero, // Removed to allow inline padding-left
        color: txtColor,
        fontSize: FontSize(fontSize),
        lineHeight: LineHeight.em(lineHeight),
      ),
      // Ensure paragraphs with mark tags don't create gaps
      "p mark": Style(
        // Inherit line-height from paragraph to maintain consistent spacing
        padding: HtmlPaddings.zero,
        margin: Margins.zero,
        verticalAlign: VerticalAlign.baseline,
      ),
      "br": Style(
        height: Height(lineHeight),
      ),
      "strong": Style(
        fontWeight: FontWeight.bold,
        color: txtColor,
      ),
      "b": Style(
        fontWeight: FontWeight.bold,
        color: txtColor,
      ),
      "em": Style(
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),
      "i": Style(
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),
      "u": Style(
        textDecoration: TextDecoration.underline,
        color: txtColor,
      ),
      "s": Style(
        textDecoration: TextDecoration.lineThrough,
        color: txtColor,
      ),
      "del": Style(
        textDecoration: TextDecoration.lineThrough,
        color: txtColor,
      ),
      "ins": Style(
        textDecoration: TextDecoration.underline,
        color: txtColor,
      ),
      "mark": Style(
        backgroundColor: Colors.yellow.withOpacity(0.3),
        color: txtColor,
        // Don't override line-height - inherit from parent to avoid gaps
        padding: HtmlPaddings.zero, // Remove padding
        margin: Margins.zero, // Remove margin
        display: Display.inline, // Ensure inline display
        verticalAlign: VerticalAlign.baseline, // Align to baseline
      ),
      "mark.search-result": Style( // Search result highlights (brighter yellow)
        backgroundColor: const Color(0xFFFFEB3B).withOpacity(0.5),
        color: txtColor,
        // lineHeight will inherit from parent automatically
        padding: HtmlPaddings.zero,
        margin: Margins.zero,
        display: Display.inline,
        verticalAlign: VerticalAlign.baseline,
      ),
      // Override styles for spans inside mark tags to prevent gaps
      "mark span": Style(
        // Inherit line-height from parent paragraph, don't override
        padding: HtmlPaddings.zero,
        margin: Margins.zero,
        verticalAlign: VerticalAlign.baseline,
      ),
      "small": Style(
        fontSize: FontSize(fontSize * 0.85),
        color: txtColor,
      ),
      "sub": Style(
        fontSize: FontSize(fontSize * 0.75),
        verticalAlign: VerticalAlign.sub,
        color: txtColor,
      ),
      "sup": Style(
        fontSize: FontSize(fontSize * 0.75),
        verticalAlign: VerticalAlign.sup,
        color: txtColor,
      ),
      "code": Style(
        fontFamily: 'monospace',
        backgroundColor: theme.alternate.withOpacity(0.1),
        padding: HtmlPaddings.all(4),
        color: txtColor,
      ),
      "pre": Style(
        fontFamily: 'monospace',
        backgroundColor: theme.alternate.withOpacity(0.1),
        padding: HtmlPaddings.all(12),
        margin: Margins.only(bottom: 16),
        whiteSpace: WhiteSpace.pre,
        color: txtColor,
      ),
      "kbd": Style(
        fontFamily: 'monospace',
        backgroundColor: theme.alternate.withOpacity(0.2),
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
        color: txtColor,
      ),
      "samp": Style(
        fontFamily: 'monospace',
        color: txtColor,
      ),
      "var": Style(
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),
      "abbr": Style(
        textDecoration: TextDecoration.underline,
        textDecorationStyle: TextDecorationStyle.dotted,
        color: txtColor,
      ),
      "dfn": Style(
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),
      "cite": Style(
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),
      "q": Style(
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),
      "blockquote": Style(
        border: Border(
          left: BorderSide(
            color: theme.alternate,
            width: 4,
          ),
        ),
        padding: HtmlPaddings.only(left: 16),
        margin: Margins.only(left: 16, top: 16, bottom: 16),
        fontStyle: FontStyle.italic,
        color: txtColor,
      ),

      // Lists
      "ul": Style(
        listStyleType: ListStyleType.disc,
        margin: Margins.only(left: 20, top: 8, bottom: 8),
        padding: HtmlPaddings.zero,
        color: txtColor,
      ),
      "ol": Style(
        listStyleType: ListStyleType.decimal,
        margin: Margins.only(left: 20, top: 8, bottom: 8),
        padding: HtmlPaddings.zero,
        color: txtColor,
      ),
      "li": Style(
        margin: Margins.only(bottom: 8),
        color: txtColor,
      ),
      "dl": Style(
        margin: Margins.only(top: 8, bottom: 8),
        color: txtColor,
      ),
      "dt": Style(
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 8),
        color: txtColor,
      ),
      "dd": Style(
        margin: Margins.only(left: 20, bottom: 8),
        color: txtColor,
      ),

      // Links
      "a": Style(
        color: theme.primary,
        textDecoration: TextDecoration.underline,
      ),

      // Tables
      "table": Style(
        backgroundColor: theme.alternate.withOpacity(0.1),
        border: Border.all(color: theme.alternate),
        width: Width.auto(),
        margin: Margins.only(bottom: 16),
        color: txtColor,
      ),
      "thead": Style(
        backgroundColor: theme.alternate.withOpacity(0.2),
        color: txtColor,
      ),
      "tbody": Style(
        color: txtColor,
      ),
      "tfoot": Style(
        backgroundColor: theme.alternate.withOpacity(0.1),
        color: txtColor,
      ),
      "tr": Style(
        border: Border(
          bottom: BorderSide(color: theme.alternate),
        ),
        color: txtColor,
      ),
      "th": Style(
        padding: HtmlPaddings.all(8),
        backgroundColor: theme.alternate,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.center,
        color: txtColor,
      ),
      "td": Style(
        padding: HtmlPaddings.all(8),
        border: Border(
          right: BorderSide(color: theme.alternate),
        ),
        color: txtColor,
      ),
      "caption": Style(
        textAlign: TextAlign.center,
        fontStyle: FontStyle.italic,
        margin: Margins.only(top: 8),
        color: txtColor,
      ),
      "colgroup": Style(
        color: txtColor,
      ),
      "col": Style(
        color: txtColor,
      ),

      // Media
      "img": Style(
        width: Width.auto(),
        height: Height.auto(),
        margin: Margins.symmetric(vertical: 10),
      ),
      "figure": Style(
        margin: Margins.only(top: 16, bottom: 16),
        color: txtColor,
      ),
      "figcaption": Style(
        fontStyle: FontStyle.italic,
        textAlign: TextAlign.center,
        margin: Margins.only(top: 8),
        fontSize: FontSize(fontSize * 0.9),
        color: txtColor,
      ),

      // Semantic elements
      "address": Style(
        fontStyle: FontStyle.italic,
        margin: Margins.only(bottom: 16),
        color: txtColor,
      ),
      "time": Style(
        color: txtColor,
      ),
      "details": Style(
        margin: Margins.only(bottom: 16),
        color: txtColor,
      ),
      "summary": Style(
        fontWeight: FontWeight.bold,
        color: txtColor,
      ),

      // Horizontal rule
      "hr": Style(
        border: Border(
          top: BorderSide(
            color: theme.alternate,
            width: 1,
          ),
        ),
        margin: Margins.symmetric(vertical: 16),
      ),

      // Form elements (if present in EPUB)
      "form": Style(
        margin: Margins.only(bottom: 16),
        color: txtColor,
      ),
      "input": Style(
        color: txtColor,
      ),
      "button": Style(
        color: txtColor,
      ),
      "label": Style(
        color: txtColor,
      ),
      "textarea": Style(
        color: txtColor,
      ),
      "select": Style(
        color: txtColor,
      ),
      "option": Style(
        color: txtColor,
      ),

      // Other elements
      "iframe": Style(
        width: Width.auto(),
        height: Height.auto(),
      ),
      "embed": Style(
        width: Width.auto(),
        height: Height.auto(),
      ),
      "object": Style(
        width: Width.auto(),
        height: Height.auto(),
      ),
      "video": Style(
        width: Width.auto(),
        height: Height.auto(),
      ),
      "audio": Style(
        width: Width.auto(),
      ),
      "source": Style(),
      "track": Style(),
      "canvas": Style(
        width: Width.auto(),
        height: Height.auto(),
      ),
      "svg": Style(
        width: Width.auto(),
        height: Height.auto(),
      ),
      "path": Style(),
      "circle": Style(),
      "rect": Style(),
      "line": Style(),
      "polyline": Style(),
      "polygon": Style(),
      "ellipse": Style(),
      "text": Style(
        color: txtColor,
      ),
      "tspan": Style(
        color: txtColor,
      ),
    });

    // Add CSS class-based styles
    for (final entry in cssStyles.entries) {
      final className = entry.key;
      final cssProps = entry.value;
      
      // Create style from CSS properties
      final style = _cssPropsToStyle(
        cssProps, 
        fontSize, 
        txtColor, 
        bgColor, 
        theme,
        baseLineHeight: lineHeight,
      );
      if (style != null) {
        // Use class selector format (e.g., ".c2")
        styles[".$className"] = style;
      }
    }
    
    return styles;
  }

  /// Convert CSS properties to Style object
  Style? _cssPropsToStyle(
    Map<String, String> cssProps,
    double baseFontSize,
    Color defaultColor,
    Color defaultBgColor,
    FlutterFlowTheme theme, {
    double? baseLineHeight,
  }) {
    Style? style;
    
    // Handle text-indent (convert to padding-left)
    if (cssProps.containsKey('text-indent')) {
      final indentValue = _convertCssSize(cssProps['text-indent']!, baseFontSize);
      if (indentValue != null) {
        style = (style ?? Style()).copyWith(
          padding: HtmlPaddings.only(left: indentValue),
        );
      }
    }
    
    // Handle font-size - make it relative to user's base font size
    // CSS font sizes should scale proportionally with user's font size preference
    if (cssProps.containsKey('font-size')) {
      final cssFontSize = cssProps['font-size']!.trim();
      double? fontSizeValue;
      
      // Parse the CSS font size
      final match = RegExp(r'([\d.]+)(\w*)').firstMatch(cssFontSize);
      if (match != null) {
        final number = double.tryParse(match.group(1) ?? '');
        final unit = match.group(2)?.toLowerCase() ?? '';
        
        if (number != null && number > 0) {
          // Calculate the ratio relative to a base (assume 12pt = 16px default)
          double cssBaseSize;
          if (unit == 'pt') {
            cssBaseSize = number * 1.333; // Convert pt to px
          } else if (unit == 'px') {
            cssBaseSize = number;
          } else if (unit == 'em' || unit == 'rem') {
            cssBaseSize = number * 16.0; // Assume 1em = 16px default
          } else {
            cssBaseSize = number; // Assume pixels
          }
          
          // Calculate scale factor: how much larger/smaller is the CSS size compared to default 16px
          final scaleRatio = cssBaseSize / 16.0;
          
          // Apply this ratio to the user's current font size preference
          fontSizeValue = baseFontSize * scaleRatio;
        }
      }
      
      if (fontSizeValue != null && fontSizeValue > 0) {
        style = (style ?? Style()).copyWith(
          fontSize: FontSize(fontSizeValue),
        );
      }
    }
    
    // Handle text-align
    if (cssProps.containsKey('text-align')) {
      final align = cssProps['text-align']!.trim();
      TextAlign? textAlign;
      switch (align) {
        case 'left':
          textAlign = TextAlign.left;
          break;
        case 'right':
          textAlign = TextAlign.right;
          break;
        case 'center':
          textAlign = TextAlign.center;
          break;
        case 'justify':
          textAlign = TextAlign.justify;
          break;
      }
      if (textAlign != null) {
        style = (style ?? Style()).copyWith(textAlign: textAlign);
      }
    }
    
    // Handle color
    if (cssProps.containsKey('color')) {
      final color = _parseCssColor(cssProps['color']!);
      if (color != null) {
        style = (style ?? Style()).copyWith(color: color);
      }
    }
    
    // Handle background-color
    if (cssProps.containsKey('background-color')) {
      final bgColor = _parseCssColor(cssProps['background-color']!);
      if (bgColor != null) {
        style = (style ?? Style()).copyWith(backgroundColor: bgColor);
      }
    }
    
    // Handle font-weight
    if (cssProps.containsKey('font-weight')) {
      final weight = cssProps['font-weight']!.trim();
      FontWeight? fontWeight;
      if (weight == 'bold' || weight == '700') {
        fontWeight = FontWeight.bold;
      } else if (weight == 'normal' || weight == '400') {
        fontWeight = FontWeight.normal;
      } else {
        final weightValue = int.tryParse(weight);
        if (weightValue != null) {
          fontWeight = FontWeight.values.firstWhere(
            (w) => w.value == weightValue,
            orElse: () => FontWeight.normal,
          );
        }
      }
      if (fontWeight != null) {
        style = (style ?? Style()).copyWith(fontWeight: fontWeight);
      }
    }
    
    // Handle font-style
    if (cssProps.containsKey('font-style')) {
      final fontStyle = cssProps['font-style']!.trim();
      if (fontStyle == 'italic') {
        style = (style ?? Style()).copyWith(fontStyle: FontStyle.italic);
      } else if (fontStyle == 'normal') {
        style = (style ?? Style()).copyWith(fontStyle: FontStyle.normal);
      }
    }
    
    // Handle font-family
    if (cssProps.containsKey('font-family')) {
      final fontFamily = cssProps['font-family']!
          .replaceAll('"', '')
          .replaceAll("'", '')
          .split(',')
          .first
          .trim();
      style = (style ?? Style()).copyWith(fontFamily: fontFamily);
    }
    
    // Handle line-height - make it relative to user's line spacing preference
    if (cssProps.containsKey('line-height')) {
      final cssLineHeight = cssProps['line-height']!.trim();
      double? lineHeightValue;
      
      if (cssLineHeight.contains('em')) {
        // For em values, use the CSS value but scale it relative to user's preference
        final emValue = double.tryParse(cssLineHeight.replaceAll('em', '').trim());
        if (emValue != null && baseLineHeight != null) {
          // Scale the CSS em value relative to user's line height preference
          // If CSS says 1.15em and user wants 1.6, scale accordingly
          final scaleFactor = baseLineHeight / 1.5; // 1.5 is a typical default
          lineHeightValue = emValue * scaleFactor;
        } else if (emValue != null) {
          lineHeightValue = emValue;
        }
      } else {
        // For px/pt values, convert and scale relative to user's preference
        final pxValue = _convertCssSize(cssLineHeight, baseFontSize);
        if (pxValue != null && baseLineHeight != null) {
          // Calculate the ratio: CSS line-height in pixels relative to font size
          final cssRatio = pxValue / baseFontSize;
          // Apply user's line height preference
          lineHeightValue = baseLineHeight * (cssRatio / 1.5); // 1.5 is typical default
        } else if (pxValue != null) {
          // Fallback: use CSS value directly
          lineHeightValue = pxValue / baseFontSize;
        }
      }
      
      if (lineHeightValue != null && lineHeightValue > 0) {
        style = (style ?? Style()).copyWith(
          lineHeight: LineHeight.em(lineHeightValue),
        );
      }
    }
    
    // Handle padding
    double? paddingTop, paddingBottom, paddingLeft, paddingRight;
    if (cssProps.containsKey('padding-top')) {
      paddingTop = _convertCssSize(cssProps['padding-top']!, baseFontSize);
    }
    if (cssProps.containsKey('padding-bottom')) {
      paddingBottom = _convertCssSize(cssProps['padding-bottom']!, baseFontSize);
    }
    if (cssProps.containsKey('padding-left')) {
      paddingLeft = _convertCssSize(cssProps['padding-left']!, baseFontSize);
    }
    if (cssProps.containsKey('padding-right')) {
      paddingRight = _convertCssSize(cssProps['padding-right']!, baseFontSize);
    }
    if (paddingTop != null || paddingBottom != null || paddingLeft != null || paddingRight != null) {
      style = (style ?? Style()).copyWith(
        padding: HtmlPaddings.only(
          top: paddingTop ?? 0,
          bottom: paddingBottom ?? 0,
          left: paddingLeft ?? 0,
          right: paddingRight ?? 0,
        ),
      );
    }
    
    // Handle vertical-align
    if (cssProps.containsKey('vertical-align')) {
      final align = cssProps['vertical-align']!.trim();
      if (align == 'super') {
        style = (style ?? Style()).copyWith(verticalAlign: VerticalAlign.sup);
      } else if (align == 'sub') {
        style = (style ?? Style()).copyWith(verticalAlign: VerticalAlign.sub);
      }
    }
    
    return style;
  }

  /// Parse CSS color to Color object
  Color? _parseCssColor(String colorStr) {
    final trimmed = colorStr.trim();
    
    // Hex color
    if (trimmed.startsWith('#')) {
      return _hexToColor(trimmed);
    }
    
    // RGB/RGBA
    if (trimmed.startsWith('rgb')) {
      return _rgbToColor(trimmed);
    }
    
    // Named colors
    final namedColors = {
      'black': Colors.black,
      'white': Colors.white,
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'yellow': Colors.yellow,
      'cyan': Colors.cyan,
      'magenta': const Color(0xFFFF00FF),
      'gray': Colors.grey,
      'grey': Colors.grey,
    };
    
    return namedColors[trimmed.toLowerCase()];
  }

  /// Convert hex color to Color
  Color? _hexToColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (hexCode.length == 8) {
        return Color(int.parse(hexCode, radix: 16));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Convert RGB color to Color
  Color? _rgbToColor(String rgb) {
    try {
      final match = RegExp(r'rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)')
          .firstMatch(rgb);
      if (match != null) {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        final a = match.group(4) != null
            ? double.parse(match.group(4)!)
            : 1.0;
        return Color.fromRGBO(r, g, b, a);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Convert CSS size (pt, px, em, etc.) to pixels
  double? _convertCssSize(String value, double baseFontSize) {
    if (value.isEmpty) return null;
    
    final trimmed = value.trim();
    
    // Handle zero
    if (trimmed == '0' || trimmed == '0pt' || trimmed == '0px') {
      return 0.0;
    }
    
    // Extract number and unit
    final match = RegExp(r'([\d.]+)(\w*)').firstMatch(trimmed);
    if (match == null) return null;
    
    final number = double.tryParse(match.group(1) ?? '');
    if (number == null) return null;
    
    final unit = match.group(2)?.toLowerCase() ?? '';
    
    switch (unit) {
      case 'pt':
        // 1pt = 1.333px (approximately, at 96 DPI)
        return number * 1.333;
      case 'px':
        return number;
      case 'em':
        return number * baseFontSize;
      case 'rem':
        return number * baseFontSize;
      case '%':
        return (number / 100) * baseFontSize;
      default:
        // Assume pixels if no unit
        return number;
    }
  }

  /// Parse CSS from HTML style tag
  Map<String, Map<String, String>> _parseCssFromHtml(String html) {
    final cssMap = <String, Map<String, String>>{};
    
    try {
      final document = html_parser.parse(html);
      final styleElements = document.querySelectorAll('style');
      
      for (final styleElement in styleElements) {
        final cssText = styleElement.text;
        if (cssText.isEmpty) continue;
        
        // Parse CSS rules
        final rules = _parseCssRules(cssText);
        cssMap.addAll(rules);
      }
    } catch (e) {
      // If parsing fails, return empty map
      debugPrint('Error parsing CSS: $e');
    }
    
    return cssMap;
  }

  /// Parse CSS rules from CSS text
  Map<String, Map<String, String>> _parseCssRules(String cssText) {
    final cssMap = <String, Map<String, String>>{};
    
    // Remove @import and comments
    String cleanedCss = cssText
        .replaceAll(RegExp(r'@import[^;]+;'), '')
        .replaceAll(RegExp(r'/\*[^*]*\*+(?:[^/*][^*]*\*+)*/'), '');
    
    // Match CSS rules: selector { properties }
    final rulePattern = RegExp(r'([^{]+)\{([^}]+)\}');
    final matches = rulePattern.allMatches(cleanedCss);
    
    for (final match in matches) {
      final selector = match.group(1)?.trim() ?? '';
      final properties = match.group(2)?.trim() ?? '';
      
      if (selector.isEmpty || properties.isEmpty) continue;
      
      // Parse properties
      final props = <String, String>{};
      final propPattern = RegExp(r'([^:]+):([^;]+);?');
      final propMatches = propPattern.allMatches(properties);
      
      for (final propMatch in propMatches) {
        final key = propMatch.group(1)?.trim() ?? '';
        final value = propMatch.group(2)?.trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          props[key] = value;
        }
      }
      
      if (props.isNotEmpty) {
        // Handle multiple selectors (comma-separated)
        final selectors = selector.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        for (final sel in selectors) {
          // Remove leading dot for class selectors
          final normalizedSelector = sel.startsWith('.') ? sel.substring(1) : sel;
          if (normalizedSelector.isNotEmpty) {
            if (cssMap.containsKey(normalizedSelector)) {
              // Merge with existing styles
              cssMap[normalizedSelector]!.addAll(props);
            } else {
              cssMap[normalizedSelector] = props;
            }
          }
        }
      }
    }
    
    return cssMap;
  }


  /// Apply CSS classes to HTML elements as inline styles
  String _applyCssClassesToHtml(
    String html,
    Map<String, Map<String, String>> cssStyles,
    double baseFontSize, {
    double? baseLineHeight,
  }) {
    if (cssStyles.isEmpty) return html;
    
    try {
      final document = html_parser.parse(html);
      
      // Find all elements with classes
      final elements = document.querySelectorAll('[class]');
      
      for (final element in elements) {
        final classes = element.classes;
        final inlineStyles = <String, String>{};
        
        // Apply styles from each class
        for (final className in classes) {
          final cssProps = cssStyles[className];
          if (cssProps != null) {
            // Convert CSS properties to inline style format
            for (final entry in cssProps.entries) {
              final key = entry.key;
              final value = entry.value;
              
              // Handle font-size - make it relative to user's base font size
              if (key == 'font-size') {
                final fontSizeValue = _convertCssSizeToRelative(value, baseFontSize);
                if (fontSizeValue != null) {
                  inlineStyles['font-size'] = '${fontSizeValue}px';
                }
              } else if (key == 'line-height') {
                // Handle line-height - make it relative to user's line spacing preference
                final lineHeightValue = _convertCssLineHeightToRelative(
                  value, 
                  baseFontSize, 
                  baseLineHeight ?? 1.6,
                );
                if (lineHeightValue != null) {
                  inlineStyles['line-height'] = '${lineHeightValue}em';
                }
              } else if (key == 'text-indent') {
                // Convert text-indent to padding-left
                final indentValue = _convertCssSize(value, baseFontSize);
                if (indentValue != null) {
                  inlineStyles['padding-left'] = '${indentValue}px';
                }
              } else {
                // Pass through other CSS properties
                inlineStyles[key] = value;
              }
            }
          }
        }
        
        // Apply inline styles to element
        if (inlineStyles.isNotEmpty) {
          final existingStyle = element.attributes['style'] ?? '';
          final newStyle = inlineStyles.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('; ');
          
          // Add word-break handling for Bengali and complex scripts on paragraphs
          final wordBreakStyle = 'word-break: normal; overflow-wrap: break-word;';
          final finalStyle = existingStyle.isNotEmpty
              ? '$existingStyle; $newStyle; $wordBreakStyle'
              : '$newStyle; $wordBreakStyle';
          
          element.attributes['style'] = finalStyle;
        } else {
          // Even if no CSS classes, add word-break for paragraphs and divs
          final tagName = element.localName?.toLowerCase() ?? '';
          if (tagName == 'p' || tagName == 'div') {
            final existingStyle = element.attributes['style'] ?? '';
            final wordBreakStyle = 'word-break: normal; overflow-wrap: break-word;';
            if (existingStyle.isNotEmpty) {
              element.attributes['style'] = '$existingStyle; $wordBreakStyle';
            } else {
              element.attributes['style'] = wordBreakStyle;
            }
          }
        }
      }
      
      return document.outerHtml;
    } catch (e) {
      debugPrint('Error applying CSS classes: $e');
      return html; // Return original HTML if processing fails
    }
  }

  /// Convert CSS line-height to relative size based on user's line spacing preference
  double? _convertCssLineHeightToRelative(
    String cssLineHeight,
    double baseFontSize,
    double baseLineHeight,
  ) {
    final trimmed = cssLineHeight.trim();
    
    // Handle em values
    if (trimmed.contains('em')) {
      final emValue = double.tryParse(trimmed.replaceAll('em', '').trim());
      if (emValue != null) {
        // Scale the CSS em value relative to user's line height preference
        final scaleFactor = baseLineHeight / 1.5; // 1.5 is a typical default
        return emValue * scaleFactor;
      }
    }
    
    // Handle px/pt values
    final pxValue = _convertCssSize(trimmed, baseFontSize);
    if (pxValue != null) {
      // Calculate the ratio: CSS line-height in pixels relative to font size
      final cssRatio = pxValue / baseFontSize;
      // Apply user's line height preference
      return baseLineHeight * (cssRatio / 1.5); // 1.5 is typical default
    }
    
    return null;
  }

  /// Convert CSS font size to relative size based on user's base font size
  double? _convertCssSizeToRelative(String cssSize, double baseFontSize) {
    final match = RegExp(r'([\d.]+)(\w*)').firstMatch(cssSize.trim());
    if (match == null) return null;
    
    final number = double.tryParse(match.group(1) ?? '');
    final unit = match.group(2)?.toLowerCase() ?? '';
    
    if (number == null || number <= 0) return null;
    
    // Calculate the ratio relative to a base (assume 12pt = 16px default)
    double cssBaseSize;
    if (unit == 'pt') {
      cssBaseSize = number * 1.333; // Convert pt to px
    } else if (unit == 'px') {
      cssBaseSize = number;
    } else if (unit == 'em' || unit == 'rem') {
      cssBaseSize = number * 16.0; // Assume 1em = 16px default
    } else {
      cssBaseSize = number; // Assume pixels
    }
    
    // Calculate scale factor: how much larger/smaller is the CSS size compared to default 16px
    final scaleRatio = cssBaseSize / 16.0;
    
    // Apply this ratio to the user's current font size preference
    return baseFontSize * scaleRatio;
  }

  /// Convert inline-block indentation spans to paragraph padding-left
  /// This handles patterns like: <p><span style="display:inline-block; width:2em;"> </span>text...</p>
  String _convertInlineBlockIndentation(String html, double baseFontSize) {
    try {
      // Skip processing if HTML is empty or too short
      if (html.isEmpty || html.length < 10) {
        return html;
      }
      
      // Use regex-based approach for more reliable matching
      // Pattern: <p><span style="...display:inline-block...width:Xem..."> </span>
      // Handle both single and double quotes, and various spacing
      // More flexible pattern that handles different HTML formatting
      final pattern = RegExp(
        r'<p([^>]*)>\s*<span\s+style\s*=\s*["'']([^"'']*display\s*:\s*inline-block[^"'']*width\s*:\s*([^;"'']+)[^"'']*)["''][^>]*>\s*(?:&nbsp;|\u00A0|[\s\u00A0])*</span>',
        caseSensitive: false,
        dotAll: true,
      );
      
      final matches = pattern.allMatches(html);
      if (matches.isEmpty) {
        return html;
      }
      
      final result = html.replaceAllMapped(pattern, (match) {
        final pAttributes = match.group(1) ?? '';
        final widthValue = match.group(3)?.trim() ?? '';
        if (widthValue.isEmpty) {
          return match.group(0)!;
        }
        
        // Convert width to text-indent
        final paddingValue = _convertCssSize(widthValue, baseFontSize);
        
        if (paddingValue == null || paddingValue <= 0) {
          return match.group(0)!;
        }
        
        // Build new paragraph tag with text-indent (only first line, not entire paragraph)
        String newPAttributes = pAttributes;
        final indentStyle = 'text-indent: ${paddingValue}px';
        
        // Check if paragraph already has a style attribute (handle both single and double quotes)
        final styleMatchDouble = RegExp(r'style\s*=\s*"([^"]*)"', caseSensitive: false).firstMatch(pAttributes);
        final styleMatchSingle = RegExp(r"style\s*=\s*'([^']*)'", caseSensitive: false).firstMatch(pAttributes);
        final styleMatch = styleMatchDouble ?? styleMatchSingle;
        
        if (styleMatch != null) {
          // Append text-indent to existing style
          final existingStyle = styleMatch.group(1) ?? '';
          final quote = styleMatchDouble != null ? '"' : "'";
          
          if (existingStyle.contains('text-indent')) {
            // Replace existing text-indent
            newPAttributes = pAttributes.replaceAll(
              RegExp(r'text-indent\s*:\s*[^;]+', caseSensitive: false),
              indentStyle,
            );
          } else {
            newPAttributes = pAttributes.replaceFirst(
              RegExp(r'style\s*=\s*["'']([^"'']*)["'']', caseSensitive: false),
              'style=$quote$existingStyle; $indentStyle$quote',
            );
          }
        } else {
          // Add new style attribute
          // Always add a space before the style attribute
          if (newPAttributes.isNotEmpty && !newPAttributes.endsWith(' ')) {
            newPAttributes += ' ';
          } else if (newPAttributes.isEmpty) {
            // If no attributes exist, we still need a space after <p
            newPAttributes = ' ';
          }
          newPAttributes += 'style="$indentStyle"';
        }
        
        return '<p$newPAttributes>';
      });
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error converting inline-block indentation: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback to DOM-based approach
      return _convertInlineBlockIndentationDom(html, baseFontSize);
    }
  }
  
  /// DOM-based fallback for converting inline-block indentation
  String _convertInlineBlockIndentationDom(String html, double baseFontSize) {
    try {
      final document = html_parser.parse(html);
      
      // Find all paragraphs
      final paragraphs = document.querySelectorAll('p');
      
      for (final paragraph in paragraphs) {
        // Get all nodes (including text nodes)
        final nodes = paragraph.nodes.toList();
        if (nodes.isEmpty) continue;
        
        // Find first span element (skip any leading text nodes)
        dynamic firstSpan;
        for (final node in nodes) {
          try {
            final element = node as dynamic;
            if (element.localName == 'span') {
              firstSpan = element;
              break;
            }
          } catch (e) {
            // Not an element node, continue
            continue;
          }
        }
        
        if (firstSpan == null) continue;
        
        final style = (firstSpan.attributes as Map<String, String>?)?['style'] ?? '';
        
        // Check if it has display:inline-block and width (case-insensitive)
        final styleLower = style.toLowerCase();
        if (styleLower.contains('display:inline-block') || styleLower.contains('display: inline-block')) {
          // Extract width value (handle various formats: width:2em, width: 2em, width:2em;, etc.)
          final widthMatch = RegExp(r'width\s*:\s*([^;]+)', caseSensitive: false).firstMatch(style);
          
          if (widthMatch != null) {
            final widthValue = widthMatch.group(1)?.trim() ?? '';
            
            // Check if span contains only whitespace (indentation marker)
            // Handle &nbsp;, regular spaces, and empty content
            final spanText = (firstSpan.text as String? ?? '').trim();
            final spanInnerHtml = (firstSpan.innerHtml as String? ?? '').trim();
            
            // Check if it's just whitespace, &nbsp;, or empty
            final isWhitespaceOnly = spanText.isEmpty || 
                                    spanText == '\u00A0' || 
                                    spanText == ' ' ||
                                    spanInnerHtml == '&nbsp;' ||
                                    spanInnerHtml == ' ' ||
                                    spanInnerHtml.isEmpty;
            
            if (isWhitespaceOnly) {
              // Convert width to padding-left
              final paddingValue = _convertCssSize(widthValue, baseFontSize);
              
              if (paddingValue != null && paddingValue > 0) {
                // Add padding-left to paragraph
                final existingStyle = paragraph.attributes['style'] ?? '';
                final paddingStyle = 'padding-left: ${paddingValue}px';
                
                if (existingStyle.isNotEmpty) {
                  // Check if padding-left already exists
                  if (existingStyle.contains('padding-left')) {
                    // Replace existing padding-left
                    paragraph.attributes['style'] = existingStyle.replaceAll(
                      RegExp(r'padding-left\s*:\s*[^;]+', caseSensitive: false),
                      paddingStyle,
                    );
                  } else {
                    paragraph.attributes['style'] = '$existingStyle; $paddingStyle';
                  }
                } else {
                  paragraph.attributes['style'] = paddingStyle;
                }
                
                // Remove the span
                (firstSpan as dynamic).remove();
              }
            }
          }
        }
      }
      
      return document.outerHtml;
    } catch (e, stackTrace) {
      debugPrint('Error in DOM-based inline-block conversion: $e');
      debugPrint('Stack trace: $stackTrace');
      return html; // Return original HTML if processing fails
    }
  }

  /// Build HTML extensions for EPUB support
  List<HtmlExtension> _buildExtensions(BuildContext context) {
    final extensions = <HtmlExtension>[
      TableHtmlExtension(),
      SvgHtmlExtension(),
      EpubTextIndentExtension(), // Add text-indent support
    ];

    // Add EPUB image extension if epubBook is provided
    if (epubBook != null) {
      extensions.add(EpubImageExtension(epubBook!));
    }

    return extensions;
  }
}

