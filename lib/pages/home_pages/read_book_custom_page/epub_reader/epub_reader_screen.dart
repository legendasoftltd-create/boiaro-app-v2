import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/internationalization.dart';
import '/services/progress_sync_service.dart';
import '/services/reading_report_service.dart';
import '/custom_code/widgets/pdf_viewer/bookmark_storage_service.dart';
import '/custom_code/widgets/pdf_viewer/highlight_storage_service.dart';
import '/models/bookmark_model.dart';
import '/models/highlight_model.dart';
import '/services/tts_service.dart';
import 'style_sheets.dart';
import 'search_overlay.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

// ── Isolate helper for base64-encoding font bytes ──────────────────────────
String _encodeBase64Isolate(List<int> bytes) => base64Encode(bytes);

class EpubReaderScreen extends StatefulWidget {
  final String epubPath;
  final String bookTitle;
  final String bookId;
  final double? initialProgress;

  const EpubReaderScreen({
    Key? key,
    required this.epubPath,
    required this.bookTitle,
    required this.bookId,
    this.initialProgress,
  }) : super(key: key);

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final EpubController epubController = EpubController();
  late final EpubSource epubSource;

  // UI state
  bool isLoading = true;
  double progress = 0.0;
  List<EpubChapter> _chapters = [];
  bool _showControls = true;
  bool _isTtsActive = false;

  // Calculated page metrics
  int _currentPage = 1;
  int _totalPages = 1;

  // Style preferences
  ReaderThemeType _themeType = ReaderThemeType.light;
  String _fontFamily = 'noto serif bengali'; // Default: Noto Serif Bengali
  double _fontSize = 16.0;

  // Local font base64 cache (populated once on epub load)
  final Map<String, String> _localFontBase64 = {};
  double _originalBrightness = 0.5;
  double _currentBrightness = 0.5;

  // Bookmarks and Highlights
  List<BookmarkModel> _bookmarks = [];
  List<HighlightModel> _highlights = [];

  // TTS State
  List<String> _sentences = [];
  int _currentSentenceIndex = 0;
  bool _isTtsPlaying = false;
  TtsAmbientTrack? _appliedAmbientTrack;
  TtsAmbientTrack? _selectedAmbientTrack;

  bool _hasJumpedToInitial = false;
  String _currentCfi = '';
  double _touchStartX = 0.0;
  double _touchStartY = 0.0;
  int _touchStartTime = 0;
  EpubTextSelection? _lastSelection;

  // Cached SharedPreferences instance to avoid Repeated async resolution
  SharedPreferences? _prefs;

  // Guard against rapid duplicate tap events (iOS WKWebView iframe touchend fallback)
  int _lastTapTimeMs = 0;
  // Guard to prevent TTS text extraction before new page DOM is ready
  bool _ttsPageSettling = false;

  @override
  void initState() {
    super.initState();
    epubSource = EpubSource.fromFile(File(widget.epubPath));
    unawaited(_preloadLocalFonts()); // Start font preloading early on isolate
    _loadPreferences();
    _loadBookmarksAndHighlights();
    _initBrightness();
    _initTts();
  }

  @override
  void dispose() {
    _restoreBrightness();
    TtsService.instance.stop();
    TtsService.instance.onSpeechCompleted = null;
    super.dispose();
  }

  // ── Preferences and Settings ───────────────────────────────────────────────

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;
    
    // Scoped style settings
    final themeIndex = prefs.getInt('epub_theme_${widget.bookId}') ?? 
                       prefs.getInt('epub_theme_global') ?? 
                       ReaderThemeType.light.index;
    final fontSize = prefs.getDouble('epub_font_size_${widget.bookId}') ?? 
                      prefs.getDouble('epub_font_size_global') ?? 
                      16.0;
    final fontFamily = prefs.getString('epub_font_family_${widget.bookId}') ?? 
                       prefs.getString('epub_font_family_global') ?? 
                       'noto serif bengali'; // Default to Noto Serif Bengali

    setState(() {
      _themeType = ReaderThemeType.values[themeIndex];
      _fontSize = fontSize;
      _fontFamily = fontFamily;
    });

