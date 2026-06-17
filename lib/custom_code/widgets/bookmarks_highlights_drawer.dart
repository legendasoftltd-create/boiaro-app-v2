// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import '/providers/pdf_viewer_provider.dart';
// import '/flutter_flow/flutter_flow_theme.dart';

// class BookmarksHighlightsDrawer extends StatefulWidget {
//   final PdfViewerController pdfController;
//   final Function(int) loadEpubChapter;

//   const BookmarksHighlightsDrawer({
//     Key? key,
//     required this.pdfController,
//     required this.loadEpubChapter,
//   }) : super(key: key);

//   @override
//   State<BookmarksHighlightsDrawer> createState() => _BookmarksHighlightsDrawerState();
// }

// class _BookmarksHighlightsDrawerState extends State<BookmarksHighlightsDrawer>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = FlutterFlowTheme.of(context);
    
//     return Drawer(
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.zero,
//       ),
//       child: Column(
//         children: [
//           // Header
//           // Container(
//           //   padding: EdgeInsets.only(
//           //     top: MediaQuery.of(context).padding.top + 16,
//           //     bottom: 16,
//           //     left: 16,
//           //     right: 16,
//           //   ),
//           //   decoration: BoxDecoration(
//           //     border: Border(
//           //       bottom: BorderSide(
//           //         color: theme.alternate.withOpacity(0.2),
//           //         width: 1,
//           //       ),
//           //     ),
//           //   ),
//           //   child: Row(
//           //     children: [
//           //       IconButton(
//           //         icon: const Icon(Icons.close),
//           //         onPressed: () {
//           //           context.read<PdfViewerProvider>().setOpenDrawer(null);
//           //           Navigator.pop(context);
//           //         },
//           //       ),
//           //       // Expanded(
//           //       //   child: Text(
//           //       //     'Bookmarks & Highlights',
//           //       //     style: theme.bodyMedium.override(
//           //       //       fontFamily: 'SF Pro Display',
//           //       //       fontSize: 16,
//           //       //       fontWeight: FontWeight.w600,
//           //       //     ),
//           //       //   ),
//           //       // ),
//           //     ],
//           //   ),
//           // ),
//           // Tabs
//           Container(
//             // color: theme.primaryBackground,
//             child: TabBar(
//               controller: _tabController,
//               labelColor: theme.primary,
//               unselectedLabelColor: theme.secondaryText,
//               indicatorColor: theme.primary,
//               tabs: const [
//                 Tab(text: 'Bookmarks'),
//                 Tab(text: 'Highlights'),
//               ],
//             ),
//           ),
//           // Tab Content
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildBookmarksTab(context, theme),
//                 _buildHighlightsTab(context, theme),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBookmarksTab(BuildContext context, FlutterFlowTheme theme) {
//     return Consumer<PdfViewerProvider>(
//       builder: (context, provider, child) {
//         if (provider.bookmarks.isEmpty) {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(32.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.bookmark_border,
//                     size: 64,
//                     color: theme.secondaryText,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     "No bookmarked ${provider.readerType == ReaderType.epub ? 'chapters' : 'pages'} yet.",
//                     style: theme.bodyMedium,
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           itemCount: provider.bookmarks.length,
//           itemBuilder: (context, index) {
//             final bookmark = provider.bookmarks[index];
//             final pageNumber = bookmark.pageNumber;

//             return ListTile(
//               leading: Icon(
//                 Icons.bookmark,
//                 color: theme.primary,
//               ),
//               title: Text(
//                 bookmark.chapterName,
//                 style: theme.bodyMedium,
//               ),
//               subtitle: provider.readerType == ReaderType.epub
//                   ? Text(
//                       'Chapter ${pageNumber}',
//                       style: theme.bodySmall,
//                     )
//                   : Text(
//                       'Page $pageNumber',
//                       style: theme.bodySmall,
//                     ),
//               trailing: IconButton(
//                 icon: const Icon(Icons.delete_outline),
//                 onPressed: () async {
//                   await provider.removeBookmark(
//                     pageNumber,
//                     bookId: provider.currentBookId,
//                   );
//                 },
//               ),
//               onTap: () {
//                 if (provider.readerType == ReaderType.pdf) {
//                   widget.pdfController.jumpToPage(pageNumber);
//                   provider.setCurrentPage(pageNumber);
//                 } else {
//                   widget.loadEpubChapter(pageNumber - 1);
//                 }
//                 provider.setOpenDrawer(null);
//                 Navigator.pop(context);
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildHighlightsTab(BuildContext context, FlutterFlowTheme theme) {
//     return Consumer<PdfViewerProvider>(
//       builder: (context, provider, child) {
//         final highlights = provider.highlights;

//         if (highlights.isEmpty) {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(32.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.highlight_outlined,
//                     size: 64,
//                     color: theme.secondaryText,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     "No highlights yet.\nSelect text and tap 'Highlight' to create one.",
//                     style: theme.bodyMedium,
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           itemCount: highlights.length,
//           itemBuilder: (context, index) {
//             final highlight = highlights[index];

//             return ListTile(
//               leading: Container(
//                 width: 4,
//                 height: double.infinity,
//                 color: theme.primary,
//                 margin: const EdgeInsets.symmetric(vertical: 8),
//               ),
//               title: Text(
//                 highlight.text,
//                 style: theme.bodyMedium,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               subtitle: Text(
//                 highlight.chapterName.isNotEmpty 
//                     ? highlight.chapterName 
//                     : 'Chapter ${highlight.chapterId}',
//                 style: theme.bodySmall,
//               ),
//               trailing: IconButton(
//                 icon: const Icon(Icons.delete_outline),
//                 onPressed: () {
//                   provider.removeHighlight(highlight);
//                 },
//               ),
//               onTap: () {
//                 if (provider.readerType == ReaderType.pdf) {
//                   final pageNumber = int.tryParse(highlight.chapterId) ?? 1;
//                   widget.pdfController.jumpToPage(pageNumber);
//                   provider.setCurrentPage(pageNumber);
//                 } else {
//                   final chapterIndex = int.tryParse(highlight.chapterId) ?? 0;
//                   widget.loadEpubChapter(chapterIndex);
//                 }
//                 provider.setOpenDrawer(null);
//                 Navigator.pop(context);
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }

