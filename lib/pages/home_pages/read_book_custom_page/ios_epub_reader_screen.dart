import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/progress_sync_service.dart';
import '/services/reading_report_service.dart';

class IosEpubReaderScreen extends StatefulWidget {
  final String epubPath;
  final String bookTitle;
  final double? initialProgress;
  final String bookId;

  const IosEpubReaderScreen({
    Key? key,
    required this.epubPath,
    required this.bookTitle,
    required this.bookId,
    this.initialProgress,
  }) : super(key: key);

  @override
  State<IosEpubReaderScreen> createState() => _IosEpubReaderScreenState();
}

class _IosEpubReaderScreenState extends State<IosEpubReaderScreen> {
  final epubController = EpubController();
  bool isLoading = true;
  double progress = 0.0;
  List<EpubChapter> _chapters = [];
  
  bool isDarkMode = false;
  double fontSize = 16.0;
  EpubFlow epubFlow = EpubFlow.paginated;
  
  late final EpubSource epubSource;
  bool _hasJumpedToInitial = false;

  @override
  void initState() {
    super.initState();
    progress = widget.initialProgress ?? 0.0;
    epubSource = EpubSource.fromFile(File(widget.epubPath));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary),
              child: const SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Chapters',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _chapters.isEmpty
                  ? const Center(child: Text('No chapters available'))
                  : ListView.builder(
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        return ListTile(
                          title: Text(chapter.title ?? 'Chapter ${index + 1}'),
                          onTap: () {
                            if (chapter.href != null) {
                              epubController.display(cfi: chapter.href!);
                            }
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: Text(
          widget.bookTitle,
          style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 0.0,
              ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Simple search dialog implementation
              String query = '';
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search in Book'),
                  content: TextField(
                    onChanged: (val) => query = val,
                    decoration: const InputDecoration(hintText: 'Enter text to search'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (query.isNotEmpty) {
                          epubController.search(query: query);
                        }
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Dark Mode'),
                                value: isDarkMode,
                                onChanged: (val) {
                                  setModalState(() => isDarkMode = val);
                                  setState(() => isDarkMode = val);
                                  epubController.updateTheme(
                                    theme: isDarkMode ? EpubTheme.dark() : EpubTheme.light(),
                                  );
                                },
                              ),
                              ListTile(
                                title: const Text('Font Size'),
                                subtitle: Slider(
                                  value: fontSize,
                                  min: 12.0,
                                  max: 30.0,
                                  divisions: 18,
                                  label: fontSize.round().toString(),
                                  onChanged: (val) {
                                    setModalState(() => fontSize = val);
                                    setState(() => fontSize = val);
                                    epubController.setFontSize(fontSize: val);
                                  },
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
            },
          ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (progress > 0)
              LinearProgressIndicator(
                value: progress,
                backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary),
              ),
            Expanded(
              child: Stack(
                children: [
                  EpubViewer(
                    epubSource: epubSource,
                    epubController: epubController,
                    displaySettings: EpubDisplaySettings(
                        flow: epubFlow,
                        theme: isDarkMode ? EpubTheme.dark() : EpubTheme.light(),
                        useSnapAnimationAndroid: false,
                        snap: true,
                        allowScriptedContent: true),
                    onChaptersLoaded: (chapters) {
                      setState(() {
                        _chapters = chapters;
                      });
                    },
                    onEpubLoaded: () async {
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                      if (!_hasJumpedToInitial && widget.initialProgress != null && widget.initialProgress! > 0) {
                        _hasJumpedToInitial = true;
                        // The library uses 0.0 to 1.0 for progress, but Boiaro stores progress as 0-100 percentages.
                        // We need to divide by 100 if the value is > 1.
                        final normalizedProgress = widget.initialProgress! > 1 
                            ? widget.initialProgress! / 100.0 
                            : widget.initialProgress!;
                        // Add a slight delay to ensure rendering is complete before jumping
                        await Future.delayed(const Duration(milliseconds: 500));
                        epubController.toProgressPercentage(normalizedProgress);
                      }
                    },
                    onRelocated: (value) {
                      setState(() {
                        progress = value.progress;
                      });
                      
                      // Sync progress to backend
                      if (progress > 0) {
                        ProgressSyncService.saveReadingProgress(
                          bookId: widget.bookId,
                          currentPage: (progress * 100).toInt(),
                          totalPages: 100, // Sync as 0-100 percentage
                        );
                        
                        ReadingReportService.instance.updateProgress(
                          percentage: (progress * 100).toInt(),
                        );
                      }
                    },
                    onTextSelected: (epubTextSelection) {
                      // Optional: handle text selection
                    },
                  ),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
