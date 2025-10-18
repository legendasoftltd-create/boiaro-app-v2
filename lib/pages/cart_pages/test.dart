// // Automatic FlutterFlow imports
// import '/backend/backend.dart';
// import '/backend/schema/structs/index.dart';
// import '/flutter_flow/flutter_flow_theme.dart';
// import '/flutter_flow/flutter_flow_util.dart';
// import 'index.dart';
// import '/custom_code/actions/index.dart';
// import '/flutter_flow/custom_functions.dart';
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/scheduler.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:percent_indicator/linear_percent_indicator.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:flutter_tts/flutter_tts.dart';

// class FlutterPdfViewWidget extends StatefulWidget {
//   const FlutterPdfViewWidget({
//     super.key,
//     this.width,
//     this.height,
//     this.pdfPath,
//     this.namePage,
//   });

//   final double? width;
//   final double? height;
//   final String? pdfPath;
//   final String? namePage;

//   @override
//   State<FlutterPdfViewWidget> createState() => _FlutterPdfViewWidgetState();
// }

// PdfViewerController pdfViewerController = PdfViewerController();

// class _FlutterPdfViewWidgetState extends State<FlutterPdfViewWidget> {
//   int currentPage = 1;
//   final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
//   final FlutterTts flutterTts = FlutterTts();

//   String selectedText = "";
//   bool isSpeaking = false;
//   double speechRate = 0.9;
//   double pitch = 1.0;

//   @override
//   void initState() {
//     super.initState();
//     SchedulerBinding.instance.addPostFrameCallback((_) {
//       setState(() => currentPage = 1);
//     });
//   }

//   void setCurrentPage() {
//     setState(() {
//       if (currentPage != FFAppState().totalPages) {
//         currentPage++;
//       }
//     });
//   }

//   void setCurrentMinusPage() {
//     setState(() {
//       if (currentPage > 1) {
//         currentPage--;
//       }
//     });
//   }

//   Future<void> _speakSelected() async {
//     if (selectedText.isEmpty) return;
//     await flutterTts.setLanguage("bn-BD");
//     await flutterTts.setSpeechRate(speechRate);
//     await flutterTts.setPitch(pitch);

//     setState(() => isSpeaking = true);
//     await flutterTts.speak(selectedText);
//   }

//   Future<void> _stopSpeaking() async {
//     await flutterTts.stop();
//     setState(() => isSpeaking = false);
//   }

//   void _openTtsSettings() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 60,
//                 height: 5,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[400],
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 "🔊 Voice Settings",
//                 style: FlutterFlowTheme.of(context).bodyLarge.override(
//                       fontFamily: 'SF Pro Display',
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 24),

