/// Highlight model for storing book highlights
class HighlightModel {
  final String id;
  final String bookId;
  final String chapterId;
  final String chapterName;
  final String text;
  final int startPosition; // Character position in chapter
  final int endPosition; // Character position in chapter
  final DateTime createdAt;

  HighlightModel({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterName,
    required this.text,
    required this.startPosition,
    required this.endPosition,
    required this.createdAt,
  });

  /// Create from JSON
  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterId: json['chapterId'] as String,
      chapterName: json['chapterName'] as String,
      text: json['text'] as String,
      startPosition: json['startPosition'] as int,
      endPosition: json['endPosition'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterName': chapterName,
      'text': text,
      'startPosition': startPosition,
      'endPosition': endPosition,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Generate unique ID from book, chapter, and position
  static String generateId(String bookId, String chapterId, int startPosition) {
    return '${bookId}_${chapterId}_$startPosition';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

