import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:epubx/epubx.dart' as epubx;
import '../models/highlight_model.dart';
import '../services/highlight_storage_service.dart';
import '../models/bookmark_model.dart';
import '../services/bookmark_storage_service.dart';

enum ReaderType { pdf, epub }

enum AppThemeMode { light, dark, sepia }

class PdfViewerProvider with ChangeNotifier {
  // Reader State
  ReaderType _readerType = ReaderType.epub;
  ReaderType get readerType => _readerType;
  
  int _currentPage = 1;
  int get currentPage => _currentPage;
  
  bool _isLoadingEpub = false;
  bool get isLoadingEpub => _isLoadingEpub;

  // EPUB State
  epubx.EpubBook? _epubBook;
  epubx.EpubBook? get epubBook => _epubBook;
  
  List<epubx.EpubChapter> _epubChapters = [];
  List<epubx.EpubChapter> get epubChapters => _epubChapters;
  
  int _currentEpubChapterIndex = 0;
  int get currentEpubChapterIndex => _currentEpubChapterIndex;
  
  String _currentEpubContent = "";
  String get currentEpubContent => _currentEpubContent;
  
  double _epubFontSize = 16.0;
  double get epubFontSize => _epubFontSize;
  
  double _epubLineHeight = 1.6;
  double get epubLineHeight => _epubLineHeight;
  
  AppThemeMode _currentThemeMode = AppThemeMode.light;
  AppThemeMode get currentThemeMode => _currentThemeMode;
  
  bool _isChangingChapter = false;
  bool get isChangingChapter => _isChangingChapter;

  // UI State
  bool _isFullScreen = false;
  bool get isFullScreen => _isFullScreen;
  
  bool _isAutoRotateEnabled = true;
  bool get isAutoRotateEnabled => _isAutoRotateEnabled;
  
  double _currentBrightness = 0.5;
  double get currentBrightness => _currentBrightness;
  
  double _originalBrightness = 0.5;
  double get originalBrightness => _originalBrightness;

  // Interactions
  String _selectedText = "";
  String get selectedText => _selectedText;
  
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;
  
  double _speechRate = 0.6;
  double get speechRate => _speechRate;
  
  double _pitch = 1.0;
  double get pitch => _pitch;
  
  String _searchText = "";
  String get searchText => _searchText;
  
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  PdfTextSearchResult get searchResult => _searchResult;
  
  List<BookmarkModel> _bookmarks = [];
  List<BookmarkModel> get bookmarks => List.unmodifiable(_bookmarks);
  
  // Legacy getter for backward compatibility (returns page numbers)
  List<int> get bookmarkedPages {
    return _bookmarks.map((b) => b.pageNumber).toList();
  }
  
  List<HighlightModel> _highlights = [];
  List<HighlightModel> get highlights => List.unmodifiable(_highlights);
  
  String? _currentBookId; // Track current book ID
  String? get currentBookId => _currentBookId;
  
  double _lastScrollPosition = 0;
  double get lastScrollPosition => _lastScrollPosition;

  // Chapter Read-Aloud State
  bool _isReadingChapter = false;
  bool get isReadingChapter => _isReadingChapter;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  int _currentReadingSentenceIndex = 0;
  int get currentReadingSentenceIndex => _currentReadingSentenceIndex;

  List<String> _chapterSentences = [];
  List<String> get chapterSentences => List.unmodifiable(_chapterSentences);

  // Reader Type Methods
  void setReaderType(ReaderType type) {
    _readerType = type;
    notifyListeners();
  }

  // Page Methods
  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void incrementPage() {
    _currentPage++;
    notifyListeners();
  }

  void decrementPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  // EPUB Loading Methods
  void setLoadingEpub(bool loading) {
    _isLoadingEpub = loading;
    notifyListeners();
  }

  void setEpubBook(epubx.EpubBook? book) {
    _epubBook = book;
    notifyListeners();
  }

  void setEpubChapters(List<epubx.EpubChapter> chapters) {
    _epubChapters = chapters;
    notifyListeners();
  }

  void setCurrentEpubChapterIndex(int index) {
    _currentEpubChapterIndex = index;
    _currentPage = index + 1;
    notifyListeners();
  }

  void setCurrentEpubContent(String content) {
    _currentEpubContent = content;
    notifyListeners();
  }

  void setChangingChapter(bool changing) {
    _isChangingChapter = changing;
    notifyListeners();
  }

