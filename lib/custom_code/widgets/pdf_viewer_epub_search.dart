// import 'dart:developer';
// import '/providers/pdf_viewer_provider.dart';
// import 'pdf_viewer_epub_reader.dart';

// /// EPUB Search Result Model
// class EpubSearchResult {
//   final int chapterIndex;
//   final String chapterName;
//   final int matchIndex; // Index of this match in the chapter
//   final int totalMatchesInChapter;
//   final int position; // Character position in HTML
//   final String preview; // Preview text around the match

//   EpubSearchResult({
//     required this.chapterIndex,
//     required this.chapterName,
//     required this.matchIndex,
//     required this.totalMatchesInChapter,
//     required this.position,
//     required this.preview,
//   });
// }

// /// EPUB Search Operations
// class PdfViewerEpubSearch {
//   static List<EpubSearchResult> _allSearchResults = [];
//   static int _currentResultIndex = -1;

//   /// Search across all EPUB chapters
//   static Future<List<EpubSearchResult>> searchInEpub(
//     PdfViewerProvider provider,
//     String searchText,
//   ) async {
//     if (searchText.trim().isEmpty) {
//       _allSearchResults = [];
//       _currentResultIndex = -1;
//       return [];
//     }

//     final normalizedSearch = searchText.trim();
//     final searchLower = normalizedSearch.toLowerCase();
//     _allSearchResults = [];
//     _currentResultIndex = -1;

//     final chapters = provider.epubChapters;
//     if (chapters.isEmpty) {
//       return [];
//     }

//     // Search through all chapters
//     for (int chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
//       final chapter = chapters[chapterIndex];
//       final chapterName = chapter.Title ?? 'Chapter ${chapterIndex + 1}';
//       final htmlContent = EpubReaderWidget.parseHtmlContent(chapter.HtmlContent);

//       // Find all matches in this chapter
//       final matches = _findAllMatches(htmlContent, normalizedSearch, searchLower);
      
//       for (int matchIndex = 0; matchIndex < matches.length; matchIndex++) {
//         final match = matches[matchIndex];
//         final preview = _getPreviewText(htmlContent, match.start, match.end);
        
//         _allSearchResults.add(EpubSearchResult(
//           chapterIndex: chapterIndex,
//           chapterName: chapterName,
//           matchIndex: matchIndex,
//           totalMatchesInChapter: matches.length,
//           position: match.start,
//           preview: preview,
//         ));
//       }
//     }

//     log('Found ${_allSearchResults.length} search results for "$searchText"');
//     return _allSearchResults;
//   }

//   /// Find all matches of search text in HTML content
//   static List<_Match> _findAllMatches(String htmlContent, String searchText, String searchLower) {
//     final List<_Match> matches = [];
    
//     // Strategy 1: Direct exact match in HTML (case-sensitive)
//     // This finds the exact text as it appears in HTML
//     int htmlIndex = 0;
//     while (htmlIndex < htmlContent.length) {
//       final index = htmlContent.indexOf(searchText, htmlIndex);
//       if (index == -1) break;
      
//       // Check if not inside HTML tag and not already inside a mark tag
//       if (!_isInsideTag(index, htmlContent) && !_isInsideMarkTag(index, htmlContent)) {
//         // Verify this is actually the text we're looking for (not part of a larger word)
//         final isWordBoundary = _isAtWordBoundary(htmlContent, index, searchText.length);
//         if (isWordBoundary) {
//           matches.add(_Match(start: index, end: index + searchText.length));
//         }
//       }
//       htmlIndex = index + 1;
//     }

//     // Strategy 2: Case-insensitive search if no exact matches found
//     if (matches.isEmpty) {
//       final htmlLower = htmlContent.toLowerCase();
//       int htmlIndex = 0;
//       while (htmlIndex < htmlLower.length) {
//         final index = htmlLower.indexOf(searchLower, htmlIndex);
//         if (index == -1) break;
        
