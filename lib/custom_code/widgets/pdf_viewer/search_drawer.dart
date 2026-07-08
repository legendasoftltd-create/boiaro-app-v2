import 'package:flutter/material.dart';
import '/flutter_flow/internationalization.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'pdf_viewer_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'pdf_viewer_pdf_operations.dart';

class SearchDrawer extends StatelessWidget {
  final TextEditingController searchController;
  final PdfViewerController pdfController;
  final VoidCallback? onNextResult;
  final VoidCallback? onPreviousResult;
  final VoidCallback? onClearSearch;

  const SearchDrawer({
    Key? key,
    required this.searchController,
    required this.pdfController,
    this.onNextResult,
    this.onPreviousResult,
    this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 500,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 50),
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Search in PDF",
                            style: theme.bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: FFLocalizations.of(context).getVariableText(enText: 'Search text', bnText: 'অনুসন্ধানের টেক্সট'),
                              hintText: FFLocalizations.of(context).getVariableText(enText: 'Enter text to search', bnText: 'অনুসন্ধানের টেক্সট লিখুন'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  PdfViewerPdfOperations.clearSearch(
                                      provider, searchController);
                                },
                              ),
                            ),
                            onChanged: (value) {
                              provider.setSearchText(value);
                            },
                            onSubmitted: (value) {
                              print('SearchDrawer: onSubmitted for PDF');
                              FocusScope.of(context).unfocus();
                              PdfViewerPdfOperations.searchPdf(
                                  provider, pdfController);
                            },
                          ),
                          const SizedBox(height: 16),
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
                            onPressed: (provider.isSearching ||
                                    provider.isNavigatingSearchResult)
                                ? null
                                : () {
                                    print('SearchDrawer: onPressed for PDF');
                                    FocusScope.of(context).unfocus();
                                    PdfViewerPdfOperations.searchPdf(
                                        provider, pdfController);
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
                                : Text(FFLocalizations.of(context).getVariableText(enText: 'Search', bnText: 'অনুসন্ধান করুন')),
                          ),
                          if (provider.searchResult.hasResult)
                            ..._buildPdfSearchResultsList(
                                context, provider, theme),
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

  List<Widget> _buildPdfSearchResultsList(BuildContext context,
      PdfViewerProvider provider, FlutterFlowTheme theme) {
    return [
      const SizedBox(height: 16),
      Text(
        'Search Results (${provider.searchResult.totalInstanceCount})',
        style: theme.bodyMedium.override(
          fontFamily: 'SF Pro Display',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: provider.searchResult.totalInstanceCount,
          itemBuilder: (context, index) {
            final isCurrentResult =
                index == provider.searchResult.currentInstanceIndex;
            final searchKeyword = provider.searchText;

            String displayText = '..."$searchKeyword"...';
            String pageInfo = 'Match ${index + 1}';

            if (index < provider.searchResultDetails.length) {
              final details = provider.searchResultDetails[index];
              if (details['snippet'] != null) {
                displayText = details['snippet'];
              }
              if (details['page'] != null) {
                pageInfo = 'Page ${details['page']}';
              }
            }

            return InkWell(
              onTap: () {
                _navigateToResult(provider, index);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isCurrentResult
                      ? theme.primary.withOpacity(0.1)
                      : theme.secondaryBackground,
                  border: Border.all(
                    color: isCurrentResult
                        ? theme.primary
                        : theme.alternate.withOpacity(0.2),
                    width: isCurrentResult ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 14,
                          color: isCurrentResult
                              ? theme.primary
                              : theme.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pageInfo,
                          style: theme.bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 11,
                            color: isCurrentResult
                                ? theme.primary
                                : theme.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isCurrentResult)
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: theme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.override(
                        fontFamily: 'SF Pro Display',
                        color: theme.primaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  void _navigateToResult(PdfViewerProvider provider, int targetIndex) {
    final currentIndex = provider.searchResult.currentInstanceIndex;
    final difference = targetIndex - currentIndex;

    if (difference > 0) {
      for (int i = 0; i < difference; i++) {
        onNextResult?.call();
      }
    } else if (difference < 0) {
      for (int i = 0; i < difference.abs(); i++) {
        onPreviousResult?.call();
      }
    }
  }
}