  // EPUB Settings Methods
  void setEpubFontSize(double size) {
    _epubFontSize = size;
    notifyListeners();
  }

  void setEpubLineHeight(double height) {
    _epubLineHeight = height;
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) {
    _currentThemeMode = mode;
    notifyListeners();
  }

  // UI State Methods
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void setFullScreen(bool value) {
    _isFullScreen = value;
    notifyListeners();
  }

  void toggleAutoRotate() {
    _isAutoRotateEnabled = !_isAutoRotateEnabled;
    notifyListeners();
  }

  void setAutoRotate(bool value) {
    _isAutoRotateEnabled = value;
    notifyListeners();
  }

  void setCurrentBrightness(double brightness) {
    _currentBrightness = brightness;
    notifyListeners();
  }

  void setOriginalBrightness(double brightness) {
    _originalBrightness = brightness;
  }

  // Interaction Methods
  void setSelectedText(String text) {
    // Only update if text actually changed
    if (_selectedText == text) {
      return; // No change, don't notify
    }
    
    final wasEmpty = _selectedText.isEmpty;
    final willBeEmpty = text.isEmpty;
    
    _selectedText = text;
    
    // Only notify if the visibility state of selection UI changes
    // (empty -> non-empty or non-empty -> empty)
    if (wasEmpty != willBeEmpty) {
      notifyListeners();
    }
    // Otherwise, don't notify to avoid interrupting active text selection
  }
  
  void setSelectedTextSilent(String text) {
    // Update without notifying - used when we don't want to trigger rebuilds
    _selectedText = text;
  }

  void clearSelectedText() {
    if (_selectedText.isNotEmpty) {
      _selectedText = "";
      notifyListeners();
    }
  }

  void setSpeaking(bool speaking) {
    // Only notify if state actually changed
    if (_isSpeaking == speaking) {
      return;
    }
    _isSpeaking = speaking;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate;
    notifyListeners();
  }