//         // Check if not inside HTML tag and not already inside a mark tag
//         if (!_isInsideTag(index, htmlContent) && !_isInsideMarkTag(index, htmlContent)) {
//           // Extract the actual text at this position (preserving original case)
//           final actualText = htmlContent.substring(index, index + searchText.length);
          
//           // Verify this is actually the text we're looking for (case-insensitive match)
//           if (actualText.toLowerCase() == searchLower) {
//             // Verify word boundary
//             final isWordBoundary = _isAtWordBoundary(htmlContent, index, searchText.length);
//             if (isWordBoundary) {
//               matches.add(_Match(start: index, end: index + searchText.length));
//             }
//           }
//         }
//         htmlIndex = index + 1;
//       }
//     }

//     // Strategy 3: Search in text content (handles HTML entities and tags)
//     // This is a fallback for cases where text might be split by HTML tags
//     if (matches.isEmpty) {
//       matches.addAll(_findMatchesInTextContent(htmlContent, searchText, searchLower));
//     }

//     // Remove duplicates and sort by position
//     matches.sort((a, b) => a.start.compareTo(b.start));
//     final uniqueMatches = <_Match>[];
//     for (final match in matches) {
//       if (uniqueMatches.isEmpty || 
//           match.start >= uniqueMatches.last.end || 
//           match.end <= uniqueMatches.last.start) {
//         uniqueMatches.add(match);
//       }
//     }

//     return uniqueMatches;
//   }

//   /// Check if position is at word boundary (start or end of word)
//   static bool _isAtWordBoundary(String htmlContent, int start, int length) {
//     // Check character before (if exists)
//     if (start > 0) {
//       final charBefore = htmlContent[start - 1];
//       if (_isWordCharacter(charBefore)) {
//         return false; // Not at word start
//       }
//     }
    
//     // Check character after (if exists)
//     final end = start + length;
//     if (end < htmlContent.length) {
//       final charAfter = htmlContent[end];
//       if (_isWordCharacter(charAfter)) {
//         return false; // Not at word end
//       }
//     }
    
//     return true;
//   }

//   /// Check if character is a word character (letter, digit, or underscore)
//   static bool _isWordCharacter(String char) {
//     if (char.isEmpty) return false;
//     final code = char.codeUnitAt(0);
//     return (code >= 65 && code <= 90) ||  // A-Z
//            (code >= 97 && code <= 122) || // a-z
//            (code >= 48 && code <= 57) ||  // 0-9
//            code == 95 ||                   // _
//            (code >= 128);                  // Unicode letters
//   }

//   /// Check if position is inside a mark tag (to avoid highlighting already highlighted text)
//   static bool _isInsideMarkTag(int position, String content) {
//     int start = position;
//     while (start > 0 && start > position - 200) {
//       if (start + 5 <= content.length && content.substring(start, start + 5) == '<mark') {
//         return true;
//       }
//       if (start + 6 <= content.length && content.substring(start, start + 6) == '</mark') {
//         return false;
//       }
//       start--;
//     }
//     return false;
//   }

//   /// Find matches in text content (handles HTML entities and tags)
//   static List<_Match> _findMatchesInTextContent(String htmlContent, String searchText, String searchLower) {
//     final List<_Match> matches = [];
    
//     // Build a regex that allows HTML tags between characters
//     // This handles cases where text is split across tags like: <span>text</span><span>more</span>
//     final searchChars = searchText.split('');
//     final pattern = searchChars.map((char) {
//       final escaped = RegExp.escape(char);
//       return '$escaped(?:<[^>]*>)*\\s*(?:</[^>]*>)*\\s*';
//     }).join('');
    
//     try {
//       final regex = RegExp(pattern, caseSensitive: false, dotAll: true);
//       final regexMatches = regex.allMatches(htmlContent);
      
