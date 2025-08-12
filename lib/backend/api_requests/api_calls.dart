import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start Ebook Group Code

class EbookGroup {
  static String getBaseUrl({
    String? token = '',
  }) =>
      'https://ebook.templatevictory.com/api/';
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
  static GetauthordetailsApiCall getauthordetailsApiCall =
      GetauthordetailsApiCall();
  static GetLatestbooksApiCall getLatestbooksApiCall = GetLatestbooksApiCall();
  static GetbookdetailsApiCall getbookdetailsApiCall = GetbookdetailsApiCall();
  static GetbookbyauthorApiCall getbookbyauthorApiCall =
      GetbookbyauthorApiCall();
  static GetbookbycategoryApiCall getbookbycategoryApiCall =
      GetbookbycategoryApiCall();
  static GetbookbysubcategoryApiCall getbookbysubcategoryApiCall =
      GetbookbysubcategoryApiCall();
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
  static GetTrendingBooksApiCall getTrendingBooksApiCall =
      GetTrendingBooksApiCall();
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
}

class CheckregistereduserApiCall {
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
      callName: 'CheckregistereduserApi',
      apiUrl: '${baseUrl}checkregistereduser',
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
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "firstname": "${firstname}",
  "lastname": "${lastname}",
  "username": "${username}",
  "country_code": "${countryCode}",
  "phone": "${phone}",
  "email": "${email}",
  "password": "${password}",
  "registrationToken": "${registrationToken}",
  "deviceId": "${deviceId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SignupApi',
      apiUrl: '${baseUrl}signup',
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

class UserverificationApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    int? otp,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}",
  "otp": ${otp}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UserverificationApi',
      apiUrl: '${baseUrl}otp_verification',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}",
  "password": "${password}",
  "registrationToken": "${registrationToken}",
  "deviceId": "${deviceId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SigninApi',
      apiUrl: '${baseUrl}signin',
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
}

class ForgotpasswordApiCall {
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
      callName: 'ForgotpasswordApi',
      apiUrl: '${baseUrl}forgotpassword',
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

class ForgotpasswordverificationApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    int? otp,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}",
  "otp": ${otp}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ForgotpasswordverificationApi',
      apiUrl: '${baseUrl}forgotpasswordverification',
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

class ResetpasswordApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? newpassword = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}",
  "newpassword": "${newpassword}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ResetpasswordApi',
      apiUrl: '${baseUrl}resetpassword',
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

