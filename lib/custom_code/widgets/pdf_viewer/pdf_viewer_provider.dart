import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../models/highlight_model.dart';
import 'highlight_storage_service.dart';
import '../../../models/bookmark_model.dart';
import 'bookmark_storage_service.dart';

enum ReaderType { pdf }

enum AppThemeMode { light, dark, sepia }

class PdfViewerProvider with ChangeNotifier {
  int _currentPage = 1;
  int get currentPage => _currentPage;

  bool _isFullScreen = false;
  bool get isFullScreen => _isFullScreen;

  bool _isAutoRotateEnabled = true;
  bool get isAutoRotateEnabled => _isAutoRotateEnabled;

  double _currentBrightness = 0.5;
  double get currentBrightness => _currentBrightness;

  double _originalBrightness = 0.5;
  double get originalBrightness => _originalBrightness;

  bool _showThemeSelectionWidget = false;
  bool get showThemeSelectionWidget => _showThemeSelectionWidget;

  String? _openDrawer; // 'bookmarks' or null
  String? get openDrawer => _openDrawer;

  bool _isChangingBrightness = false;
  bool get isChangingBrightness => _isChangingBrightness;

  bool _isChangingTheme = false;
  bool get isChangingTheme => _isChangingTheme;

  String _selectedText = "";
  String get selectedText => _selectedText;

  String _searchText = "";
  String get searchText => _searchText;

  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  PdfTextSearchResult get searchResult => _searchResult;

  List<Map<String, dynamic>> _searchResultDetails = [];
  List<Map<String, dynamic>> get searchResultDetails => _searchResultDetails;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _isNavigatingSearchResult = false;
  bool get isNavigatingSearchResult => _isNavigatingSearchResult;

  List<BookmarkModel> _bookmarks = [];
  List<BookmarkModel> get bookmarks => List.unmodifiable(_bookmarks);

  List<int> get bookmarkedPages {
    return _bookmarks.map((b) => b.pageNumber).toList();
  }

  List<HighlightModel> _highlights = [];
  List<HighlightModel> get highlights => List.unmodifiable(_highlights);

  String? _currentBookId;
  String? get currentBookId => _currentBookId;

  bool _isPdfVerticalScroll = true;
  bool get isPdfVerticalScroll => _isPdfVerticalScroll;

  double _blueLightFilter = 0.0;
  double get blueLightFilter => _blueLightFilter;

  AppThemeMode _currentThemeMode =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light;
  AppThemeMode get currentThemeMode => _currentThemeMode;

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

  void setEnableSwipeBrightness(bool enable) {
    // Keep method signature for helper/caller compatibility
  }

  void setBlueLightFilter(double filter) {
    if ((_blueLightFilter - filter).abs() > 0.1) {
      _blueLightFilter = filter;
      notifyListeners();
    }
  }

  void setScreenLightTime(int minutes) {
    // Keep method signature for helper/caller compatibility
  }