//       for (final match in regexMatches) {
//         // Verify the match is not inside HTML tags
//         if (!_isInsideTag(match.start, htmlContent) && !_isInsideMarkTag(match.start, htmlContent)) {
//           // Extract the actual matched text (without HTML tags)
//           final matchedHtml = htmlContent.substring(match.start, match.end);
//           final matchedText = _extractPlainText(matchedHtml).trim();
          
//           // Verify it matches our search text (case-insensitive)
//           if (matchedText.toLowerCase() == searchLower) {
//             // Find the actual start and end positions of the text (excluding tags)
//             final (actualStart, actualEnd) = _findTextBoundsInHtml(htmlContent, match.start, match.end, searchText);
//             if (actualStart != -1 && actualEnd > actualStart) {
//               matches.add(_Match(start: actualStart, end: actualEnd));
//             }
//           }
//         }
//       }
//     } catch (e) {
//       log('Error in regex matching: $e');
//     }
    
//     return matches;
//   }

//   /// Find the actual text bounds in HTML (excluding tags)
//   static (int, int) _findTextBoundsInHtml(String htmlContent, int htmlStart, int htmlEnd, String searchText) {
//     int textStart = -1;
//     int textEnd = -1;
//     int charCount = 0;
//     bool inTag = false;
    
//     for (int i = htmlStart; i < htmlEnd && i < htmlContent.length; i++) {
//       if (htmlContent[i] == '<') {
//         inTag = true;
//       } else if (htmlContent[i] == '>') {
//         inTag = false;
//       } else if (!inTag) {
//         if (textStart == -1) {
//           textStart = i;
//         }
//         if (htmlContent[i] == '&') {
//           // Handle HTML entities
//           int entityEnd = htmlContent.indexOf(';', i);
//           if (entityEnd != -1 && entityEnd < htmlEnd) {
//             charCount++;
//             i = entityEnd;
//             textEnd = entityEnd + 1;
//             if (charCount >= searchText.length) break;
//             continue;
//           }
//         }
//         charCount++;
//         textEnd = i + 1;
//         if (charCount >= searchText.length) break;
//       }
//     }
    
//     return (textStart, textEnd);
//   }

//   /// Extract plain text from HTML
//   static String _extractPlainText(String html) {
//     return html
//         .replaceAll(RegExp(r'<[^>]*>'), ' ')
//         .replaceAll('&nbsp;', ' ')
//         .replaceAll('&amp;', '&')
//         .replaceAll('&lt;', '<')
//         .replaceAll('&gt;', '>')
//         .replaceAll('&quot;', '"')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();
//   }

//   /// Check if position is inside HTML tag
//   static bool _isInsideTag(int position, String content) {
//     int start = position;
//     while (start > 0 && start > position - 100) {
//       if (content[start] == '>') {
//         return false; // Outside tag
//       }
//       if (content[start] == '<') {
//         return true; // Inside tag
//       }
//       start--;
//     }
//     return false;
//   }

//   /// Get preview text around match
//   static String _getPreviewText(String htmlContent, int start, int end) {
//     const previewLength = 50;
//     final previewStart = (start - previewLength).clamp(0, htmlContent.length);
//     final previewEnd = (end + previewLength).clamp(0, htmlContent.length);
    
//     final previewHtml = htmlContent.substring(previewStart, previewEnd);
//     final preview = _extractPlainText(previewHtml);
    
//     return preview.length > previewLength * 2 
//         ? '...${preview.substring(0, previewLength)}...${preview.substring(preview.length - previewLength)}'
//         : preview;
//   }

//   /// Highlight search results in HTML content
//   /// Returns highlighted content and the position of the current result (if specified)
//   static (String, int?) highlightSearchResults(
//     String htmlContent, 
//     String searchText, {
//     int? currentResultIndex,
//   }) {
//     if (searchText.trim().isEmpty) {
//       return (htmlContent, null);
//     }

//     final normalizedSearch = searchText.trim();
//     final searchLower = normalizedSearch.toLowerCase();
//     String result = htmlContent;
//     int? currentResultPosition;