//               /// Speech Speed
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("Speed",
//                       style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
//                             fontWeight: FontWeight.bold,
//                           )),
//                   Text("${speechRate.toStringAsFixed(2)}x",
//                       style: FlutterFlowTheme.of(context).bodyMedium),
//                 ],
//               ),
//               Slider(
//                 value: speechRate,
//                 min: 0.3,
//                 max: 1.5,
//                 divisions: 12,
//                 activeColor: FlutterFlowTheme.of(context).primary,
//                 label: speechRate.toStringAsFixed(2),
//                 onChanged: (val) {
//                   setState(() => speechRate = val);
//                 },
//               ),
//               const SizedBox(height: 10),

//               /// Pitch
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("Pitch",
//                       style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
//                             fontWeight: FontWeight.bold,
//                           )),
//                   Text("${pitch.toStringAsFixed(2)}",
//                       style: FlutterFlowTheme.of(context).bodyMedium),
//                 ],
//               ),
//               Slider(
//                 value: pitch,
//                 min: 0.5,
//                 max: 2.0,
//                 divisions: 15,
//                 activeColor: FlutterFlowTheme.of(context).primary,
//                 label: pitch.toStringAsFixed(2),
//                 onChanged: (val) {
//                   setState(() => pitch = val);
//                 },
//               ),
//               const SizedBox(height: 16),

//               /// Test Voice Button
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: FlutterFlowTheme.of(context).primary,
//                   minimumSize: const Size(double.infinity, 48),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//                 onPressed: () async {
//                   await flutterTts.setLanguage("bn-BD");
//                   await flutterTts.setSpeechRate(speechRate);
//                   await flutterTts.setPitch(pitch);
//                   await flutterTts.speak("এই সেটিংস প্রিভিউ করার জন্য ধন্যবাদ।");
//                 },
//                 icon: const Icon(Icons.play_arrow, color: Colors.white),
//                 label: const Text("Preview Voice",
//                     style: TextStyle(color: Colors.white)),
//               ),
//               const SizedBox(height: 10),

//               /// Done button
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Done",
//                     style:
//                         TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     context.watch<FFAppState>();

//     return Scaffold(
//       backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
//       body: Column(
//         children: [
//           /// ---------- AppBar ----------
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.only(
//               top: MediaQuery.of(context).padding.top + 8,
//               bottom: 12,
//               left: 16,
//               right: 16,
//             ),
//             decoration: BoxDecoration(
//               color: FlutterFlowTheme.of(context).secondaryBackground,
//               border: Border(
//                 bottom: BorderSide(
//                   color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 InkWell(
//                   onTap: () async => context.safePop(),
//                   child: Icon(
//                     Icons.arrow_back_ios,
//                     size: 22,
//                     color: FlutterFlowTheme.of(context).primaryText,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     widget.namePage ?? 'সূরজ পাড়ার বন',
//                     textAlign: TextAlign.center,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: FlutterFlowTheme.of(context).bodyMedium.override(
//                           fontFamily: 'SF Pro Display',
//                           fontSize: 18,
//                           letterSpacing: 0.0,
//                           fontWeight: FontWeight.w600,
//                           useGoogleFonts: false,
//                         ),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     InkWell(
//                       onTap: () {
//                         // Search functionality
//                       },
//                       child: Icon(
//                         Icons.search,
//                         size: 24,
//                         color: FlutterFlowTheme.of(context).primaryText,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     InkWell(
//                       onTap: () {
//                         // Bookmark functionality
//                       },
//                       child: Icon(
//                         Icons.bookmark_border,
//                         size: 24,
//                         color: FlutterFlowTheme.of(context).primaryText,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     InkWell(
//                       onTap: _openTtsSettings,
//                       child: Icon(
//                         Icons.more_vert,
//                         size: 24,
//                         color: FlutterFlowTheme.of(context).primaryText,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           /// ---------- PDF Viewer ----------
//           Expanded(
//             child: Stack(
//               children: [
//                 SfPdfViewer.network(
//                   widget.pdfPath!,
//                   key: _pdfViewerKey,
//                   controller: pdfViewerController,
//                   scrollDirection: PdfScrollDirection.horizontal,
//                   canShowTextSelectionMenu: false,
//                   onDocumentLoaded: (PdfDocumentLoadedDetails details) {
//                     int totalPages = details.document.pages.count;
//                     setState(() => FFAppState().totalPages = totalPages);
//                     FFAppState().update(() {
//                       FFAppState().homePageTotalPdfPageIndex =
//                           FFAppState().totalPages;
//                     });
//                     pdfViewerController.jumpToPage(currentPage);
//                   },
//                   onPageChanged: (details) {
//                     SchedulerBinding.instance.addPostFrameCallback((_) {
//                       setState(() {
//                         currentPage = details.newPageNumber;
//                         FFAppState().update(() {
//                           FFAppState().homePageCurrentPdfIndex = currentPage;
//                         });
//                       });
//                     });
//                   },
//                   onTextSelectionChanged:
//                       (PdfTextSelectionChangedDetails details) {
//                     if (details.selectedText != null &&
//                         details.selectedText!.isNotEmpty) {
//                       setState(() => selectedText = details.selectedText!);
//                     } else {
//                       setState(() => selectedText = "");
//                     }
//                   },
//                 ),

//                 /// 🔊 Floating Read Button
//                 if (selectedText.isNotEmpty)
//                   Positioned(
//                     bottom: 110,
//                     right: 20,
//                     child: FloatingActionButton.extended(
//                       backgroundColor: isSpeaking
//                           ? Colors.redAccent
//                           : FlutterFlowTheme.of(context).primary,
//                       onPressed: isSpeaking ? _stopSpeaking : _speakSelected,
//                       icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
//                       label: Text(
//                         isSpeaking ? "Stop" : "Listen",
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           /// ---------- Bottom Navigation ----------
//           Container(
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: FlutterFlowTheme.of(context).secondaryBackground,
//               border: Border(
//                 top: BorderSide(
//                   color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 /// Page indicator and slider
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   child: Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'পৃষ্ঠা $currentPage/${FFAppState().totalPages}',
//                             style: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   fontFamily: 'SF Pro Display',
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w500,
//                                   color: FlutterFlowTheme.of(context)
//                                       .secondaryText,
//                                 ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       SliderTheme(
//                         data: SliderThemeData(
//                           activeTrackColor: const Color(0xFFFFD700),
//                           inactiveTrackColor:
//                               FlutterFlowTheme.of(context).alternate,
//                           thumbColor: const Color(0xFFFFD700),
//                           overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
//                           thumbShape: const RoundSliderThumbShape(
//                               enabledThumbRadius: 8),
//                           trackHeight: 4,
//                         ),
//                         child: Slider(
//                           value: currentPage.toDouble(),
//                           min: 1,
//                           max: FFAppState().totalPages.toDouble(),
//                           onChanged: (value) {
//                             setState(() => currentPage = value.toInt());
//                             pdfViewerController.jumpToPage(currentPage);
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 /// Bottom action buttons
//                 Container(
//                   padding: EdgeInsets.only(
//                     left: 16,
//                     right: 16,
//                     bottom: MediaQuery.of(context).padding.bottom + 8,
//                     top: 8,
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildBottomIcon(
//                         Icons.list,
//                         'Table of Contents',
//                         () {
//                           // Table of contents
//                         },
//                       ),
//                       _buildBottomIcon(
//                         Icons.content_copy,
//                         'Copy',
//                         () {
//                           // Copy functionality
//                         },
//                       ),
//                       _buildBottomIcon(
//                         Icons.chrome_reader_mode,
//                         'Reader Mode',
//                         () {
//                           // Reader mode
//                         },
//                       ),
//                       _buildBottomIcon(
//                         Icons.delete_outline,
//                         'Delete',
//                         () {
//                           // Delete functionality
//                         },
//                       ),
//                       _buildBottomIcon(
//                         Icons.brightness_6,
//                         'Brightness',
//                         () {
//                           // Brightness settings
//                         },
//                       ),
//                       _buildBottomIcon(
//                         Icons.text_fields,
//                         'Font',
//                         () {
//                           // Font settings
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomIcon(IconData icon, String tooltip, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Icon(
//           icon,
//           size: 24,
//           color: FlutterFlowTheme.of(context).secondaryText,
//         ),
//       ),
//     );
//   }
// }