  void setThemeMode(AppThemeMode mode) {
    if (_currentThemeMode != mode) {
      _isChangingTheme = true;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 300), () {
        _currentThemeMode = mode;
        _isChangingTheme = false;
        notifyListeners();
      });
    }
  }

  void togglePdfScrollDirection() {
    _isPdfVerticalScroll = !_isPdfVerticalScroll;
    notifyListeners();
  }

  void setPdfVerticalScroll(bool vertical) {
    if (_isPdfVerticalScroll != vertical) {
      _isPdfVerticalScroll = vertical;
      notifyListeners();
    }
  }

  void setOpenDrawer(String? drawer) {
    if (_openDrawer != drawer) {
      _openDrawer = drawer;
      notifyListeners();
    }
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void toggleAutoRotate() {
    _isAutoRotateEnabled = !_isAutoRotateEnabled;
    notifyListeners();
  }

  void setOriginalBrightness(double brightness) {
    _originalBrightness = brightness;
    notifyListeners();
  }

  void setCurrentBrightness(double brightness) {
    _currentBrightness = brightness;
    notifyListeners();
  }

  void setShowThemeSelectionWidget(bool show) {
    _showThemeSelectionWidget = show;
    notifyListeners();
  }

  void setSelectedText(String text) {
    _selectedText = text;
    notifyListeners();
  }

  void setSelectedTextSilent(String text) {
    _selectedText = text;
  }

  void clearSelectedText() {
    _selectedText = "";
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  void setSearchResult(PdfTextSearchResult result) {
    _searchResult = result;
    _searchResultDetails = List.generate(
        result.totalInstanceCount, (index) => <String, dynamic>{});
    notifyListeners();
  }

  void updateSearchResultDetail(int index, int page, String? snippet) {
    if (index >= 0 && index < _searchResultDetails.length) {
      _searchResultDetails[index] = {
        'page': page,
        'snippet': snippet,
      };
      notifyListeners();
    }
  }

  void setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void setNavigatingSearchResult(bool navigating) {
    _isNavigatingSearchResult = navigating;
    notifyListeners();
  }

  void clearSearch() {
    _searchText = "";
    _searchResult = PdfTextSearchResult();
    _searchResultDetails = [];
    notifyListeners();
  }

  void goToNextSearchResult() {
    _searchResult.nextInstance();
    notifyListeners();
  }

  void goToPreviousSearchResult() {
    _searchResult.previousInstance();
    notifyListeners();
  }

  void setCurrentBookId(String? bookId) {
    _currentBookId = bookId;
  }

  Future<void> loadBookmarks(String bookId) async {
    _bookmarks = await BookmarkStorageService.getBookmarksForBook(bookId);
    notifyListeners();
  }

  Future<void> toggleBookmark(
    int pageNumber, {
    String? bookId,
    String? chapterId,
    String? chapterName,
  }) async {
    final activeBookId = bookId ?? _currentBookId;
    if (activeBookId == null) return;

    final existingIndex = _bookmarks.indexWhere((b) => b.pageNumber == pageNumber);
    if (existingIndex >= 0) {
      final bookmark = _bookmarks[existingIndex];
      await BookmarkStorageService.deleteBookmark(bookmark);
      _bookmarks.removeAt(existingIndex);
    } else {
      final bookmark = BookmarkModel(
        id: BookmarkModel.generateId(activeBookId, pageNumber.toString()),
        bookId: activeBookId,
        chapterId: pageNumber.toString(),
        chapterName: chapterName ?? 'Page $pageNumber',
        pageNumber: pageNumber,
        createdAt: DateTime.now(),
      );
      await BookmarkStorageService.saveBookmark(bookmark);
      _bookmarks.add(bookmark);
    }
    notifyListeners();
  }

  Future<void> removeBookmark(int pageNumber, {String? bookId}) async {
    final activeBookId = bookId ?? _currentBookId;
    if (activeBookId == null) return;

    final existingIndex = _bookmarks.indexWhere((b) => b.pageNumber == pageNumber);
    if (existingIndex >= 0) {
      final bookmark = _bookmarks[existingIndex];
      await BookmarkStorageService.deleteBookmark(bookmark);
      _bookmarks.removeAt(existingIndex);
      notifyListeners();
    }
  }

  Future<void> loadHighlights(String bookId) async {
    _highlights = await HighlightStorageService.getHighlightsForBook(bookId);
    notifyListeners();
  }

  Future<void> addHighlight(HighlightModel highlight) async {
    await HighlightStorageService.saveHighlight(highlight);
    _highlights.add(highlight);
    notifyListeners();
  }

  Future<void> removeHighlight(HighlightModel highlight) async {
    await HighlightStorageService.deleteHighlight(highlight);
    _highlights.removeWhere((h) => h.id == highlight.id);
    notifyListeners();
  }

  void setReaderType(ReaderType type) {}
}