    // Wait for ambient tracks to load from API then apply saved track if any
    await TtsService.instance.fetchAmbientTracks();
    final savedAmbientTrackId = prefs.getString('epub_ambient_track_id_${widget.bookId}');
    if (savedAmbientTrackId != null && TtsService.instance.ambientTracks.isNotEmpty) {
      final matchedTrack = TtsService.instance.ambientTracks.firstWhere(
        (t) => t.id == savedAmbientTrackId,
        orElse: () => TtsService.instance.ambientTracks.first,
      );
      setState(() {
        _appliedAmbientTrack = matchedTrack;
        _selectedAmbientTrack = matchedTrack;
      });
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  // Map to track actual rendered screen pages per chapter dynamically
  final Map<int, int> _chapterPageTotals = {};

  void _registerAllPagesHandler() {
    epubController.webViewController?.addJavaScriptHandler(
      handlerName: 'epubAllPagesCalculated',
      callback: (args) {
        if (args.isNotEmpty && args[0] is String) {
          try {
            final map = jsonDecode(args[0] as String) as Map<String, dynamic>;
            final total = (map['total'] as num?)?.toInt() ?? 0;
            final pages = (map['pages'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [];

            if (total > 0 && pages.isNotEmpty) {
              for (int i = 0; i < pages.length; i++) {
                _chapterPageTotals[i] = pages[i];
              }
              _prefs?.setInt('epub_total_pages_${widget.bookId}_$_fontSize', total);
              if (mounted) {
                setState(() {
                  _totalPages = total;
                });
              }
            }
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _preloadAllChapterPages() async {
    try {
      _registerAllPagesHandler();

      final js = '''
        (function() {
          try {
            var spine = rendition.book.spine;
            if (!spine || !spine.spineItems || spine.spineItems.length === 0) return;
            
            var chapterPages = [];
            var promises = [];
            var fs = $_fontSize;
            // 790 chars per page maps 1:1 to rendered WKWebView column page density for Bengali text
            var charsPerPage = Math.max(150, Math.round(790 * (16.0 / fs)));

            for (var i = 0; i < spine.spineItems.length; i++) {
              (function(item, idx) {
                promises.push(
                  item.load(rendition.book.load.bind(rendition.book)).then(function(doc) {
                    if (!doc) { chapterPages[idx] = 1; return 1; }
                    var text = (doc.body ? doc.body.textContent : doc.textContent) || '';
                    var len = text.replace(/\\s+/g, ' ').trim().length;
                    if (len === 0) { chapterPages[idx] = 1; return 1; }
                    
                    var pages = Math.max(1, Math.ceil(len / charsPerPage));
                    chapterPages[idx] = pages;
                    return pages;
                  }).catch(function() {
                    chapterPages[idx] = 1;
                    return 1;
                  })
                );
              })(spine.spineItems[i], i);
            }

            Promise.all(promises).then(function() {
              var total = 0;
              for (var k = 0; k < chapterPages.length; k++) {
                total += (chapterPages[k] || 1);
              }
              try {
                window.flutter_inappwebview.callHandler('epubAllPagesCalculated', JSON.stringify({
                  total: total,
                  pages: chapterPages
                }));
              } catch(err) {}
            });
          } catch(e) {}
        })();
      ''';

      await epubController.webViewController?.evaluateJavascript(source: js);
    } catch (_) {}
  }

  void _updateTotalPages() {
    _chapterPageTotals.clear();
    final cached = _prefs?.getInt('epub_total_pages_${widget.bookId}_$_fontSize');
    if (cached != null && cached > 0) {
      if (_totalPages != cached) {
        setState(() {
          _totalPages = cached;
        });
      }
      return;
    }

    final numChapters = _chapters.isNotEmpty ? _chapters.length : 1;
    final fontScale = _fontSize / 16.0;
    final totalEst = (numChapters * 4.1 * fontScale).round().clamp(10, 800);
    if (_totalPages != totalEst) {
      setState(() {
        _totalPages = totalEst;
      });
    }
  }

  Future<void> _applyStyles() async {
    // Inject @font-face BEFORE updateTheme so EpubJS can resolve the
    // font-family name when it applies the theme CSS
    await _injectLocalFontsInWebView();
    await _injectGoogleFontsInWebView();

    final theme = EpubStyleHelper.getEpubTheme(
      themeType: _themeType,
      fontFamilyKey: _fontFamily,
      fontSize: _fontSize,
    );
    await epubController.updateTheme(theme: theme);
    await epubController.setFontSize(fontSize: _fontSize);
    _updateTotalPages();
  }

  Future<void> _loadPageTextAndPlay() async {
    try {
      // Small settle delay (150ms) for EpubJS iframe DOM rendering
      await Future.delayed(const Duration(milliseconds: 150));
      if (!_isTtsActive || !mounted) return;

      // Extract text strictly from leaf elements visible inside current page column bounds
      const js = '''
        (function() {
          try {
            var iframes = document.querySelectorAll('iframe');
            var visibleText = "";
            for (var i = 0; i < iframes.length; i++) {
              var iframe = iframes[i];
              var doc = iframe.contentDocument || iframe.contentWindow.document;
              if (!doc || !doc.body) continue;

              var winWidth = iframe.clientWidth || window.innerWidth;
              var winHeight = iframe.clientHeight || window.innerHeight;

              var allElements = doc.body.querySelectorAll('*');
              var pageLines = [];
              for (var j = 0; j < allElements.length; j++) {
                var el = allElements[j];
                // Only inspect leaf elements (elements with no child elements) that contain text
                if (el.children && el.children.length > 0) continue;
                var text = (el.textContent || el.innerText || '').trim();
                if (!text || text.length < 2) continue;

                var rect = el.getBoundingClientRect();
                if (rect.right > 5 && rect.left < winWidth - 5 && rect.bottom > 0 && rect.top < winHeight) {
                  pageLines.push(text);
                }
              }
              if (pageLines.length > 0) {
                visibleText = pageLines.join(' ');
                break;
              }
              if (doc.body.innerText) {
                visibleText = doc.body.innerText;
              }
            }
            return visibleText;
          } catch(e) { return ""; }
        })();
      ''';

      final rawText = await epubController.webViewController
          ?.evaluateJavascript(source: js)
          .timeout(const Duration(seconds: 2), onTimeout: () => '');
      
      String text = rawText is String ? rawText.trim() : '';

      final parsed = _splitIntoSentences(text);
      
      if (mounted) {
        setState(() {
          _sentences = parsed;
          _currentSentenceIndex = 0;
        });
      }

      if (_isTtsPlaying && mounted && _sentences.isNotEmpty) {
        await _speakCurrentSentence();
      }
    } catch (_) {
      if (_isTtsPlaying && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        _ttsPageSettling = true;
        epubController.next();
      }
    }
  }

  Future<void> _loadBookmarksAndHighlights() async {
    final b = await BookmarkStorageService.getBookmarksForBook(widget.bookId);
    final h = await HighlightStorageService.getHighlightsForBook(widget.bookId);
    setState(() {
      _bookmarks = b;
      _highlights = h;
    });
  }

  // ── Brightness controls ────────────────────────────────────────────────────

  Future<void> _initBrightness() async {
    try {
      await ScreenBrightness().setAnimate(false);
      _originalBrightness = await ScreenBrightness().application;
      _currentBrightness = _originalBrightness;
    } catch (_) {}
  }

  Future<void> _setBrightness(double value) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(value);
      setState(() {
        _currentBrightness = value;
      });
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_originalBrightness);
    } catch (_) {}
  }

  // ── JavaScript injections ──────────────────────────────────────────────────

  /// Preloads local font bytes from Flutter assets and caches them as base64.
  /// Heavy encoding work is run on a background isolate.
  Future<void> _preloadLocalFonts() async {
    const fontAssets = {
      'NotoSerifBengali': 'assets/fonts/NotoSerifBengali.ttf',
      'SolaimanLipi': 'assets/fonts/SolaimanLipi.ttf',
    };
    for (final entry in fontAssets.entries) {
      if (_localFontBase64.containsKey(entry.key)) continue;
      try {
        final bytes = await rootBundle.load(entry.value);
        final list = bytes.buffer.asUint8List();
        // Encode on isolate to avoid blocking UI thread
        final b64 = await compute(_encodeBase64Isolate, list);
        _localFontBase64[entry.key] = b64;
      } catch (e) {
        debugPrint('Failed to preload font ${entry.key}: $e');
      }
    }
  }

  /// Injects locally bundled Bengali fonts as @font-face CSS into EPUB iframes.
  /// Fonts are served as base64 data URIs so no network is needed.
  /// Uses JSON-encoded strings to safely embed the base64 data in JS without quoting issues.
  Future<void> _injectLocalFontsInWebView() async {
    if (_localFontBase64.isEmpty) return;

    // Build @font-face blocks. We pass the base64 string via a JS variable
    // to avoid any single/double quote conflicts in the evaluateJavascript call.
    final declarations = <Map<String, String>>[];
    if (_localFontBase64.containsKey('NotoSerifBengali')) {
      declarations.add({
        'family': 'Noto Serif Bengali',
        'weight': '100 900',
        'b64': _localFontBase64['NotoSerifBengali']!,
      });
    }
    if (_localFontBase64.containsKey('SolaimanLipi')) {
      declarations.add({
        'family': 'SolaimanLipi',
        'weight': '400',
        'b64': _localFontBase64['SolaimanLipi']!,
      });
    }
    if (declarations.isEmpty) return;

    for (final decl in declarations) {
      // Encode family name and b64 as JSON strings so JS receives them safely
      final familyJson = jsonEncode(decl['family']);
      final weightJson = jsonEncode(decl['weight']);
      // The base64 string is very long; assign it to a JS variable rather than
      // embedding it inside a string literal to avoid any escaping issues.
      final b64 = decl['b64']!;

      final js = '''
        (function() {
          var family = $familyJson;
          var weight = $weightJson;
          var b64 = "$b64";
          var css = "@font-face { font-family: '" + family + "'; font-style: normal; font-weight: " + weight + "; src: url('data:font/truetype;base64," + b64 + "') format('truetype'); }";
          var styleId = 'local-font-' + family.replace(/\\s+/g, '-');

          function injectDoc(doc) {
            if (!doc || !doc.head) return;
            if (doc.getElementById(styleId)) return;
            var style = doc.createElement('style');
            style.id = styleId;
            style.textContent = css;
            doc.head.insertBefore(style, doc.head.firstChild);
          }

          // Inject into all current iframes
          var iframes = document.querySelectorAll('iframe');
          for (var i = 0; i < iframes.length; i++) {
            var iframeDoc = iframes[i].contentDocument || iframes[i].contentWindow.document;
            injectDoc(iframeDoc);
          }

          // Register hook on EpubJS rendition so all future chapter iframes automatically get font CSS
          if (window.rendition && window.rendition.hooks && window.rendition.hooks.content) {
            var hookKey = '_fontHook_' + styleId.replace(/-/g, '_');
            if (!window[hookKey]) {
              window[hookKey] = true;
              window.rendition.hooks.content.register(function(contents) {
                if (contents && contents.document) {
                  injectDoc(contents.document);
                }
              });
            }
          }
        })();
      ''';
      await epubController.webViewController?.evaluateJavascript(source: js);
    }
  }

  Future<void> _injectGoogleFontsInWebView() async {
    const js = '''
      (function() {
        var iframes = document.querySelectorAll('iframe');
        for (var i = 0; i < iframes.length; i++) {
          var iframeDoc = iframes[i].contentDocument || iframes[i].contentWindow.document;
          if (!iframeDoc) continue;
          if (iframeDoc.getElementById('google-fonts-injection')) continue;
          
          var link = iframeDoc.createElement('link');
          link.id = 'google-fonts-injection';
          link.rel = 'stylesheet';
          link.href = 'https://fonts.googleapis.com/css2?family=Literata:ital,wght@0,300..900;1,300..900&family=Noto+Sans+Bengali:wght@100..900&family=Noto+Serif+Bengali:wght@100..900&family=Tiro+Bangla:ital@0;1&family=Inter:wght@300;400;500;600;700&display=swap';
          iframeDoc.head.appendChild(link);
        }
      })();
    ''';
    await epubController.webViewController?.evaluateJavascript(source: js);
  }

  Future<void> _highlightSentenceInWebView(String sentence) async {
    final escaped = sentence
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');
    final js = '''
      (function() {
        function removeTtsHighlight() {
          var iframes = document.querySelectorAll('iframe');
          for (var i = 0; i < iframes.length; i++) {
            var iframeDoc = iframes[i].contentDocument || iframes[i].contentWindow.document;
            if (!iframeDoc) continue;
            var highlights = iframeDoc.querySelectorAll('.tts-active-highlight');
            highlights.forEach(function(span) {
              var parent = span.parentNode;
              if (parent) {
                while (span.firstChild) {
                  parent.insertBefore(span.firstChild, span);
                }
                parent.removeChild(span);
                parent.normalize();
              }
            });
          }
        }
        
        removeTtsHighlight();
        var searchText = "$escaped".replace(/\\s+/g, ' ').trim().toLowerCase();
        if (searchText.length < 2) return false;
        
        var iframes = document.querySelectorAll('iframe');
        for (var i = 0; i < iframes.length; i++) {
          var iframeDoc = iframes[i].contentDocument || iframes[i].contentWindow.document;
          if (!iframeDoc) continue;
          var body = iframeDoc.body;
          if (!body) continue;
          
          var nodeIterator = iframeDoc.createNodeIterator(
            body,
            NodeFilter.SHOW_TEXT,
            null,
            false
          );
          
          var textNode;
          while ((textNode = nodeIterator.nextNode())) {
            var val = textNode.nodeValue;
            var cleanVal = val.replace(/\\s+/g, ' ').toLowerCase();
            var index = cleanVal.indexOf(searchText);
            
            if (index === -1 && searchText.length > 25) {
              var shortSearch = searchText.substring(0, 20);
              index = cleanVal.indexOf(shortSearch);
            }
            
            if (index !== -1) {
              var originalIndex = val.toLowerCase().indexOf(searchText.substring(0, Math.min(10, searchText.length)));
              if (originalIndex === -1) originalIndex = index;
              
              var span = iframeDoc.createElement('span');
              span.className = 'tts-active-highlight';
              span.style.backgroundColor = 'rgba(255, 235, 59, 0.45)';
              span.style.color = 'black';
              span.style.borderRadius = '2px';
              span.style.padding = '1px 0';
              
              var matchLen = Math.min("$escaped".length, val.length - originalIndex);
              if (matchLen <= 0) matchLen = 10;
              
              var matchedText = textNode.splitText(originalIndex);
              matchedText.splitText(matchLen);
              
              var parent = matchedText.parentNode;
              if (parent) {
                parent.insertBefore(span, matchedText);
                span.appendChild(matchedText);
                // Do NOT call scrollIntoView in paginated mode, as horizontal scrolling
                // corrupts WKWebView column layout alignment and shifts page margins!
                return true;
              }
            }
          }
        }
        return false;
      })();
    ''';
    await epubController.webViewController?.evaluateJavascript(source: js);
  }

  Future<void> _clearTtsHighlight() async {
    const js = '''
      (function() {
        var iframes = document.querySelectorAll('iframe');
        for (var i = 0; i < iframes.length; i++) {
          var iframeDoc = iframes[i].contentDocument || iframes[i].contentWindow.document;
          if (!iframeDoc) continue;
          var highlights = iframeDoc.querySelectorAll('.tts-active-highlight');
          highlights.forEach(function(span) {
            var parent = span.parentNode;
            if (parent) {
              while (span.firstChild) {
                parent.insertBefore(span.firstChild, span);
              }
              parent.removeChild(span);
              parent.normalize();
            }
          });
        }
      })();
    ''';
    await epubController.webViewController?.evaluateJavascript(source: js);
  }

  // ── TTS engine ─────────────────────────────────────────────────────────────

  void _initTts() {
    TtsService.instance.onSpeechCompleted = () {
      if (_isTtsActive && _isTtsPlaying && mounted) {
        _onSentenceFinished();
      }
    };
  }

  Future<void> _toggleTtsPlay() async {
    if (_isTtsPlaying || TtsService.instance.isPlaying) {
      await TtsService.instance.pause();
      if (mounted) {
        setState(() => _isTtsPlaying = false);
      }
    } else {
      if (mounted) {
        setState(() => _isTtsPlaying = true);
      }
      if (_sentences.isEmpty) {
        await _loadPageTextAndPlay();
      } else {
        await _speakCurrentSentence();
      }
    }
  }



  List<String> _splitIntoSentences(String text) {
    if (text.isEmpty) return [];
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Split by Bengali full stop (।), English period (.), question mark, exclamation.
    final regex = RegExp(r'[^.!?।]+[.!?।]?');
    return regex.allMatches(normalized)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty && s.length > 2)
        .toList();
  }

  Future<void> _speakCurrentSentence() async {
    if (_sentences.isEmpty) {
      await _loadPageTextAndPlay();
      return;
    }

    if (_currentSentenceIndex >= _sentences.length) {
      // Page completed, turn to next page
      _ttsPageSettling = true;
      await _clearTtsHighlight();
      epubController.next();
      return;
    }

    final sentence = _sentences[_currentSentenceIndex];
    // Start sentence highlight in webview asynchronously so audio starts instantly
    unawaited(_highlightSentenceInWebView(sentence));
    await TtsService.instance.speak(
      text: sentence,
      bookId: widget.bookId,
      paragraphIndex: _currentSentenceIndex,
    );
  }



  Future<void> _onSentenceFinished() async {
    _currentSentenceIndex++;
    if (_currentSentenceIndex < _sentences.length) {
      // Small 60ms delay for iOS AVSpeechSynthesizer delegate reset before next utterance
      await Future.delayed(const Duration(milliseconds: 60));
      if (_isTtsActive && _isTtsPlaying && mounted) {
        await _speakCurrentSentence();
      }
    } else {
      // Mark that we are waiting for the new page to settle before extracting text
      _ttsPageSettling = true;
      await _clearTtsHighlight();
      // Turn to next page; onRelocated will trigger _loadPageTextAndPlay after settle delay
      epubController.next();
    }
  }

  Future<void> _ttsMoveLeft() async {
    if (_currentSentenceIndex > 0) {
      setState(() {
        _currentSentenceIndex--;
      });
      if (_isTtsPlaying) {
        await _speakCurrentSentence();
      } else {
        await _highlightSentenceInWebView(_sentences[_currentSentenceIndex]);
      }
    } else {
      // Go to previous page
      epubController.prev();
    }
  }

  Future<void> _ttsMoveRight() async {
    if (_currentSentenceIndex < _sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
      });
      if (_isTtsPlaying) {
        await _speakCurrentSentence();
      } else {
        await _highlightSentenceInWebView(_sentences[_currentSentenceIndex]);
      }
    } else {
      // Go to next page
      epubController.next();
    }
  }

  Future<void> _stopTts() async {
    TtsService.instance.onSpeechCompleted = null;
    await TtsService.instance.stop();
    await _clearTtsHighlight();
    if (mounted) {
      setState(() {
        _isTtsActive = false;
        _isTtsPlaying = false;
        _sentences = [];
        _currentSentenceIndex = 0;
        _showControls = true;
      });
    }
  }

  Future<void> _clearSelection() async {
    if (_lastSelection == null) return;
    const js = '''
      (function() {
        window.getSelection().removeAllRanges();
        var iframes = document.querySelectorAll('iframe');
        for (var i = 0; i < iframes.length; i++) {
          var iframeDoc = iframes[i].contentDocument || iframes[i].contentWindow.document;
          if (iframeDoc) {
            iframeDoc.getSelection().removeAllRanges();
          }
        }
      })();
    ''';
    await epubController.webViewController?.evaluateJavascript(source: js);
    setState(() {
      _lastSelection = null;
    });
  }

  // ── Bookmarking ────────────────────────────────────────────────────────────

  Future<void> _toggleBookmarkCurrentPage() async {
    final currentLocation = await epubController.getCurrentLocation();
    final cfi = currentLocation.startCfi;
    
    // Check if bookmarked
    final index = _bookmarks.indexWhere((b) => b.chapterId == cfi);
    if (index != -1) {
      // Delete bookmark
      final bookmark = _bookmarks[index];
      await BookmarkStorageService.deleteBookmark(bookmark);
    } else {
      // Add bookmark
      // Estimate chapter name from current relocation
      String chapterName = 'Page ${_currentPage}';
      if (_chapters.isNotEmpty) {
        // Attempt to match chapter
        for (final ch in _chapters) {
          if (cfi.contains(ch.href.replaceAll(RegExp(r'\.html|\.xhtml'), ''))) {
            chapterName = ch.title;
            break;
          }
        }
      }

      final bookmark = BookmarkModel(
        id: BookmarkModel.generateId(widget.bookId, cfi),
        bookId: widget.bookId,
        chapterId: cfi,
        chapterName: chapterName,
        pageNumber: _currentPage,
        createdAt: DateTime.now(),
      );
      await BookmarkStorageService.saveBookmark(bookmark);
    }
    await _loadBookmarksAndHighlights();
  }

  bool _isCurrentPageBookmarked(String cfi) {
    return _bookmarks.any((b) => b.chapterId == cfi);
  }

  // ── Navigation Drawer sheets ───────────────────────────────────────────────

  void _openChaptersAndBookmarksSheet({int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localizations = FFLocalizations.of(context);
        final theme = FlutterFlowTheme.of(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 3,
              initialIndex: initialTabIndex,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.alternate,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TabBar(
                      indicatorColor: theme.primary,
                      labelColor: theme.primaryText,
                      unselectedLabelColor: theme.secondaryText,
                      labelStyle: theme.titleMedium.override(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        Tab(text: localizations.getVariableText(enText: 'Chapters', bnText: 'অধ্যায়')),
                        Tab(text: localizations.getVariableText(enText: 'Bookmarks', bnText: 'বুকমার্ক')),
                        Tab(text: localizations.getVariableText(enText: 'Highlights', bnText: 'হাইলাইট')),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Chapters list
                          _chapters.isEmpty
                              ? Center(
                                  child: Text(
                                    localizations.getVariableText(enText: 'No chapters available', bnText: 'কোনো অধ্যায় পাওয়া যায়নি'),
                                    style: theme.bodyMedium,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _chapters.length,
                                  itemBuilder: (context, index) {
                                    final chapter = _chapters[index];
                                    return ListTile(
                                      title: Text(
                                        chapter.title,
                                        style: theme.bodyLarge,
                                      ),
                                      onTap: () {
                                        epubController.display(cfi: chapter.href);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                          // Bookmarks list
                          _bookmarks.isEmpty
                              ? Center(
                                  child: Text(
                                    localizations.getVariableText(enText: 'No bookmarks saved', bnText: 'কোনো বুকমার্ক সংরক্ষিত নেই'),
                                    style: theme.bodyMedium,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _bookmarks.length,
                                  itemBuilder: (context, index) {
                                    final bookmark = _bookmarks[index];
                                    return ListTile(
                                      title: Text(
                                        bookmark.chapterName,
                                        style: theme.bodyLarge,
                                      ),
                                      subtitle: Text(
                                        'Page ${bookmark.pageNumber}',
                                        style: theme.bodySmall.override(
                                          fontFamily: 'Inter',
                                          color: theme.secondaryText,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_outline, color: theme.error),
                                        onPressed: () async {
                                          await BookmarkStorageService.deleteBookmark(bookmark);
                                          await _loadBookmarksAndHighlights();
                                          setModalState(() {});
                                        },
                                      ),
                                      onTap: () {
                                        epubController.display(cfi: bookmark.chapterId);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                          // Highlights list
                          _highlights.isEmpty
                              ? Center(
                                  child: Text(
                                    localizations.getVariableText(enText: 'No highlights saved', bnText: 'কোনো হাইলাইট সংরক্ষিত নেই'),
                                    style: theme.bodyMedium,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _highlights.length,
                                  itemBuilder: (context, index) {
                                    final highlight = _highlights[index];
                                    return ListTile(
                                      title: Text(
                                        highlight.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.bodyMedium,
                                      ),
                                      subtitle: Text(
                                        highlight.chapterName,
                                        style: theme.bodySmall.override(
                                          fontFamily: 'Inter',
                                          color: theme.secondaryText,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_outline, color: theme.error),
                                        onPressed: () async {
                                          await HighlightStorageService.deleteHighlight(highlight);
                                          await _loadBookmarksAndHighlights();
                                          setModalState(() {});
                                        },
                                      ),
                                      onTap: () {
                                        epubController.display(cfi: highlight.chapterId);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openStyleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localizations = FFLocalizations.of(context);
        final theme = FlutterFlowTheme.of(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Font selection
                    Text(
                      localizations.getVariableText(enText: 'Fonts', bnText: 'ফন্ট'),
                      style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'default',
                          'literata',
                          'sans serif',
                          'noto sans bengali',
                          'noto serif bengali',
                          'tiro bangla'
                        ].map((fontKey) {
                          final label = fontKey == 'default'
                              ? 'Default'
                              : fontKey == 'sans serif' ? 'Sans Serif' : fontKey.split(' ').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
                          final isSelected = _fontFamily == fontKey;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) async {
                                if (selected) {
                                  setState(() => _fontFamily = fontKey);
                                  setModalState(() {});
                                  await _savePreference('epub_font_family_${widget.bookId}', fontKey);
                                  await _applyStyles();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 24),
                    // Font size selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.getVariableText(enText: 'Font Size', bnText: 'ফন্টের সাইজ'),
                          style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                        ),
                        Text('${_fontSize.toInt()}'),
                      ],
                    ),
                    Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 30.0,
                      divisions: 18,
                      activeColor: theme.primary,
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                        setModalState(() {});
                      },
                      onChangeEnd: (value) async {
                        await _savePreference('epub_font_size_${widget.bookId}', value);
                        await _applyStyles();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openBrightnessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localizations = FFLocalizations.of(context);
        final theme = FlutterFlowTheme.of(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme selector
                    Text(
                      localizations.getVariableText(enText: 'Themes', bnText: 'থিম'),
                      style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildThemeButton(ReaderThemeType.light, 'Light', const Color(0xffffffff), const Color(0xff000000), setModalState),
                        _buildThemeButton(ReaderThemeType.sepia, 'Sepia', const Color(0xfff4ecd8), const Color(0xff5b4636), setModalState),
                        _buildThemeButton(ReaderThemeType.dark, 'Dark', const Color(0xff121212), const Color(0xffffffff), setModalState),
                      ],
                    ),
                    const Divider(height: 24),
                    // Brightness slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.getVariableText(enText: 'Brightness', bnText: 'উজ্জ্বলতা'),
                          style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.brightness_medium, color: theme.secondaryText),
                      ],
                    ),
                    Slider(
                      value: _currentBrightness,
                      min: 0.0,
                      max: 1.0,
                      activeColor: theme.primary,
                      onChanged: (value) async {
                        await _setBrightness(value);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeButton(
    ReaderThemeType type,
    String label,
    Color bg,
    Color fg,
    StateSetter setModalState,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = _themeType == type;

    return InkWell(
      onTap: () async {
        setState(() => _themeType = type);
        setModalState(() {});
        await _savePreference('epub_theme_${widget.bookId}', type.index);
        await _applyStyles();
      },
      child: Container(
        width: 90,
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: isSelected ? theme.primary : theme.alternate,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _openTtsSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localizations = FFLocalizations.of(context);
        final theme = FlutterFlowTheme.of(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Speed slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.getVariableText(enText: 'Speech Speed', bnText: 'পড়ার গতি'),
                          style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                        ),
                        Text('${(TtsService.instance.speechRate * 2.0).toStringAsFixed(1)}x'),
                      ],
                    ),
                    Slider(
                      value: TtsService.instance.speechRate,
                      min: 0.1,
                      max: 1.0,
                      activeColor: theme.primary,
                      onChanged: (value) async {
                        await TtsService.instance.setSpeechRate(value);
                        setModalState(() {});
                      },
                    ),
                    const Divider(height: 24),
                    // Ambient backgrounds
                    Text(
                      localizations.getVariableText(enText: 'Background Sound', bnText: 'ব্যাকগ্রাউন্ড সুর'),
                      style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TtsService.instance.ambientTracks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              localizations.getVariableText(enText: 'Loading tracks...', bnText: 'লোড হচ্ছে...'),
                              style: theme.bodySmall.override(fontFamily: 'Inter', color: theme.secondaryText),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // None track
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text('${localizations.getVariableText(enText: 'None', bnText: 'কিছু না')} 🔇'),
                                    selected: _selectedAmbientTrack == null,
                                    onSelected: (selected) async {
                                      if (selected) {
                                        setState(() {
                                          _selectedAmbientTrack = null;
                                        });
                                        setModalState(() {});
                                        await TtsService.instance.selectAmbientTrack(null);
                                      }
                                    },
                                  ),
                                ),
                                ...TtsService.instance.ambientTracks.map((track) {
                                  final isSelected = _selectedAmbientTrack?.id == track.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text('${track.label} ${track.emoji}'),
                                      selected: isSelected,
                                      onSelected: (selected) async {
                                        if (selected) {
                                          setState(() {
                                            _selectedAmbientTrack = track;
                                          });
                                          setModalState(() {});
                                          await TtsService.instance.selectAmbientTrack(track);
                                        }
                                      },
                                    ),
                                  );
                                }).toList()
                              ],
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _appliedAmbientTrack = _selectedAmbientTrack;
                            });
                            if (_selectedAmbientTrack != null) {
                              _prefs?.setString('epub_ambient_track_id_${widget.bookId}', _selectedAmbientTrack!.id);
                            } else {
                              _prefs?.remove('epub_ambient_track_id_${widget.bookId}');
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                          ),
                          child: Text(
                            localizations.getVariableText(enText: 'Apply', bnText: 'প্রয়োগ করুন'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final localizations = FFLocalizations.of(context);

    return Scaffold(
      backgroundColor: EpubStyleHelper.getBackgroundColor(_themeType),
      body: SafeArea(
        child: Stack(
          children: [
            // EPUB viewer
            Positioned(
              top: (_showControls && !isLoading) ? 56.0 : 0.0,
              bottom: (_showControls && !isLoading)
                  ? (_isTtsActive ? 70.0 : 56.0) // nav bar height only
                  : (isLoading ? 0.0 : 28.0), // slim progress bar at bottom
              left: 0,
              right: 0,
              child: EpubViewer(
                epubSource: epubSource,
                epubController: epubController,
                displaySettings: EpubDisplaySettings(
                  flow: EpubFlow.paginated,
                  theme: EpubStyleHelper.getEpubTheme(
                    themeType: _themeType,
                    fontFamilyKey: _fontFamily,
                    fontSize: _fontSize,
                  ),
                  useSnapAnimationAndroid: false,
                  snap: false, // snap: false on iOS avoids WKWebView scroll-snap column misalignment & overlap
                  allowScriptedContent: true,
                ),
                onChaptersLoaded: (chapters) {
                  setState(() {
                    _chapters = chapters;
                    _updateTotalPages();
                  });
                },
                onEpubLoaded: () async {
                  setState(() {
                    isLoading = false;
                  });
                  // Preload local fonts on isolate (fire-and-forget, then apply)
                  unawaited(_preloadLocalFonts().then((_) async {
                    await _applyStyles();
                    await _preloadAllChapterPages();
                  }));

                  if (!_hasJumpedToInitial) {
                    _hasJumpedToInitial = true;
                    
                    // Prioritize SharedPreferences exact CFI position
                    final savedCfi = _prefs?.getString('epub_cfi_${widget.bookId}');
                    
                    if (savedCfi != null && savedCfi.isNotEmpty) {
                      await Future.delayed(const Duration(milliseconds: 600));
                      epubController.display(cfi: savedCfi);
                    } else if (widget.initialProgress != null && widget.initialProgress! > 0) {
                      // Fallback to percentage jump
                      final normalized = widget.initialProgress! > 1 
                          ? widget.initialProgress! / 100.0 
                          : widget.initialProgress!;
                      await Future.delayed(const Duration(milliseconds: 600));
                      epubController.toProgressPercentage(normalized);
                    }
                  }
                },
                onRelocated: (value) async {
                  final percent = (value.progress * 100).toInt().clamp(0, 100);

                  // Sync reading progress (non-blocking)
                  if (percent > 0) {
                    unawaited(ProgressSyncService.saveReadingProgress(
                      bookId: widget.bookId,
                      currentPage: percent,
                      totalPages: 100,
                    ));
                    unawaited(ReadingReportService.instance.updateProgress(
                      percentage: percent,
                    ));
                    _prefs?.setString('epub_cfi_${widget.bookId}', value.startCfi);
                  }

                  // Clear active selection on relocate to prevent blocked gestures/white screens
                  if (_lastSelection != null) {
                    unawaited(_clearSelection());
                  }

                  // Determine current page & total pages using exact chapter screen page counts
                  int calcTotal = _totalPages;
                  int calcCurrent = _currentPage;
                  try {
                    final rawJson = await epubController.webViewController?.evaluateJavascript(
                      source: '(function(){ try { var c = rendition.currentLocation(); if (!c || !c.start) return JSON.stringify({chI: 0, p: 1, t: 1}); var chI = c.start.index !== undefined ? c.start.index : 0; var p = (c.start.displayed && c.start.displayed.page) ? c.start.displayed.page : 1; var t = (c.start.displayed && c.start.displayed.total) ? c.start.displayed.total : 1; return JSON.stringify({chI: chI, p: p, t: t}); } catch(e){ return "{\\"chI\\":0,\\"p\\":1,\\"t\\":1}"; } })()',
                    );
                    if (rawJson is String && rawJson.contains('{')) {
                      final map = jsonDecode(rawJson) as Map<String, dynamic>;
                      final chI = (map['chI'] as num?)?.toInt() ?? 0;
                      final p = (map['p'] as num?)?.toInt() ?? 1;
                      final t = (map['t'] as num?)?.toInt() ?? 1;

                      _chapterPageTotals[chI] = t;

                      int totalVisitedPages = 0;
                      _chapterPageTotals.forEach((_, count) => totalVisitedPages += count);
                      final avgPages = _chapterPageTotals.isNotEmpty
                          ? (totalVisitedPages / _chapterPageTotals.length).round()
                          : 5;

                      int prevSum = 0;
                      for (int i = 0; i < chI; i++) {
                        prevSum += _chapterPageTotals[i] ?? avgPages;
                      }
                      calcCurrent = prevSum + p;

                      int totalSum = 0;
                      final numChapters = _chapters.isNotEmpty ? _chapters.length : (chI + 1);
                      for (int i = 0; i < numChapters; i++) {
                        totalSum += _chapterPageTotals[i] ?? avgPages;
                      }
                      calcTotal = totalSum > 0 ? totalSum : 1;
                    }
                  } catch (_) {
                    calcTotal = _totalPages > 0 ? _totalPages : (_chapters.length * 5).clamp(10, 300);
                    calcCurrent = ((value.progress * calcTotal).floor() + 1).clamp(1, calcTotal);
                  }

                  // Single batched state update per page relocation
                  setState(() {
                    progress = value.progress;
                    _currentCfi = value.startCfi;
                    _totalPages = calcTotal;
                    _currentPage = calcCurrent.clamp(1, calcTotal);
                  });

                  // Note: Local and Google fonts are injected during initial load (onEpubLoaded)
                  // and when theme changes (_applyStyles). Do NOT re-inject on every relocate,
                  // as injecting <style> nodes during page turns causes WKWebView reflow flickering.

                  // TTS continuous playback logic when page turns
                  if (_isTtsActive && _isTtsPlaying && _ttsPageSettling) {
                    _ttsPageSettling = false;
                    setState(() {
                      _sentences = [];
                      _currentSentenceIndex = 0;
                    });
                    // Wait for the new page iframe to fully render before extracting text
                    await Future.delayed(const Duration(milliseconds: 600));
                    if (_isTtsActive && _isTtsPlaying && mounted) {
                      await _loadPageTextAndPlay();
                    }
                  }
                },
                onTouchDown: (x, y) {
                  _touchStartX = x;
                  _touchStartY = y;
                  _touchStartTime = DateTime.now().millisecondsSinceEpoch;
                },
                onTouchUp: (x, y) async {
                  final nowMs = DateTime.now().millisecondsSinceEpoch;
                  // Debounce rapid duplicate taps (e.g. within 350ms)
                  if (nowMs - _lastTapTimeMs < 350) return;

                  final deltaX = x - _touchStartX; // Directional horizontal distance
                  final deltaY = (y - _touchStartY).abs();
                  final duration = nowMs - _touchStartTime;

                  // 1. Swipe / Drag gesture (horizontal distance >= 6% of screen, vertical < 15%)
                  if (deltaX.abs() >= 0.06 && deltaY < 0.15 && duration < 750) {
                    _lastTapTimeMs = nowMs;
                    if (_lastSelection != null) {
                      await _clearSelection();
                      return;
                    }
                    if (deltaX < 0) {
                      // Swiped left (dragged right-to-left) -> Next page
                      epubController.next();
                    } else {
                      // Swiped right (dragged left-to-right) -> Previous page
                      epubController.prev();
                    }
                    return;
                  }

                  // 2. Tap gesture (minimal movement < 6% of screen)
                  if (deltaX.abs() < 0.06 && deltaY < 0.12 && duration < 450) {
                    _lastTapTimeMs = nowMs;

                    // If text selection is active, clear it first
                    if (_lastSelection != null) {
                      await _clearSelection();
                      return;
                    }
                    if (x < 0.35) {
                      epubController.prev();
                    } else if (x > 0.65) {
                      epubController.next();
                    } else {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    }
                  }
                },
                selectionContextMenu: ContextMenu(
                  menuItems: [
                    ContextMenuItem(
                      title: localizations.getVariableText(enText: 'Highlight', bnText: 'হাইলাইট'),
                      id: 1,
                      action: () async {
                        if (_lastSelection != null) {
                          final text = _lastSelection!.selectedText.trim();
                          if (text.isNotEmpty) {
                            epubController.addHighlight(
                              cfi: _lastSelection!.selectionCfi,
                              color: Colors.yellow,
                            );

                            // Create highlight model
                            String chapterName = 'Page $_currentPage';
                            if (_chapters.isNotEmpty) {
                              for (final ch in _chapters) {
                                if (_lastSelection!.selectionCfi.contains(ch.href.replaceAll(RegExp(r'\.html|\.xhtml'), ''))) {
                                  chapterName = ch.title;
                                  break;
                                }
                              }
                            }

                            final highlight = HighlightModel(
                              id: HighlightModel.generateId(widget.bookId, _lastSelection!.selectionCfi, text.hashCode),
                              bookId: widget.bookId,
                              chapterId: _lastSelection!.selectionCfi,
                              chapterName: chapterName,
                              text: text,
                              startPosition: 0,
                              endPosition: text.length,
                              createdAt: DateTime.now(),
                            );
                            await HighlightStorageService.saveHighlight(highlight);
                            await _loadBookmarksAndHighlights();
                          }
                        }
                      },
                    ),
                    ContextMenuItem(
                      title: localizations.getVariableText(enText: 'Translate', bnText: 'অনুবাদ'),
                      id: 2,
                      action: () async {
                        if (_lastSelection != null) {
                          final text = _lastSelection!.selectedText.trim();
                          if (text.isNotEmpty) {
                            final urlStr = 'https://translate.google.com/?sl=auto&tl=bn&text=${Uri.encodeComponent(text)}&op=translate';
                            final uri = Uri.parse(urlStr);
                            await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
                          }
                        }
                      },
                    ),
                  ],
                ),
                onDeselection: () {
                  setState(() {
                    _lastSelection = null;
                  });
                },
                onTextSelected: (selection) async {
                  _lastSelection = selection;
                },
              ),
            ),
            
            // Loading Overlay
            if (isLoading)
              Container(
                color: EpubStyleHelper.getBackgroundColor(_themeType),
                child: Center(
                  child: CircularProgressIndicator(color: theme.primary),
                ),
              ),

            // AppBar
            if (_showControls && !isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 56,
                  color: EpubStyleHelper.getBackgroundColor(_themeType),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: EpubStyleHelper.getForegroundColor(_themeType)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium.override(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            color: EpubStyleHelper.getForegroundColor(_themeType),
                          ),
                        ),
                      ),
                      // Search icon
                      IconButton(
                        icon: Icon(Icons.search, color: EpubStyleHelper.getForegroundColor(_themeType)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EpubSearchOverlay(
                                epubController: epubController,
                                bookTitle: widget.bookTitle,
                              ),
                            ),
                          );
                        },
                      ),
                      // TTS audio toggle — always show headset icon; use color to indicate state
                      IconButton(
                        icon: Icon(
                          Icons.headset,
                          color: _isTtsActive ? theme.primary : EpubStyleHelper.getForegroundColor(_themeType).withValues(alpha: 0.7),
                        ),
                        onPressed: () async {
                          if (_isTtsActive) {
                            await _stopTts();
                          } else {
                            // Turn on ambient track if saved
                            if (_appliedAmbientTrack != null) {
                              await TtsService.instance.selectAmbientTrack(_appliedAmbientTrack);
                            }
                            setState(() {
                              _isTtsActive = true;
                              _showControls = false; // Automatically enter full screen when TTS starts
                            });
                            await _loadPageTextAndPlay();
                          }
                        },
                      ),
                      // Bookmark toggle
                      IconButton(
                        icon: Icon(
                          _isCurrentPageBookmarked(_currentCfi)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isCurrentPageBookmarked(_currentCfi) ? theme.primary : EpubStyleHelper.getForegroundColor(_themeType),
                        ),
                        onPressed: _toggleBookmarkCurrentPage,
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Navigation Bar (no progress indicator here — only in fullscreen)
            if (_showControls && !_isTtsActive && !isLoading)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 56,
                  color: EpubStyleHelper.getBackgroundColor(_themeType),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomNavButton(Icons.toc, localizations.getVariableText(enText: 'Contents', bnText: 'সূচিপত্র'), () {
                        _openChaptersAndBookmarksSheet(initialTabIndex: 0);
                      }),
                      _buildBottomNavButton(Icons.bookmark_border, localizations.getVariableText(enText: 'Bookmarks', bnText: 'বুকমার্ক'), () {
                        _openChaptersAndBookmarksSheet(initialTabIndex: 1);
                      }),
                      _buildBottomNavButton(Icons.fullscreen, localizations.getVariableText(enText: 'Full Screen', bnText: 'ফুল স্ক্রিন'), () {
                        setState(() {
                          _showControls = false;
                        });
                      }),
                      _buildBottomNavButton(Icons.brightness_5, localizations.getVariableText(enText: 'Brightness', bnText: 'উজ্জ্বলতা'), _openBrightnessSheet),
                      _buildBottomNavButton(Icons.text_fields, localizations.getVariableText(enText: 'Font', bnText: 'ফন্ট'), _openStyleSheet),
                    ],
                  ),
                ),
              ),

            // TTS Controller Bar
            if (_isTtsActive && !isLoading)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 70,
                  color: EpubStyleHelper.getBackgroundColor(_themeType),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Settings
                      IconButton(
                        icon: Icon(Icons.settings, color: EpubStyleHelper.getForegroundColor(_themeType)),
                        onPressed: _openTtsSettingsSheet,
                      ),
                      // Skip previous / Left
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: EpubStyleHelper.getForegroundColor(_themeType), size: 28),
                        onPressed: _ttsMoveLeft,
                      ),
                      // Play / Pause
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: theme.primary,
                        onPressed: _toggleTtsPlay,
                        child: Icon(
                          _isTtsPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                      // Skip next / Right
                      IconButton(
                        icon: Icon(Icons.skip_next, color: EpubStyleHelper.getForegroundColor(_themeType), size: 28),
                        onPressed: _ttsMoveRight,
                      ),
                      // Stop
                      IconButton(
                        icon: Icon(Icons.stop, color: theme.error),
                        onPressed: _stopTts,
                      ),
                    ],
                  ),
                ),
              ),

            // Progress bar at very bottom (visible when controls hidden, but hidden during TTS)
            if (!_showControls && !_isTtsActive && !isLoading)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        _totalPages > 0
                            ? '$_currentPage/$_totalPages  ·  ${(progress * 100).toInt()}%'
                            : '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: EpubStyleHelper.getForegroundColor(_themeType).withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: EpubStyleHelper.getForegroundColor(_themeType).withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavButton(IconData icon, String label, VoidCallback onTap) {
    final theme = FlutterFlowTheme.of(context);
    final fgColor = EpubStyleHelper.getForegroundColor(_themeType).withValues(alpha: 0.7);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fgColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.bodySmall.override(
              fontFamily: 'Inter',
              color: fgColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
