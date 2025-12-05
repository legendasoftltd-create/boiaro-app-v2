import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '/providers/pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'pdf_viewer_pdf_operations.dart';

class SearchDrawer extends StatelessWidget {
  final TextEditingController searchController;
  final PdfViewerController pdfController;
  final VoidCallback? onSearchEpub;
  final VoidCallback? onNextResult;
  final VoidCallback? onPreviousResult;
  final VoidCallback? onClearSearch;

  const SearchDrawer({
    Key? key,
    required this.searchController,
    required this.pdfController,
    this.onSearchEpub,
    this.onNextResult,
    this.onPreviousResult,
    this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Drawer(
      width: 300, 
      backgroundColor: Colors.transparent, 
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 500, 
          width: double.infinity,
          margin: EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Consumer<PdfViewerProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                          'Search',
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
                // Search Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const SizedBox(height: 8),
                        Text(
                          "Search in ${provider.readerType == ReaderType.pdf ? 'PDF' : 'EPUB'}",
                          style: theme.bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: "Search text",
                            hintText: "Enter text to search",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                // Clear search for both PDF and EPUB
                                if (provider.readerType == ReaderType.pdf) {
                                  PdfViewerPdfOperations.clearSearch(provider, searchController);
                                } else {
                                  onClearSearch?.call();
                                }
                              },
                            ),
                          ),
                          onChanged: (value) {
                            provider.setSearchText(value);
                          },
                          onSubmitted: (value) {
                            if (provider.readerType == ReaderType.pdf) {
                              PdfViewerPdfOperations.searchPdf(provider, pdfController);
                            } else {
                              onSearchEpub?.call();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Search results info and navigation
                        if (provider.readerType == ReaderType.pdf)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  provider.searchResult.hasResult
                                      ? "${provider.searchResult.currentInstanceIndex + 1} of ${provider.searchResult.totalInstanceCount}"
                                      : "No results",
                                  style: theme.bodySmall,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: provider.isNavigatingSearchResult
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.arrow_upward),
                                    onPressed: (provider.searchResult.hasResult &&
                                            provider.searchResult.currentInstanceIndex > 0 &&
                                            !provider.isNavigatingSearchResult &&
                                            !provider.isSearching)
                                        ? () {
                                            onPreviousResult?.call();
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: provider.isNavigatingSearchResult
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.arrow_downward),
                                    onPressed: (provider.searchResult.hasResult &&
                                            provider.searchResult.currentInstanceIndex <
                                                provider.searchResult.totalInstanceCount - 1 &&
                                            !provider.isNavigatingSearchResult &&
                                            !provider.isSearching)
                                        ? () {
                                            onNextResult?.call();
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          )
                        else if (provider.readerType == ReaderType.epub)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  provider.hasEpubSearchResults
                                      ? "${provider.epubCurrentSearchIndex + 1} of ${provider.epubSearchResultCount}"
                                      : "No results",
                                  style: theme.bodySmall,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: provider.isNavigatingSearchResult
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.arrow_upward),
                                    onPressed: (provider.hasEpubSearchResults &&
                                            provider.epubCurrentSearchIndex > 0 &&
                                            !provider.isNavigatingSearchResult &&
                                            !provider.isSearching)
                                        ? () {
                                            onPreviousResult?.call();
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward),
                                    onPressed: (provider.hasEpubSearchResults &&
                                            provider.epubCurrentSearchIndex <
                                                provider.epubSearchResultCount - 1 &&
                                            !provider.isNavigatingSearchResult &&
                                            !provider.isSearching)
                                        ? () {
                                            onNextResult?.call();
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (provider.isSearching || provider.isNavigatingSearchResult)
                              ? null
                              : () {
                                  if (provider.readerType == ReaderType.pdf) {
                                    PdfViewerPdfOperations.searchPdf(provider, pdfController);
                                  } else {
                                    // Hide keyboard
                                    FocusScope.of(context).unfocus();
                                    onSearchEpub?.call();
                                  }
                                },
                          child: provider.isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Search'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
          ),
        ),
      ),
    );
  }
}


