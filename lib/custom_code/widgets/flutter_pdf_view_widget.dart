// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:screen_brightness/screen_brightness.dart';

class FlutterPdfViewWidget extends StatefulWidget {
  const FlutterPdfViewWidget({
    super.key,
    this.width,
    this.height,
    this.pdfPath,
    this.namePage,
  });

  final double? width;
  final double? height;
  final String? pdfPath;
  final String? namePage;

  @override
  State<FlutterPdfViewWidget> createState() => _FlutterPdfViewWidgetState();
}

PdfViewerController pdfViewerController = PdfViewerController();

class _FlutterPdfViewWidgetState extends State<FlutterPdfViewWidget> {
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() => currentPage = 1);
      _getInitialBrightness();
    });
  }

  @override
  void dispose() {
    _restoreOriginalBrightness();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _searchController.dispose();
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
      print('Error getting initial brightness: $e');
    }
  }

  Future<void> _restoreOriginalBrightness() async {
    try {
      await ScreenBrightness().setScreenBrightness(originalBrightness);
    } catch (e) {
      print('Error restoring brightness: $e');
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
      setState(() => currentBrightness = brightness);
    } catch (e) {
      print('Error setting brightness: $e');
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
      if (currentPage != FFAppState().totalPages) {
        currentPage++;
      }
    });
  }

  void setCurrentMinusPage() {
    setState(() {
      if (currentPage > 1) {
        currentPage--;
      }
    });
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
    await flutterTts.setLanguage("bn-BD");
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.setPitch(pitch);

    setState(() => isSpeaking = true);
    await flutterTts.speak(selectedText);
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
                  setState(() => speechRate = val);
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
                  setState(() => pitch = val);
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
                  await flutterTts.setLanguage("bn-BD");
                  await flutterTts.setSpeechRate(speechRate);
                  await flutterTts.setPitch(pitch);
                  await flutterTts.speak("এই সেটিংস প্রিভিউ করার জন্য ধন্যবাদ।");
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
                      _buildBrightnessPreset(
                        context,
                        "25%",
                        0.25,
                        setModalState,
                      ),
                      _buildBrightnessPreset(
                        context,
                        "50%",
                        0.50,
                        setModalState,
                      ),
                      _buildBrightnessPreset(
                        context,
                        "75%",
                        0.75,
                        setModalState,
                      ),
                      _buildBrightnessPreset(
                        context,
                        "100%",
                        1.0,
                        setModalState,
                      ),
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
                    "🔍 Search in PDF",
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
                        _searchPdf();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
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
                        _searchPdf();
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
                    "🔖 Bookmarked Pages",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _bookmarkedPages.isEmpty
                      ? Text(
                          "No bookmarked pages yet.",
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        )
                      : Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _bookmarkedPages.length,
                            itemBuilder: (context, index) {
                              final pageNumber = _bookmarkedPages[index];
                              return ListTile(
                                title: Text("Page $pageNumber",
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium),
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
                                  pdfViewerController.jumpToPage(pageNumber);
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

  void _searchPdf() {
    if (searchText.isNotEmpty) {
      setState(() {
        _searchResult = pdfViewerController.searchText(searchText);
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchResult.clear();
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

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
                color: FlutterFlowTheme.of(context).secondaryBackground,
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
                      color: FlutterFlowTheme.of(context).primaryText,
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
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _openSearchOverlay,
                        child: Icon(
                          Icons.search,
                          size: 24,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _toggleBookmark,
                        child: Icon(
                          _bookmarkedPages.contains(currentPage)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 24,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _openTtsSettings,
                        child: Icon(
                          Icons.more_vert,
                          size: 24,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// ---------- PDF Viewer ----------
          Expanded(
            child: Stack(
              children: [
                SfPdfViewer.network(
                  widget.pdfPath!,
                  key: _pdfViewerKey,
                  controller: pdfViewerController,
                  scrollDirection: PdfScrollDirection.vertical,
                  canShowTextSelectionMenu: false,
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
                ),

                /// 🔊 Floating Read Button
                if (selectedText.isNotEmpty && !_isFullScreen)
                  Positioned(
                    bottom: 110,
                    right: 20,
                    child: FloatingActionButton.extended(
                      backgroundColor: isSpeaking
                          ? Colors.redAccent
                          : FlutterFlowTheme.of(context).primary,
                      onPressed: isSpeaking ? _stopSpeaking : _speakSelected,
                      icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                      label: Text(
                        isSpeaking ? "Stop" : "Listen",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

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
          Visibility(
            visible: !_isFullScreen,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
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
                              'পৃষ্ঠা $currentPage/${FFAppState().totalPages}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                              pdfViewerController.jumpToPage(currentPage);
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
                          () {
                            // Table of contents
                          },
                        ),
                        _buildBottomIcon(
                          Icons.collections_bookmark_outlined,
                          'Bookmark Collection',
                          _openBookmarkCollection,
                        ),
                        _buildBottomIcon(
                          _isFullScreen
                              ? Icons.fullscreen_exit_outlined
                              : Icons.fullscreen_outlined,
                          'Full Screen Mode',
                          _toggleFullScreen,
                        ),
                        _buildBottomIcon(
                          _isAutoRotateEnabled
                              ? Icons.screen_rotation
                              : Icons.screen_lock_rotation,
                          'Screen rotation',
                          _toggleAutoRotate,
                        ),
                        _buildBottomIcon(
                          Icons.brightness_6,
                          'Brightness',
                          _openBrightnessSettings,
                        ),
                        _buildBottomIcon(
                          Icons.text_fields,
                          'Font',
                          () {
                            // Font settings
                          },
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

  Widget _buildBottomIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 24,
          color: FlutterFlowTheme.of(context).secondaryText,
        ),
      ),
    );
  }
}
