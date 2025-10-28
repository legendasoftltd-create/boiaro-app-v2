// Automatic FlutterFlow imports
import 'dart:developer';

import 'package:a_i_ebook_app/custom_code/extensions/epub_image_extension.dart';
import 'package:a_i_ebook_app/custom_code/extensions/custom_text_selection_controls.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';

import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser; // Import html parser

enum ReaderType { pdf, epub }

enum AppThemeMode { light, dark, sepia }

class FlutterPdfViewWidget extends StatefulWidget {
  const FlutterPdfViewWidget({
    super.key,
    this.width,
    this.height,
    this.filePath,
    this.namePage,
  });

  final double? width;
  final double? height;
  final String? filePath;
  final String? namePage;

  @override
  State<FlutterPdfViewWidget> createState() => _FlutterPdfViewWidgetState();
}

PdfViewerController pdfViewerController = PdfViewerController();

class _FlutterPdfViewWidgetState extends State<FlutterPdfViewWidget> {
  ReaderType _readerType = ReaderType.epub;
  int currentPage = 1;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final FlutterTts flutterTts = FlutterTts();

  String selectedText = "";
  bool isSpeaking = false;
  double speechRate = 0.9;
  double pitch = 1.0;

  // Search variables
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  // Full screen mode variable
  bool _isFullScreen = false;

  // Screen rotation variable
  bool _isAutoRotateEnabled = true;

  // Brightness variables
  double currentBrightness = 0.5;
  double originalBrightness = 0.5;

  // Bookmark variables
  List<int> _bookmarkedPages = [];

  // Highlight variables for EPUB
  List<String> _highlights = [];

  // EPUB variables
  epubx.EpubBook? _epubBook;
  List<epubx.EpubChapter> _epubChapters = [];
  int _currentEpubChapterIndex = 0;
  String _currentEpubContent = "";
  bool _isLoadingEpub = false;
  final ScrollController _epubScrollController = ScrollController();
  final ValueNotifier<String> _currentEpubContentNotifier =
      ValueNotifier<String>('');
  
  // Font size for EPUB
  double _epubFontSize = 16.0;

  // Line height for EPUB
  double _epubLineHeight = 1.6;

  // Theme mode for EPUB
  AppThemeMode _currentThemeMode = AppThemeMode.light;

