import 'package:flutter/material.dart';
import 'flutter_flow/request_manager.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  initilizePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _isIntro = prefs.getBool('ff_isIntro') ?? _isIntro;
    });
    _safeInit(() {
      _isLogin = prefs.getBool('ff_isLogin') ?? _isLogin;
    });
    _safeInit(() {
      _userId = prefs.getString('ff_userId') ?? _userId;
    });
    _safeInit(() {
      _token = prefs.getString('ff_token') ?? _token;
    });
    _safeInit(() {
      _refreshToken = prefs.getString('ff_refreshToken') ?? _refreshToken;
    });
    _safeInit(() {
      _currentPassword =
          prefs.getString('ff_currentPassword') ?? _currentPassword;
    });
    _safeInit(() {
      if (prefs.containsKey('ff_userDetail')) {
        try {
          _userDetail = jsonDecode(prefs.getString('ff_userDetail') ?? '');
        } catch (e) {
          print("Can't decode persisted json. Error: $e.");
        }
      }
    });
    _safeInit(() {
      _onlyPhoneNumber =
          prefs.getString('ff_onlyPhoneNumber') ?? _onlyPhoneNumber;
    });
    _safeInit(() {
      _favChange = prefs.getBool('ff_favChange') ?? _favChange;
    });
    _safeInit(() {
      _bookId = prefs.getString('ff_bookId') ?? _bookId;
    });
    _safeInit(() {
      _currentPagesPdf = prefs.getInt('ff_currentPagesPdf') ?? _currentPagesPdf;
    });
    _safeInit(() {
      _homePageLiveReadBook =
          prefs.getString('ff_homePageLiveReadBook') ?? _homePageLiveReadBook;
    });
    _safeInit(() {
      _homePageCurrentPdfIndex = prefs.getInt('ff_homePageCurrentPdfIndex') ??
          _homePageCurrentPdfIndex;
    });
    _safeInit(() {
      _homePageTotalPdfPageIndex =
          prefs.getInt('ff_homePageTotalPdfPageIndex') ??
              _homePageTotalPdfPageIndex;
    });
    _safeInit(() {
      _homePageBookId = prefs.getString('ff_homePageBookId') ?? _homePageBookId;
    });
    _safeInit(() {
      _homePageBookName =
          prefs.getString('ff_homePageBookName') ?? _homePageBookName;
    });
    _safeInit(() {
      _homePageBookAuthor =
          prefs.getString('ff_homePageBookAuthor') ?? _homePageBookAuthor;
    });
    _safeInit(() {
      _homePageBookPdf =
          prefs.getString('ff_homePageBookPdf') ?? _homePageBookPdf;
    });
    _safeInit(() {
      _homePageLastAudioBookId =
          prefs.getString('ff_homePageLastAudioBookId') ??
              _homePageLastAudioBookId;
    });
    _safeInit(() {
      _homePageLastAudioBookName =
          prefs.getString('ff_homePageLastAudioBookName') ??
              _homePageLastAudioBookName;
    });
    _safeInit(() {
      _homePageLastAudioBookAuthor =
          prefs.getString('ff_homePageLastAudioBookAuthor') ??
              _homePageLastAudioBookAuthor;
    });
    _safeInit(() {
      _homePageLastAudioBookImage =
          prefs.getString('ff_homePageLastAudioBookImage') ??
              _homePageLastAudioBookImage;
    });
    _safeInit(() {
      _homePageLastAudioProgress =
          prefs.getDouble('ff_homePageLastAudioProgress') ??
              _homePageLastAudioProgress;
    });
    _safeInit(() {
      _homePageLastAudioPositionSec =
          prefs.getInt('ff_homePageLastAudioPositionSec') ??
              _homePageLastAudioPositionSec;
    });
    _safeInit(() {
      _homePageLastAudioDurationSec =
          prefs.getInt('ff_homePageLastAudioDurationSec') ??
              _homePageLastAudioDurationSec;
    });
    _safeInit(() {
      _deviceId = prefs.getString('ff_deviceId') ?? _deviceId;
    });
    _safeInit(() {
      _tokenFcm = prefs.getString('ff_tokenFcm') ?? _tokenFcm;
    });
    _safeInit(() {
      _searchList = prefs.getStringList('ff_searchList') ?? _searchList;
    });
    _safeInit(() {
      _pdfPathSave = prefs.getString('ff_pdfPathSave') ?? _pdfPathSave;
    });
    _safeInit(() {
      _favText = prefs.getString('ff_favText') ?? _favText;
    });
    _safeInit(() {
      _unFavText = prefs.getString('ff_unFavText') ?? _unFavText;
    });
    _safeInit(() {
      _countryCodeEdit =
          prefs.getString('ff_countryCodeEdit') ?? _countryCodeEdit;
    });
    _safeInit(() {
      _watchedAdBooks = prefs.getStringList('ff_watchedAdBooks') ?? _watchedAdBooks;
    });
    _safeInit(() {
      _lastAdShownAtMillis =
          prefs.getInt('ff_lastAdShownAtMillis') ?? _lastAdShownAtMillis;
    });
    ApiManager.setAuthTokens(
      accessToken: _token,
      refreshToken: _refreshToken,
    );
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  bool _isIntro = false;
  bool get isIntro => _isIntro;
  set isIntro(bool value) {
    _isIntro = value;
    prefs.setBool('ff_isIntro', value);
  }

  bool _isLogin = false;
  bool get isLogin => _isLogin;
  set isLogin(bool value) {
    _isLogin = value;
    prefs.setBool('ff_isLogin', value);
  }

  String _phone = '';
  String get phone => _phone;
  set phone(String value) {
    _phone = value;
  }

  String _countryCode = '91';
  String get countryCode => _countryCode;
  set countryCode(String value) {
    _countryCode = value;
  }

  int _introIndex = 0;
  int get introIndex => _introIndex;
  set introIndex(int value) {
    _introIndex = value;
  }

  bool _connected = true;
  bool get connected => _connected;
  set connected(bool value) {
    _connected = value;
  }

  String _userId = '';
  String get userId => _userId;
  set userId(String value) {
    _userId = value;
    prefs.setString('ff_userId', value);
  }

  String _token = '';
  String get token {
    if (_token.isEmpty && prefs.getString('ff_token') != null) {
      _token = prefs.getString('ff_token') ?? _token;
    }
    final persisted = prefs.getString('ff_token');
    if (persisted != null && persisted != _token) {
      _token = persisted;
    }
    return _token;
  }
  set token(String value) {
    _token = value;
    prefs.setString('ff_token', value);
    ApiManager.setAuthTokens(accessToken: value, refreshToken: _refreshToken);
  }

  String _refreshToken = '';
  String get refreshToken {
    if (_refreshToken.isEmpty && prefs.getString('ff_refreshToken') != null) {
      _refreshToken = prefs.getString('ff_refreshToken') ?? _refreshToken;
    }
    final persisted = prefs.getString('ff_refreshToken');
    if (persisted != null && persisted != _refreshToken) {
      _refreshToken = persisted;
    }
    return _refreshToken;
  }
  set refreshToken(String value) {
    _refreshToken = value;
    prefs.setString('ff_refreshToken', value);
    ApiManager.setAuthTokens(accessToken: _token, refreshToken: value);
  }

  String _currentPassword = '';
  String get currentPassword => _currentPassword;
  set currentPassword(String value) {
    _currentPassword = value;
    prefs.setString('ff_currentPassword', value);
  }

  String _currency = '';
  String get currency => _currency;
  set currency(String value) {
    _currency = value;
  }

  dynamic _userDetail;
  dynamic get userDetail => _userDetail;
  set userDetail(dynamic value) {
    _userDetail = value;
    prefs.setString('ff_userDetail', jsonEncode(value));
  }

  String _onlyPhoneNumber = '';
  String get onlyPhoneNumber => _onlyPhoneNumber;
  set onlyPhoneNumber(String value) {
    _onlyPhoneNumber = value;
    prefs.setString('ff_onlyPhoneNumber', value);
  }

  bool _favChange = false;
  bool get favChange => _favChange;
  set favChange(bool value) {
    _favChange = value;
    prefs.setBool('ff_favChange', value);
  }

  String _bookId = '';
  String get bookId => _bookId;
  set bookId(String value) {
    _bookId = value;
    prefs.setString('ff_bookId', value);
  }

  int _currentPagesPdf = 1;
  int get currentPagesPdf => _currentPagesPdf;
  set currentPagesPdf(int value) {
    _currentPagesPdf = value;
    prefs.setInt('ff_currentPagesPdf', value);
  }

  int _totalPages = 1;
  int get totalPages => _totalPages;
  set totalPages(int value) {
    _totalPages = value;
  }

  String _homePageLiveReadBook = '';
  String get homePageLiveReadBook => _homePageLiveReadBook;
  set homePageLiveReadBook(String value) {
    _homePageLiveReadBook = value;
    prefs.setString('ff_homePageLiveReadBook', value);
  }

  int _homePageCurrentPdfIndex = 1;
  int get homePageCurrentPdfIndex => _homePageCurrentPdfIndex;
  set homePageCurrentPdfIndex(int value) {
    _homePageCurrentPdfIndex = value;
    prefs.setInt('ff_homePageCurrentPdfIndex', value);
  }

  int _homePageTotalPdfPageIndex = 1;
  int get homePageTotalPdfPageIndex => _homePageTotalPdfPageIndex;
  set homePageTotalPdfPageIndex(int value) {
    _homePageTotalPdfPageIndex = value;
    prefs.setInt('ff_homePageTotalPdfPageIndex', value);
  }

  String _homePageBookId = '';
  String get homePageBookId => _homePageBookId;
  set homePageBookId(String value) {
    _homePageBookId = value;
    prefs.setString('ff_homePageBookId', value);
  }

  String _homePageBookName = '';
  String get homePageBookName => _homePageBookName;
  set homePageBookName(String value) {
    _homePageBookName = value;
    prefs.setString('ff_homePageBookName', value);
  }

  String _homePageBookAuthor = '';
  String get homePageBookAuthor => _homePageBookAuthor;
  set homePageBookAuthor(String value) {
    _homePageBookAuthor = value;
    prefs.setString('ff_homePageBookAuthor', value);
  }

  String _homePageBookPdf = '';
  String get homePageBookPdf => _homePageBookPdf;
  set homePageBookPdf(String value) {
    _homePageBookPdf = value;
    prefs.setString('ff_homePageBookPdf', value);
  }

  String _homePageLastAudioBookId = '';
  String get homePageLastAudioBookId => _homePageLastAudioBookId;
  set homePageLastAudioBookId(String value) {
    _homePageLastAudioBookId = value;
    prefs.setString('ff_homePageLastAudioBookId', value);
  }

  String _homePageLastAudioBookName = '';
  String get homePageLastAudioBookName => _homePageLastAudioBookName;
  set homePageLastAudioBookName(String value) {
    _homePageLastAudioBookName = value;
    prefs.setString('ff_homePageLastAudioBookName', value);
  }

  String _homePageLastAudioBookAuthor = '';
  String get homePageLastAudioBookAuthor => _homePageLastAudioBookAuthor;
  set homePageLastAudioBookAuthor(String value) {
    _homePageLastAudioBookAuthor = value;
    prefs.setString('ff_homePageLastAudioBookAuthor', value);
  }

  String _homePageLastAudioBookImage = '';
  String get homePageLastAudioBookImage => _homePageLastAudioBookImage;
  set homePageLastAudioBookImage(String value) {
    _homePageLastAudioBookImage = value;
    prefs.setString('ff_homePageLastAudioBookImage', value);
  }

  double _homePageLastAudioProgress = 0.0;
  double get homePageLastAudioProgress => _homePageLastAudioProgress;
  set homePageLastAudioProgress(double value) {
    _homePageLastAudioProgress = value;
    prefs.setDouble('ff_homePageLastAudioProgress', value);
  }

  int _homePageLastAudioPositionSec = 0;
  int get homePageLastAudioPositionSec => _homePageLastAudioPositionSec;
  set homePageLastAudioPositionSec(int value) {
    _homePageLastAudioPositionSec = value;
    prefs.setInt('ff_homePageLastAudioPositionSec', value);
  }

  int _homePageLastAudioDurationSec = 0;
  int get homePageLastAudioDurationSec => _homePageLastAudioDurationSec;
  set homePageLastAudioDurationSec(int value) {
    _homePageLastAudioDurationSec = value;
    prefs.setInt('ff_homePageLastAudioDurationSec', value);
  }

  String _deviceId = '';
  String get deviceId => _deviceId;
  set deviceId(String value) {
    _deviceId = value;
    prefs.setString('ff_deviceId', value);
  }

  String _tokenFcm =
      'e0Z5SQPMRaat0gxQ2EzQva:APA91bEFZ3KS9sck72eDw5HzQ1HkhU_TbIpX7zfNghLFF7aiAnyHN68zcCOdOJrG_lHpICTaNif7NxudJY2Als_6cpbOp6VQtIFT3VCYikSwrzhZtUXxrO7chlQ2g8f_pkQHH-G8OZIc';
  String get tokenFcm => _tokenFcm;
  set tokenFcm(String value) {
    _tokenFcm = value;
    prefs.setString('ff_tokenFcm', value);
  }

  List<String> _authorId = [];
  List<String> get authorId => _authorId;
  set authorId(List<String> value) {
    _authorId = value;
  }

  void addToAuthorId(String value) {
    authorId.add(value);
  }

  void removeFromAuthorId(String value) {
    authorId.remove(value);
  }

  void removeAtIndexFromAuthorId(int index) {
    authorId.removeAt(index);
  }

  void updateAuthorIdAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    authorId[index] = updateFn(_authorId[index]);
  }

  void insertAtIndexInAuthorId(int index, String value) {
    authorId.insert(index, value);
  }

  List<String> _categoryId = [];
  List<String> get categoryId => _categoryId;
  set categoryId(List<String> value) {
    _categoryId = value;
  }

  void addToCategoryId(String value) {
    categoryId.add(value);
  }

  void removeFromCategoryId(String value) {
    categoryId.remove(value);
  }

  void removeAtIndexFromCategoryId(int index) {
    categoryId.removeAt(index);
  }

  void updateCategoryIdAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    categoryId[index] = updateFn(_categoryId[index]);
  }

  void insertAtIndexInCategoryId(int index, String value) {
    categoryId.insert(index, value);
  }

  bool _filterVariable = false;
  bool get filterVariable => _filterVariable;
  set filterVariable(bool value) {
    _filterVariable = value;
  }

  List<String> _searchList = [];
  List<String> get searchList => _searchList;
  set searchList(List<String> value) {
    _searchList = value;
    prefs.setStringList('ff_searchList', value);
  }

  void addToSearchList(String value) {
    searchList.add(value);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void removeFromSearchList(String value) {
    searchList.remove(value);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void removeAtIndexFromSearchList(int index) {
    searchList.removeAt(index);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void updateSearchListAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    searchList[index] = updateFn(_searchList[index]);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void insertAtIndexInSearchList(int index, String value) {
    searchList.insert(index, value);
    prefs.setStringList('ff_searchList', _searchList);
  }

  String _pdfPathSave = '';
  String get pdfPathSave => _pdfPathSave;
  set pdfPathSave(String value) {
    _pdfPathSave = value;
    prefs.setString('ff_pdfPathSave', value);
  }

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value) {
    _loading = value;
  }

  double _progress = 0.0;
  double get progress => _progress;
  set progress(double value) {
    _progress = value;
  }

  String _subscriptionId = '';
  String get subscriptionId => _subscriptionId;
  set subscriptionId(String value) {
    _subscriptionId = value;
  }

  bool _paymentSuccessCheck = false;
  bool get paymentSuccessCheck => _paymentSuccessCheck;
  set paymentSuccessCheck(bool value) {
    _paymentSuccessCheck = value;
  }

  String _paypalTransationId = '';
  String get paypalTransationId => _paypalTransationId;
  set paypalTransationId(String value) {
    _paypalTransationId = value;
  }

  String _razorpayTransationId = '';
  String get razorpayTransationId => _razorpayTransationId;
  set razorpayTransationId(String value) {
    _razorpayTransationId = value;
  }

  String _favText = '     Book added to favorite     ';
  String get favText => _favText;
  set favText(String value) {
    _favText = value;
    prefs.setString('ff_favText', value);
  }

  String _unFavText = '     Book removed from favorite     ';
  String get unFavText => _unFavText;
  set unFavText(String value) {
    _unFavText = value;
    prefs.setString('ff_unFavText', value);
  }

  String _countryName = 'BD';
  String get countryName => _countryName;
  set countryName(String value) {
    _countryName = value;
  }

  String _countryCodeEdit = '';
  String get countryCodeEdit => _countryCodeEdit;
  set countryCodeEdit(String value) {
    _countryCodeEdit = value;
    prefs.setString('ff_countryCodeEdit', value);
  }

  List<String> _watchedAdBooks = [];
  List<String> get watchedAdBooks => _watchedAdBooks;
  set watchedAdBooks(List<String> value) {
    _watchedAdBooks = value;
    prefs.setStringList('ff_watchedAdBooks', value);
  }

  void addToWatchedAdBooks(String bookId) {
    if (!_watchedAdBooks.contains(bookId)) {
      _watchedAdBooks.add(bookId);
      prefs.setStringList('ff_watchedAdBooks', _watchedAdBooks);
    }
  }

  bool hasWatchedAdForBook(String bookId) {
    return _watchedAdBooks.contains(bookId);
  }

  int _lastAdShownAtMillis = 0;
  int get lastAdShownAtMillis => _lastAdShownAtMillis;
  set lastAdShownAtMillis(int value) {
    _lastAdShownAtMillis = value;
    prefs.setInt('ff_lastAdShownAtMillis', value);
  }

  bool isAdIntervalPassed({Duration interval = const Duration(minutes: 10)}) {
    if (_lastAdShownAtMillis <= 0) {
      return true;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastAdShownAtMillis) >= interval.inMilliseconds;
  }

  void markAdShownNow() {
    lastAdShownAtMillis = DateTime.now().millisecondsSinceEpoch;
  }

  final _getCategoriesCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getCategoriesCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getCategoriesCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetCategoriesCacheCache() => _getCategoriesCacheManager.clear();
  void clearGetCategoriesCacheCacheKey(String? uniqueKey) =>
      _getCategoriesCacheManager.clearRequest(uniqueKey);

  final _getauthorsCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getauthorsCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getauthorsCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetauthorsCacheCache() => _getauthorsCacheManager.clear();
  void clearGetauthorsCacheCacheKey(String? uniqueKey) =>
      _getauthorsCacheManager.clearRequest(uniqueKey);

  final _getpublishersCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getpublishersCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getpublishersCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetpublishersCacheCache() => _getpublishersCacheManager.clear();
  void clearGetpublishersCacheCacheKey(String? uniqueKey) =>
      _getpublishersCacheManager.clearRequest(uniqueKey);

  final _getnarratorsCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getnarratorsCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getnarratorsCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetnarratorsCacheCache() => _getnarratorsCacheManager.clear();
  void clearGetnarratorsCacheCacheKey(String? uniqueKey) =>
      _getnarratorsCacheManager.clearRequest(uniqueKey);

  final _getBookbyCategoryCacheManager =
      FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getBookbyCategoryCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getBookbyCategoryCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetBookbyCategoryCacheCache() =>
      _getBookbyCategoryCacheManager.clear();
  void clearGetBookbyCategoryCacheCacheKey(String? uniqueKey) =>
      _getBookbyCategoryCacheManager.clearRequest(uniqueKey);

  final _getReviewCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getReviewCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getReviewCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetReviewCacheCache() => _getReviewCacheManager.clear();
  void clearGetReviewCacheCacheKey(String? uniqueKey) =>
      _getReviewCacheManager.clearRequest(uniqueKey);

  final _getTrendingBooksCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getTrendingBooksCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getTrendingBooksCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetTrendingBooksCacheCache() =>
      _getTrendingBooksCacheManager.clear();
  void clearGetTrendingBooksCacheCacheKey(String? uniqueKey) =>
      _getTrendingBooksCacheManager.clearRequest(uniqueKey);

  final _getFavouriteBookCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getFavouriteBookCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getFavouriteBookCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetFavouriteBookCacheCache() =>
      _getFavouriteBookCacheManager.clear();
  void clearGetFavouriteBookCacheCacheKey(String? uniqueKey) =>
      _getFavouriteBookCacheManager.clearRequest(uniqueKey);

  final _getLatestAllBookCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getLatestAllBookCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getLatestAllBookCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetLatestAllBookCacheCache() =>
      _getLatestAllBookCacheManager.clear();
  void clearGetLatestAllBookCacheCacheKey(String? uniqueKey) =>
      _getLatestAllBookCacheManager.clearRequest(uniqueKey);

  final _popularBookCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> popularBookCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _popularBookCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearPopularBookCacheCache() => _popularBookCacheManager.clear();
  void clearPopularBookCacheCacheKey(String? uniqueKey) =>
      _popularBookCacheManager.clearRequest(uniqueKey);

  final _getPageCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getPageCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getPageCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetPageCacheCache() => _getPageCacheManager.clear();
  void clearGetPageCacheCacheKey(String? uniqueKey) =>
      _getPageCacheManager.clearRequest(uniqueKey);

  final _getSlidersCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getSlidersCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getSlidersCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetSlidersCacheCache() => _getSlidersCacheManager.clear();
  void clearGetSlidersCacheCacheKey(String? uniqueKey) =>
      _getSlidersCacheManager.clearRequest(uniqueKey);

  final _getHomepageCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getHomepageCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getHomepageCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetHomepageCacheCache() => _getHomepageCacheManager.clear();
  void clearGetHomepageCacheCacheKey(String? uniqueKey) =>
      _getHomepageCacheManager.clearRequest(uniqueKey);

  final _getNewBooksCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getNewBooksCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getNewBooksCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetNewBooksCacheCache() => _getNewBooksCacheManager.clear();
  void clearGetNewBooksCacheCacheKey(String? uniqueKey) =>
      _getNewBooksCacheManager.clearRequest(uniqueKey);

  final _getFeaturedBooksByCategoryCacheManager =
      FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> getFeaturedBooksByCategoryCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _getFeaturedBooksByCategoryCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetFeaturedBooksByCategoryCacheCache() =>
      _getFeaturedBooksByCategoryCacheManager.clear();
  void clearGetFeaturedBooksByCategoryCacheCacheKey(String? uniqueKey) =>
      _getFeaturedBooksByCategoryCacheManager.clearRequest(uniqueKey);
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
