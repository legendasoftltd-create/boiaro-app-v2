import 'package:flutter/material.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// void main() {
//   runApp(const EpubViewerApp());
// }

// class EpubViewerApp extends StatelessWidget {
//   const EpubViewerApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'EPUB Viewer',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: const EpubReaderScreen(),
//     );
//   }
// }

// class EpubReaderScreen extends StatefulWidget {
//   const EpubReaderScreen({Key? key}) : super(key: key);

//   @override
//   State<EpubReaderScreen> createState() => _EpubReaderScreenState();
// }

// class _EpubReaderScreenState extends State<EpubReaderScreen> {
//   bool _isLoading = false;
//   String _error = '';
//   String? _epubPath;

//   @override
//   void initState() {
//     super.initState();
//     _prepareEpub();
//   }

//   Future<void> _prepareEpub() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = '';
//       });

//       // Copy EPUB from assets to local storage
//       final ByteData data = await rootBundle.load('assets/pdfs/test.epub');
//       final List<int> bytes = data.buffer.asUint8List();
      
//       // Get temporary directory
//       final Directory tempDir = await getTemporaryDirectory();
//       final String filePath = '${tempDir.path}/test.epub';
      
//       // Write file
//       final File file = File(filePath);
//       await file.writeAsBytes(bytes);
      
//       setState(() {
//         _epubPath = filePath;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _error = 'Failed to load EPUB: $e';
//       });
//     }
//   }

//   Future<void> _openEpubReader() async {
//     if (_epubPath == null) return;

//     try {
//       VocsyEpub.setConfig(
//         themeColor: Theme.of(context).primaryColor,
//         identifier: "epubViewer",
//         scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
//         allowSharing: true,
//         enableTts: true,
//         nightMode: false,
//       );

//       // Open the EPUB file
//        VocsyEpub.open(
//         _epubPath!,
//         lastLocation: EpubLocator.fromJson({
//           "bookId": "test_epub",
//           "href": "",
//           "created": DateTime.now().millisecondsSinceEpoch,
//           "locations": {
//             "cfi": "",
//           }
//         }),
//       );

