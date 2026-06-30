import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/app_constants.dart';
import '/app_state.dart';
import '/backend/boiaro_legacy_adapter.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

Map<String, dynamic> _boiaroAuthHeaders(String? token) => {
      'Content-Type': 'application/json',
      if (FFAppConstants.supabaseAnonApiKey.isNotEmpty)
        'apikey': FFAppConstants.supabaseAnonApiKey,
      if ((token ?? '').isNotEmpty) 'Authorization': 'Bearer $token',
    };

/// Public uploads and covers may be absolute URLs or site-relative paths.
String resolveBoiaroPublicMediaUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return '${FFAppConstants.webUrl}$trimmed';
}

/// One homepage hero slider row (book-shaped API) plus legacy card for navigation.
Map<String, dynamic> homepageSliderDetailFromRaw(Map<String, dynamic> m) {
  final coverRaw =
      (m['image'] ?? m['cover_url'] ?? m['banner_url'])?.toString() ?? '';
  final coverResolved = resolveBoiaroPublicMediaUrl(coverRaw);
  final directUrl = (m['button_url'] ?? m['url'])?.toString() ?? '';
  final slug = m['slug']?.toString() ?? '';
  final buttonUrl = directUrl.isNotEmpty
      ? directUrl
      : slug.isNotEmpty
          ? '${FFAppConstants.webUrl}/book/$slug'
          : FFAppConstants.webUrl;

  final legacyBook = BoiaroLegacyAdapter.legacyBookFromHomepageItem(
    Map<String, dynamic>.from(m),
    preferredFormat: 'ebook',
  );
  if (coverResolved.isNotEmpty) {
    legacyBook['image'] = coverResolved;
  }

  var hasEbook = false;
  var hasAudiobook = false;
  var hasHardcopy = false;
  final formats = m['formats'];
  if (formats is List) {
    for (final f in formats) {
      if (f is! Map) {
        continue;
      }
      if (f['in_stock'] == false) {
        continue;
      }
      final ft = f['format']?.toString().toLowerCase().trim() ?? '';
      if (ft == 'ebook' || ft == 'e-book') {
        hasEbook = true;
      } else if (ft.contains('audio')) {
        hasAudiobook = true;
      } else if (ft == 'hardcopy' || ft.contains('hard') || ft == 'print') {
        hasHardcopy = true;
      }
    }
  }

  final titleBn = m['title']?.toString().trim() ?? '';
  final titleEn = m['title_en']?.toString().trim() ?? '';
  final title =
      titleBn.isNotEmpty ? titleBn : (titleEn.isNotEmpty ? titleEn : '');

  var authorName = '';
  final author = m['author'];
  if (author is Map) {
    authorName = author['name']?.toString() ?? '';
  }

  var categoryName = '';
  final category = m['category'];
  if (category is Map) {
    categoryName = category['name']?.toString() ?? '';
  }

  final showEditorsBadge = m['is_featured'] == true;
  final displayTitle =
      title.isNotEmpty ? title : (legacyBook['name']?.toString() ?? '');

  return {
    'image': coverResolved.isNotEmpty ? coverResolved : coverRaw,
    'button_url': buttonUrl,
    'title': displayTitle,
    'author_name': authorName,
    'category_name': categoryName,
    'has_ebook': hasEbook,
    'has_audiobook': hasAudiobook,
    'has_hardcopy': hasHardcopy,
    'show_editors_badge': showEditorsBadge,
    'legacy_book': legacyBook,
  };
}

ApiCallResponse _v2Error(dynamic body, int status) {
  final msg = BoiaroLegacyAdapter.v2Error(body) ?? 'Request failed';
  return ApiCallResponse(
    BoiaroLegacyAdapter.legacyDataEnvelope(
      success: 0,
      message: msg,
      extra: <String, dynamic>{'error': 1},
    ),
    {},
    status,
  );
}

bool _matchesBookTypeFilter(Map<String, dynamic> b, String? type) {
  final t = _normalizeHomepageTypeValue(type);
  if (t.isEmpty) {
    return true;
  }
  final combined = '${b['type'] ?? ''} ${b['bookType'] ?? ''}'.toLowerCase();
  if (t == 'audiobook' || t == 'audio') {
    return combined.contains('audio');
  }
  if (t == 'ebook' || t == 'e-book') {
    return combined.contains('ebook') ||
        combined.contains('epub') ||
        combined.contains('pdf') ||
        combined.isEmpty;
  }
  if (t == 'hardcopy') {
    return combined.contains('hard') ||
        combined.contains('print') ||
        combined.contains('paper');
  }
  return true;
}

String _normalizeHomepageTypeValue(String? type) {
  final t = (type ?? '').trim().toLowerCase();
  if (t.isEmpty) {
    return '';
  }
  if (t == 'hardcover') {
    return 'hardcopy';
  }
  if (t == 'ebook' || t == 'audiobook' || t == 'hardcopy') {
    return t;
  }
  return '__invalid__';
}

String _preferredHomepageFormatForSection(String sectionKey, String? type) {
  final normalizedType = _normalizeHomepageTypeValue(type);
  if (normalizedType.isNotEmpty && normalizedType != '__invalid__') {
    return normalizedType;
  }
  switch (sectionKey) {
    case 'popularAudiobooks':
    case 'continueListening':
      return 'audiobook';
    case 'popularHardCopies':
      return 'hardcopy';
    case 'popularEbooks':
    case 'continueReading':
      return 'ebook';
    default:
      return '';
  }
}

List<String> _homepageSectionBucketCandidates(String sectionKey, String? type) {
  final normalizedType = _normalizeHomepageTypeValue(type);
  switch (normalizedType) {
    case 'ebook':
      return const ['ebooks', 'ebook', 'all'];
    case 'audiobook':
      return const ['audiobooks', 'audiobook', 'all'];
    case 'hardcopy':
      return const [
        'hardcopies',
        'hardcopy',
        'hardCovers',
        'hardcovers',
        'all'
      ];
    default:
      break;
  }

  switch (sectionKey) {
    case 'popularAudiobooks':
    case 'continueListening':
      return const ['audiobooks', 'audiobook', 'all'];
    case 'popularHardCopies':
      return const [
        'hardcopies',
        'hardcopy',
        'hardCovers',
        'hardcovers',
        'all'
      ];
    case 'popularEbooks':
    case 'continueReading':
      return const ['ebooks', 'ebook', 'all'];
    default:
      return const ['all'];
  }
}

dynamic _extractHomepageSectionRows(
    String sectionKey, dynamic body, String? type) {
  if (body is! Map) {
    return null;
  }
  dynamic raw = body[sectionKey];
  final data = body['data'];
  if (raw == null && data is Map) {
    raw = data[sectionKey] ?? data;
  }
  if (raw == null && data is List) {
    raw = data;
  }
  if (raw is Map) {
    if (raw['data'] is Map) {
      final nested = _extractHomepageSectionRows(
        sectionKey,
        raw['data'],
        type,
      );
      if (nested != null) {
        return nested;
      }
    }
    if (raw.containsKey(sectionKey)) {
      return raw[sectionKey];
    }
    for (final bucket in _homepageSectionBucketCandidates(sectionKey, type)) {
      if (raw.containsKey(bucket)) {
        return raw[bucket];
      }
    }
    for (final fallbackKey in const ['items', 'books', 'results', 'list']) {
      if (raw[fallbackKey] is List) {
        return raw[fallbackKey];
      }
    }
    if (sectionKey == 'newReleases' && raw.containsKey('all')) {
      return raw['all'];
    }
    if (sectionKey == 'slider' && raw.containsKey('slider')) {
      return raw['slider'];
    }
    final listValues = raw.values.whereType<List>().toList();
    if (listValues.length == 1) {
      return listValues.first;
    }
  }
  return raw;
}

Future<ApiCallResponse> _homepageSectionRequest({
  required String sectionKey,
  String? type,
  String? token,
  int? limit,
  int? offset,
}) async {
  final normalizedType = _normalizeHomepageTypeValue(type);
  if (normalizedType == '__invalid__') {
    return ApiCallResponse(
      {
        'error': 'Invalid type. Allowed values: ebook, audiobook, hardcopy',
      },
      const {},
      400,
    );
  }
  final safeLimit = (limit ?? 10).clamp(1, 100);
  final baseUrl = EbookGroup.getBaseUrl();
  return ApiManager.instance.makeApiCall(
    callName: 'HomepageSection_$sectionKey',
    apiUrl: '${baseUrl}homepage/$sectionKey',
    callType: ApiCallType.GET,
    headers: _boiaroAuthHeaders(token),
    params: {
      'limit': '$safeLimit',
      if (offset != null) 'offset': '$offset',
      if (normalizedType.isNotEmpty) 'type': normalizedType,
    },
    bodyType: BodyType.NONE,
    returnBody: true,
    encodeBodyUtf8: false,
    decodeUtf8: false,
    cache: false,
    isStreamingApi: false,
    alwaysAllowBody: false,
  );
}

Future<ApiCallResponse> _homepageSectionAsBooks({
  required String sectionKey,
  String? type,
  String? token,
  int? limit,
  int? offset,
}) async {
  final res = await _homepageSectionRequest(
    sectionKey: sectionKey,
    type: type,
    token: token,
    limit: limit,
    offset: offset,
  );
  final body = res.jsonBody;
  if (!res.succeeded || body is! Map) {
    return _v2Error(body, res.statusCode);
  }
  final err = BoiaroLegacyAdapter.v2Error(body);
  if (err != null) {
    return _v2Error(body, res.statusCode);
  }
  final raw = _extractHomepageSectionRows(sectionKey, body, type);
  if (raw is! List) {
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
          extra: {'bookDetails': <dynamic>[]}),
      res.headers,
      res.statusCode,
    );
  }
  var leg = raw
      .whereType<Map>()
      .map((e) => BoiaroLegacyAdapter.legacyBookFromHomepageItem(
            Map<String, dynamic>.from(e),
            preferredFormat: _preferredHomepageFormatForSection(
              sectionKey,
              type,
            ),
          ))
      .where((b) => _matchesBookTypeFilter(b, type))
      .toList();
  return ApiCallResponse(
    BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'bookDetails': leg}),
    res.headers,
    res.statusCode,
  );
}

Future<ApiCallResponse> _booksForAuthor({
  required String authorId,
  String? type,
  String? token,
  int? limit,
  int? offset,
}) async {
  final baseUrl = EbookGroup.getBaseUrl();
  final safeLimit = (limit ?? 10).clamp(1, 100);
  final res = await ApiManager.instance.makeApiCall(
    callName: 'BooksForAuthor',
    apiUrl: '${baseUrl}books',
    callType: ApiCallType.GET,
    headers: _boiaroAuthHeaders(token),
    params: {
      'limit': '$safeLimit',
      if (offset != null) 'offset': '$offset',
      'author': authorId,
      'authorId': authorId,
    },
    bodyType: BodyType.NONE,
    returnBody: true,
    encodeBodyUtf8: false,
    decodeUtf8: false,
    cache: false,
    isStreamingApi: false,
    alwaysAllowBody: false,
  );
  final body = res.jsonBody;
  if (!res.succeeded || body is! Map) {
    return _v2Error(body, res.statusCode);
  }
  final err = BoiaroLegacyAdapter.v2Error(body);
  if (err != null) {
    return _v2Error(body, res.statusCode);
  }
  final raw = body['books'];
  if (raw is! List) {
    return _v2Error(body, res.statusCode);
  }
  final aid = authorId.trim();
  var leg = raw
      .whereType<Map>()
      .map((e) =>
          BoiaroLegacyAdapter.legacyBookFromV2(Map<String, dynamic>.from(e)))
      .where((b) {
        final a = b['author'];
        if (a is Map) {
          return a['_id']?.toString() == aid;
        }
        return false;
      })
      .where((b) => _matchesBookTypeFilter(b, type))
      .toList();
  return ApiCallResponse(
    BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'bookDetails': leg}),
    res.headers,
    res.statusCode,
  );
}

Future<ApiCallResponse> _booksQuery({
  Map<String, String>? query,
  String? type,
  String? token,
  int? limit,
  int? offset,
}) async {
  final baseUrl = EbookGroup.getBaseUrl();
  final safeLimit = (limit ?? 10).clamp(1, 100);
  final qp = <String, dynamic>{
    'limit': '$safeLimit',
    if (offset != null) 'offset': '$offset',
    if (query != null) ...query,
  };
  final res = await ApiManager.instance.makeApiCall(
    callName: 'BooksQuery',
    apiUrl: '${baseUrl}books',
    callType: ApiCallType.GET,
    headers: _boiaroAuthHeaders(token),
    params: qp,
    bodyType: BodyType.NONE,
    returnBody: true,
    encodeBodyUtf8: false,
    decodeUtf8: false,
    cache: false,
    isStreamingApi: false,
    alwaysAllowBody: false,
  );
  final body = res.jsonBody;
  if (!res.succeeded || body is! Map) {
    return _v2Error(body, res.statusCode);
  }
  final err = BoiaroLegacyAdapter.v2Error(body);
  if (err != null) {
    return _v2Error(body, res.statusCode);
  }
  final raw = body['books'];
  if (raw is! List) {
    return _v2Error(body, res.statusCode);
  }
  var leg = raw
      .whereType<Map>()
      .map((e) =>
          BoiaroLegacyAdapter.legacyBookFromV2(Map<String, dynamic>.from(e)))
      .where((b) => _matchesBookTypeFilter(b, type))
      .toList();
  return ApiCallResponse(
    BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'bookDetails': leg}),
    res.headers,
    res.statusCode,
  );
}

