import 'dart:async';
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

  /// Extract plain text from HTML content
  static String extractPlainTextFromHtml(String htmlContent) {
    // Remove HTML tags and decode entities
    String text = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), ' ') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    return text;
  }

  /// Split text into sentences
  static List<String> splitIntoSentences(String text) {
    // Split by sentence-ending punctuation, but keep the punctuation
    final sentences = <String>[];
    final pattern = RegExp(r'[.!?।]+');
    final parts = text.split(pattern);
    
    int lastIndex = 0;
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isNotEmpty) {
        // Find the punctuation that was used
        final startIndex = lastIndex;
        final endIndex = text.indexOf(part, startIndex) + part.length;
        if (endIndex < text.length) {
          final punctuation = text[endIndex];
          sentences.add(part + punctuation);
          lastIndex = endIndex + 1;
        } else {
          sentences.add(part);
        }
      }
    }
    
    // If no sentences found, return the whole text as one sentence
    if (sentences.isEmpty) {
      return [text];
    }
    
    return sentences.where((s) => s.trim().isNotEmpty).toList();
  }

  /// Start reading chapter aloud (with loop support)
  static Future<void> startReadingChapter(
    PdfViewerProvider provider,
    FlutterTts flutterTts,
    String htmlContent,
    Function(String) onSentenceHighlight,
    Function(double) onScrollToPosition,
  ) async {
    // Extract plain text and split into sentences
    final plainText = extractPlainTextFromHtml(htmlContent);
    final sentences = splitIntoSentences(plainText);
    
    if (sentences.isEmpty) return;
    
    // Only set sentences if not already set (to preserve current index when resuming)
    if (provider.chapterSentences.isEmpty) {
      provider.setChapterSentences(sentences);
    }
    
    // Set reading state - if already reading, the loop is already running
    // so we just need to unpause. Otherwise, start the loop.
    final wasAlreadyReading = provider.isReadingChapter;
    if (!wasAlreadyReading) {
      provider.setReadingChapter(true);
      provider.setPaused(false);
    } else {
      // If already reading, just unpause - the loop will continue
      provider.setPaused(false);
      return; // Don't start a new loop if one is already running
    }
    
    try {
      await flutterTts.setLanguage("bn-BD");
      await flutterTts.setSpeechRate(provider.speechRate);
      await flutterTts.setPitch(provider.pitch);
      
      // Use provider's sentences array for consistency
      final chapterSentences = provider.chapterSentences;
      if (chapterSentences.isEmpty) {
        provider.setReadingChapter(false);
        return;
      }
      
      // Set up completion handler with proper tracking
      Completer<void>? sentenceCompleter;
      
      flutterTts.setCompletionHandler(() {
        // Complete the current completer if it exists and isn't already completed
        // The completer is created fresh for each sentence, so this should always
        // complete the correct one for the sentence currently being spoken
        final completer = sentenceCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      });
      
      // Loop through sentences continuously
      while (provider.isReadingChapter) {
        // Check if paused - wait until resumed
        while (provider.isPaused && provider.isReadingChapter) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        if (!provider.isReadingChapter) break;
        
        // Get current sentence index
        int currentIndex = provider.currentReadingSentenceIndex;
        if (currentIndex >= chapterSentences.length) {
          // Loop back to beginning
          currentIndex = 0;
          provider.setCurrentReadingSentenceIndex(0);
        }
        
        // Create new completer for this sentence BEFORE speaking
        // This ensures the completion handler always references the correct completer
        // and prevents race conditions where a previous sentence's completion
        // handler might complete the wrong completer
        sentenceCompleter = Completer<void>();
        
        // Highlight current sentence in HTML
        onSentenceHighlight(chapterSentences[currentIndex]);
        
        // Speak the sentence
        await flutterTts.speak(chapterSentences[currentIndex]);
        
        // Wait for speech to complete (with timeout)
        // But check for pause during waiting and complete completer if paused
        bool wasPaused = false;
        try {
          // Wait for completer with periodic pause checks
          while (!sentenceCompleter.isCompleted && provider.isReadingChapter) {
            if (provider.isPaused) {
              // Complete the completer manually so loop can continue
              if (!sentenceCompleter.isCompleted) {
                sentenceCompleter.complete();
              }
              wasPaused = true;
              break;
            }
            // Wait a bit and check again
            try {
              await sentenceCompleter.future.timeout(
                const Duration(milliseconds: 100),
                onTimeout: () {
                  // Continue checking
                },
              );
              break; // Completer completed
            } catch (e) {
              // Timeout, continue checking
              continue;
            }
          }
          
          // If still waiting, wait for completion or timeout
          if (!sentenceCompleter.isCompleted && !wasPaused) {
            try {
              await sentenceCompleter.future.timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  log('Sentence speech timeout');
                },
              );
            } catch (e) {
              log('Error waiting for speech: $e');
            }
          }
        } catch (e) {
          log('Error waiting for speech: $e');
        }
        
        // Check if paused after speech
        if (provider.isPaused && !wasPaused) {
          wasPaused = true;
        }
        
        // If paused, don't move to next sentence - will re-read when resumed
        if (wasPaused) {
          continue; // Will re-read current sentence when resumed
        }
        
        // Move to next sentence (will loop if at end)
        // Only increment AFTER we've confirmed the current sentence completed
        provider.incrementReadingSentenceIndex();
        
        // Small delay between sentences
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      provider.setReadingChapter(false);
    } catch (e) {
      log('Error reading chapter: $e');
      provider.setReadingChapter(false);
    }
  }

  /// Pause reading chapter
  static Future<void> pauseReadingChapter(
    PdfViewerProvider provider,
    FlutterTts flutterTts,
  ) async {
    // Stop current speech but keep the reading state
    await flutterTts.stop();
    provider.setPaused(true);
  }

  /// Resume reading chapter
  static Future<void> resumeReadingChapter(
    PdfViewerProvider provider,
    FlutterTts flutterTts,
  ) async {
    provider.setPaused(false);
    // The loop will continue from the current sentence index
    // The while loop in startReadingChapter will detect the pause state change
    // and continue reading from the current sentence
  }

  /// Stop reading chapter
  static Future<void> stopReadingChapter(
    PdfViewerProvider provider,
    FlutterTts flutterTts,
  ) async {
    await flutterTts.stop();
    provider.setReadingChapter(false);
    provider.setPaused(false);
  }
}

