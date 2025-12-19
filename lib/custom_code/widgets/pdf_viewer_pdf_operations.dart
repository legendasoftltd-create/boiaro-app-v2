import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '/providers/pdf_viewer_provider.dart';
import 'bijoy_converter.dart';

/// PDF operations (search and navigation)
class PdfViewerPdfOperations {
  /// Search in PDF
  static void searchPdf(
      PdfViewerProvider provider, PdfViewerController controller) {
    print(
        'PdfViewerPdfOperations: searchPdf called. Text: "${provider.searchText}", Type: ${provider.readerType}');
    if (provider.searchText.isNotEmpty &&
        provider.readerType == ReaderType.pdf) {
      // Try converting Bijoy to Unicode first if applicable
      String searchText = provider.searchText.trim();
      String convertedText = BijoyConverter.convert(searchText);
      if (convertedText != searchText) {
        print(
            'PdfViewerPdfOperations: Converted "$searchText" to "$convertedText"');
        searchText = convertedText;
      }

      // First try searching with the converted text (or original if no conversion needed)
      var result = controller.searchText(searchText);

      // If converted text yielded 0 matches and conversion actually happened,
      // fallback to searching with the original text (in case input was already Unicode)
      if (result.totalInstanceCount == 0 && searchText != provider.searchText) {
        print(
            'PdfViewerPdfOperations: Converted text found 0 matches. Retrying with original text: "${provider.searchText}"');
        result = controller.searchText(provider.searchText);
      }

      // If still 0 matches, try converting Unicode to Bijoy (Reverse Search)
      // This handles cases where PDF is encoded in Bijoy/ANSI but user types Unicode
      if (result.totalInstanceCount == 0) {
        String reverseBijoyText =
            BijoyConverter.convertToBijoy(provider.searchText);
        if (reverseBijoyText != provider.searchText) {
          print(
              'PdfViewerPdfOperations: Attempting Bijoy search with: "$reverseBijoyText"');

          try {
            result = controller.searchText(reverseBijoyText);
            print(
                'DEBUG: Bijoy search completed. Found ${result.totalInstanceCount} matches');
          } catch (e) {
            print('ERROR: Bijoy search failed: $e');
          }
        }
      }

      print(
          'PdfViewerPdfOperations: search result: ${result.totalInstanceCount} matches');
      provider.setSearchResult(result);

      // Capture page number for the first result
      if (result.hasResult) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final currentPage = controller.pageNumber;
          provider.updateSearchResultDetail(0, currentPage, null);
        });
      }
    } else {
      print(
          'PdfViewerPdfOperations: search skipped. Empty text or wrong type.');
    }
  }

  /// Clear search results
  static void clearSearch(
      PdfViewerProvider provider, TextEditingController searchController) {
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