class GetuserApiCall {
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
      callName: 'GetuserApi',
      apiUrl: '${baseUrl}getuser',
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

class UsereditprofileApiCall {
  Future<ApiCallResponse> call({
    String? id = '',
    String? firstname = '',
    String? lastname = '',
    String? phone = '',
    String? image = '',
    String? countryCode = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "id": "${id}",
  "firstname": "${firstname}",
  "lastname": "${lastname}",
  "country_code": "${countryCode}",
  "phone": "${phone}",
  "image": "${image}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UsereditprofileApi',
      apiUrl: '${baseUrl}usereditprofile',
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
      apiUrl: '${baseUrl}uploadimage',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'image': image,
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}",
  "deviceId": "${deviceId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SignoutApi',
      apiUrl: '${baseUrl}signout',
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

class GetcategoriesApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetcategoriesApi',
      apiUrl: '${baseUrl}getcategories',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetauthorsApi',
      apiUrl: '${baseUrl}getauthors',
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

class GetauthordetailsApiCall {
  Future<ApiCallResponse> call({
    String? authorId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "authorId": "${authorId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetauthordetailsApi',
      apiUrl: '${baseUrl}getauthordetails',
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

class GetLatestbooksApiCall {
  Future<ApiCallResponse> call({
    List<String>? authorIdList,
    List<String>? categoryIdList,
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );
    final authorId = _serializeList(authorIdList);
    final categoryId = _serializeList(categoryIdList);

    final ffApiRequestBody = '''
{
 
  "authorId": ${authorId},
  "categoryId": ${categoryId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetLatestbooksApi',
      apiUrl: '${baseUrl}getbooks',
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
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "bookId": "${bookId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetbookdetailsApi',
      apiUrl: '${baseUrl}getbookdetails',
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
  String? pdf(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].pdf''',
      ));
  String? categoryId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].category._id''',
      ));
  String? categoryName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.bookDetails[:].category.name''',
      ));
  int? download(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.bookDetails[:].download''',
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
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "authorId": "${authorId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetbookbyauthorApi',
      apiUrl: '${baseUrl}getbookbyauthor',
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
      callName: 'GetbookbycategoryApi',
      apiUrl: '${baseUrl}getbookbycategory',
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
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "subcategoryId": "${subcategoryId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetbookbysubcategoryApi',
      apiUrl: '${baseUrl}getbookbysubcategory',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetsubscriptionplanApi',
      apiUrl: '${baseUrl}getsubscriptionplan',
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
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}",
  "subscriptionplanId": "${subscriptionplanId}",
  "paymentmode": "${paymentmode}",
  "transactionId": "${transactionId}",
  "paymentstatus": "${paymentstatus}",
  "paymentdate": "${paymentdate}",
  "price": "${price}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UsersubscriptionApi',
      apiUrl: '${baseUrl}usersubscription',
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

class UsersubscriptionrecordApiCall {
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
      callName: 'UsersubscriptionrecordApi',
      apiUrl: '${baseUrl}usersubscriptionrecord',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UsersubscriptionvalidityApi',
      apiUrl: '${baseUrl}usersubscriptionvalidity',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "bookId": "${bookId}",
  "userId": "${userId}",
  "description": "${description}",
  "date": "${date}",
  "time": "${time}",
  "rating": ${rating}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AddreviewApi',
      apiUrl: '${baseUrl}addreview',
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

class GetreviewApiCall {
  Future<ApiCallResponse> call({
    String? bookId = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "bookId": "${bookId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetreviewApi',
      apiUrl: '${baseUrl}getreview',
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

  List<String>? date(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookReviewDetails[:].reviews[:].date''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<double>? rating(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookReviewDetails[:].reviews[:].rating''',
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
        r'''$.data.bookReviewDetails[:].reviews''',
        true,
      ) as List?;
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
}

class GetTrendingBooksApiCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetTrendingBooksApi',
      apiUrl: '${baseUrl}gettrendingbooks',
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

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  List<String>? averageRating(dynamic response) => (getJsonField(
        response,
        r'''$.data.bookDetails[:].averageRating''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
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
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetPopularBooksApi',
      apiUrl: '${baseUrl}getpopularbooks',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}",
  "bookId": "${bookId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AddFavouriteBookApi',
      apiUrl: '${baseUrl}addfavouritebook',
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
}

class GetFavouriteBookCall {
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
      callName: 'GetFavouriteBook',
      apiUrl: '${baseUrl}getfavouritebook',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}",
  "bookId": "${bookId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'RemoveFavouritebook',
      apiUrl: '${baseUrl}removefavouritebook',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'DownloadhistoryApi',
      apiUrl: '${baseUrl}downloadhistory',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "userId": "${userId}",
  "bookId": "${bookId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'DownloadpdfApi',
      apiUrl: '${baseUrl}downloadpdf',
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

class SearchApiCall {
  Future<ApiCallResponse> call({
    String? search = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "search": "${search}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SearchApi',
      apiUrl: '${baseUrl}getbooks',
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
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'LatestAllBookApi',
      apiUrl: '${baseUrl}getbooks',
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
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetnotificationApi',
      apiUrl: '${baseUrl}getnotification',
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

class ChangepasswordApiCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
    String? token = '',
  }) async {
    final baseUrl = EbookGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "email": "${email}",
  "password": "${password}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ChangepasswordApi',
      apiUrl: '${baseUrl}changepassword',
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
