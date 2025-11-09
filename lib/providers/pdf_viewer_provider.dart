import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:epubx/epubx.dart' as epubx;

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
  
  double _speechRate = 0.9;
  double get speechRate => _speechRate;
  
  double _pitch = 1.0;
  double get pitch => _pitch;
  
  String _searchText = "";
  String get searchText => _searchText;
  
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  PdfTextSearchResult get searchResult => _searchResult;
  
  List<int> _bookmarkedPages = [];
  List<int> get bookmarkedPages => List.unmodifiable(_bookmarkedPages);
  
  List<String> _highlights = [];
  List<String> get highlights => List.unmodifiable(_highlights);
  
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

  void toggleBookmark(int page) {
    if (_bookmarkedPages.contains(page)) {
      _bookmarkedPages.remove(page);
    } else {
      _bookmarkedPages.add(page);
    }
    notifyListeners();
  }

  void removeBookmark(int page) {
    _bookmarkedPages.remove(page);
    notifyListeners();
  }

  bool isBookmarked(int page) {
    return _bookmarkedPages.contains(page);
  }

  void addHighlight(String text) {
    if (!_highlights.contains(text)) {
      _highlights.add(text);
      notifyListeners();
    }
  }

  void removeHighlight(String text) {
    _highlights.remove(text);
    notifyListeners();
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
    _bookmarkedPages = [];
    _highlights = [];
    _lastScrollPosition = 0;
    notifyListeners();
  }
}

