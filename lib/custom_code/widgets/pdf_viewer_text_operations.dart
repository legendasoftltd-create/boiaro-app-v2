import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '/providers/pdf_viewer_provider.dart';
import '/models/highlight_model.dart';
import '/services/highlight_storage_service.dart';

/// Text operations for PDF Viewer (highlighting and text-to-speech)
class PdfViewerTextOperations {
  /// Generate book ID from file path
  static String generateBookId(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return 'unknown_book';
    }
    // Use file path as book ID (or hash it for shorter ID)
    // For now, use a hash of the path
    return base64Encode(utf8.encode(filePath)).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, 32);
  }

  /// Add highlight to selected text with position tracking
  static Future<void> addHighlight(
    PdfViewerProvider provider,
    ValueNotifier<String> localSelectedTextNotifier,
    ValueNotifier<String> currentEpubContentNotifier,
    String? bookId,
    String? chapterId,
    String? chapterName,
    String originalHtmlContent, // Original HTML before any highlights
  ) async {
    final selectedText = localSelectedTextNotifier.value.trim();
    if (selectedText.isEmpty || provider.readerType != ReaderType.epub) {
      return;
    }

    if (bookId == null || chapterId == null) {
      log('Cannot add highlight: missing bookId or chapterId');
      return;
    }

    // Get current content from ValueNotifier (which is the displayed content)
    final currentContent = currentEpubContentNotifier.value;
    
    // Find the position of the selected text in the original HTML
    final normalizedSelected = selectedText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Find position in original HTML (before any highlights were applied)
    int startPosition = -1;
    int endPosition = -1;
    
    // Try to find the text in original HTML
    final plainText = _extractPlainTextFromHtml(originalHtmlContent);
    final normalizedPlainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final searchIndex = normalizedPlainText.toLowerCase().indexOf(normalizedSelected.toLowerCase());
    
    if (searchIndex != -1) {
      // Map plain text position back to HTML position
      startPosition = _mapPlainTextToHtmlPosition(originalHtmlContent, searchIndex);
      endPosition = _mapPlainTextToHtmlPosition(originalHtmlContent, searchIndex + normalizedSelected.length);
    } else {
      // Fallback: use character count from start of content
      startPosition = 0;
      endPosition = normalizedSelected.length;
    }
    
    if (startPosition == -1 || endPosition == -1) {
      log('Could not determine position for highlight');
      return;
    }

    // Create highlight model
    final highlightId = HighlightModel.generateId(bookId, chapterId, startPosition);
    final highlight = HighlightModel(
      id: highlightId,
      bookId: bookId,
      chapterId: chapterId,
      chapterName: chapterName ?? 'Chapter ${provider.currentEpubChapterIndex + 1}',
      text: selectedText,
      startPosition: startPosition,
      endPosition: endPosition,
      createdAt: DateTime.now(),
    );

    // Save to storage
    await HighlightStorageService.saveHighlight(highlight);
    
    // Add to provider
    provider.addHighlight(highlight);

    // Check if text is already highlighted (avoid double highlighting)
    // Use a more flexible check that looks for any mark tag containing the text
    final escapedSelected = normalizedSelected.replaceAll('&', '&amp;');
    final normalizedPattern = RegExp.escape(normalizedSelected);
    final escapedPattern = RegExp.escape(escapedSelected);
    final markPattern1 = RegExp('<mark[^>]*>$normalizedPattern</mark>', caseSensitive: false);
    final markPattern2 = RegExp('<mark[^>]*>$escapedPattern</mark>', caseSensitive: false);
    final markPattern3 = RegExp('<mark[^>]*>.*?$normalizedPattern.*?</mark>', caseSensitive: false, dotAll: true);
    final isAlreadyHighlighted = markPattern1.hasMatch(currentContent) ||
        markPattern2.hasMatch(currentContent) ||
        markPattern3.hasMatch(currentContent);
    
    if (isAlreadyHighlighted) {
      log('Text already highlighted: $normalizedSelected');
      // Still update the content to ensure it's visible, but don't add another highlight
      return;
    }

    // Try multiple matching strategies with increasing flexibility
    String newContent = currentContent;
    bool found = false;

    log('Attempting to highlight text: "$normalizedSelected"');
    log('Current content length: ${currentContent.length}');
    log('Content preview: ${currentContent.substring(0, currentContent.length > 200 ? 200 : currentContent.length)}...');

    // Strategy 1: Try exact match (for plain text in HTML)
    if (!found && currentContent.contains(normalizedSelected)) {
      // Find all occurrences and try each one
      int searchIndex = 0;
      while (searchIndex < currentContent.length) {
        final index = currentContent.indexOf(normalizedSelected, searchIndex);
        if (index == -1) break;
        
        if (!_isInsideMark(index, currentContent)) {
          // Replace at specific position
          newContent = currentContent.substring(0, index) +
              '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$normalizedSelected</mark>' +
              currentContent.substring(index + normalizedSelected.length);
          found = true;
          log('Highlight added using exact match at position $index: "$normalizedSelected"');
          break;
        }
        searchIndex = index + 1;
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
            '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$escapedText</mark>',
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
            '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$actualText</mark>',
          );
          found = true;
          log('Highlight added using case-insensitive match: $normalizedSelected');
        }
      }
    }

    // Strategy 4: Try matching text that spans across HTML tags (for Bangla and other languages)
    // This handles cases where text is split across multiple <span> or other tags
    if (!found) {
      newContent = _highlightTextAcrossTags(currentContent, normalizedSelected);
      if (newContent != currentContent) {
        found = true;
        log('Highlight added using cross-tag matching: $normalizedSelected');
      }
    }

    // Strategy 5: Try matching with flexible whitespace (normalize both)
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
                  '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$textAtPos</mark>',
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

    // Update content if found (the matching strategies above should have set found and newContent)
    if (found && newContent != currentContent) {
      provider.setCurrentEpubContent(newContent);
      currentEpubContentNotifier.value = newContent;
      log('Highlight applied and saved: $highlightId');
    } else {
      // Fallback: Try to apply highlight using position if text matching failed
      log('Text matching failed, trying position-based highlighting for: "$normalizedSelected"');
      log('Start position: $startPosition, End position: $endPosition');
      log('Original HTML length: ${originalHtmlContent.length}');
      
      if (startPosition >= 0 && endPosition > startPosition && endPosition <= originalHtmlContent.length) {
        try {
          // Use current content (which may already have some highlights) but work with original positions
          // Find the text at the position in current content
          final plainText = _extractPlainTextFromHtml(currentContent);
          if (startPosition < plainText.length) {
            // Try to find the corresponding position in currentContent
            // This is approximate but should work for most cases
            int htmlPos = 0;
            int plainPos = 0;
            int targetStartPos = -1;
            int targetEndPos = -1;
            
            // Map plain text position to HTML position in current content
            for (int i = 0; i < currentContent.length && plainPos <= endPosition; i++) {
              if (plainPos == startPosition && targetStartPos == -1) {
                targetStartPos = htmlPos;
              }
              if (plainPos == endPosition && targetEndPos == -1) {
                targetEndPos = htmlPos;
                break;
              }
              
              // Skip HTML tags
              if (currentContent[i] == '<') {
                while (i < currentContent.length && currentContent[i] != '>') i++;
                htmlPos = i + 1;
                continue;
              }
              
              // Count text characters
              if (currentContent[i] != ' ' || (i > 0 && currentContent[i-1] != ' ')) {
                plainPos++;
              }
              htmlPos++;
            }
            
            if (targetStartPos != -1 && targetEndPos > targetStartPos) {
              final beforeText = currentContent.substring(0, targetStartPos);
              final highlightedText = currentContent.substring(targetStartPos, targetEndPos);
              final afterText = currentContent.substring(targetEndPos);
              
              // Check if already highlighted
              if (!highlightedText.contains('<mark')) {
                final positionBasedContent = beforeText +
                    '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$highlightedText</mark>' +
                    afterText;
                
                provider.setCurrentEpubContent(positionBasedContent);
                currentEpubContentNotifier.value = positionBasedContent;
                log('Highlight applied using position-based method: $highlightId');
              } else {
                log('Text at position already contains mark tag');
              }
            } else {
              log('Could not map positions to current content');
            }
          }
        } catch (e) {
          log('Error applying position-based highlight: $e');
        }
      } else {
        log('Could not find text to highlight: "$normalizedSelected" (positions invalid: $startPosition-$endPosition)');
      }
    }
  }

  /// Extract plain text from HTML (helper for position mapping)
  static String _extractPlainTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Map plain text position to HTML position
  static int _mapPlainTextToHtmlPosition(String html, int plainTextPos) {
    int htmlPos = 0;
    int plainPos = 0;
    bool inTag = false;

    for (int i = 0; i < html.length && plainPos < plainTextPos; i++) {
      if (html[i] == '<') {
        inTag = true;
      } else if (html[i] == '>') {
        inTag = false;
      } else if (!inTag) {
        if (html[i] == '&') {
          int entityEnd = html.indexOf(';', i);
          if (entityEnd != -1) {
            plainPos++;
            i = entityEnd;
            htmlPos = entityEnd + 1;
            continue;
          }
        }
        plainPos++;
        htmlPos = i + 1;
      }
    }

    return htmlPos;
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

  /// Highlight text that spans across HTML tags (e.g., multiple spans)
  /// This handles cases where text is split across multiple HTML elements
  static String _highlightTextAcrossTags(String htmlContent, String searchText) {
    final normalizedSearch = searchText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Create a regex pattern that matches the text even when split by HTML tags
    // This pattern allows for optional HTML tags between characters
    final escapedSearch = RegExp.escape(normalizedSearch);
    // Replace each character with pattern that allows HTML tags in between
    final pattern = escapedSearch.split('').join(r'(?:<[^>]*>)*\s*(?:</[^>]*>)*\s*');
    
    try {
      final regex = RegExp(pattern, caseSensitive: false, dotAll: true);
      final match = regex.firstMatch(htmlContent);
      
      if (match != null) {
        final matchedText = match.group(0)!;
        final startPos = match.start;
        
        // Check if already highlighted
        if (_isInsideMark(startPos, htmlContent)) {
          return htmlContent; // Already highlighted
        }
        
        // Wrap the matched text with mark tag
        final wrappedText = '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$matchedText</mark>';
        return htmlContent.replaceRange(startPos, match.end, wrappedText);
      }
    } catch (e) {
      log('Error in cross-tag matching: $e');
    }
    
    // Fallback: Try a simpler approach - find text and wrap it, handling tags
    // Remove HTML tags temporarily to find position, then wrap in original HTML
    final plainText = extractPlainTextFromHtml(htmlContent);
    final normalizedPlainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final searchIndex = normalizedPlainText.toLowerCase().indexOf(normalizedSearch.toLowerCase());
    
    if (searchIndex != -1) {
      // Try to find and wrap the actual HTML structure
      // This is a simplified version - in practice, you might need a proper HTML parser
      final searchLower = normalizedSearch.toLowerCase();
      
      // Try to find a substring that contains the search text
      // Look for patterns like: text1</span> <span>text2 where text1+text2 = searchText
      int start = 0;
      while (start < htmlContent.length) {
        final remaining = htmlContent.substring(start);
        final plainRemaining = extractPlainTextFromHtml(remaining);
        final normalizedRemaining = plainRemaining.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        if (normalizedRemaining.toLowerCase().startsWith(searchLower)) {
          // Found a match starting at 'start'
          // Now we need to find where it ends in the HTML
          // This is approximate - find the end by counting characters
          int charCount = 0;
          int endPos = start;
          bool inTag = false;
          
          for (int i = start; i < htmlContent.length && charCount < normalizedSearch.length; i++) {
            if (htmlContent[i] == '<') {
              inTag = true;
            } else if (htmlContent[i] == '>') {
              inTag = false;
            } else if (!inTag) {
              if (htmlContent[i] == '&') {
                int entityEnd = htmlContent.indexOf(';', i);
                if (entityEnd != -1) {
                  charCount++;
                  i = entityEnd;
                  endPos = entityEnd + 1;
                  continue;
                }
              }
              charCount++;
              endPos = i + 1;
            }
          }
          
          if (endPos > start && !_isInsideMark(start, htmlContent)) {
            final before = htmlContent.substring(0, start);
            final toWrap = htmlContent.substring(start, endPos);
            final after = htmlContent.substring(endPos);
            final wrapped = '<mark style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$toWrap</mark>';
            return before + wrapped + after;
          }
        }
        
        // Move to next potential start (skip tags)
        if (htmlContent[start] == '<') {
          final tagEnd = htmlContent.indexOf('>', start);
          if (tagEnd != -1) {
            start = tagEnd + 1;
          } else {
            start++;
          }
        } else {
          start++;
        }
      }
    }
    
    return htmlContent; // Not found
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
    
    // Set reading state - if already reading and not paused, the loop is already running
    // so we just need to return. Otherwise, start the loop.
    final wasAlreadyReading = provider.isReadingChapter;
    if (wasAlreadyReading && !provider.isPaused) {
      // Already reading and not paused - loop is running, don't start a new one
      return;
    }
    
    // If we're here, either:
    // 1. Not reading (need to start)
    // 2. Reading but paused (need to restart the loop)
    // In both cases, we start/restart the loop
    
    // Start or restart reading
    provider.setReadingChapter(true);
    provider.setPaused(false);
    
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
        
        // Check if we've reached or exceeded the end
        if (currentIndex >= chapterSentences.length) {
          // Reached the end - stop reading instead of looping
          provider.setReadingChapter(false);
          provider.setPaused(false);
          break;
        }
        
        // Check if this is the last sentence - after reading it, we'll stop
        bool isLastSentence = (currentIndex == chapterSentences.length - 1);
        
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
        
        // If this was the last sentence, stop reading
        if (isLastSentence) {
          provider.setReadingChapter(false);
          provider.setPaused(false);
          break;
        }
        
        // Move to next sentence
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
    // Just unpause - the loop will continue from where it paused
    // If the loop has exited, the UI should call startReadingChapter to restart it
    provider.setPaused(false);
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

