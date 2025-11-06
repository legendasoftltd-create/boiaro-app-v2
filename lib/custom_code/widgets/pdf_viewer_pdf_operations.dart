import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '/providers/pdf_viewer_provider.dart';

/// PDF operations (search and navigation)
class PdfViewerPdfOperations {
  /// Search in PDF
  static void searchPdf(PdfViewerProvider provider, PdfViewerController controller) {
    if (provider.searchText.isNotEmpty && provider.readerType == ReaderType.pdf) {
      final result = controller.searchText(provider.searchText);
      provider.setSearchResult(result);
    }
  }

  /// Clear search results
  static void clearSearch(PdfViewerProvider provider, TextEditingController searchController) {
    if (provider.readerType == ReaderType.pdf) {
      // Clear search results in PDF viewer
      final emptyResult = PdfTextSearchResult();
      provider.setSearchResult(emptyResult);
    }
    provider.clearSearch();
    searchController.clear();
  }

  /// Go to next search result
  static void goToNextSearchResult(PdfViewerProvider provider) {
    provider.goToNextSearchResult();
  }

  /// Go to previous search result
  static void goToPreviousSearchResult(PdfViewerProvider provider) {
    provider.goToPreviousSearchResult();
  }
}

