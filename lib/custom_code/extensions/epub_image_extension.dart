import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'dart:developer';

class EpubImageExtension extends HtmlExtension {
  final epubx.EpubBook epubBook;

  EpubImageExtension(this.epubBook);

  @override
  Set<String> get supportedTags => {"img", "image", "svg"};

  @override
  bool matches(ExtensionContext context) {
    return supportedTags.contains(context.elementName);
  }

  @override
  InlineSpan build(ExtensionContext context) {
    log("🎨 Extension called for: ${context.elementName}");
    
    // Handle <svg> tags with embedded images
    if (context.elementName == 'svg') {
      return _buildSvgImage(context);
    }

    // Handle standalone <image> tags (usually inside SVG)
    if (context.elementName == 'image') {
      final src = context.attributes['xlink:href'] ?? 
                  context.attributes['href'] ??
                  context.attributes['src'];
      log("🖼️ Processing <image> tag with src: $src");
      if (src != null) {
        final imageData = _getImageData(src);
        if (imageData != null) {
          log("✅ Rendering <image> tag with ${imageData.length} bytes");
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Image.memory(
                Uint8List.fromList(imageData),
                fit: BoxFit.contain,
              ),
            ),
          );
        }
      }
      return const TextSpan(text: '');
    }

    // Handle regular <img> tags
    final src = context.attributes['src'];
    if (src == null) {
      log("⚠️ <img> tag has no src attribute");
      return const TextSpan(text: '');
    }

    log("🖼️ Processing <img> tag with src: $src");

    final imageData = _getImageData(src);
    if (imageData != null) {
      log("✅ Rendering <img> tag with ${imageData.length} bytes");
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Image.memory(
            Uint8List.fromList(imageData),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback to network image if it's a URL
    if (src.startsWith('http')) {
      log("🌐 Loading network image: $src");
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Image.network(src, fit: BoxFit.contain),
      );
    }

    log("❌ Image not found: $src");
    return const TextSpan(text: '');
  }

  WidgetSpan _buildSvgImage(ExtensionContext context) {
    log("🎨 Building SVG image");
    
    // Check if SVG contains an embedded image
    final element = context.element;
    if (element == null) {
      log("❌ SVG element is null");
      return const WidgetSpan(child: SizedBox.shrink());
    }
    
    // Try to find image element using different methods
    final imageElements = element.getElementsByTagName('image');
    
    log("🔍 Found ${imageElements.length} image elements in SVG");
    
    if (imageElements.isNotEmpty) {
      final imageElement = imageElements.first;
      final src = imageElement.attributes['xlink:href'] ?? 
                  imageElement.attributes['href'];
      
      log("🖼️ SVG embedded image src: $src");
      
      if (src != null && src.isNotEmpty) {
        final imageData = _getImageData(src);
        
        if (imageData != null) {
          log("✅ Successfully loaded image data: ${imageData.length} bytes");
          
          // Get dimensions from the image element or SVG viewBox
          final viewBox = context.attributes['viewBox'];
          double? aspectRatio;
          
          if (viewBox != null) {
            final parts = viewBox.split(' ');
            if (parts.length == 4) {
              final width = double.tryParse(parts[2]);
              final height = double.tryParse(parts[3]);
              if (width != null && height != null && height > 0) {
                aspectRatio = width / height;
                log("📐 Aspect ratio from viewBox: $aspectRatio");
              }
            }
          }
          
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AspectRatio(
                aspectRatio: aspectRatio ?? 1.0,
                child: Image.memory(
                  Uint8List.fromList(imageData),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        } else {
          log("❌ Failed to load image data for: $src");
        }
      } else {
        log("❌ Image src is null or empty");
      }
    }

    // Fallback: try to render SVG with base64 inline images
    log("⚠️ Attempting fallback: rendering SVG with inline base64 images");
    try {
      String svgString = element.outerHtml;
      log("📝 Original SVG length: ${svgString.length}");
      
      // Find all xlink:href in the SVG string
      final hrefPattern = RegExp(r'xlink:href=["\"]([^"\"]+)["\"]');
      final matches = hrefPattern.allMatches(svgString);
      
      log("🔍 Found ${matches.length} xlink:href attributes");
      
      for (final match in matches) {
        final src = match.group(1);
        if (src != null && !src.startsWith('data:')) {
          log("🔄 Processing href: $src");
          final imageData = _getImageData(src);
          if (imageData != null) {
            final base64String = base64Encode(imageData);
            final mimeType = _getMimeType(src);
            final dataUri = 'data:$mimeType;base64,$base64String';
            svgString = svgString.replaceAll(src, dataUri);
            log("✅ Replaced $src with data URI (${base64String.length} chars)");
          } else {
            log("❌ Could not load image data for: $src");
          }
        }
      }
      
      log("📝 Modified SVG length: ${svgString.length}");
      
      return WidgetSpan(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SvgPicture.string(
            svgString,
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (e, stackTrace) {
      log("❌ Error rendering SVG: $e");
      log("Stack trace: $stackTrace");
      return const WidgetSpan(child: SizedBox.shrink());
    }
  }

  String _getMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'image/png'; // default
  }

  List<int>? _getImageData(String src) {
    if (epubBook.Content?.Images == null) {
      log("❌ EPUB has no images");
      return null;
    }

    log("🔍 Looking for image: $src");
    
    // Log all available images once
    if (epubBook.Content!.Images!.isNotEmpty) {
      final imageCount = epubBook.Content!.Images!.length;
      log("📚 Available images ($imageCount total):");
      for (final key in epubBook.Content!.Images!.keys) {
        log("  📄 $key");
      }
    }

    // Normalize the source path
    String normalizedSrc = src.replaceAll('\\', '/');
    if (normalizedSrc.startsWith('./')) {
      normalizedSrc = normalizedSrc.substring(2);
    }
    if (normalizedSrc.startsWith('../')) {
      normalizedSrc = normalizedSrc.substring(3);
    }
    
    final filename = normalizedSrc.split('/').last;
    log("🔍 Normalized src: $normalizedSrc");
    log("🔍 Filename: $filename");

    epubx.EpubByteContentFile? epubImage;

    // Try exact match first
    epubImage = epubBook.Content!.Images![normalizedSrc];
    if (epubImage != null) {
      final size = epubImage.Content?.length ?? 0;
      log("✅ Found image with exact match: $normalizedSrc ($size bytes)");
      return epubImage.Content;
    }

    // Try different path combinations
    const prefixes = [
      '',
      'OEBPS/',
      'OPS/',
      'OEBPS/Text/',
      'OPS/Text/',
      'Text/',
      'html/',
      'xhtml/',
      'images/',
      'Images/',
      'OEBPS/images/',
      'OEBPS/Images/',
      'OPS/images/',
      'OPS/Images/',
      'OEBPS/text/images/',
      'OPS/text/images/',
    ];

    for (final prefix in prefixes) {
      final key = '$prefix$normalizedSrc';
      epubImage = epubBook.Content!.Images![key];
      if (epubImage != null) {
        final size = epubImage.Content?.length ?? 0;
        log("✅ Found image with prefix '$prefix': $key ($size bytes)");
        return epubImage.Content;
      }
    }

    // Try matching by filename only
    log("🔍 Trying filename-only match for: $filename");
    for (final entry in epubBook.Content!.Images!.entries) {
      if (entry.key.endsWith(filename) || entry.key.endsWith('/$filename')) {
        final size = entry.value.Content?.length ?? 0;
        log("✅ Found image by filename match: ${entry.key} ($size bytes)");
        return entry.value.Content;
      }
    }

    // Case-insensitive search
    log("🔍 Trying case-insensitive match");
    final lowerFilename = filename.toLowerCase();
    for (final entry in epubBook.Content!.Images!.entries) {
      if (entry.key.toLowerCase().endsWith(lowerFilename)) {
        final size = entry.value.Content?.length ?? 0;
        log("✅ Found image by case-insensitive match: ${entry.key} ($size bytes)");
        return entry.value.Content;
      }
    }

    log("❌ Image not found in EPUB: $src");
    log("❌ Tried normalized path: $normalizedSrc");
    log("❌ Tried filename: $filename");
    return null;
  }
}