  @override
  void initState() {
    super.initState();
    _determineReaderType();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() => currentPage = 1);
      _getInitialBrightness();
      if (_readerType == ReaderType.epub) {
        _loadEpubBook();
      }
    });
  }

  void _determineReaderType() {
    if (widget.filePath != null) {
      final String path = widget.filePath!.toLowerCase();
      if (path.endsWith('.epub')) {
        _readerType = ReaderType.epub;
      } else if (path.endsWith('.pdf')) {
        _readerType = ReaderType.pdf;
      } else {
        // Default to PDF if extension is not recognized
        _readerType = ReaderType.pdf;
      }
    }
  }
  Future<void> _loadEpubBook() async {
    if (widget.filePath == null || widget.filePath!.isEmpty) {
      log('Invalid EPUB path');
      return;
    }
  
    setState(() => _isLoadingEpub = true);
    try {
      List<int> bytes;
  
      if (widget.filePath!.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.filePath!));
        bytes = response.bodyBytes;
      } else if (widget.filePath!.startsWith('assets/')) {
        final data = await rootBundle.load(widget.filePath!);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(widget.filePath!);
        bytes = await file.readAsBytes();
      }
  
      _epubBook = await epubx.EpubReader.readBook(bytes);
      _epubChapters = _getAllChapters(_epubBook!.Chapters ?? []);
  
      if (_epubChapters.isNotEmpty) {
        _loadEpubChapter(0);
      }
    } catch (e, stacktrace) {
      log('Error loading EPUB: $e stacktrace $stacktrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading EPUB file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingEpub = false);
    }
  }


  List<epubx.EpubChapter> _getAllChapters(List<epubx.EpubChapter> chapters) {
    List<epubx.EpubChapter> allChapters = [];
    for (var chapter in chapters) {
      allChapters.add(chapter);
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        allChapters.addAll(_getAllChapters(chapter.SubChapters!));
      }
    }
    return allChapters;
  }

  String _parseHtmlContent(String? htmlContent) {
    if (htmlContent == null || htmlContent.isEmpty) return "";
    // Parse HTML content to extract plain text for TTS
    final document = html_parser.parse(htmlContent);
    final String parsedText = document.body?.text ?? '';
    return htmlContent;
  }

  void _loadEpubChapter(int index) {
    if (index >= 0 && index < _epubChapters.length) {
      setState(() {
        _currentEpubChapterIndex = index;
        currentPage = index + 1;
        
        final chapter = _epubChapters[index];
        _currentEpubContent = _parseHtmlContent(chapter.HtmlContent);

        // Apply highlights
        for (final highlight in _highlights) {
          _currentEpubContent = _currentEpubContent.replaceAll(
            highlight,
            '<mark style="background-color: yellow;">$highlight</mark>',
          );
        }
        _currentEpubContentNotifier.value = _currentEpubContent;
        
        // Update total pages for EPUB (based on chapters)
        FFAppState().totalPages = _epubChapters.length;
        FFAppState().update(() {
          FFAppState().homePageTotalPdfPageIndex = _epubChapters.length;
          FFAppState().homePageCurrentPdfIndex = currentPage;
        });
        
        // Scroll to top when changing chapters
        if (_epubScrollController.hasClients) {
          _epubScrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _restoreOriginalBrightness();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _searchController.dispose();
    _epubScrollController.dispose();
    _currentEpubContentNotifier.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _getInitialBrightness() async {
    try {
      final brightness = await ScreenBrightness().current;
      setState(() {
        originalBrightness = brightness;
        currentBrightness = brightness;
      });
    } catch (e) {
      log('Error getting initial brightness: $e');
    }
  }

  Future<void> _restoreOriginalBrightness() async {
    try {
      await ScreenBrightness().setScreenBrightness(originalBrightness);
    } catch (e) {
      log('Error restoring brightness: $e');
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
      setState(() => currentBrightness = brightness);
    } catch (e) {
      log('Error setting brightness: $e');
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _toggleAutoRotate() {
    setState(() {
      _isAutoRotateEnabled = !_isAutoRotateEnabled;
      if (_isAutoRotateEnabled) {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  void setCurrentPage() {
    setState(() {
      if (_readerType == ReaderType.epub) {
        if (_currentEpubChapterIndex < _epubChapters.length - 1) {
          _loadEpubChapter(_currentEpubChapterIndex + 1);
        }
      } else {
        if (currentPage != FFAppState().totalPages) {
          currentPage++;
          pdfViewerController.jumpToPage(currentPage);
        }
      }
    });
  }

  void setCurrentMinusPage() {
    setState(() {
      if (_readerType == ReaderType.epub) {
        if (_currentEpubChapterIndex > 0) {
          _loadEpubChapter(_currentEpubChapterIndex - 1);
        }
      } else {
        if (currentPage > 1) {
          currentPage--;
          pdfViewerController.jumpToPage(currentPage);
        }
      }
    });
  }

  void _addHighlight() {
    if (selectedText.isNotEmpty && _readerType == ReaderType.epub) {
      if (!_highlights.contains(selectedText)) {
        _highlights.add(selectedText);
      }
      final newContent = _currentEpubContent.replaceAll(
        selectedText,
        '<mark style="background-color: yellow;">$selectedText</mark>',
      );
      if (newContent != _currentEpubContent) {
        _currentEpubContent = newContent;
        _currentEpubContentNotifier.value = _currentEpubContent;
      }
      // Do not clear selection, so the buttons remain.
      // User can tap away to clear selection.
    }
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarkedPages.contains(currentPage)) {
        _bookmarkedPages.remove(currentPage);
      } else {
        _bookmarkedPages.add(currentPage);
      }
    });
  }

  Future<void> _speakSelected() async {
    if (selectedText.isEmpty) return;
    
    try {
      await flutterTts.setLanguage("bn-BD");
      await flutterTts.setSpeechRate(speechRate);
      await flutterTts.setPitch(pitch);

      setState(() => isSpeaking = true);
      
      flutterTts.setCompletionHandler(() {
        setState(() => isSpeaking = false);
      });
      
      await flutterTts.speak(selectedText);
    } catch (e) {
      log('Error speaking text: $e');
      setState(() => isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  void _openTtsSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔊 Voice Settings",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Speech Speed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Speed",
                          style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text("${speechRate.toStringAsFixed(2)}x",
                          style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                  Slider(
                    value: speechRate,
                    min: 0.3,
                    max: 1.5,
                    divisions: 12,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    label: speechRate.toStringAsFixed(2),
                    onChanged: (val) {
                      setModalState(() => speechRate = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),

                  /// Pitch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Pitch",
                          style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text("${pitch.toStringAsFixed(2)}",
                          style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                  Slider(
                    value: pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    label: pitch.toStringAsFixed(2),
                    onChanged: (val) {
                      setModalState(() => pitch = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Test Voice Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      bool isBnAvailable = false;
                      await flutterTts.getLanguages.then((languages) {
                        isBnAvailable = languages.contains("bn-BD");
                      });
                      log("isBnAvailable $isBnAvailable");
                      await flutterTts.setSpeechRate(speechRate);
                      await flutterTts.setPitch(pitch);
                      if (isBnAvailable) {
                        await flutterTts.setLanguage("bn-BD");
                        await flutterTts.speak("এই সেটিংস প্রিভিউ করার জন্য ধন্যবাদ।");
                      } else {
                        await flutterTts.setLanguage("en-US");
                        await flutterTts.speak(
                            "Bangla voice not available in this device, playing English sample.");
                      }
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text("Preview Voice",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),

                  /// Done button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBrightnessSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "☀️ Brightness Settings",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Brightness Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.brightness_low,
                          color: FlutterFlowTheme.of(context).secondaryText),
                      Expanded(
                        child: Slider(
                          value: currentBrightness,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          activeColor: FlutterFlowTheme.of(context).primary,
                          label: "${(currentBrightness * 100).toInt()}%",
                          onChanged: (val) {
                            setModalState(() {
                              _setBrightness(val);
                            });
                            setState(() {});
                          },
                        ),
                      ),
                      Icon(Icons.brightness_high,
                          color: FlutterFlowTheme.of(context).secondaryText),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(currentBrightness * 100).toInt()}%",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Quick Brightness Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBrightnessPreset(context, "25%", 0.25, setModalState),
                      _buildBrightnessPreset(context, "50%", 0.50, setModalState),
                      _buildBrightnessPreset(context, "75%", 0.75, setModalState),
                      _buildBrightnessPreset(context, "100%", 1.0, setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Theme Mode
                  Text(
                    "Theme Mode",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeModePreset(context, "Light", AppThemeMode.light, setModalState),
                      _buildThemeModePreset(context, "Dark", AppThemeMode.dark, setModalState),
                      _buildThemeModePreset(context, "Sepia", AppThemeMode.sepia, setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Done button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _setThemeMode(AppThemeMode mode) {
    setState(() {
      _currentThemeMode = mode;
    });
  }

  Widget _buildThemeModePreset(
    BuildContext context,
    String label,
    AppThemeMode mode,
    StateSetter setModalState,
  ) {
    final isSelected = _currentThemeMode == mode;
    return InkWell(
      onTap: () {
        setModalState(() {
          _setThemeMode(mode);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _openFontSettings() {
    if (_readerType != ReaderType.epub) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔤 Font Settings",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Font Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Font Size",
                          style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text("${_epubFontSize.toInt()}",
                          style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                  Slider(
                    value: _epubFontSize,
                    min: 12.0,
                    max: 32.0,
                    divisions: 20,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    label: _epubFontSize.toInt().toString(),
                    onChanged: (val) {
                      setModalState(() => _epubFontSize = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Font Size Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFontPreset(context, "Small", 14.0, setModalState),
                      _buildFontPreset(context, "Medium", 18.0, setModalState),
                      _buildFontPreset(context, "Large", 24.0, setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Preview Text
                  /// Line Spacing Slider
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Line Spacing",
                          style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text("${_epubLineHeight.toStringAsFixed(1)}x",
                          style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                  Slider(
                    value: _epubLineHeight,
                    min: 1.0,
                    max: 2.5,
                    divisions: 15,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    label: _epubLineHeight.toStringAsFixed(1),
                    onChanged: (val) {
                      setModalState(() => _epubLineHeight = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Line Spacing Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLineHeightPreset(context, "Compact", 1.2, setModalState),
                      _buildLineHeightPreset(context, "Normal", 1.6, setModalState),
                      _buildLineHeightPreset(context, "Relaxed", 2.0, setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Preview Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Sample Text Preview\nনমুনা পাঠ্য প্রিভিউ",
                      style: TextStyle(fontSize: _epubFontSize, height: _epubLineHeight),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Done button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSearchOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔍 Search in ${_readerType == ReaderType.pdf ? 'PDF' : 'EPUB'}",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Search text",
                      hintText: "Enter text to search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setModalState(() {
                            _searchController.clear();
                            _clearSearch();
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchText = value;
                      });
                    },
                    onSubmitted: (value) {
                      setModalState(() {
                        if (_readerType == ReaderType.pdf) {
                          _searchPdf();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_readerType == ReaderType.pdf)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchResult.hasResult
                              ? "${_searchResult.currentInstanceIndex + 1} of ${_searchResult.totalInstanceCount}"
                              : "No results",
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: _searchResult.hasResult &&
                                      _searchResult.currentInstanceIndex > 0
                                  ? () {
                                      setModalState(() {
                                        _goToPreviousSearchResult();
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: _searchResult.hasResult &&
                                      _searchResult.currentInstanceIndex <
                                          _searchResult.totalInstanceCount - 1
                                  ? () {
                                      setModalState(() {
                                        _goToNextSearchResult();
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setModalState(() {
                        if (_readerType == ReaderType.pdf) {
                          _searchPdf();
                        }
                      });
                    },
                    child: const Text("Search",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(context);
                    },
                    child: const Text("Done",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBookmarkCollection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔖 Bookmarked ${_readerType == ReaderType.epub ? 'Chapters' : 'Pages'}",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _bookmarkedPages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No bookmarked ${_readerType == ReaderType.epub ? 'chapters' : 'pages'} yet.",
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _bookmarkedPages.length,
                            itemBuilder: (context, index) {
                              final pageNumber = _bookmarkedPages[index];
                              String title = _readerType == ReaderType.epub
                                  ? "Chapter $pageNumber"
                                  : "Page $pageNumber";
                              
                              if (_readerType == ReaderType.epub && 
                                  pageNumber - 1 < _epubChapters.length) {
                                final chapterTitle = _epubChapters[pageNumber - 1].Title;
                                if (chapterTitle != null && chapterTitle.isNotEmpty) {
                                  title = chapterTitle;
                                }
                              }
                              
                              return ListTile(
                                leading: Icon(
                                  Icons.bookmark,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                                title: Text(
                                  title,
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setModalState(() {
                                      _bookmarkedPages.remove(pageNumber);
                                    });
                                    setState(() {});
                                  },
                                ),
                                onTap: () {
                                  if (_readerType == ReaderType.pdf) {
                                    pdfViewerController.jumpToPage(pageNumber);
                                  } else {
                                    _loadEpubChapter(pageNumber - 1);
                                  }
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openChapterList() {
    if (_readerType != ReaderType.epub || _epubChapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "📖 Table of Contents",
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _epubChapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _epubChapters[index];
                    final isCurrentChapter = index == _currentEpubChapterIndex;
                    return ListTile(
                      leading: Icon(
                        Icons.book_outlined,
                        color: isCurrentChapter
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).secondaryText,
                      ),
                      title: Text(
                        chapter.Title ?? "Chapter ${index + 1}",
                        style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                              fontWeight: isCurrentChapter
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentChapter
                                  ? FlutterFlowTheme.of(context).primary
                                  : null,
                            ),
                      ),
                      trailing: isCurrentChapter
                          ? Icon(
                              Icons.play_arrow,
                              color: FlutterFlowTheme.of(context).primary,
                            )
                          : null,
                      onTap: () {
                        _loadEpubChapter(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _searchPdf() {
    if (searchText.isNotEmpty && _readerType == ReaderType.pdf) {
      setState(() {
        _searchResult = pdfViewerController.searchText(searchText);
      });
    }
  }

  void _clearSearch() {
    setState(() {
      if (_readerType == ReaderType.pdf) {
        _searchResult.clear();
      }
      searchText = "";
      _searchController.clear();
    });
  }

  void _goToNextSearchResult() {
    if (_searchResult.hasResult) {
      setState(() {
        _searchResult.nextInstance();
      });
    }
  }

  void _goToPreviousSearchResult() {
    if (_searchResult.hasResult) {
      setState(() {
        _searchResult.previousInstance();
      });
    }
  }

  Widget _buildBrightnessPreset(
    BuildContext context,
    String label,
    double value,
    StateSetter setModalState,
  ) {
    final isSelected = (currentBrightness - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        setModalState(() {
          _setBrightness(value);
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLineHeightPreset(
    BuildContext context,
    String label,
    double value,
    StateSetter setModalState,
  ) {
    final isSelected = (_epubLineHeight - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        setModalState(() => _epubLineHeight = value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFontPreset(
    BuildContext context,
    String label,
    double value,
    StateSetter setModalState,
  ) {
    final isSelected = (_epubFontSize - value).abs() < 1.0;
    return InkWell(
      onTap: () {
        setModalState(() => _epubFontSize = value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEpubReader() {
  if (_isLoadingEpub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: FlutterFlowTheme.of(context).primary,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading...",
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
        ],
      ),
    );
  }

  if (_epubBook == null || _currentEpubContent.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load EPUB file",
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
        ],
      ),
    );
  }

  Color backgroundColor;
  Color textColor;

  switch (_currentThemeMode) {
    case AppThemeMode.light:
      backgroundColor = Colors.white;
      textColor = Colors.black;
      break;
    case AppThemeMode.dark:
      backgroundColor = Colors.black;
      textColor = Colors.white;
      break;
    case AppThemeMode.sepia:
      backgroundColor = const Color(0xFFF5DEB3); // Sepia color
      textColor = Colors.black;
      break;
  }

  return Container(
    color: backgroundColor,
    child: SelectionArea(
      selectionControls: CustomTextSelectionControls(
        onHighlight: _addHighlight,
        onListen: () {
          setState(() {
            selectedText=selectedText;
          });
          isSpeaking ? _stopSpeaking() : _speakSelected();
        },
      ),
      onSelectionChanged: (SelectedContent? selection) {
        final newSelectedText = selection?.plainText ?? '';
        if ((selectedText.isEmpty && newSelectedText.isNotEmpty) ||
            (selectedText.isNotEmpty && newSelectedText.isEmpty)) {
            selectedText = newSelectedText;
        } else {
          selectedText = newSelectedText;
        }
      },
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (ScrollEndNotification notification) {
          if (notification.metrics.pixels == notification.metrics.maxScrollExtent) {
            // User has scrolled to the end of the current chapter
            if (_currentEpubChapterIndex < _epubChapters.length - 1) {
              _loadEpubChapter(_currentEpubChapterIndex + 1);
              return true; // Prevent further notifications
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _epubScrollController,
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<String>(
            valueListenable: _currentEpubContentNotifier,
            builder: (context, content, child) {
              return Html(
                data: content,
                style: {
                  "body": Style(
                    fontFamily: 'SF Pro Display',
                    fontSize: FontSize(_epubFontSize),
                    letterSpacing: 0.3,
                    lineHeight: LineHeight.em(_epubLineHeight),
                    textAlign: TextAlign.justify,
                    color: textColor,
                    backgroundColor: backgroundColor,
                  ),
                  "p": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: textColor,
                  ),
                  "h1": Style(
                    fontSize: FontSize(_epubFontSize * 1.8),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "h2": Style(
                    fontSize: FontSize(_epubFontSize * 1.6),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "h3": Style(
                    fontSize: FontSize(_epubFontSize * 1.4),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "h4": Style(
                    fontSize: FontSize(_epubFontSize * 1.2),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "h5": Style(
                    fontSize: FontSize(_epubFontSize * 1.1),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "h6": Style(
                    fontSize: FontSize(_epubFontSize),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "em": Style(
                    fontStyle: FontStyle.italic,
                    color: textColor,
                  ),
                  "ul": Style(
                    listStyleType: ListStyleType.disc,
                    margin: Margins.only(left: 20),
                    color: textColor,
                  ),
                  "ol": Style(
                    listStyleType: ListStyleType.decimal,
                    margin: Margins.only(left: 20),
                    color: textColor,
                  ),
                  "li": Style(
                    margin: Margins.only(bottom: 8),
                    color: textColor,
                  ),
                  "table": Style(
                    backgroundColor: FlutterFlowTheme.of(context)
                        .alternate
                        .withOpacity(0.1),
                    border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate),
                    width: Width.auto(),
                    color: textColor,
                  ),
                  "th": Style(
                    padding: HtmlPaddings.all(8),
                    backgroundColor: FlutterFlowTheme.of(context).alternate,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  "td": Style(
                    padding: HtmlPaddings.all(8),
                    border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate),
                    color: textColor,
                  ),
                },
                extensions: [
                  EpubImageExtension(_epubBook!),
                  TableHtmlExtension(),
                  SvgHtmlExtension(),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    log("_currentEpubContent: ${_currentEpubContent}");
    Color scaffoldBackgroundColor;
    Color appBarBackgroundColor;
    Color appBarTextColor;
    Color bottomNavIconColor;

    if (_readerType == ReaderType.epub) {
      switch (_currentThemeMode) {
        case AppThemeMode.light:
          scaffoldBackgroundColor = Colors.white;
          appBarBackgroundColor = FlutterFlowTheme.of(context).secondaryBackground;
          appBarTextColor = Colors.black;
          bottomNavIconColor = FlutterFlowTheme.of(context).secondaryText;
          break;
        case AppThemeMode.dark:
          scaffoldBackgroundColor = Colors.black;
          appBarBackgroundColor = Colors.black; // Darker app bar for full screen
          appBarTextColor = Colors.white;
          bottomNavIconColor = Colors.white;
          break;
        case AppThemeMode.sepia:
          scaffoldBackgroundColor = const Color(0xFFF5DEB3); // Sepia color
          appBarBackgroundColor = FlutterFlowTheme.of(context).secondaryBackground;
          appBarTextColor = Colors.black;
          bottomNavIconColor = FlutterFlowTheme.of(context).secondaryText;
          break;
      }
    } else {
      scaffoldBackgroundColor = FlutterFlowTheme.of(context).primaryBackground;
      appBarBackgroundColor = FlutterFlowTheme.of(context).secondaryBackground;
      appBarTextColor = FlutterFlowTheme.of(context).primaryText;
      bottomNavIconColor = FlutterFlowTheme.of(context).secondaryText;
    }

    // Adjust colors for full screen mode if it's dark theme
    if (_isFullScreen && _currentThemeMode == AppThemeMode.dark) {
      scaffoldBackgroundColor = Colors.black;
      appBarBackgroundColor = Colors.black;
      appBarTextColor = Colors.white;
      bottomNavIconColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Column(
        children: [
          /// ---------- AppBar ----------
          Visibility(
            visible: !_isFullScreen,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: appBarBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () async => context.safePop(),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 22,
                      color: appBarTextColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.namePage ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            useGoogleFonts: false,
                            color: appBarTextColor,
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      if (_readerType == ReaderType.pdf)
                        InkWell(
                          onTap: _openSearchOverlay,
                          child: Icon(
                            Icons.search,
                            size: 24,
                            color: appBarTextColor,
                          ),
                        ),
                      if (_readerType == ReaderType.pdf) const SizedBox(width: 16),
                      InkWell(
                        onTap: _toggleBookmark,
                        child: Icon(
                          _bookmarkedPages.contains(currentPage)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 24,
                          color: appBarTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _openTtsSettings,
                        child: Icon(
                          Icons.more_vert,
                          size: 24,
                          color: appBarTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// ---------- Content Viewer ----------
          Expanded(
            child: Stack(
              children: [
                if (_readerType == ReaderType.pdf)
                  SfPdfViewer.network(
                    widget.filePath!,
                    key: _pdfViewerKey,
                    controller: pdfViewerController,
                    scrollDirection: PdfScrollDirection.vertical,
                    canShowTextSelectionMenu: true,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      int totalPages = details.document.pages.count;
                      setState(() => FFAppState().totalPages = totalPages);
                      FFAppState().update(() {
                        FFAppState().homePageTotalPdfPageIndex =
                            FFAppState().totalPages;
                      });
                      pdfViewerController.jumpToPage(currentPage);
                    },
                    onPageChanged: (details) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          currentPage = details.newPageNumber;
                          FFAppState().update(() {
                            FFAppState().homePageCurrentPdfIndex = currentPage;
                          });
                        });
                      });
                    },
                    onTextSelectionChanged:
                        (PdfTextSelectionChangedDetails details) {
                      if (details.selectedText != null &&
                          details.selectedText!.isNotEmpty) {
                        setState(() => selectedText = details.selectedText!);
                      } else {
                        setState(() => selectedText = "");
                      }
                    },
                  )
                else
                  _buildEpubReader(),

                /// Full Screen Exit Button (only visible in full screen)
                if (_isFullScreen)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: InkWell(
                      onTap: _toggleFullScreen,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen_exit_outlined,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// ---------- Bottom Navigation ----------
          /// Listen and Highlight controls
          if (selectedText.isNotEmpty && !_isFullScreen)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: appBarBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color:
                        FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Listen Button
                  Expanded(
                    child: InkWell(
                      onTap: isSpeaking ? _stopSpeaking : _speakSelected,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSpeaking
                              ? Colors.redAccent
                              : FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSpeaking ? Icons.stop : Icons.volume_up,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSpeaking ? "Stop" : "Listen",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Visibility(
            visible: !_isFullScreen && selectedText.isEmpty,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: appBarBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Page indicator and slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _readerType == ReaderType.epub
                                  ? 'অধ্যায় $currentPage/${FFAppState().totalPages}'
                                  : 'পৃষ্ঠা $currentPage/${FFAppState().totalPages}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: appBarTextColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (FFAppState().totalPages > 1)
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFFFD700),
                              inactiveTrackColor:
                                  FlutterFlowTheme.of(context).alternate,
                              thumbColor: const Color(0xFFFFD700),
                              overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: currentPage.toDouble(),
                              min: 1,
                              max: FFAppState().totalPages.toDouble(),
                              onChanged: (value) {
                                setState(() => currentPage = value.toInt());
                                if (_readerType == ReaderType.pdf) {
                                  pdfViewerController.jumpToPage(currentPage);
                                } else {
                                  _loadEpubChapter(currentPage - 1);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// Bottom action buttons
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      top: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomIcon(
                          Icons.list,
                          'Table of Contents',
                          _readerType == ReaderType.epub
                              ? _openChapterList
                              : () {
                                  // Table of contents for PDF (not implemented)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PDF Table of Contents not available'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          Icons.collections_bookmark_outlined,
                          'Bookmark Collection',
                          _openBookmarkCollection,
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          _isFullScreen
                              ? Icons.fullscreen_exit_outlined
                              : Icons.fullscreen_outlined,
                          'Full Screen Mode',
                          _toggleFullScreen,
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          _isAutoRotateEnabled
                              ? Icons.screen_rotation
                              : Icons.screen_lock_rotation,
                          'Screen rotation',
                          _toggleAutoRotate,
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          Icons.brightness_6,
                          'Brightness',
                          _openBrightnessSettings,
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          Icons.text_fields,
                          'Font',
                          _readerType == ReaderType.epub
                              ? _openFontSettings
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Font settings only available for EPUB'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                          bottomNavIconColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, String tooltip, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 24,
          color: iconColor,
        ),
      ),
    );
  }
}
