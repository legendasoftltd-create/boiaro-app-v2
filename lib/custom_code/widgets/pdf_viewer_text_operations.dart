import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '/providers/pdf_viewer_provider.dart';

/// Text operations for PDF Viewer (highlighting and text-to-speech)
class PdfViewerTextOperations {
  /// Add highlight to selected text
  static void addHighlight(
    PdfViewerProvider provider,
    ValueNotifier<String> localSelectedTextNotifier,
    ValueNotifier<String> currentEpubContentNotifier,
  ) {
    final selectedText = localSelectedTextNotifier.value.trim();
    if (selectedText.isEmpty || provider.readerType != ReaderType.epub) {
      return;
    }

    // Add to highlights list
    provider.addHighlight(selectedText);

    // Get current content from ValueNotifier (which is the displayed content)
    final currentContent = currentEpubContentNotifier.value;

    // Normalize the selected text for matching (handle multiple spaces, newlines, etc.)
    final normalizedSelected = selectedText
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize all whitespace to single space
        .trim();

    // Check if text is already highlighted (avoid double highlighting)
    // Check both escaped and unescaped versions
    final escapedSelected = normalizedSelected.replaceAll('&', '&amp;');
    if (currentContent.contains('<mark style="background-color: yellow;">$normalizedSelected</mark>') ||
        currentContent.contains('<mark style="background-color: yellow;">$escapedSelected</mark>') ||
        currentContent.contains('background-color: yellow;">$normalizedSelected</mark>') ||
        currentContent.contains('background-color: yellow;">$escapedSelected</mark>')) {
      log('Text already highlighted: $normalizedSelected');
      return; // Already highlighted
    }

    // Try multiple matching strategies with increasing flexibility
    String newContent = currentContent;
    bool found = false;

    // Strategy 1: Try exact match (for plain text in HTML)
    if (!found && currentContent.contains(normalizedSelected)) {
      final index = currentContent.indexOf(normalizedSelected);
      if (index != -1 && !_isInsideMark(index, currentContent)) {
        newContent = currentContent.replaceFirst(
          normalizedSelected,
          '<mark style="background-color: yellow;">$normalizedSelected</mark>',
        );
        found = true;
        log('Highlight added using exact match: $normalizedSelected');
      }
    }

    // Strategy 2: Try with HTML-escaped text
    if (!found) {
      final escapedText = normalizedSelected
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;');

      if (currentContent.contains(escapedText)) {
        final index = currentContent.indexOf(escapedText);
        if (index != -1 && !_isInsideMark(index, currentContent)) {
          newContent = currentContent.replaceFirst(
            escapedText,
            '<mark style="background-color: yellow;">$escapedText</mark>',
          );
          found = true;
          log('Highlight added using escaped match: $normalizedSelected');
        }
      }
    }

    // Strategy 3: Try case-insensitive match
    if (!found) {
      final lowerContent = currentContent.toLowerCase();
      final lowerSelected = normalizedSelected.toLowerCase();
      if (lowerContent.contains(lowerSelected)) {
        final index = lowerContent.indexOf(lowerSelected);
        if (index != -1 && !_isInsideMark(index, currentContent)) {
          // Extract the actual text at this position (preserving original case)
          final actualText = currentContent.substring(index, index + normalizedSelected.length);
          newContent = currentContent.replaceFirst(
            actualText,
            '<mark style="background-color: yellow;">$actualText</mark>',
          );
          found = true;
          log('Highlight added using case-insensitive match: $normalizedSelected');
        }
      }
    }

    // Strategy 4: Try matching with flexible whitespace (normalize both)
    if (!found) {
      // Normalize both content and selected text for comparison
      final normalizedContent = currentContent.replaceAll(RegExp(r'\s+'), ' ');
      if (normalizedContent.contains(normalizedSelected)) {
        // Find all occurrences to find one that's not already highlighted
        final regex = RegExp(RegExp.escape(normalizedSelected), caseSensitive: false);
        final matches = regex.allMatches(normalizedContent);

        for (final match in matches) {
          final normalizedIndex = match.start;
          // Find corresponding position in original content
          // This is approximate but should work for most cases
          int originalIndex = 0;
          int normalizedPos = 0;

          // Map normalized position to original position
          for (int i = 0; i < currentContent.length && normalizedPos < normalizedIndex; i++) {
            if (RegExp(r'\s').hasMatch(currentContent[i])) {
              // Skip if this whitespace would be normalized
              if (i == 0 || !RegExp(r'\s').hasMatch(currentContent[i - 1])) {
                normalizedPos++;
              }
            } else {
              normalizedPos++;
            }
            originalIndex = i;
          }

          // Check if this position is already highlighted
          if (originalIndex != -1 && !_isInsideMark(originalIndex, currentContent)) {
            // Try to extract actual text at this position
            final textAtPos = _extractTextAtPosition(currentContent, originalIndex, normalizedSelected.length);
            if (textAtPos != null) {
              // Normalize extracted text for comparison
              final normalizedExtracted = textAtPos.replaceAll(RegExp(r'\s+'), ' ').trim();
              if (normalizedExtracted.toLowerCase() == normalizedSelected.toLowerCase()) {
                newContent = currentContent.replaceFirst(
                  textAtPos,
                  '<mark style="background-color: yellow;">$textAtPos</mark>',
                );
                found = true;
                log('Highlight added using normalized whitespace match: $normalizedSelected');
                break;
              }
            }
          }
        }
      }
    }

    // Update both provider and ValueNotifier if content changed
    if (found && newContent != currentContent) {
      provider.setCurrentEpubContent(newContent);
      currentEpubContentNotifier.value = newContent;
    } else {
      log('Could not find text to highlight: "$normalizedSelected" (length: ${normalizedSelected.length})');
      log('Content preview: ${currentContent.substring(0, currentContent.length > 500 ? 500 : currentContent.length)}...');
    }

    // Do not clear selection, so the buttons remain.
    // User can tap away to clear selection.
  }