//     // Find all matches
//     final matches = _findAllMatches(htmlContent, normalizedSearch, searchLower);
    
//     // Apply highlights from end to start to preserve positions
//     for (int i = matches.length - 1; i >= 0; i--) {
//       final match = matches[i];
      
//       // Check if already highlighted
//       if (!_isInsideSearchHighlight(match.start, result)) {
//         final before = result.substring(0, match.start);
//         final matchedText = result.substring(match.start, match.end);
//         final after = result.substring(match.end);
        
//         // Add unique ID to current result for accurate scrolling
//         final isCurrentResult = currentResultIndex != null && i == currentResultIndex;
//         final idAttr = isCurrentResult ? ' id="current-search-result"' : '';
        
//         result = before +
//             '<mark class="search-result"$idAttr style="background-color: #FFEB3B; padding: 2px 0; margin: 0; display: inline; vertical-align: baseline;">$matchedText</mark>' +
//             after;
        
//         // Store position of current result (in plain text, not HTML)
//         if (isCurrentResult) {
//           // Calculate plain text position by counting characters before this match
//           currentResultPosition = _getPlainTextPosition(htmlContent, match.start);
//         }
//       }
//     }

//     return (result, currentResultPosition);
//   }

//   /// Get plain text position (excluding HTML tags) for a given HTML position
//   static int _getPlainTextPosition(String htmlContent, int htmlPosition) {
//     int plainTextPos = 0;
//     bool insideTag = false;
    
//     for (int i = 0; i < htmlPosition && i < htmlContent.length; i++) {
//       if (htmlContent[i] == '<') {
//         insideTag = true;
//       } else if (htmlContent[i] == '>') {
//         insideTag = false;
//       } else if (!insideTag) {
//         plainTextPos++;
//       }
//     }
    
//     return plainTextPos;
//   }

//   /// Check if position is inside a search highlight
//   static bool _isInsideSearchHighlight(int position, String content) {
//     int start = position;
//     while (start > 0 && start > position - 200) {
//       if (start + 20 <= content.length && 
//           content.substring(start, start + 20).contains('class="search-result"')) {
//         return true;
//       }
//       if (start + 6 <= content.length && content.substring(start, start + 6) == '</mark') {
//         return false;
//       }
//       start--;
//     }
//     return false;
//   }

//   /// Clear search highlights from HTML
//   static String clearSearchHighlights(String htmlContent) {
//     return htmlContent
//         .replaceAll(RegExp(r'<mark class="search-result"[^>]*>'), '')
//         .replaceAll('</mark>', '');
//   }

//   /// Get current search result
//   static EpubSearchResult? getCurrentResult() {
//     if (_currentResultIndex >= 0 && _currentResultIndex < _allSearchResults.length) {
//       return _allSearchResults[_currentResultIndex];
//     }
//     return null;
//   }

//   /// Get next search result
//   static EpubSearchResult? getNextResult() {
//     if (_allSearchResults.isEmpty) return null;
    
//     _currentResultIndex = (_currentResultIndex + 1) % _allSearchResults.length;
//     return getCurrentResult();
//   }

//   /// Get previous search result
//   static EpubSearchResult? getPreviousResult() {
//     if (_allSearchResults.isEmpty) return null;
    
//     _currentResultIndex = _currentResultIndex <= 0 
//         ? _allSearchResults.length - 1 
//         : _currentResultIndex - 1;
//     return getCurrentResult();
//   }

//   /// Get total result count
//   static int getTotalResults() => _allSearchResults.length;

//   /// Get current result index (0-based)
//   static int getCurrentResultIndex() => _currentResultIndex;

//   /// Clear search results
//   static void clearResults() {
//     _allSearchResults = [];
//     _currentResultIndex = -1;
//   }
// }

// /// Internal match class
// class _Match {
//   final int start;
//   final int end;

//   _Match({required this.start, required this.end});
// }

