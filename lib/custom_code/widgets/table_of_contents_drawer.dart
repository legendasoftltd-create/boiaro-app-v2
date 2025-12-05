import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class TableOfContentsDrawer extends StatelessWidget {
  final Function(int) loadEpubChapter;

  const TableOfContentsDrawer({
    Key? key,
    required this.loadEpubChapter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Consumer<PdfViewerProvider>(
      builder: (context, provider, child) {
        if (provider.readerType != ReaderType.epub || provider.epubChapters.isEmpty) {
          return Drawer(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_outlined,
                      size: 64,
                      color: theme.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.readerType == ReaderType.pdf
                          ? 'Table of Contents not available for PDF'
                          : 'No chapters available',
                      style: theme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.alternate.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        provider.setOpenDrawer(null);
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Table of Contents',
                        style: theme.bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Chapters List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provider.epubChapters.length,
                  itemBuilder: (context, index) {
                    final chapter = provider.epubChapters[index];
                    final isCurrentChapter = index == provider.currentEpubChapterIndex;

                    return ListTile(
                      leading: Icon(
                        Icons.book_outlined,
                        color: isCurrentChapter
                            ? theme.primary
                            : theme.secondaryText,
                      ),
                      title: Text(
                        chapter.Title ?? "Chapter ${index + 1}",
                        style: theme.bodyMedium.copyWith(
                          fontWeight: isCurrentChapter
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentChapter
                              ? theme.primary
                              : null,
                        ),
                      ),
                      trailing: isCurrentChapter
                          ? Icon(
                              Icons.play_arrow,
                              color: theme.primary,
                            )
                          : null,
                      onTap: () {
                        loadEpubChapter(index);
                        provider.setOpenDrawer(null);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

