import 'dart:convert';

/// Text operations for PDF Viewer (book ID generation)
class PdfViewerTextOperations {
  /// Generate book ID from file path
  static String generateBookId(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return 'unknown_book';
    }
    return base64Encode(utf8.encode(filePath)).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, 32);
  }
}