/// Start Ebook Group Code

class EbookGroup {
  static String getBaseUrl({
    String? token = '',
  }) =>
      '${FFAppConstants.mobileApiBaseUrl}/';
  static Map<String, String> headers = {
    'Authorization': 'Bearer [token]',
  };
  static CheckregistereduserApiCall checkregistereduserApiCall =
      CheckregistereduserApiCall();
  static SignupApiCall signupApiCall = SignupApiCall();
  static UserverificationApiCall userverificationApiCall =
      UserverificationApiCall();
  static SigninApiCall signinApiCall = SigninApiCall();
  static ForgotpasswordApiCall forgotpasswordApiCall = ForgotpasswordApiCall();
  static ForgotpasswordverificationApiCall forgotpasswordverificationApiCall =
      ForgotpasswordverificationApiCall();
  static ResetpasswordApiCall resetpasswordApiCall = ResetpasswordApiCall();
  static GetuserApiCall getuserApiCall = GetuserApiCall();
  static GetprofileApiCall getprofileApiCall = GetprofileApiCall();
  static UsereditprofileApiCall usereditprofileApiCall =
      UsereditprofileApiCall();
  static UploadimageApiCall uploadimageApiCall = UploadimageApiCall();
  static DeleteuserApiCall deleteuserApiCall = DeleteuserApiCall();
  static SignoutApiCall signoutApiCall = SignoutApiCall();
  static GetcategoriesApiCall getcategoriesApiCall = GetcategoriesApiCall();
  static GetsubcategoriesApiCall getsubcategoriesApiCall =
      GetsubcategoriesApiCall();
  static GetsubcategoriesbycategoryApiCall getsubcategoriesbycategoryApiCall =
      GetsubcategoriesbycategoryApiCall();
  static GetauthorsApiCall getauthorsApiCall = GetauthorsApiCall();
  static GetpublishersApiCall getpublishersApiCall = GetpublishersApiCall();
  static GetnarratorsApiCall getnarratorsApiCall = GetnarratorsApiCall();
  static GetpublisherdetailsApiCall getpublisherdetailsApiCall =
      GetpublisherdetailsApiCall();
  static GetauthordetailsApiCall getauthordetailsApiCall =
      GetauthordetailsApiCall();
  static GettranslatordetailsApiCall gettranslatordetailsApiCall =
      GettranslatordetailsApiCall();
  static GettranslatorsApiCall gettranslatorsApiCall = GettranslatorsApiCall();
  static GetbookbytranslatorApiCall getbookbytranslatorApiCall =
      GetbookbytranslatorApiCall();
  static GetnarratordetailsApiCall getnarratordetailsApiCall =
      GetnarratordetailsApiCall();
  static GetbookbypublisherApiCall getbookbypublisherApiCall =
      GetbookbypublisherApiCall();
  static GetLatestbooksApiCall getLatestbooksApiCall = GetLatestbooksApiCall();
  static GetbookdetailsApiCall getbookdetailsApiCall = GetbookdetailsApiCall();
  static GetbookbyauthorApiCall getbookbyauthorApiCall =
      GetbookbyauthorApiCall();
  static GetbookbynarratorApiCall getbookbynarratorApiCall =
      GetbookbynarratorApiCall();
  static GetbookbycategoryApiCall getbookbycategoryApiCall =
      GetbookbycategoryApiCall();
  static GetbookbysubcategoryApiCall getbookbysubcategoryApiCall =
      GetbookbysubcategoryApiCall();
  static GetRelatedBooksApiCall getRelatedBooksApiCall =
      GetRelatedBooksApiCall();
  static GetsubscriptionplanApiCall getsubscriptionplanApiCall =
      GetsubscriptionplanApiCall();
  static GetpagesApiCall getpagesApiCall = GetpagesApiCall();
  static UsersubscriptionApiCall usersubscriptionApiCall =
      UsersubscriptionApiCall();
  static UsersubscriptionrecordApiCall usersubscriptionrecordApiCall =
      UsersubscriptionrecordApiCall();
  static UsersubscriptionvalidityApiCall usersubscriptionvalidityApiCall =
      UsersubscriptionvalidityApiCall();
  static CurrencyApiCall currencyApiCall = CurrencyApiCall();
  static AddreviewApiCall addreviewApiCall = AddreviewApiCall();
  static GetreviewApiCall getreviewApiCall = GetreviewApiCall();
  static GetbookcommentsApiCall getbookcommentsApiCall =
      GetbookcommentsApiCall();
  static AddcommentApiCall addcommentApiCall = AddcommentApiCall();
  static WalletApiCall walletApiCall = WalletApiCall();
  static WalletTransactionsApiCall walletTransactionsApiCall =
      WalletTransactionsApiCall();
  static WalletClaimDailyApiCall walletClaimDailyApiCall =
      WalletClaimDailyApiCall();
  static WalletClaimAdApiCall walletClaimAdApiCall = WalletClaimAdApiCall();
  static GetHomepageApiCall getHomepageApiCall = GetHomepageApiCall();
  static GetCategorySectionsApiCall getCategorySectionsApiCall =
      GetCategorySectionsApiCall();
  static GetTrendingBooksApiCall getTrendingBooksApiCall =
      GetTrendingBooksApiCall();
  static GetNewBooksApiCall getNewBooksApiCall = GetNewBooksApiCall();
  static GetPopularBooksApiCall getPopularBooksApiCall =
      GetPopularBooksApiCall();
  static AddFavouriteBookApiCall addFavouriteBookApiCall =
      AddFavouriteBookApiCall();
  static GetFavouriteBookCall getFavouriteBookCall = GetFavouriteBookCall();
  static RemoveFavouritebookCall removeFavouritebookCall =
      RemoveFavouritebookCall();
  static DownloadhistoryApiCall downloadhistoryApiCall =
      DownloadhistoryApiCall();
  static DownloadpdfApiCall downloadpdfApiCall = DownloadpdfApiCall();
  static SearchApiCall searchApiCall = SearchApiCall();
  static LatestAllBookApiCall latestAllBookApiCall = LatestAllBookApiCall();
  static GetnotificationApiCall getnotificationApiCall =
      GetnotificationApiCall();
  static ChangepasswordApiCall changepasswordApiCall = ChangepasswordApiCall();
  static UserVerifyApiCall userVerifyApiCall = UserVerifyApiCall();
  static ResendOTPApiCall resendOTPApiCall = ResendOTPApiCall();
  static PaymentGatewayApiCall paymentGatewayApiCall = PaymentGatewayApiCall();
  static GetSlidersApiCall getSlidersApiCall = GetSlidersApiCall();
  static UserBookPurchaseRecordsApiCall userBookPurchaseRecordsApiCall =
      UserBookPurchaseRecordsApiCall();
  static SocialLoginCall socialLoginCall = SocialLoginCall();
  static GetFeaturedBooksByCategoryApiCall getFeaturedBooksByCategoryApiCall =
      GetFeaturedBooksByCategoryApiCall();
  static BookViewApiCall bookViewApiCall = BookViewApiCall();
  static BookReadingStartApiCall bookReadingStartApiCall =
      BookReadingStartApiCall();
  static BookReadingEndApiCall bookReadingEndApiCall = BookReadingEndApiCall();
  static BookReadingProgressApiCall bookReadingProgressApiCall =
      BookReadingProgressApiCall();
  static GetCouponApiCall getCouponApiCall = GetCouponApiCall();
  static ValidateCouponApiCall validateCouponApiCall = ValidateCouponApiCall();
  static GetOrdersApiCall getOrdersApiCall = GetOrdersApiCall();
  static PhoneSendOtpApiCall phoneSendOtpApiCall = PhoneSendOtpApiCall();
  static PhoneVerifyOtpApiCall phoneVerifyOtpApiCall = PhoneVerifyOtpApiCall();
  static RegisterNotificationTokenApiCall registerNotificationTokenApiCall =
      RegisterNotificationTokenApiCall();
  static UnregisterNotificationTokenApiCall unregisterNotificationTokenApiCall =
      UnregisterNotificationTokenApiCall();
  static ReadNotificationsApiCall readNotificationsApiCall =
      ReadNotificationsApiCall();
  static PresenceHeartbeatApiCall presenceHeartbeatApiCall =
      PresenceHeartbeatApiCall();
  static RegisterBookReadApiCall registerBookReadApiCall =
      RegisterBookReadApiCall();
  static GetBookChaptersApiCall getBookChaptersApiCall =
      GetBookChaptersApiCall();
  static UnlockChapterWithCoinsCall unlockChapterWithCoinsCall =
      UnlockChapterWithCoinsCall();
  static InitiateChapterPaymentCall initiateChapterPaymentCall =
      InitiateChapterPaymentCall();
  static PollPaymentStatusCall pollPaymentStatusCall =
      PollPaymentStatusCall();
  static GetAdSettingsCall getAdSettingsCall = GetAdSettingsCall();
  static GetActiveBannersCall getActiveBannersCall = GetActiveBannersCall();
  static GetRewardedAdStatusCall getRewardedAdStatusCall =
      GetRewardedAdStatusCall();
  static ClaimRewardedAdRewardCall claimRewardedAdRewardCall =
      ClaimRewardedAdRewardCall();
  static GetAdPlacementsCall getAdPlacementsCall = GetAdPlacementsCall();
  static UnlockChapterWithIAPCall unlockChapterWithIAPCall =
      UnlockChapterWithIAPCall();
  static UnlockBookWithIAPCall unlockBookWithIAPCall =
      UnlockBookWithIAPCall();
  static PostAdImpressionCall postAdImpressionCall = PostAdImpressionCall();
  static PostAdClickCall postAdClickCall = PostAdClickCall();
  static GetGamificationSummaryCall getGamificationSummaryCall =
      GetGamificationSummaryCall();
  static UpdateStreakCall updateStreakCall = UpdateStreakCall();
  static LogConsumptionTimeCall logConsumptionTimeCall =
      LogConsumptionTimeCall();
  static GetReferralInfoCall getReferralInfoCall = GetReferralInfoCall();
  static ValidateReferralCodeCall validateReferralCodeCall =
      ValidateReferralCodeCall();
  static GetStreakCall getStreakCall = GetStreakCall();
  static GetPointsHistoryCall getPointsHistoryCall = GetPointsHistoryCall();
  static AddPointsCall addPointsCall = AddPointsCall();
  static GetLeaderboardCall getLeaderboardCall = GetLeaderboardCall();
  static GetMyBadgesCall getMyBadgesCall = GetMyBadgesCall();
  static GetBadgeDefinitionsCall getBadgeDefinitionsCall =
      GetBadgeDefinitionsCall();
  static CheckAwardBadgesCall checkAwardBadgesCall = CheckAwardBadgesCall();
  static ClaimDailyRewardCall claimDailyRewardCall = ClaimDailyRewardCall();
  static GetMyGoalsCall getMyGoalsCall = GetMyGoalsCall();
  static AddGoalCall addGoalCall = AddGoalCall();
  static LogActivityCall logActivityCall = LogActivityCall();
}