  void setPitch(double pitchValue) {
    _pitch = pitchValue;
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  void setSearchResult(PdfTextSearchResult result) {
    _searchResult = result;
    notifyListeners();
  }

  void clearSearch() {
    _searchResult = PdfTextSearchResult();
    _searchText = "";
    notifyListeners();
  }

  void goToNextSearchResult() {
    if (_searchResult.hasResult) {
      _searchResult.nextInstance();
      notifyListeners();
    }
  }

  void goToPreviousSearchResult() {
    if (_searchResult.hasResult) {
      _searchResult.previousInstance();
      notifyListeners();
    }
  }

  /// Load bookmarks for current book
  Future<void> loadBookmarks(String bookId) async {
    _bookmarks = await BookmarkStorageService.getBookmarksForBook(bookId);
    notifyListeners();
  }

  /// Toggle bookmark (add or remove)
  Future<void> toggleBookmark(int page, {String? bookId, String? chapterId, String? chapterName}) async {
    if (bookId == null) {
      // If no bookId provided, try to use current book
      bookId = _currentBookId;
    }
    
    if (bookId == null) {
      print('Cannot toggle bookmark: bookId is null');
      return;
    }

    // Use page as chapterId if not provided
    chapterId ??= page.toString();
    chapterName ??= 'Page $page';

    final bookmarkId = BookmarkModel.generateId(bookId, chapterId);
    final existingBookmark = _bookmarks.firstWhere(
      (b) => b.id == bookmarkId,
      orElse: () => BookmarkModel(
        id: '',
        bookId: '',
        chapterId: '',
        chapterName: '',
        pageNumber: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (existingBookmark.id.isNotEmpty) {
      // Remove bookmark
      await BookmarkStorageService.deleteBookmark(existingBookmark);
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
    } else {
      // Add bookmark
      final bookmark = BookmarkModel(
        id: bookmarkId,
        bookId: bookId,
        chapterId: chapterId,
        chapterName: chapterName,
        pageNumber: page,
        createdAt: DateTime.now(),
      );
      await BookmarkStorageService.saveBookmark(bookmark);
      _bookmarks.add(bookmark);
    }
    notifyListeners();
  }

  /// Remove bookmark
  Future<void> removeBookmark(int page, {String? bookId}) async {
    if (bookId == null) {
      bookId = _currentBookId;
    }
    
    if (bookId == null) {
      print('Cannot remove bookmark: bookId is null');
      return;
    }

    final chapterId = page.toString();
    final bookmarkId = BookmarkModel.generateId(bookId, chapterId);
    
    final bookmark = _bookmarks.firstWhere(
      (b) => b.id == bookmarkId,
      orElse: () => BookmarkModel(
        id: '',
        bookId: '',
        chapterId: '',
        chapterName: '',
        pageNumber: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (bookmark.id.isNotEmpty) {
      await BookmarkStorageService.deleteBookmark(bookmark);
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
      notifyListeners();
    }
  }

  bool isBookmarked(int page, {String? bookId}) {
    if (bookId == null) {
      bookId = _currentBookId;
    }
    
    if (bookId == null) {
      return false;
    }

    final chapterId = page.toString();
    final bookmarkId = BookmarkModel.generateId(bookId, chapterId);
    return _bookmarks.any((b) => b.id == bookmarkId);
  }

  /// Set current book ID (used for highlights)
  void setCurrentBookId(String? bookId) {
    _currentBookId = bookId;
    notifyListeners();
  }

  /// Load highlights for current book
  Future<void> loadHighlights(String bookId) async {
    _currentBookId = bookId;
    final highlights = await HighlightStorageService.getHighlightsForBook(bookId);
    _highlights = highlights;
    notifyListeners();
  }

  /// Add a highlight
  void addHighlight(HighlightModel highlight) {
    if (!_highlights.any((h) => h.id == highlight.id)) {
      _highlights.add(highlight);
      notifyListeners();
    }
  }

  /// Remove a highlight
  void removeHighlight(HighlightModel highlight) {
    _highlights.removeWhere((h) => h.id == highlight.id);
    notifyListeners();
  }

  /// Get highlights for current chapter
  List<HighlightModel> getHighlightsForChapter(String chapterId) {
    return _highlights.where((h) => h.chapterId == chapterId).toList();
  }

  /// Check if a position is highlighted
  bool isPositionHighlighted(String chapterId, int startPosition, int endPosition) {
    return _highlights.any((h) =>
        h.chapterId == chapterId &&
        h.startPosition == startPosition &&
        h.endPosition == endPosition);
  }

  void setLastScrollPosition(double position) {
    // Don't trigger rebuilds for scroll position changes
    // This is just internal state tracking
    _lastScrollPosition = position;
    // No notifyListeners() - scroll position doesn't need UI updates
  }

  // Chapter Read-Aloud Methods
  void setReadingChapter(bool reading) {
    _isReadingChapter = reading;
    if (!reading) {
      _currentReadingSentenceIndex = 0;
      _chapterSentences = [];
      _isPaused = false;
    }
    notifyListeners();
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void setChapterSentences(List<String> sentences) {
    _chapterSentences = sentences;
    _currentReadingSentenceIndex = 0;
    notifyListeners();
  }

  void setCurrentReadingSentenceIndex(int index) {
    if (index >= 0 && index < _chapterSentences.length) {
      _currentReadingSentenceIndex = index;
      notifyListeners();
    }
  }

  void incrementReadingSentenceIndex() {
    if (_currentReadingSentenceIndex < _chapterSentences.length - 1) {
      _currentReadingSentenceIndex++;
      notifyListeners();
    }
  }

  void decrementReadingSentenceIndex() {
    if (_currentReadingSentenceIndex > 0) {
      _currentReadingSentenceIndex--;
      notifyListeners();
    }
  }

  // Reset method for cleanup
  void reset() {
    _readerType = ReaderType.epub;
    _currentPage = 1;
    _isLoadingEpub = false;
    _epubBook = null;
    _epubChapters = [];
    _currentEpubChapterIndex = 0;
    _currentEpubContent = "";
    _epubFontSize = 16.0;
    _epubLineHeight = 1.6;
    _currentThemeMode = AppThemeMode.light;
    _isChangingChapter = false;
    _isFullScreen = false;
    _isAutoRotateEnabled = true;
    _currentBrightness = 0.5;
    _originalBrightness = 0.5;
    _selectedText = "";
    _isSpeaking = false;
    _speechRate = 0.9;
    _pitch = 1.0;
    _searchText = "";
    _searchResult = PdfTextSearchResult();
    _bookmarks = [];
    _highlights = [];
    _currentBookId = null;
    _lastScrollPosition = 0;
    notifyListeners();
  }
}

