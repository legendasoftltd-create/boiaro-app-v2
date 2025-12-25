import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '/providers/pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class TableOfContentsDrawer extends StatelessWidget {
  final Function(int) loadEpubChapter;
  final PdfViewerController? pdfController;

  const TableOfContentsDrawer({
    Key? key,
    required this.loadEpubChapter,
    this.pdfController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Consumer<PdfViewerProvider>(
      builder: (context, provider, child) {
        final isPdf = provider.readerType == ReaderType.pdf;
        final hasContent = isPdf
            ? provider.pdfToc.isNotEmpty
            : provider.epubChapters.isNotEmpty;

        if (!hasContent) {
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
                      isPdf
                          ? 'Table of Contents not available'
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
                child: isPdf
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: provider.pdfToc.length,
                        itemBuilder: (context, index) {
                          return _buildPdfTocItem(
                              context, provider, provider.pdfToc[index]);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: provider.epubChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = provider.epubChapters[index];
                          final isCurrentChapter =
                              index == provider.currentEpubChapterIndex;

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
                                color: isCurrentChapter ? theme.primary : null,
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

  Widget _buildPdfTocItem(
      BuildContext context, PdfViewerProvider provider, PdfTocItem item) {
    final theme = FlutterFlowTheme.of(context);
    final isCurrentPage = provider.currentPage == item.pageNumber;

    if (item.children.isNotEmpty) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            item.title,
            style: theme.bodyMedium.copyWith(
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              color: isCurrentPage ? theme.primary : null,
            ),
          ),
          leading: Icon(
            Icons.folder_open,
            color: isCurrentPage ? theme.primary : theme.secondaryText,
          ),
          childrenPadding: const EdgeInsets.only(left: 16.0),
          children: item.children
              .map((child) => _buildPdfTocItem(context, provider, child))
              .toList(),
        ),
      );
    } else {
      return ListTile(
        leading: Icon(
          Icons.article_outlined,
          color: isCurrentPage ? theme.primary : theme.secondaryText,
        ),
        title: Text(
          item.title,
          style: theme.bodyMedium.copyWith(
            fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            color: isCurrentPage ? theme.primary : null,
          ),
        ),
        onTap: () {
          if (pdfController != null) {
            pdfController!.jumpToPage(item.pageNumber);
          }
          provider.setOpenDrawer(null);
          Navigator.pop(context);
        },
      );
    }
  }
}
