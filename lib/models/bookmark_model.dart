/// Bookmark model for storing bookmark information
class BookmarkModel {
  final String id;
  final String bookId;
  final String chapterId; // For EPUB: chapter index as string, For PDF: page number as string
  final String chapterName; // Chapter title or "Page X" for PDF
  final int pageNumber; // Page number (1-indexed)
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterName,
    required this.pageNumber,
    required this.createdAt,
  });

  /// Generate unique ID for bookmark
  static String generateId(String bookId, String chapterId) {
    return '${bookId}_${chapterId}';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterName': chapterName,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterId: json['chapterId'] as String,
      chapterName: json['chapterName'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