  /// Helper method to check if a position is inside an existing mark tag
  static bool _isInsideMark(int position, String content) {
    // Look backwards for opening mark tag
    int start = position;
    while (start > 0 && start > position - 100) {
      if (start + 5 <= content.length && content.substring(start, start + 5) == '<mark') {
        return true;
      }
      if (start + 6 <= content.length && content.substring(start, start + 6) == '</mark') {
        return false;
      }
      start--;
    }
    return false;
  }

  /// Helper method to extract text at a position, skipping HTML tags
  static String? _extractTextAtPosition(String content, int start, int length) {
    StringBuffer buffer = StringBuffer();
    int pos = start;
    int found = 0;

    while (pos < content.length && found < length && pos < start + length * 3) {
      if (content[pos] == '<') {
        // Skip HTML tags
        while (pos < content.length && content[pos] != '>') {
          pos++;
        }
        if (pos < content.length) pos++;
      } else if (content[pos] == '&') {
        // Handle HTML entities
        int entityEnd = content.indexOf(';', pos);
        if (entityEnd != -1) {
          buffer.write(content.substring(pos, entityEnd + 1));
          pos = entityEnd + 1;
          found++;
        } else {
          buffer.write(content[pos]);
          pos++;
          found++;
        }
      } else {
        buffer.write(content[pos]);
        pos++;
        found++;
      }
    }

    final result = buffer.toString();
    return result.length >= length ? result : null;
  }

  /// Speak selected text
  static Future<void> speakSelected(
    PdfViewerProvider provider,
    FlutterTts flutterTts,
    ValueNotifier<String> localSelectedTextNotifier,
  ) async {
    final selectedText = localSelectedTextNotifier.value;
    if (selectedText.isEmpty) return;

    // Use silent update to avoid triggering rebuilds
    // We only need selectedText in provider for the bottom bar visibility check
    provider.setSelectedTextSilent(selectedText);

    try {
      await flutterTts.setLanguage("bn-BD");
      await flutterTts.setSpeechRate(provider.speechRate);
      await flutterTts.setPitch(provider.pitch);

      // Set speaking state - will only notify if state changed
      provider.setSpeaking(true);

      flutterTts.setCompletionHandler(() {
        provider.setSpeaking(false);
      });

      await flutterTts.speak(selectedText);
    } catch (e) {
      log('Error speaking text: $e');
      provider.setSpeaking(false);
    }
  }

  /// Stop speaking
  static Future<void> stopSpeaking(PdfViewerProvider provider, FlutterTts flutterTts) async {
    await flutterTts.stop();
    provider.setSpeaking(false);
  }
}