//       // Get the locator when user closes the reader
//       VocsyEpub.locatorStream.listen((locator) {
//         print('Current location: ${locator.toJson()}');
//         // You can save this locator to resume reading later
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to open EPUB reader: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('EPUB Viewer'),
//         elevation: 2,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (_isLoading)
//                 Column(
//                   children: const [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 24),
//                     Text(
//                       'Preparing EPUB...',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ],
//                 )
//               else if (_error.isNotEmpty)
//                 Column(
//                   children: [
//                     const Icon(
//                       Icons.error_outline,
//                       size: 64,
//                       color: Colors.red,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _error,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: _prepareEpub,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Retry'),
//                     ),
//                   ],
//                 )
//               else
//                 Column(
//                   children: [
//                     Container(
//                       width: 120,
//                       height: 160,
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Colors.blue.shade200,
//                           width: 2,
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.menu_book,
//                             size: 64,
//                             color: Colors.blue.shade700,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'EPUB',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue.shade700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'test.epub',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Ready to read',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _openEpubReader,
//                         icon: const Icon(Icons.auto_stories),
//                         label: const Text(
//                           'Open Book',
//                           style: TextStyle(fontSize: 16),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 32,
//                             vertical: 16,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Features:',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       alignment: WrapAlignment.center,
//                       children: [
//                         _FeatureChip(
//                           icon: Icons.bookmark,
//                           label: 'Bookmarks',
//                         ),
//                         _FeatureChip(
//                           icon: Icons.highlight,
//                           label: 'Highlights',
//                         ),
//                         _FeatureChip(
//                           icon: Icons.text_fields,
//                           label: 'Font Control',
//                         ),
//                         _FeatureChip(
//                           icon: Icons.volume_up,
//                           label: 'Text-to-Speech',
//                         ),
//                         _FeatureChip(
//                           icon: Icons.share,
//                           label: 'Sharing',
//                         ),
//                         _FeatureChip(
//                           icon: Icons.dark_mode,
//                           label: 'Night Mode',
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FeatureChip extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _FeatureChip({
//     required this.icon,
//     required this.label,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Chip(
//       avatar: Icon(icon, size: 16),
//       label: Text(
//         label,
//         style: const TextStyle(fontSize: 12),
//       ),
//       backgroundColor: Colors.blue.shade50,
//       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
//     );
//   }
// }

/// A reusable EPUB reader widget with customizable styling
class EpubReaderWidget extends StatefulWidget {
  final String epubPath;
  final String bookTitle;
  final Color? themeColor;
  final bool enableTts;
  final bool allowSharing;
  final EpubLocator? lastLocation;
  final Function(EpubLocator)? onLocationChanged;
  final bool initialNightMode;

  const EpubReaderWidget({
    Key? key,
    required this.epubPath,
    required this.bookTitle,
    this.themeColor,
    this.enableTts = true,
    this.allowSharing = true,
    this.lastLocation,
    this.onLocationChanged,
    this.initialNightMode = false,
  }) : super(key: key);

  @override
  State<EpubReaderWidget> createState() => _EpubReaderWidgetState();
}

class _EpubReaderWidgetState extends State<EpubReaderWidget> {
  bool _isNightMode = false;
  String? _epubPath;

  @override
  void initState() {
    super.initState();
    _prepareEpub();
    _isNightMode = widget.initialNightMode;
    _setupLocatorListener();
  }
 
  void _setupLocatorListener() {
    VocsyEpub.locatorStream.listen((locator) {
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(locator);
      }
    });
  }


  Future<void> _prepareEpub() async {
    try {

      // Copy EPUB from assets to local storage
      final ByteData data = await rootBundle.load('assets/pdfs/test.epub');
      final List<int> bytes = data.buffer.asUint8List();
      
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/test.epub';
      
      // Write file
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      

        _epubPath = filePath;

    } catch (e) {
      print('Failed to load EPUB: $e');
    }
  }

  Future<void> _openEpubReader() async {
    try {
      VocsyEpub.setConfig(
        themeColor: widget.themeColor ?? Theme.of(context).primaryColor,
        identifier: "epubViewer_${widget.bookTitle}",
        scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
        allowSharing: widget.allowSharing,
        enableTts: widget.enableTts,
        nightMode: _isNightMode,
      );

      VocsyEpub.open(
        _epubPath!,
        lastLocation: widget.lastLocation ??
            EpubLocator.fromJson({
              "bookId": widget.bookTitle,
              "href": "",
              "created": DateTime.now().millisecondsSinceEpoch,
              "locations": {
                "cfi": "",
              }
            }),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open EPUB: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme ? Colors.black : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.bookTitle,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.bookmark_border, color: textColor),
                onPressed: () {
                  // Bookmark functionality
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: textColor),
                onPressed: () {
                  // More options
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Main reading area - This will show the EPUB content
              Expanded(
                child: GestureDetector(
                  onTap: _openEpubReader,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(
                        color: textColor.withOpacity(0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 80,
                            color: textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tap to open book',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.bookTitle,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'অধ্যায় 3/19',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: 0.15,
                        onChanged: (value) {},
                        activeColor: Colors.amber,
                        inactiveColor: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Bottom toolbar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarButton(Icons.format_list_bulleted, textColor),
                    _buildToolbarButton(
                        Icons.collections_bookmark_outlined, textColor),
                    _buildToolbarButton(Icons.fullscreen, textColor),
                    _buildToolbarButton(Icons.edit_outlined, textColor),
                    IconButton(
                      icon: Icon(
                        _isNightMode ? Icons.light_mode : Icons.dark_mode,
                        color: textColor,
                      ),
                      onPressed: _toggleNightMode,
                    ),
                    _buildToolbarButton(Icons.text_fields, textColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, Color color) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () {
        // Handle toolbar actions
      },
    );
  }
}
