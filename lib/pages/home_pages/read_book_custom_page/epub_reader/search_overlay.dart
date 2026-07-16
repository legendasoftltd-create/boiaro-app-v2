import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/internationalization.dart';

class EpubSearchOverlay extends StatefulWidget {
  final EpubController epubController;
  final String bookTitle;

  const EpubSearchOverlay({
    Key? key,
    required this.epubController,
    required this.bookTitle,
  }) : super(key: key);

  @override
  State<EpubSearchOverlay> createState() => _EpubSearchOverlayState();
}

class _EpubSearchOverlayState extends State<EpubSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  List<EpubSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final results = await widget.epubController.search(query: cleanQuery);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _errorMessage = 'Search failed: $e';
          _isSearching = false;
        });
      }
    }
  }

  Widget _buildHighlightedExcerpt(String excerpt, String query, BuildContext context) {
    if (query.isEmpty) {
      return Text(
        excerpt,
        style: FlutterFlowTheme.of(context).bodyMedium,
      );
    }

    final lowercaseExcerpt = excerpt.toLowerCase();
    final lowercaseQuery = query.toLowerCase();

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowercaseExcerpt.indexOf(lowercaseQuery, start);

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(
          text: excerpt.substring(start, indexOfMatch),
          style: FlutterFlowTheme.of(context).bodyMedium,
        ));
      }

      spans.add(TextSpan(
        text: excerpt.substring(indexOfMatch, indexOfMatch + query.length),
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Inter',
              color: FlutterFlowTheme.of(context).primary,
              fontWeight: FontWeight.bold,
            ).copyWith(
              backgroundColor: FlutterFlowTheme.of(context).accent3.withValues(alpha: 0.3),
            ),
      ));

      start = indexOfMatch + query.length;
      indexOfMatch = lowercaseExcerpt.indexOf(lowercaseQuery, start);
    }

    if (start < excerpt.length) {
      spans.add(TextSpan(
        text: excerpt.substring(start),
        style: FlutterFlowTheme.of(context).bodyMedium,
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: FlutterFlowTheme.of(context).bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        iconTheme: IconThemeData(color: theme.primaryText),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: localizations.getVariableText(
              enText: 'Search in "${widget.bookTitle}"...',
              bnText: '"${widget.bookTitle}"-এ খুঁজুন...',
            ),
            hintStyle: theme.bodyMedium.override(
              fontFamily: 'Inter',
              color: theme.secondaryText,
            ),
            border: InputBorder.none,
          ),
          style: theme.bodyLarge,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
          ),
        ],
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isSearching)
              LinearProgressIndicator(color: theme.primary)
            else
              const SizedBox(height: 4),
            Expanded(
              child: _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: theme.error,
                        ),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.trim().isEmpty
                                ? localizations.getVariableText(
                                    enText: 'Type to start searching',
                                    bnText: 'খুঁজতে টাইপ করুন',
                                  )
                                : localizations.getVariableText(
                                    enText: 'No results found',
                                    bnText: 'কোনো ফলাফল পাওয়া যায়নি',
                                  ),
                            style: theme.bodyMedium.override(
                              fontFamily: 'Inter',
                              color: theme.secondaryText,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(
                            color: theme.alternate,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: _buildHighlightedExcerpt(
                                result.excerpt,
                                _searchController.text.trim(),
                                context,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  result.cfi,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: theme.secondaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              onTap: () {
                                widget.epubController.display(cfi: result.cfi);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