class PhoneSendOtpApiCall {
  Future<ApiCallResponse> call({
    String? phone = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'PhoneSendOtpApi',
      apiUrl: '${baseUrl}auth/phone/send-otp',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({'phone': phone}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (res.succeeded && body is Map && body['sent'] == true) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: 'OTP sent successfully',
          extra: {'sent': true},
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(body, res.statusCode);
  }

  bool? sent(dynamic response) {
    final s = getJsonField(response, r'''$.data.sent''');
    if (s is bool) return s;
    return null;
  }

  String? errorMessage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
}

class PhoneVerifyOtpApiCall {
  Future<ApiCallResponse> call({
    String? phone = '',
    String? otp = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'PhoneVerifyOtpApi',
      apiUrl: '${baseUrl}auth/phone/verify-otp',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'phone': phone,
        'otp': otp,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final access =
        (body['access_token'] ?? body['accessToken'])?.toString();
    if (access == null || access.isEmpty) {
      return _v2Error(body, res.statusCode);
    }
    final Map<String, dynamic> user = body['user'] is Map
        ? Map<String, dynamic>.from(body['user'] as Map)
        : <String, dynamic>{};
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message: body['message']?.toString() ?? 'Login successful',
        extra: {
          'token': access,
          'refresh_token':
              (body['refresh_token'] ?? body['refreshToken'])?.toString() ?? '',
          'expires_in': body['expires_in'],
          'user_id':
              body['user_id']?.toString() ?? user['id']?.toString() ?? '',
          'userDetails': BoiaroLegacyAdapter.legacyUserFromAuthUser(user),
        },
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  String? token(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.token''',
      ));
  String? refreshToken(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.refresh_token''',
      ));
  dynamic userDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.userDetails''',
      );
  String? userId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.id''',
      ));
}

class SocialLoginCall {
  Future<ApiCallResponse> call({
    String? email,
    String? firstname,
    String? lastname,
    String? username,
    String? provider,
    String? providerId,
    String? accessToken,
    String? idToken,
    String? registrationToken,
    String? deviceId,
  }) async {
    final providerNormalized = (provider ?? '').toLowerCase().trim();
    final isGoogle = providerNormalized == 'google';
    final isFacebook = providerNormalized == 'facebook';
    final isApple = providerNormalized == 'apple';
    if (!isGoogle && !isFacebook && !isApple) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'Unsupported social provider.',
          extra: const {'error': 1},
        ),
        {},
        400,
      );
    }
    final tokenForServer =
        (accessToken ?? '').trim().isNotEmpty ? accessToken!.trim() : '';
    final idTokenForServer =
        (idToken ?? '').trim().isNotEmpty ? idToken!.trim() : '';

    if (tokenForServer.isEmpty && idTokenForServer.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'Social token is required.',
          extra: const {'error': 1},
        ),
        {},
        400,
      );
    }
    final baseUrl = EbookGroup.getBaseUrl();
    final endpoint = isGoogle
        ? 'auth/social/google'
        : (isFacebook ? 'auth/social/facebook' : 'auth/social/apple');
    final body = BoiaroLegacyAdapter.jsonEncodeBody({
      if (tokenForServer.isNotEmpty) 'access_token': tokenForServer,
      if (tokenForServer.isNotEmpty) 'accessToken': tokenForServer,
      if (idTokenForServer.isNotEmpty) 'id_token': idTokenForServer,
      if (idTokenForServer.isNotEmpty) 'idToken': idTokenForServer,
      if ((registrationToken ?? '').trim().isNotEmpty)
        'registrationToken': registrationToken!.trim(),
      if ((deviceId ?? '').trim().isNotEmpty) 'deviceId': deviceId!.trim(),
      if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
      if ((firstname ?? '').trim().isNotEmpty) 'firstname': firstname!.trim(),
      if ((lastname ?? '').trim().isNotEmpty) 'lastname': lastname!.trim(),
      if ((username ?? '').trim().isNotEmpty) 'username': username!.trim(),
      if ((providerId ?? '').trim().isNotEmpty)
        'providerId': providerId!.trim(),
    });
    final res = await ApiManager.instance.makeApiCall(
      callName: 'SocialLoginCall',
      apiUrl: '$baseUrl$endpoint',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(''),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (!res.succeeded || jb is! Map) {
      return _v2Error(jb, res.statusCode);
    }
    final Map<String, dynamic> user = jb['user'] is Map
        ? Map<String, dynamic>.from(jb['user'] as Map)
        : <String, dynamic>{};
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message: jb['message']?.toString() ?? 'Login successful',
        extra: {
          'token': jb['access_token']?.toString() ?? '',
          'refresh_token': jb['refresh_token']?.toString() ?? '',
          'expires_in': jb['expires_in'],
          'user_id': jb['user_id']?.toString() ?? user['id']?.toString() ?? '',
          'userDetails': BoiaroLegacyAdapter.legacyUserFromAuthUser(user),
        },
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  String? token(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.token''',
      ));
  dynamic userDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.userDetails''',
      );
  String? userId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.id''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class UserBookPurchaseRecordsApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final h = _boiaroAuthHeaders(token);
    final pRes = await ApiManager.instance.makeApiCall(
      callName: 'LibraryPurchases',
      apiUrl: '${baseUrl}library/purchases',
      callType: ApiCallType.GET,
      headers: h,
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final uRes = await ApiManager.instance.makeApiCall(
      callName: 'LibraryUnlocks',
      apiUrl: '${baseUrl}library/unlocks',
      callType: ApiCallType.GET,
      headers: h,
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final purchaseDetails = <Map<String, dynamic>>[];
    final seen = <String>{};
    void addFrom(dynamic list) {
      if (list is! List) {
        return;
      }
      for (final row in list) {
        if (row is! Map) {
          continue;
        }
        final m = Map<String, dynamic>.from(row);
        final books = m['books'];
        if (books is! Map) {
          continue;
        }
        final bid = books['id']?.toString() ?? '';
        final format = (m['format'] ?? '').toString().toLowerCase().trim();
        final dedupeKey = format.isNotEmpty ? '$bid::$format' : bid;
        if (bid.isEmpty || seen.contains(dedupeKey)) {
          continue;
        }
        seen.add(dedupeKey);
        final legacyBook = BoiaroLegacyAdapter.legacyBookFromV2(
            Map<String, dynamic>.from(books));
        if (format.isNotEmpty) {
          legacyBook['type'] = format;
          legacyBook['bookType'] = format;
        }
        purchaseDetails.add({
          'bookDetails': legacyBook,
          'type': format,
          'contentType': format,
          'format': format,
        });
      }
    }

    if (pRes.succeeded && pRes.jsonBody is Map) {
      addFrom((pRes.jsonBody as Map)['purchases']);
      addFrom((pRes.jsonBody as Map)['items']);
    }
    if (uRes.succeeded && uRes.jsonBody is Map) {
      addFrom((uRes.jsonBody as Map)['unlocks']);
      addFrom((uRes.jsonBody as Map)['items']);
    }
    final ok = pRes.succeeded || uRes.succeeded;
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: ok ? 1 : 0,
        message: ok ? 'Success' : 'Could not load library',
        extra: {'purchaseDetails': purchaseDetails},
      ),
      pRes.headers,
      ok ? 200 : pRes.statusCode,
    );
  }

  List? purchaseDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.purchaseDetails''',
        true,
      ) as List?;
  List? bookDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails''',
        true,
      ) as List?;
  List<String>? bookId(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails._id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? bookName(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? bookImage(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? authorName(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.author.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? authorImage(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.author.image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? publisherName(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.publisher.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? publisherImage(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.publisher.image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? pdf(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.pdf''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<int>? download(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.download''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List<double>? averageRating(dynamic response) => (getJsonField(
        response,
        r'''$.data.purchaseDetails[:].bookDetails.averageRating''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<double>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class BookReadingStartApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? userId = '',
    String? sessionId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "bookId": "${bookId}",
  "userId": "${userId}",
  "sessionId": "${sessionId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'BookReadingStartApi',
      apiUrl: '${baseUrl}book/reading/start',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class BookViewApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? userId = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final ffApiRequestBody = '''
{
  "bookId": "${bookId}",
  "userId": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'BookViewApi',
      apiUrl: '${baseUrl}book/view',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class BookReadingEndApiCall {
  Future<ApiCallResponse> call({
    String? sessionId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "sessionId": "${sessionId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'BookReadingEndApi',
      apiUrl: '${baseUrl}book/reading/end',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? duration(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.duration''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class BookReadingProgressApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? userId = '',
    int? percentage = 0,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "bookId": "${bookId}",
  "userId": "${userId}",
  "percentage": ${percentage}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'BookReadingProgressApi',
      apiUrl: '${baseUrl}book/reading/progress',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  bool? completed(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.data.completed''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class GetSlidersApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetSlidersApi',
      apiUrl: '${baseUrl}homepage',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    var featured = body['slider'] ?? body['featured'];
    if (featured is Map && featured['slider'] is List) {
      featured = featured['slider'];
    }
    final sliderDetails = <Map<String, dynamic>>[];
    final sliderRows = featured is List
        ? featured
        : featured is Map
            ? [featured]
            : const [];
    for (final raw in sliderRows) {
      if (raw is! Map) {
        continue;
      }
      sliderDetails.add(
        homepageSliderDetailFromRaw(Map<String, dynamic>.from(raw)),
      );
    }
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
          extra: {'sliderDetails': sliderDetails}),
      res.headers,
      res.statusCode,
    );
  }

  List? sliderDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.sliderDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class CheckregistereduserApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? token = '',
  }) async {
    // v2 has no duplicate-email probe; signup will fail if the email exists.
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 0,
        message: '',
      ),
      {},
      200,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class SignupApiCall {
  Future<ApiCallResponse> call({
    String? firstname = '',
    String? lastname = '',
    String? username = '',
    String? phone = '',
    String? email = '',
    String? password = '',
    String? countryCode = '',
    String? registrationToken = '',
    String? deviceId = '',
    String? token = '',
    String? referralCode = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final displayName = [
      (firstname ?? '').trim(),
      (lastname ?? '').trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final res = await ApiManager.instance.makeApiCall(
      callName: 'SignupApi',
      apiUrl: '${baseUrl}auth/signup',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'email': email,
        'password': password,
        if (displayName.isNotEmpty) 'display_name': displayName,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (res.statusCode == 201 && body is Map) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: body['message']?.toString() ?? 'Please verify your email',
        ),
        res.headers,
        res.statusCode,
      );
    }
    if (body is Map && BoiaroLegacyAdapter.v2Error(body) != null) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 2,
          message: BoiaroLegacyAdapter.v2Error(body) ?? 'Sign up failed',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 2,
        message: 'Sign up failed',
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class UserverificationApiCall {
  /// v2 uses Supabase email verification; OTP is not used. When [password] is
  /// provided, this performs `POST /auth/login` so the user can continue after
  /// confirming email (same as sign-in).
  Future<ApiCallResponse> call({
    String? email = '',
    int? otp,
    String? password,
    String? token = '',
  }) async {
    final pw = (password ?? '').trim();
    if (pw.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 2,
          message:
              'Confirm your email using the link we sent, then enter your password below or sign in from the login screen.',
        ),
        {},
        400,
      );
    }
    return SigninApiCall().call(
      email: email,
      password: pw,
      registrationToken: '',
      deviceId: '',
      token: '',
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  String? token(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.token''',
      ));
  String? refreshToken(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.refresh_token''',
      ));
  dynamic userDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.userDetails''',
      );
  String? userId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.id''',
      ));
  String? firstname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.firstname''',
      ));
  String? lastname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.lastname''',
      ));
  String? username(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.username''',
      ));
  String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.email''',
      ));
  String? countrycode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.country_code''',
      ));
  String? phone(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.phone''',
      ));
}

class SigninApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
    String? registrationToken = '',
    String? deviceId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'SigninApi',
      apiUrl: '${baseUrl}auth/login',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'email': email,
        'password': password,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final access = (body['accessToken'] ?? body['access_token'])?.toString();
    if (access == null || access.isEmpty) {
      return _v2Error(
        body is Map<String, dynamic>
            ? body
            : <String, dynamic>{'error': 'Login failed: missing access token'},
        res.statusCode,
      );
    }
    final user = body['user'];
    final uid = user is Map ? user['id']?.toString() : null;
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: {
          'token': access,
          'refresh_token': body['refreshToken'] ?? body['refresh_token'],
          'userDetails': user is Map
              ? BoiaroLegacyAdapter.legacyUserFromAuthUser(
                  Map<String, dynamic>.from(user),
                )
              : {
                  'id': uid,
                  'email': user is Map ? user['email'] : null,
                },
        },
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  String? token(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.token''',
      ));
  String? refreshToken(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.refresh_token''',
      ));
  dynamic userDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.userDetails''',
      );
  String? userId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.userDetails.id''',
      ));
}

class ForgotpasswordApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'ForgotpasswordApi',
      apiUrl: '${baseUrl}auth/reset-password',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({'email': email}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (res.succeeded &&
        body is Map &&
        BoiaroLegacyAdapter.v2Error(body) == null) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: body['message']?.toString() ?? 'Password reset email sent',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(body, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class ForgotpasswordverificationApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    int? otp,
    String? token = '',
  }) async {
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message:
            'Open the password reset link from your email, then sign in with your new password.',
      ),
      {},
      200,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class ResetpasswordApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? newpassword = '',
    String? token = '',
  }) async {
    final bearer =
        ((token ?? '').trim().isNotEmpty ? token : FFAppState().token)
                ?.trim() ??
            '';
    if (bearer.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message:
              'Sign in with the link from your email first, or use Change password from your profile while logged in.',
        ),
        {},
        401,
      );
    }
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'ResetpasswordApi',
      apiUrl: '${baseUrl}auth/update-password',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(bearer),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({'password': newpassword}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (res.succeeded &&
        body is Map &&
        BoiaroLegacyAdapter.v2Error(body) == null) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: body['message']?.toString() ?? 'Password updated',
        ),
        res.headers,
        res.statusCode,
      );
    }
    if (body is Map && BoiaroLegacyAdapter.v2Error(body) != null) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 2,
          message: BoiaroLegacyAdapter.v2Error(body) ?? 'Validation error',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(body, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetuserApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetuserApi',
      apiUrl: '${baseUrl}auth/me',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    var user = BoiaroLegacyAdapter.legacyUserFromAuthUser(
      Map<String, dynamic>.from(body),
    );
    final existingEmail = FFAppState().userDetail;
    String? em;
    if (existingEmail is Map) {
      em = existingEmail['email']?.toString();
    }
    user = {...user, if (em != null && em.isNotEmpty) 'email': em};
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'user': user}),
      res.headers,
      res.statusCode,
    );
  }

  dynamic userDetail(dynamic response) => getJsonField(
        response,
        r'''$.data.user''',
      );
  String? userId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.id''',
      ));
  String? firstname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.firstname''',
      ));
  String? lastname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.lastname''',
      ));
  String? username(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.username''',
      ));
  String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.email''',
      ));
  String? phone(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.phone''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.image''',
      ));
  String? countrycode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user.country_code''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetprofileApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetprofileApi',
      apiUrl: '${baseUrl}profile',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final account = body['userProfile'];
    if (account is! Map || account['profile'] is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final user = BoiaroLegacyAdapter.legacyUserFromProfile(
      account: Map<String, dynamic>.from(account),
      profile: Map<String, dynamic>.from(account['profile'] as Map),
    );
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'user': user,
        'profile': account['profile'],
        'userProfile': account,
      }),
      res.headers,
      res.statusCode,
    );
  }

  dynamic userDetail(dynamic response) => getJsonField(
        response,
        r'''$.data.user''',
      );
  dynamic profile(dynamic response) => getJsonField(
        response,
        r'''$.data.profile''',
      );
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class UsereditprofileApiCall {
  Future<ApiCallResponse> call({
    String? id = '',
    String? firstname = '',
    String? lastname = '',
    String? displayName = '',
    String? fullName = '',
    String? phone = '',
    String? email = '',
    String? image = '',
    String? countryCode = '',
    String? bio = '',
    String? preferredLanguage = '',
    String? genre = '',
    String? specialty = '',
    String? experience = '',
    String? websiteUrl = '',
    String? facebookUrl = '',
    String? instagramUrl = '',
    String? youtubeUrl = '',
    String? portfolioUrl = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final rawImage = (image ?? '').trim();
    final normalizedImage = (rawImage.toLowerCase() == 'null' ||
            rawImage.toLowerCase() == 'undefined')
        ? ''
        : rawImage;
    final dn = (displayName ?? '').trim();
    final fn = (fullName ?? '').trim();
    final composedFromNames = [
      (firstname ?? '').trim(),
      (lastname ?? '').trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final effectiveDisplay = dn.isNotEmpty ? dn : composedFromNames;
    final body = <String, dynamic>{
      if (effectiveDisplay.isNotEmpty) 'display_name': effectiveDisplay,
      if (fn.isNotEmpty) 'full_name': fn,
      if (normalizedImage.isNotEmpty) 'avatar_url': normalizedImage,
      if ((phone ?? '').trim().isNotEmpty) 'phone': phone,
      if ((email ?? '').trim().isNotEmpty) 'email': email,
      if ((bio ?? '').trim().isNotEmpty) 'bio': bio,
      if ((preferredLanguage ?? '').trim().isNotEmpty)
        'preferred_language': preferredLanguage,
      if ((genre ?? '').trim().isNotEmpty) 'genre': genre,
      if ((specialty ?? '').trim().isNotEmpty) 'specialty': specialty,
      if ((experience ?? '').trim().isNotEmpty) 'experience': experience,
      if ((websiteUrl ?? '').trim().isNotEmpty) 'website_url': websiteUrl,
      if ((facebookUrl ?? '').trim().isNotEmpty) 'facebook_url': facebookUrl,
      if ((instagramUrl ?? '').trim().isNotEmpty) 'instagram_url': instagramUrl,
      if ((youtubeUrl ?? '').trim().isNotEmpty) 'youtube_url': youtubeUrl,
      if ((portfolioUrl ?? '').trim().isNotEmpty) 'portfolio_url': portfolioUrl,
    };
    final res = await ApiManager.instance.makeApiCall(
      callName: 'UsereditprofileApi',
      apiUrl: '${baseUrl}profile',
      callType: ApiCallType.PATCH,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded && jb is Map && BoiaroLegacyAdapter.v2Error(jb) == null) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb['message']?.toString() ?? 'Profile updated',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class UploadimageApiCall {
  Future<ApiCallResponse> call({
    FFUploadedFile? image,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'UploadimageApi',
      apiUrl: '${baseUrl}profile/upload-image',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {
        'image': image,
        'file': image,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteuserApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'DeleteuserApi',
      apiUrl: '${baseUrl}deleteuser',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class SignoutApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? deviceId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'SignoutApi',
      apiUrl: '${baseUrl}auth/logout',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb is Map
              ? (jb['message']?.toString() ?? 'Logged out')
              : 'Logged out',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetcategoriesApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetcategoriesApi',
      apiUrl: '${baseUrl}categories',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body['categories'];
    if (raw is! List) {
      return _v2Error(body, res.statusCode);
    }
    final leg = raw
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyCategoryFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'categoryDetails': leg}),
      res.headers,
      res.statusCode,
    );
  }

  List? categoryDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.categoryDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetsubcategoriesApiCall {
  Future<ApiCallResponse> call({
    String? id = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "_id": "${id}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetsubcategoriesApi',
      apiUrl: '${baseUrl}getsubcategories',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? subcategoryDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.subcategoryDetails''',
        true,
      ) as List?;
}

class GetsubcategoriesbycategoryApiCall {
  Future<ApiCallResponse> call({
    String? categoryId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "categoryId": "${categoryId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetsubcategoriesbycategoryApi',
      apiUrl: '${baseUrl}getsubcategoriesbycategory',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? subcategoryDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.subcategoryDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetauthorsApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetauthorsApi',
      apiUrl: '${baseUrl}authors',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {'limit': '50', 'offset': '0'},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body['authors'];
    if (raw is! List) {
      return _v2Error(body, res.statusCode);
    }
    final leg = raw
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyAuthorFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'authorDetails': leg}),
      res.headers,
      res.statusCode,
    );
  }

  List? authorDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.authorDetails''',
        true,
      ) as List?;
  List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$.data.authorDetails[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? image(dynamic response) => (getJsonField(
        response,
        r'''$.data.authorDetails[:].image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetpublishersApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetpublishersApi',
      apiUrl: '${baseUrl}publishers',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body['publishers'];
    if (raw is! List) {
      return _v2Error(body, res.statusCode);
    }
    final leg = raw
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyPublisherFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'publisherDetails': leg}),
      res.headers,
      res.statusCode,
    );
  }

  List? publisherDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.publisherDetails''',
        true,
      ) as List?;
  List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$.data.publisherDetails[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? image(dynamic response) => (getJsonField(
        response,
        r'''$.data.publisherDetails[:].image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetnarratorsApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetnarratorsApi',
      apiUrl: '${baseUrl}narrators',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body['narrators'];
    if (raw is! List) {
      return _v2Error(body, res.statusCode);
    }
    final leg = raw
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyNarratorFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'narratorDetails': leg}),
      res.headers,
      res.statusCode,
    );
  }

  List? narratorDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.narratorDetails''',
        true,
      ) as List?;
  List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$.data.narratorDetails[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? image(dynamic response) => (getJsonField(
        response,
        r'''$.data.narratorDetails[:].image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetpublisherdetailsApiCall {
  Future<ApiCallResponse> call({
    String? publisherId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final id = Uri.encodeComponent((publisherId ?? '').trim());
    if (id.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
            success: 0, message: 'publisherId required'),
        {},
        400,
      );
    }
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetpublisherdetailsApi',
      apiUrl: '${baseUrl}publishers/$id',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    if (BoiaroLegacyAdapter.v2Error(body) != null) {
      return _v2Error(body, res.statusCode);
    }
    final leg = BoiaroLegacyAdapter.legacyPublisherFromV2(
        Map<String, dynamic>.from(body));
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'publisherDetails': [leg],
      }),
      res.headers,
      res.statusCode,
    );
  }

  List? publisherDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.publisherDetails''',
        true,
      ) as List?;
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].name''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].image''',
      ));
  String? facebookurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].facebook_url''',
      ));
  String? instagramurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].instagram_url''',
      ));
  String? youtubeurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].youtube_url''',
      ));
  String? websiteurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].website_url''',
      ));
  String? description(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:].description''',
      ));
  String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.publisherDetails[:]._id''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetbookbypublisherApiCall {
  Future<ApiCallResponse> call({
    String? publisherId = '',
    String? type = '',
    String? token = '',
  }) async {
    final pid = (publisherId ?? '').trim();
    if (pid.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'publisherId required',
        ),
        {},
        400,
      );
    }
    return _booksQuery(
      query: {'publisher': pid, 'publisherId': pid},
      type: type,
      token: token,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
}

class GetauthordetailsApiCall {
  Future<ApiCallResponse> call({
    String? authorId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final id = Uri.encodeComponent((authorId ?? '').trim());
    if (id.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
            success: 0, message: 'authorId required'),
        {},
        400,
      );
    }
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetauthordetailsApi',
      apiUrl: '${baseUrl}authors/$id',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    if (BoiaroLegacyAdapter.v2Error(body) != null) {
      return _v2Error(body, res.statusCode);
    }
    final leg =
        BoiaroLegacyAdapter.legacyAuthorFromV2(Map<String, dynamic>.from(body));
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'authorDetails': [leg],
      }),
      res.headers,
      res.statusCode,
    );
  }

  List? authorDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.authorDetails''',
        true,
      ) as List?;
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].name''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].image''',
      ));
  String? facebookurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].facebook_url''',
      ));
  String? instagramurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].instagram_url''',
      ));
  String? youtubeurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].youtube_url''',
      ));
  String? websiteurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].website_url''',
      ));
  String? description(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:].description''',
      ));
  String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.authorDetails[:]._id''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetnarratordetailsApiCall {
  Future<ApiCallResponse> call({
    String? narratorId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final id = Uri.encodeComponent((narratorId ?? '').trim());
    if (id.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
            success: 0, message: 'narratorId required'),
        {},
        400,
      );
    }
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetnarratordetailsApi',
      apiUrl: '${baseUrl}narrators/$id',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    if (BoiaroLegacyAdapter.v2Error(body) != null) {
      return _v2Error(body, res.statusCode);
    }
    final leg = BoiaroLegacyAdapter.legacyNarratorFromV2(
        Map<String, dynamic>.from(body));
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'narratorDetails': [leg],
      }),
      res.headers,
      res.statusCode,
    );
  }

  List? narratorDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.narratorDetails''',
        true,
      ) as List?;
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].name''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].image''',
      ));
  String? facebookurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].facebook_url''',
      ));
  String? instagramurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].instagram_url''',
      ));
  String? youtubeurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].youtube_url''',
      ));
  String? websiteurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].website_url''',
      ));
  String? description(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:].description''',
      ));
  String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.narratorDetails[:]._id''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetLatestbooksApiCall {
  Future<ApiCallResponse> call({
    List<String>? authorIdList,
    List<String>? categoryIdList,
    String? type = '',
    String? token = '',
    int? limit,
    int? offset,
  }) async {
    String? cid;
    if (categoryIdList != null && categoryIdList.isNotEmpty) {
      cid = categoryIdList.first;
    }
    if (authorIdList != null &&
        authorIdList.isNotEmpty &&
        (authorIdList.first ?? '').trim().isNotEmpty) {
      return _booksForAuthor(
        authorId: authorIdList.first!.trim(),
        type: type,
        token: token,
        limit: limit,
        offset: offset,
      );
    }
    return _booksQuery(
      query: cid != null ? {'categoryId': cid} : null,
      type: type,
      token: token,
      limit: limit,
      offset: offset,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  List<String>? id(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookDetails[:]._id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookDetails[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? image(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookDetails[:].image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? authorName(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookDetails[:].author.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetbookdetailsApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? type = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final id = Uri.encodeComponent((bookId ?? '').trim());
    if (id.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'Book id required',
        ),
        {},
        400,
      );
    }
    final trimmed = (bookId ?? '').trim();
    final isUuid = RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$').hasMatch(trimmed);
    final isMongoId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(trimmed);
    final isSlug = !(isUuid || isMongoId);
    final urlPath = isSlug ? 'books/slug/$id' : 'books/$id';
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetbookdetailsApi',
      apiUrl: '$baseUrl$urlPath',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final leg = BoiaroLegacyAdapter.legacyBookDetailFromV2(
      Map<String, dynamic>.from(body),
    );
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'bookDetails': [leg],
      }),
      res.headers,
      res.statusCode,
    );
  }

  String? slug(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].slug''',
      ));

  String? authorName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].author.name''',
      ));
  String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:]._id''',
      ));
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].name''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].image''',
      ));
  String? description(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].description''',
      ));
  String? authorid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].author._id''',
      ));
  String? chapterFirstFile(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].chapters[0].file''',
      ));
  String? pdf(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].pdf''',
      ));
  String? previewPdf(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].preview_pdf''',
      ));
  dynamic price(dynamic response) => castToType<dynamic>(getJsonField(
        response,
        r'''$.data.bookDetails[:].price''',
      ));
  dynamic discountAmount(dynamic response) => castToType<dynamic>(getJsonField(
        response,
        r'''$.data.bookDetails[:].discount_amount''',
      ));
  dynamic discountPercentage(dynamic response) =>
      castToType<dynamic>(getJsonField(
        response,
        r'''$.data.bookDetails[:].discount_percentage''',
      ));
  String? categoryId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].category._id''',
      ));
  String? categoryName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].category.name''',
      ));
  String? subcategoryId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].subcategory._id''',
      ));
  String? subcategoryName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].subcategory.name''',
      ));
  int? download(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.bookDetails[:].download''',
      ));
  int? viewCount(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.bookDetails[:].viewCount''',
      ));
  List? bookDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  String? language(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].language''',
      ));
  String? authorimage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].author.image''',
      ));
  List? reviewsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails[:].reviews''',
        true,
      ) as List?;
  double? averageRating(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.bookDetails[:].averageRating''',
      ));
  String? accesstype(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].access_type''',
      ));
  String? translatorName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].translator.name''',
      ));
  String? translatorid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].translator._id''',
      ));
  String? translatorimage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].translator.image''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetbookbyauthorApiCall {
  Future<ApiCallResponse> call({
    String? authorId = '',
    String? type = '',
    String? token = '',
  }) async {
    return _booksForAuthor(
      authorId: authorId ?? '',
      type: type,
      token: token,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
}

class GetbookbynarratorApiCall {
  Future<ApiCallResponse> call({
    String? narratorId = '',
    String? token = '',
  }) async {
    final nid = (narratorId ?? '').trim();
    if (nid.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'narratorId required',
        ),
        {},
        400,
      );
    }
    return _booksQuery(
      query: {'narrator': nid},
      token: token,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
}

class GetbookbycategoryApiCall {
  Future<ApiCallResponse> call({
    String? categoryId = '',
    String? type = '',
    String? token = '',
  }) async {
    final cid = (categoryId ?? '').trim();
    if (cid.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'categoryId required',
        ),
        {},
        400,
      );
    }
    return _booksQuery(
      query: {'categoryId': cid},
      type: type,
      token: token,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetbookbysubcategoryApiCall {
  Future<ApiCallResponse> call({
    String? subcategoryId = '',
    String? type = '',
    String? token = '',
  }) async {
    final sid = (subcategoryId ?? '').trim();
    if (sid.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'subcategoryId required',
        ),
        {},
        400,
      );
    }
    return _booksQuery(
      query: {
        'subcategoryId': sid,
        'subcategory': sid,
      },
      type: type,
      token: token,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetRelatedBooksApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? type = '',
    String? token = '',
  }) async {
    final base = await _booksQuery(
      query: const {'limit': '30'},
      type: type,
      token: token,
    );
    final bid = (bookId ?? '').trim();
    final root = base.jsonBody;
    if (root is! Map) {
      return base;
    }
    final data = root['data'];
    if (data is! Map) {
      return base;
    }
    final books = data['bookDetails'];
    if (books is! List) {
      return base;
    }
    final filtered = books
        .where((b) => b is Map && (b['_id']?.toString() ?? '') != bid)
        .take(12)
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'bookDetails': filtered}),
      base.headers,
      base.statusCode,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetsubscriptionplanApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetsubscriptionplanApi',
      apiUrl: '${baseUrl}subscriptions/plans',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final plans =
        (body['plans'] is List ? body['plans'] as List : const <dynamic>[])
            .whereType<Map>()
            .map((e) {
      final m = Map<String, dynamic>.from(e);
      return <String, dynamic>{
        ...m,
        '_id': m['id'],
        'duration': m['duration_days'],
        'duration_in_terms': 'days',
      };
    }).toList()
          ..sort((a, b) {
            final featuredA = a['is_featured'] == true ? 1 : 0;
            final featuredB = b['is_featured'] == true ? 1 : 0;
            if (featuredA != featuredB) {
              return featuredB.compareTo(featuredA);
            }
            final left = castToType<int>(a['sort_order']) ?? 0;
            final right = castToType<int>(b['sort_order']) ?? 0;
            return left.compareTo(right);
          });
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
          extra: {'subscriptionDetails': plans}),
      res.headers,
      res.statusCode,
    );
  }

  List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? duration(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].duration''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? price(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].price''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<int>? isactive(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].is_active''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List<String>? durationinterms(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].duration_in_terms''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? subscriptionId(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:]._id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List? subscriptionDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.subscriptionDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetpagesApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetpagesApi',
      apiUrl: '${baseUrl}getpages',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? termsofuse(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.pagesDetails[:].terms_of_use''',
      ));
  String? deleteaccountinstruction(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.pagesDetails[:].delete_account_instruction''',
      ));
  String? privacypolicy(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.pagesDetails[:].privacy_policy''',
      ));
  String? aboutus(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.pagesDetails[:].about_us''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class UsersubscriptionApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? subscriptionplanId = '',
    String? paymentmode = '',
    String? transactionId = '',
    String? paymentstatus = '',
    String? paymentdate = '',
    String? price = '',
    String? couponCode = '',
    double? couponDiscount,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final normalizedMethod = (paymentmode ?? '').trim().toLowerCase();
    final paymentMethod = switch (normalizedMethod) {
      'sslcommerz' => 'sslcommerz',
      'bkash' => 'bkash',
      'nagad' => 'nagad',
      'demo' => 'demo',
      'free' => 'demo',
      _ => 'demo',
    };

    final payload = <String, dynamic>{
      'plan_id': subscriptionplanId,
      'payment_method': paymentMethod,
    };
    if ((couponCode ?? '').trim().isNotEmpty) {
      payload['coupon_code'] = couponCode!.trim();
    }
    if ((couponDiscount ?? 0) > 0) {
      payload['coupon_discount'] = couponDiscount;
    }
    final ffApiRequestBody = jsonEncode(payload);

    final res = await ApiManager.instance.makeApiCall(
      callName: 'UsersubscriptionApi',
      apiUrl: '${baseUrl}subscriptions/subscribe',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: {
          'success': 1,
          'message': body['message'] ?? 'Subscription created',
          'requires_payment': body['requires_payment'] == true,
          'gateway_url': body['gateway_url']?.toString() ?? '',
          'subscription_id': body['subscription_id']?.toString() ?? '',
          'transaction_id': body['transaction_id']?.toString() ?? '',
          'subscriptionDetails': body['subscription'] ?? {
            'id': body['subscription_id']?.toString() ?? '',
            'transactionId': body['transaction_id']?.toString() ?? '',
            'gatewayUrl': body['gateway_url']?.toString() ?? '',
            'requiresPayment': body['requires_payment'] == true,
          },
        },
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  bool? requiresPayment(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.data.requires_payment''',
      ));
  String? gatewayUrl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.gateway_url''',
      ));
  String? subscriptionId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscription_id''',
      ));
  String? transactionId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.transaction_id''',
      ));
}

class UsersubscriptionrecordApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'UsersubscriptionrecordApi',
      apiUrl: '${baseUrl}subscriptions/my',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final rows = (body['subscriptions'] is List
            ? body['subscriptions'] as List
            : const <dynamic>[])
        .whereType<Map>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          final plan = m['plan'];
          final normalizedPlan = plan is Map
              ? <String, dynamic>{
                  ...Map<String, dynamic>.from(plan),
                  'duration': plan['duration_days'],
                  'duration_in_terms': 'days',
                }
              : <String, dynamic>{};
          return <String, dynamic>{
            ...m,
            '_id': m['id'],
            'userId': m['user_id'],
            'subscriptionplanId':
                m['plan_id'] ?? normalizedPlan['id'] ?? normalizedPlan['_id'],
            'paymentmode': m['payment_method'],
            'paymentstatus': m['status'],
            'paymentdate': m['created_at'],
            'price': m['amount_paid'],
            'subscription_plans': normalizedPlan,
          };
        })
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
          extra: {'subscriptionDetails': rows}),
      res.headers,
      res.statusCode,
    );
  }

  List<String>? subscriptionDetailsId(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:]._id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? userId(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].userId''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? subscriptionplanId(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].subscriptionplanId''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? paymentmode(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].paymentmode''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? transactionId(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].transactionId''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? paymentstatus(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].paymentstatus''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? paymentdate(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].paymentdate''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? price(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails[:].price''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class UsersubscriptionvalidityApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'UsersubscriptionvalidityApi',
      apiUrl: '${baseUrl}subscriptions/active',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final active = body['subscription'];
    if (active is! Map) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'No active subscription',
          extra: {
            'subscriptionDetails': <String, dynamic>{'daysLeft': 0}
          },
        ),
        res.headers,
        res.statusCode,
      );
    }
    final first = Map<String, dynamic>.from(active);
    final endDateRaw = (first['end_date'] ?? '').toString();
    final endDate = DateTime.tryParse(endDateRaw);
    final now = DateTime.now().toUtc();
    final daysLeft =
        endDate == null ? 0 : endDate.difference(now).inDays.clamp(0, 9999);
    final plan = first['plan'];
    final normalizedPlan = plan is Map
        ? <String, dynamic>{
            ...Map<String, dynamic>.from(plan),
            'duration': plan['duration_days'],
            'duration_in_terms': 'days',
          }
        : <String, dynamic>{};
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: {
          'subscriptionDetails': {
            'daysLeft': daysLeft,
            'expirationDate': endDateRaw,
            'amountPaid': first['amount_paid'],
            'couponCode': first['coupon_code'],
            'discountAmount': first['discount_amount'],
            'paymentMethod': first['payment_method'],
            'subscriptionplanDetails': normalizedPlan,
          },
        },
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? daysLeft(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.daysLeft''',
      ));
  String? expirationDate(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.expirationDate''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.subscriptionplanDetails.name''',
      ));
  String? durationinterms(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.subscriptionplanDetails.duration_in_terms''',
      ));
  String? price(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.subscriptionplanDetails.price''',
      ));
  String? duration(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.subscriptionplanDetails.duration''',
      ));
  String? description(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.subscriptionplanDetails.description''',
      ));
  List<String>? features(dynamic response) => (getJsonField(
        response,
        r'''$.data.subscriptionDetails.subscriptionplanDetails.features''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  String? amountPaid(dynamic response) {
    final raw = getJsonField(
      response,
      r'''$.data.subscriptionDetails.amountPaid''',
    );
    return raw == null ? null : raw.toString();
  }
  String? couponCode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.couponCode''',
      ));
  String? discountAmount(dynamic response) {
    final raw = getJsonField(
      response,
      r'''$.data.subscriptionDetails.discountAmount''',
    );
    return raw == null ? null : raw.toString();
  }
  String? paymentMethod(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.subscriptionDetails.paymentMethod''',
      ));
}

class CurrencyApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'CurrencyApi',
      apiUrl: '${baseUrl}currency',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? currency(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.currencydetails[:].currency''',
      ));
}

class AddreviewApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? userId = '',
    String? description = '',
    String? date = '',
    String? time = '',
    double? rating,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final bid = Uri.encodeComponent((bookId ?? '').trim());
    final res = await ApiManager.instance.makeApiCall(
      callName: 'AddreviewApi',
      apiUrl: '${baseUrl}books/$bid/reviews',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'rating': rating ?? 0,
        'comment': description,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (res.succeeded) {
      final body = res.jsonBody;
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: body is Map
              ? (body['message']?.toString() ?? 'Review added')
              : 'Review added',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(res.jsonBody, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetreviewApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final bid = (bookId ?? '').trim();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetreviewApi',
      apiUrl: '${baseUrl}books/$bid/reviews',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded) {
      return _v2Error(body, res.statusCode);
    }
    final rawRows = body is List
        ? body
        : (body is Map && body['reviews'] is List
            ? body['reviews'] as List
            : const <dynamic>[]);
    final rows = rawRows
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyReviewFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: {
          'bookReviewDetails': [
            {'reviews': rows}
          ]
        },
      ),
      res.headers,
      res.statusCode,
    );
  }

  List<String>? date(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookReviewDetails[0].reviews[:].date''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<double>? rating(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookReviewDetails[0].reviews[:].rating''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<double>(x))
          .withoutNulls
          .toList();
  List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookReviewDetails[:].reviews[:].description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? userName(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookReviewDetails[:].reviews[:].userDetails.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  List? reviewsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookReviewDetails[0].reviews''',
        true,
      ) as List?;
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetbookcommentsApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final bid = (bookId ?? '').trim();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetbookcommentsApi',
      apiUrl: '${baseUrl}books/$bid/comments',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final rows = (body['comments'] is List
            ? body['comments'] as List
            : const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'commentDetails': rows}),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  List? commentDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.commentDetails''',
        true,
      ) as List?;
}

class AddcommentApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? comment = '',
    String? parentId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final payload = <String, dynamic>{
      'book_id': bookId,
      'comment': comment,
      if ((parentId ?? '').trim().isNotEmpty) 'parent_id': parentId,
    };
    final res = await ApiManager.instance.makeApiCall(
      callName: 'AddcommentApi',
      apiUrl: '${baseUrl}comments',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody(payload),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (!res.succeeded) {
      return _v2Error(res.jsonBody, res.statusCode);
    }
    final body = res.jsonBody;
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message: body is Map
            ? (body['message']?.toString() ?? 'Comment posted')
            : 'Comment posted',
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class WalletApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'WalletApi',
      apiUrl: '${baseUrl}wallet',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (!res.succeeded || res.jsonBody is! Map) {
      return _v2Error(res.jsonBody, res.statusCode);
    }
    final body = Map<String, dynamic>.from(res.jsonBody as Map);
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'wallet': body}),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  int? balance(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.wallet.balance''',
      ));
  int? totalEarned(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.wallet.total_earned''',
      ));
  int? totalSpent(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.wallet.total_spent''',
      ));
}

class WalletTransactionsApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    int? limit,
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'WalletTransactionsApi',
      apiUrl: '${baseUrl}wallet/transactions',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {
        if (limit != null) 'limit': limit,
      },
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (!res.succeeded || res.jsonBody is! Map) {
      return _v2Error(res.jsonBody, res.statusCode);
    }
    final body = Map<String, dynamic>.from(res.jsonBody as Map);
    final tx = (body['transactions'] is List
            ? body['transactions'] as List
            : const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'transactions': tx}),
      res.headers,
      res.statusCode,
    );
  }

  List? transactions(dynamic response) => getJsonField(
        response,
        r'''$.data.transactions''',
        true,
      ) as List?;
}

class WalletClaimDailyApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'WalletClaimDailyApi',
      apiUrl: '${baseUrl}wallet/claim-daily',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (!res.succeeded) {
      return _v2Error(res.jsonBody, res.statusCode);
    }
    final body = res.jsonBody;
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message: body is Map
            ? (body['message']?.toString() ?? 'Daily reward claimed')
            : 'Daily reward claimed',
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class WalletClaimAdApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? placement = 'general',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'WalletClaimAdApi',
      apiUrl: '${baseUrl}wallet/claim-ad',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody(
          {'placement': placement ?? 'general'}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (!res.succeeded) {
      return _v2Error(res.jsonBody, res.statusCode);
    }
    final body = res.jsonBody;
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message: body is Map
            ? (body['message']?.toString() ?? 'Ad reward claimed')
            : 'Ad reward claimed',
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetHomepageApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? type = '',
    int? limit,
  }) async {
    final normalizedType = _normalizeHomepageTypeValue(type);
    if (normalizedType == '__invalid__') {
      return ApiCallResponse(
        {
          'error': 'Invalid type. Allowed values: ebook, audiobook, hardcopy',
        },
        const {},
        400,
      );
    }
    final safeLimit = (limit ?? 10).clamp(1, 50);
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetHomepageApi',
      apiUrl: '${baseUrl}homepage',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {
        'limit': '$safeLimit',
        if (normalizedType.isNotEmpty) 'type': normalizedType,
      },
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }

    // Sliders: body['slider'] is {'slider': [...]}
    final sliderRaw = body['slider'];
    final sliderList = sliderRaw is Map ? sliderRaw['slider'] : sliderRaw;
    final sliderDetails = <Map<String, dynamic>>[];
    if (sliderList is List) {
      for (final raw in sliderList) {
        if (raw is! Map) {
          continue;
        }
        sliderDetails.add(
          homepageSliderDetailFromRaw(Map<String, dynamic>.from(raw)),
        );
      }
    }

    // Categories: body['allCategory']
    final catRaw = body['allCategory'];
    final categoryDetails = <Map<String, dynamic>>[];
    if (catRaw is List) {
      for (final c in catRaw) {
        if (c is Map) {
          categoryDetails.add(BoiaroLegacyAdapter.legacyCategoryFromV2(
              Map<String, dynamic>.from(c)));
        }
      }
    }

    // Authors: body['allAuthor']
    final authorRaw = body['allAuthor'];
    final authorDetails = <Map<String, dynamic>>[];
    if (authorRaw is List) {
      for (final a in authorRaw) {
        if (a is Map) {
          authorDetails.add(BoiaroLegacyAdapter.legacyAuthorFromV2(
              Map<String, dynamic>.from(a)));
        }
      }
    }

    // Narrators: body['allNarrators']
    final narratorRaw = body['allNarrators'];
    final narratorDetails = <Map<String, dynamic>>[];
    if (narratorRaw is List) {
      for (final n in narratorRaw) {
        if (n is Map) {
          narratorDetails.add(BoiaroLegacyAdapter.legacyNarratorFromV2(
              Map<String, dynamic>.from(n)));
        }
      }
    }

    // Trending: body['trendingNow']['trendingNow']
    final trendingRaw = body['trendingNow'];
    final trendingList =
        trendingRaw is Map ? trendingRaw['trendingNow'] : trendingRaw;
    final trendingBooks = <Map<String, dynamic>>[];
    if (trendingList is List) {
      for (final b in trendingList) {
        if (b is Map) {
          trendingBooks.add(BoiaroLegacyAdapter.legacyBookFromHomepageItem(
            Map<String, dynamic>.from(b),
            preferredFormat: normalizedType,
          ));
        }
      }
    }

    // Popular: body['popularBooks']
    final popularRaw = body['popularBooks'];
    final popularBooks = <Map<String, dynamic>>[];
    if (popularRaw is List) {
      for (final b in popularRaw) {
        if (b is Map) {
          popularBooks.add(BoiaroLegacyAdapter.legacyBookFromHomepageItem(
            Map<String, dynamic>.from(b),
            preferredFormat: normalizedType,
          ));
        }
      }
    }

    // New releases: body['NewReleases']['all']
    final newRaw = body['newReleases'] ?? body['NewReleases'];
    final newList = newRaw is Map ? newRaw['all'] : newRaw;
    final newBooks = <Map<String, dynamic>>[];
    if (newList is List) {
      for (final b in newList) {
        if (b is Map) {
          newBooks.add(BoiaroLegacyAdapter.legacyBookFromHomepageItem(
            Map<String, dynamic>.from(b),
            preferredFormat: normalizedType,
          ));
        }
      }
    }

    List<Map<String, dynamic>> mapHomepageBookList(
      dynamic raw, {
      String? nestedKey,
      String? sectionKey,
    }) {
      final source = raw is Map && nestedKey != null ? raw[nestedKey] : raw;
      final rows = <Map<String, dynamic>>[];
      if (source is List) {
        for (final item in source) {
          if (item is Map) {
            rows.add(BoiaroLegacyAdapter.legacyBookFromHomepageItem(
              Map<String, dynamic>.from(item),
              preferredFormat: _preferredHomepageFormatForSection(
                sectionKey ?? nestedKey ?? '',
                normalizedType,
              ),
            ));
          }
        }
      }
      return rows;
    }

    final becauseYouRead = mapHomepageBookList(
      body['becauseYouRead'] ?? body['BecauseYouRead'],
      sectionKey: 'becauseYouRead',
    );
    final editorsPick = mapHomepageBookList(
      body['editorsPick'],
      sectionKey: 'editorsPick',
    );
    final popularEbooks = mapHomepageBookList(
      body['popularEbooks'],
      sectionKey: 'popularEbooks',
    );
    final popularAudiobooks = mapHomepageBookList(
      body['popularAudiobooks'],
      sectionKey: 'popularAudiobooks',
    );
    final popularHardCopies = mapHomepageBookList(
      body['popularHardCopies'],
      sectionKey: 'popularHardCopies',
    );
    final topTenMostRead = mapHomepageBookList(
      body['topMostRead'] ?? body['topTenMostRead'],
      sectionKey: 'topMostRead',
    );
    final freeBooks = mapHomepageBookList(
      body['freeBooks'] ?? body['FreeBooks'],
      sectionKey: 'freeBooks',
    );

    List<Map<String, dynamic>> mapContinueList(
      dynamic raw, {
      required String format,
    }) {
      final rows = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final bookRaw = item['book'];
            if (bookRaw is Map) {
              final legacyBook = BoiaroLegacyAdapter.legacyBookFromHomepageItem(
                Map<String, dynamic>.from(bookRaw),
                preferredFormat: format,
              );
              rows.add({
                'id': item['id']?.toString() ?? '',
                'book_id': item['book_id']?.toString() ?? '',
                'created_at': item['created_at']?.toString() ?? '',
                'current_position': (item['current_position'] as num?)?.toInt() ?? 0,
                'current_track': (item['current_track'] as num?)?.toInt() ?? 1,
                'current_page': (item['current_page'] as num?)?.toInt() ?? 1,
                'percentage': (item['percentage'] as num?)?.toDouble() ?? 0.0,
                'total_duration': (item['total_duration'] as num?)?.toInt() ?? 0,
                'total_pages': (item['total_pages'] as num?)?.toInt() ?? 1,
                'playback_speed': item['playback_speed']?.toString() ?? '',
                'last_read_at': (item['last_read_at'] ?? item['last_listened_at'])?.toString() ?? '',
                'book': legacyBook,
              });
            }
          }
        }
      }
      return rows;
    }

    final continueListening = mapContinueList(
      body['continueListening'] ?? body['ContinueListening'],
      format: 'audiobook',
    );
    final continueReading = mapContinueList(
      body['continueReading'] ?? body['ContinueReading'],
      format: 'ebook',
    );

    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'sliderDetails': sliderDetails,
        'categoryDetails': categoryDetails,
        'authorDetails': authorDetails,
        'narratorDetails': narratorDetails,
        'trendingBooks': trendingBooks,
        'popularBooks': popularBooks,
        'newBooks': newBooks,
        'becauseYouRead': becauseYouRead,
        'editorsPick': editorsPick,
        'popularEbooks': popularEbooks,
        'popularAudiobooks': popularAudiobooks,
        'popularHardCopies': popularHardCopies,
        'topTenMostRead': topTenMostRead,
        'freeBooks': freeBooks,
        'continueListening': continueListening,
        'continueReading': continueReading,
      }),
      res.headers,
      res.statusCode,
    );
  }

  List? sliderDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.sliderDetails''',
        true,
      ) as List?;
  List? categoryDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.categoryDetails''',
        true,
      ) as List?;
  List? authorDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.authorDetails''',
        true,
      ) as List?;
  List? narratorDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.narratorDetails''',
        true,
      ) as List?;
  List? trendingBookList(dynamic response) => getJsonField(
        response,
        r'''$.data.trendingBooks''',
        true,
      ) as List?;
  List? popularBookList(dynamic response) => getJsonField(
        response,
        r'''$.data.popularBooks''',
        true,
      ) as List?;
  List? newBookList(dynamic response) => getJsonField(
        response,
        r'''$.data.newBooks''',
        true,
      ) as List?;
  List? becauseYouReadList(dynamic response) => getJsonField(
        response,
        r'''$.data.becauseYouRead''',
        true,
      ) as List?;
  List? editorsPickList(dynamic response) => getJsonField(
        response,
        r'''$.data.editorsPick''',
        true,
      ) as List?;
  List? popularEbookList(dynamic response) => getJsonField(
        response,
        r'''$.data.popularEbooks''',
        true,
      ) as List?;
  List? popularAudiobookList(dynamic response) => getJsonField(
        response,
        r'''$.data.popularAudiobooks''',
        true,
      ) as List?;
  List? popularHardCopyList(dynamic response) => getJsonField(
        response,
        r'''$.data.popularHardCopies''',
        true,
      ) as List?;
  List? topTenMostReadList(dynamic response) => getJsonField(
        response,
        r'''$.data.topTenMostRead''',
        true,
      ) as List?;
  List? freeBookList(dynamic response) => getJsonField(
        response,
        r'''$.data.freeBooks''',
        true,
      ) as List?;
  List? continueListeningList(dynamic response) => getJsonField(
        response,
        r'''$.data.continueListening''',
        true,
      ) as List?;
  List? continueReadingList(dynamic response) => getJsonField(
        response,
        r'''$.data.continueReading''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetCategorySectionsApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetCategorySectionsApi',
      apiUrl: '${baseUrl}category-sections',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }

    final sections = <Map<String, dynamic>>[];
    final rawSections = body['sections'];
    if (rawSections is List) {
      for (final row in rawSections) {
        if (row is! Map) {
          continue;
        }
        final section = Map<String, dynamic>.from(row);
        final books = <Map<String, dynamic>>[];
        final rawBooks = section['books'];
        if (rawBooks is List) {
          for (final bookRow in rawBooks) {
            if (bookRow is Map) {
              books.add(
                BoiaroLegacyAdapter.legacyBookFromHomepageItem(
                  Map<String, dynamic>.from(bookRow),
                ),
              );
            }
          }
        }

        sections.add({
          'id': section['id']?.toString() ?? '',
          'title': section['title'],
          'subtitle': section['subtitle'],
          'category_id': section['category_id']?.toString() ?? '',
          'sort_order': section['sort_order'],
          'book_limit': section['book_limit'],
          'category': section['category'] is Map
              ? BoiaroLegacyAdapter.legacyCategoryFromV2(
                  Map<String, dynamic>.from(section['category'] as Map),
                )
              : null,
          'books': books,
        });
      }
    }

    sections.sort((a, b) {
      final left = castToType<int>(a['sort_order']) ?? 0;
      final right = castToType<int>(b['sort_order']) ?? 0;
      return left.compareTo(right);
    });

    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: {'categorySections': sections},
      ),
      res.headers,
      res.statusCode,
    );
  }

  List? categorySectionsList(dynamic response) => getJsonField(
        response,
        r'''$.data.categorySections''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetTrendingBooksApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? type = '',
    int? limit,
    int? offset,
  }) async {
    return _homepageSectionAsBooks(
      sectionKey: 'trendingNow',
      type: type,
      token: token,
      limit: limit,
      offset: offset,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetNewBooksApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? type = '',
    int? limit,
    int? offset,
  }) async {
    return _homepageSectionAsBooks(
      sectionKey: 'newReleases',
      type: type,
      token: token,
      limit: limit,
      offset: offset,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetPopularBooksApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? type = '',
    String? sectionKey = '',
    int? limit,
    int? offset,
  }) async {
    final normalizedType = _normalizeHomepageTypeValue(type);
    final normalizedSection = (sectionKey ?? '').trim();
    final resolvedSection = normalizedSection.isNotEmpty
        ? normalizedSection
        : normalizedType == 'audiobook'
            ? 'popularAudiobooks'
            : normalizedType == 'hardcopy'
                ? 'popularHardCopies'
                : normalizedType == 'ebook'
                    ? 'popularEbooks'
                    : 'popularBooks';
    return _homepageSectionAsBooks(
      sectionKey: resolvedSection,
      type: type,
      token: token,
      limit: limit,
      offset: offset,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class AddFavouriteBookApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'AddFavouriteBookApi',
      apiUrl: '${baseUrl}me/bookmarks',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({'book_id': bookId}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.statusCode == 201 || (res.succeeded && jb is Map)) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb is Map
              ? (jb['message']?.toString() ?? 'Bookmarked')
              : 'Bookmarked',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }
}

class GetFavouriteBookCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetFavouriteBook',
      apiUrl: '${baseUrl}me/bookmarks',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body is List ? body : (body is Map ? body['bookmarks'] : null);
    final fav = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final row in raw) {
        if (row is Map) {
          fav.add(
            BoiaroLegacyAdapter.legacyBookmarkFromV2(
              Map<String, dynamic>.from(row),
            ),
          );
        }
      }
    }
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: {'favouriteBookDetails': fav},
      ),
      res.headers,
      res.statusCode,
    );
  }

  List? favouriteBookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.favouriteBookDetails''',
        true,
      ) as List?;
  String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.favouriteBookDetails[:].bookDetails._id''',
      ));
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.favouriteBookDetails[:].bookDetails.name''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.favouriteBookDetails[:].bookDetails.image''',
      ));
  String? authorname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.favouriteBookDetails[:].bookDetails.author.name''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class RemoveFavouritebookCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final bid = Uri.encodeComponent((bookId ?? '').trim());
    final res = await ApiManager.instance.makeApiCall(
      callName: 'RemoveFavouritebook',
      apiUrl: '${baseUrl}me/bookmarks/$bid',
      callType: ApiCallType.DELETE,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message:
              jb is Map ? (jb['message']?.toString() ?? 'Removed') : 'Removed',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
}

class DownloadhistoryApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'DownloadhistoryApi',
      apiUrl: '${baseUrl}library/purchases',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final rows = ((body['purchases'] is List
            ? body['purchases'] as List
            : (body['items'] is List
                ? body['items'] as List
                : const <dynamic>[])))
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'downloadDetails': rows}),
      res.headers,
      res.statusCode,
    );
  }

  List? downloadDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.downloadDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class DownloadpdfApiCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'DownloadpdfApi',
      apiUrl: '${baseUrl}content/ebook-url',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({'book_id': bookId}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (!res.succeeded) {
      return _v2Error(res.jsonBody, res.statusCode);
    }
    final body = res.jsonBody;
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        success: 1,
        message: body is Map
            ? (body['signed_url']?.toString() ?? 'URL ready')
            : 'URL ready',
      ),
      res.headers,
      res.statusCode,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class SearchApiCall {
  Future<ApiCallResponse> call({
    String? search = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final q = (search ?? '').trim();
    if (q.length < 2) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 0,
          message: 'Search query too short (min 2 chars)',
          extra: {'bookDetails': <dynamic>[]},
        ),
        {},
        400,
      );
    }
    final res = await ApiManager.instance.makeApiCall(
      callName: 'SearchApi',
      apiUrl: '${baseUrl}search',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {'q': q},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body['results'];
    if (raw is! List) {
      return _v2Error(body, res.statusCode);
    }
    final leg = raw
        .whereType<Map>()
        .map((e) =>
            BoiaroLegacyAdapter.legacyBookFromV2(Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'bookDetails': leg}),
      res.headers,
      res.statusCode,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  String? bookId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:]._id''',
      ));
  String? bookName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].name''',
      ));
  String? bookImage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].image''',
      ));
  String? authorname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].author.name''',
      ));
}

class LatestAllBookApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? type = '',
  }) async {
    return _booksQuery(
      query: null,
      type: type,
      token: token,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetnotificationApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GetnotificationApi',
      apiUrl: '${baseUrl}notifications',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final rows = (body['notifications'] is List
            ? body['notifications'] as List
            : const <dynamic>[])
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyNotificationFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
          extra: {'notificationDetails': rows}),
      res.headers,
      res.statusCode,
    );
  }

  List? notificationDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.notificationDetails''',
        true,
      ) as List?;
  List<String>? title(dynamic response) => (getJsonField(
        response,
        r'''$.data.notificationDetails[:].title''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.data.notificationDetails[:].description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? date(dynamic response) => (getJsonField(
        response,
        r'''$.data.notificationDetails[:].date''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class RegisterNotificationTokenApiCall {
  Future<ApiCallResponse> call({
    String? tokenFcm = '',
    String? platform = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'RegisterNotificationTokenApi',
      apiUrl: '${baseUrl}notifications/register-token',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'token': tokenFcm,
        'platform': platform,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb is Map ? (jb['message']?.toString() ?? 'Token registered') : 'Token registered',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class UnregisterNotificationTokenApiCall {
  Future<ApiCallResponse> call({
    String? tokenFcm = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'UnregisterNotificationTokenApi',
      apiUrl: '${baseUrl}notifications/register-token',
      callType: ApiCallType.DELETE,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'token': tokenFcm,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb is Map ? (jb['message']?.toString() ?? 'Token unregistered') : 'Token unregistered',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class ReadNotificationsApiCall {
  Future<ApiCallResponse> call({
    List<String>? ids,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'ReadNotificationsApi',
      apiUrl: '${baseUrl}notifications/read',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({
        'ids': ids ?? const [],
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb is Map ? (jb['message']?.toString() ?? 'Notifications marked as read') : 'Notifications marked as read',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class ChangepasswordApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'ChangepasswordApi',
      apiUrl: '${baseUrl}auth/update-password',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody({'password': password}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    if (res.succeeded) {
      final body = res.jsonBody;
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: body is Map
              ? (body['message']?.toString() ?? 'Password updated')
              : 'Password updated',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(res.jsonBody, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class UserVerifyApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UserVerifyApi',
      apiUrl: '${baseUrl}/verify_user',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class ResendOTPApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ResendOTPApi',
      apiUrl: '${baseUrl}/resend_otp',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class PaymentGatewayApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'PaymentGatewayApi',
      apiUrl: '${baseUrl}/payment_gateway',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? razorpaykeysecret(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].razorpay.razorpay_key_secret''',
      ));
  String? razorpaykeyId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].razorpay.razorpay_key_Id''',
      ));
  String? stripepublishablekey(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].stripe.stripe_publishable_key''',
      ));
  String? stripesecretkey(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].stripe.stripe_secret_key''',
      ));
  int? stripeEnable(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].stripe.stripe_is_enable''',
      ));
  int? razorpayEnable(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].razorpay.razorpay_is_enable''',
      ));
  int? paypalEnable(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].paypal.paypal_is_enable''',
      ));
  String? paypalpublickey(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].paypal.paypal_public_key''',
      ));
  String? paypalprivatekey(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.paymentMethod[:].paypal.paypal_private_key''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetFeaturedBooksByCategoryApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final catRes = await ApiManager.instance.makeApiCall(
      callName: 'GetFeaturedBooksByCategory_categories',
      apiUrl: '${baseUrl}categories',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final catBody = catRes.jsonBody;
    if (!catRes.succeeded || catBody is! Map) {
      return _v2Error(catBody, catRes.statusCode);
    }
    final cats = catBody['categories'];
    if (cats is! List) {
      return _v2Error(catBody, catRes.statusCode);
    }
    final out = <Map<String, dynamic>>[];
    for (final c in cats.take(12)) {
      if (c is! Map) {
        continue;
      }
      final cm = Map<String, dynamic>.from(c);
      final cid = cm['id']?.toString();
      if (cid == null || cid.isEmpty) {
        continue;
      }
      final bRes = await ApiManager.instance.makeApiCall(
        callName: 'GetFeaturedBooksByCategory_books',
        apiUrl: '${baseUrl}books',
        callType: ApiCallType.GET,
        headers: _boiaroAuthHeaders(token),
        params: {
          'categoryId': cid,
          'limit': '12',
          'isFeatured': 'true',
        },
        bodyType: BodyType.NONE,
        returnBody: true,
        encodeBodyUtf8: false,
        decodeUtf8: false,
        cache: false,
        isStreamingApi: false,
        alwaysAllowBody: false,
      );
      final jb = bRes.jsonBody;
      if (!bRes.succeeded || jb is! Map) {
        continue;
      }
      final booksRaw = jb['books'];
      if (booksRaw is! List) {
        continue;
      }
      final featuredBooks = booksRaw
          .whereType<Map>()
          .map((e) => BoiaroLegacyAdapter.legacyBookFromV2(
              Map<String, dynamic>.from(e)))
          .toList();
      if (featuredBooks.isEmpty) {
        continue;
      }
      out.add({
        'name': cm['name'] ?? '',
        'featuredBooks': featuredBooks,
      });
    }
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'categoryBooks': out}),
      catRes.headers,
      200,
    );
  }

  List? categoryBooks(dynamic response) => getJsonField(
        response,
        r'''$.data.categoryBooks''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetCouponApiCall {
  Future<ApiCallResponse> call({
    String code = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetCoupon',
      apiUrl: '${baseUrl}coupons/$code',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(''),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ValidateCouponApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String code = '',
    double totalAmount = 0.0,
    bool hasHardcopy = false,
    bool hasEbook = false,
    bool hasAudiobook = false,
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'code': code,
      'total_amount': totalAmount,
      'has_hardcopy': hasHardcopy,
      'has_ebook': hasEbook,
      'has_audiobook': hasAudiobook,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'ValidateCoupon',
      apiUrl: '${baseUrl}coupons/validate',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetOrdersApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetOrders',
      apiUrl: '${baseUrl}orders',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class PresenceHeartbeatApiCall {
  Future<ApiCallResponse> call({
    required String activityType,
    required String sessionId,
    String? bookId,
    String? currentPage,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final payload = <String, dynamic>{
      'activity_type': activityType,
      'session_id': sessionId,
      if (bookId != null && bookId.isNotEmpty) 'book_id': bookId,
      if (currentPage != null && currentPage.isNotEmpty) 'current_page': currentPage,
    };
    final res = await ApiManager.instance.makeApiCall(
      callName: 'PresenceHeartbeatApi',
      apiUrl: '${baseUrl}presence/heartbeat',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: BoiaroLegacyAdapter.jsonEncodeBody(payload),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final jb = res.jsonBody;
    if (res.succeeded) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
          success: 1,
          message: jb is Map ? (jb['message']?.toString() ?? 'Heartbeat sent') : 'Heartbeat sent',
        ),
        res.headers,
        res.statusCode,
      );
    }
    return _v2Error(jb, res.statusCode);
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

/// End Ebook Group Code

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

/// POST /api/v1/books/:id/read
/// Auth optional — with token also creates BookRead record for personalization.
class RegisterBookReadApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? token,
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final bid = Uri.encodeComponent((bookId ?? '').trim());
    final headers = token != null && token.isNotEmpty
        ? _boiaroAuthHeaders(token)
        : <String, dynamic>{};
    final res = await ApiManager.instance.makeApiCall(
      callName: 'RegisterBookRead',
      apiUrl: '${baseUrl}books/$bid/read',
      callType: ApiCallType.POST,
      headers: headers,
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    return res;
  }

  bool? success(dynamic response) {
    final s = getJsonField(response, r'''$.success''');
    if (s is bool) return s;
    return null;
  }

  int? totalReads(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.total_reads'''));
}

class GetBookChaptersApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final bid = Uri.encodeComponent((bookId ?? '').trim());
    return ApiManager.instance.makeApiCall(
      callName: 'GetBookChapters',
      apiUrl: '${baseUrl}books/$bid/chapters',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UnlockChapterWithCoinsCall {
  Future<ApiCallResponse> call({
    String? trackId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final tid = Uri.encodeComponent((trackId ?? '').trim());
    return ApiManager.instance.makeApiCall(
      callName: 'UnlockChapterWithCoins',
      apiUrl: '${baseUrl}chapters/$tid/unlock-coin',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class InitiateChapterPaymentCall {
  Future<ApiCallResponse> call({
    String? trackId = '',
    String? bookId = '',
    String? gateway = 'sslcommerz', // sslcommerz | bkash
    String? successRedirect = 'myapp://payment/success',
    String? failRedirect = 'myapp://payment/failed',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final tid = Uri.encodeComponent((trackId ?? '').trim());
    final body = json.encode({
      'book_id': bookId,
      'gateway': gateway,
      'success_redirect': successRedirect,
      'fail_redirect': failRedirect,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'InitiateChapterPayment',
      apiUrl: '${baseUrl}chapters/$tid/initiate-payment',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class PollPaymentStatusCall {
  Future<ApiCallResponse> call({
    String? purchaseId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final pid = Uri.encodeComponent((purchaseId ?? '').trim());
    return ApiManager.instance.makeApiCall(
      callName: 'PollPaymentStatus',
      apiUrl: '${baseUrl}chapters/payment-status/$pid',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetAdSettingsCall {
  Future<ApiCallResponse> call() async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetAdSettings',
      apiUrl: '${baseUrl}ads/settings',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(null),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetActiveBannersCall {
  Future<ApiCallResponse> call({
    String? placement,
    String? device,
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetActiveBanners',
      apiUrl: '${baseUrl}ads/banners',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(null),
      params: {
        'placement': placement ?? '',
        'device': device ?? '',
      },
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetRewardedAdStatusCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetRewardedAdStatus',
      apiUrl: '${baseUrl}ads/rewarded/status',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ClaimRewardedAdRewardCall {
  Future<ApiCallResponse> call({
    String? placement = 'mobile_player',
    String? adEventId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'placement': placement,
      if (adEventId != null && adEventId.isNotEmpty) 'ad_event_id': adEventId,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'ClaimRewardedAdReward',
      apiUrl: '${baseUrl}ads/rewarded/claim',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetGamificationSummaryCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetGamificationSummary',
      apiUrl: '${baseUrl}gamification/summary',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UpdateStreakCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'UpdateStreak',
      apiUrl: '${baseUrl}gamification/streak/update',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class LogConsumptionTimeCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? format = 'audiobook',
    int seconds = 60,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'book_id': bookId,
      'format': format,
      'seconds': seconds,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'LogConsumptionTime',
      apiUrl: '${baseUrl}gamification/consumption-time',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetReferralInfoCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetReferralInfo',
      apiUrl: '${baseUrl}referral/info',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ValidateReferralCodeCall {
  Future<ApiCallResponse> call({
    String? code = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final c = Uri.encodeComponent((code ?? '').trim());
    return ApiManager.instance.makeApiCall(
      callName: 'ValidateReferralCode',
      apiUrl: '${baseUrl}referral/validate/$c',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(null),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetAdPlacementsCall {
  Future<ApiCallResponse> call() async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetAdPlacements',
      apiUrl: '${baseUrl}ads/placements',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(null),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class PostAdImpressionCall {
  Future<ApiCallResponse> call({
    required String bannerId,
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'banner_id': bannerId,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'PostAdImpression',
      apiUrl: '${baseUrl}ads/impression',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class PostAdClickCall {
  Future<ApiCallResponse> call({
    required String bannerId,
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'banner_id': bannerId,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'PostAdClick',
      apiUrl: '${baseUrl}ads/click',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(null),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetStreakCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetStreak',
      apiUrl: '${baseUrl}gamification/streak',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetPointsHistoryCall {
  Future<ApiCallResponse> call({
    int? limit = 20,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetPointsHistory',
      apiUrl: '${baseUrl}gamification/points',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {
        'limit': '$limit',
      },
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddPointsCall {
  Future<ApiCallResponse> call({
    int? points,
    String? eventType,
    String? referenceId,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      if (points != null) 'points': points,
      if (eventType != null) 'event_type': eventType,
      if (referenceId != null) 'reference_id': referenceId,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'AddPoints',
      apiUrl: '${baseUrl}gamification/points',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetLeaderboardCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetLeaderboard',
      apiUrl: '${baseUrl}gamification/leaderboard',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetMyBadgesCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetMyBadges',
      apiUrl: '${baseUrl}gamification/badges',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetBadgeDefinitionsCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetBadgeDefinitions',
      apiUrl: '${baseUrl}gamification/badges/definitions',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckAwardBadgesCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'CheckAwardBadges',
      apiUrl: '${baseUrl}gamification/badges/check',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ClaimDailyRewardCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'ClaimDailyReward',
      apiUrl: '${baseUrl}gamification/daily-reward',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetMyGoalsCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    return ApiManager.instance.makeApiCall(
      callName: 'GetMyGoals',
      apiUrl: '${baseUrl}gamification/goals',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddGoalCall {
  Future<ApiCallResponse> call({
    String? goalType = 'reading',
    int? targetValue = 30,
    String? period = 'daily',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'goal_type': goalType,
      'target_value': targetValue,
      'period': period,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'AddGoal',
      apiUrl: '${baseUrl}gamification/goals',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class LogActivityCall {
  Future<ApiCallResponse> call({
    String? action = 'play',
    String? activityType = 'audiobook',
    String? bookId = '',
    String? format = 'audiobook',
    String? page = 'player',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final body = json.encode({
      'action': action,
      'activity_type': activityType,
      'book_id': bookId,
      'format': format,
      'page': page,
    });
    return ApiManager.instance.makeApiCall(
      callName: 'LogActivity',
      apiUrl: '${baseUrl}gamification/activity',
      callType: ApiCallType.POST,
      headers: _boiaroAuthHeaders(token),
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

Future<ApiCallResponse> _booksForTranslator({
  required String translatorId,
  String? type,
  String? token,
  int? limit,
  int? offset,
}) async {
  final baseUrl = EbookGroup.getBaseUrl();
  final safeLimit = (limit ?? 10).clamp(1, 100);
  final res = await ApiManager.instance.makeApiCall(
    callName: 'BooksForTranslator',
    apiUrl: '${baseUrl}books',
    callType: ApiCallType.GET,
    headers: _boiaroAuthHeaders(token),
    params: {
      'limit': '$safeLimit',
      if (offset != null) 'offset': '$offset',
      'translator': translatorId,
      'translatorId': translatorId,
    },
    bodyType: BodyType.NONE,
    returnBody: true,
    encodeBodyUtf8: false,
    decodeUtf8: false,
    cache: false,
    isStreamingApi: false,
    alwaysAllowBody: false,
  );
  final body = res.jsonBody;
  if (!res.succeeded || body is! Map) {
    return _v2Error(body, res.statusCode);
  }
  final err = BoiaroLegacyAdapter.v2Error(body);
  if (err != null) {
    return _v2Error(body, res.statusCode);
  }
  final raw = body['books'];
  if (raw is! List) {
    return _v2Error(body, res.statusCode);
  }
  final tid = translatorId.trim();
  var leg = raw
      .whereType<Map>()
      .map((e) =>
          BoiaroLegacyAdapter.legacyBookFromV2(Map<String, dynamic>.from(e)))
      .where((b) {
        final t = b['translator'];
        if (t is Map) {
          return t['_id']?.toString() == tid;
        }
        return false;
      })
      .where((b) => _matchesBookTypeFilter(b, type))
      .toList();
  return ApiCallResponse(
    BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'bookDetails': leg}),
    res.headers,
    res.statusCode,
  );
}

class GettranslatordetailsApiCall {
  Future<ApiCallResponse> call({
    String? translatorId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final id = Uri.encodeComponent((translatorId ?? '').trim());
    if (id.isEmpty) {
      return ApiCallResponse(
        BoiaroLegacyAdapter.legacyDataEnvelope(
            success: 0, message: 'translatorId required'),
        {},
        400,
      );
    }
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GettranslatordetailsApi',
      apiUrl: '${baseUrl}translators/$id',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    if (BoiaroLegacyAdapter.v2Error(body) != null) {
      return _v2Error(body, res.statusCode);
    }
    final leg =
        BoiaroLegacyAdapter.legacyTranslatorFromV2(Map<String, dynamic>.from(body));
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {
        'translatorDetails': [leg],
      }),
      res.headers,
      res.statusCode,
    );
  }

  List? translatorDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.translatorDetails''',
        true,
      ) as List?;
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].name''',
      ));
  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].image''',
      ));
  String? facebookurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].facebook_url''',
      ));
  String? instagramurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].instagram_url''',
      ));
  String? youtubeurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].youtube_url''',
      ));
  String? websiteurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].website_url''',
      ));
  String? description(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.translatorDetails[:].description''',
      ));
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GettranslatorsApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    final res = await ApiManager.instance.makeApiCall(
      callName: 'GettranslatorsApi',
      apiUrl: '${baseUrl}translators',
      callType: ApiCallType.GET,
      headers: _boiaroAuthHeaders(token),
      params: {'limit': '50', 'offset': '0'},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
    final body = res.jsonBody;
    if (!res.succeeded || body is! Map) {
      return _v2Error(body, res.statusCode);
    }
    final err = BoiaroLegacyAdapter.v2Error(body);
    if (err != null) {
      return _v2Error(body, res.statusCode);
    }
    final raw = body['translators'];
    if (raw is! List) {
      return _v2Error(body, res.statusCode);
    }
    final leg = raw
        .whereType<Map>()
        .map((e) => BoiaroLegacyAdapter.legacyTranslatorFromV2(
            Map<String, dynamic>.from(e)))
        .toList();
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(extra: {'translatorDetails': leg}),
      res.headers,
      res.statusCode,
    );
  }

  List? translatorDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.translatorDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetbookbytranslatorApiCall {
  Future<ApiCallResponse> call({
    String? translatorId = '',
    String? type = '',
    String? token = '',
  }) async {
    return _booksForTranslator(
      translatorId: translatorId ?? '',
      type: type,
      token: token,
    );
  }

  List? bookDetailsList(dynamic response) => getJsonField(
        response,
        r'''$.data.bookDetails''',
        true,
      ) as List?;
  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
}

class UnlockBookWithIAPCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? transactionId = '',
    String? productId = '',
    String? format = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    
    final ffApiRequestBody = '''
{
  "transaction_id": "${transactionId}",
  "product_id": "${productId}",
  "format": "${format}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UnlockBookWithIAP',
      apiUrl: '${baseUrl}books/${bookId}/unlock-iap',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      alwaysAllowBody: false,
    );
  }
}

class UnlockChapterWithIAPCall {
  Future<ApiCallResponse> call({
    String? trackId = '',
    String? bookId = '',
    String? transactionId = '',
    String? productId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl();
    
    final ffApiRequestBody = '''
{
  "book_id": "${bookId}",
  "transaction_id": "${transactionId}",
  "product_id": "${productId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UnlockChapterWithIAP',
      apiUrl: '${baseUrl}chapters/${trackId}/unlock-iap',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      alwaysAllowBody: false,
    );
  }
}

