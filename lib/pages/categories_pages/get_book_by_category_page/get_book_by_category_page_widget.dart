import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/empty_components/no_categories_yet/no_categories_yet_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'get_book_by_category_page_model.dart';
export 'get_book_by_category_page_model.dart';

class GetBookByCategoryPageWidget extends StatefulWidget {
  const GetBookByCategoryPageWidget({
    super.key,
    required this.name,
    required this.id,
  });

  final String? name;
  final String? id;

  static String routeName = 'GetBookByCategoryPage';
  static String routePath = '/getBookByCategoryPage';

  @override
  State<GetBookByCategoryPageWidget> createState() =>
      _GetBookByCategoryPageWidgetState();
}

class _GetBookByCategoryPageWidgetState
    extends State<GetBookByCategoryPageWidget> {
  late GetBookByCategoryPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String _resolveBookType(dynamic book) {
    final type = getJsonField(book, r'''$.type''') ??
        getJsonField(book, r'''$.bookType''') ??
        getJsonField(book, r'''$.book_type''');
    return (type?.toString() ?? '').toLowerCase();
  }

  bool _isAudiobook(dynamic book) {
    final type = _resolveBookType(book);
    return type.contains('audio');
  }

  double _parseRating(dynamic raw) {
    if (raw == null) {
      return 0.0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GetBookByCategoryPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
      }
      safeSetState(() {});
    });
  }

  Future<void> _loadPurchasedBooks() async {
    try {
      final response = await EbookGroup.userBookPurchaseRecordsApiCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      );

      if (EbookGroup.userBookPurchaseRecordsApiCall.success(
            response.jsonBody ?? '',
          ) ==
          1) {
        final bookIds = EbookGroup.userBookPurchaseRecordsApiCall.bookId(
          response.jsonBody ?? '',
        );
        _model.purchasedBookIds = bookIds ?? [];
        safeSetState(() {});
      }
    } catch (e) {
      debugPrint('Error loading purchased books: $e');
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: widget.name,
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: FFAppState()
                            .getFavouriteBookCache(
                          requestFn: () => EbookGroup.getFavouriteBookCall.call(
                            userId: FFAppState().userId,
                            token: FFAppState().token,
                          ),
                        )
                            .then((result) {
                          _model.apiRequestCompleted1 = true;
                          return result;
                        }),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final containerGetFavouriteBookResponse =
                              snapshot.data!;

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(),
                            child: FutureBuilder<ApiCallResponse>(
                              future: (_model.apiRequestCompleter2 ??=
                                      Completer<ApiCallResponse>()
                                        ..complete(EbookGroup
                                            .getbookbycategoryApiCall
                                            .call(
                                          categoryId: widget.id,
                                        )))
                                  .future,
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context).primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final containerGetbookbycategoryApiResponse =
                                    snapshot.data!;

                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(),
                                  child: Builder(
                                    builder: (context) {
                                      if (EbookGroup.getbookbycategoryApiCall
                                              .success(
                                            containerGetbookbycategoryApiResponse
                                                .jsonBody,
                                          ) ==
                                          2) {
                                        return Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            child: Text(
                                              valueOrDefault<String>(
                                                EbookGroup
                                                    .getbookbycategoryApiCall
                                                    .message(
                                                  containerGetbookbycategoryApiResponse
                                                      .jsonBody,
                                                ),
                                                'Message',
                                              ),
                                              textAlign: TextAlign.center,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        fontSize: 18.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        lineHeight: 1.5,
                                                      ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Builder(
                                          builder: (context) {
                                            if (EbookGroup
                                                        .getbookbycategoryApiCall
                                                        .bookDetailsList(
                                                      containerGetbookbycategoryApiResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (EbookGroup
                                                        .getbookbycategoryApiCall
                                                        .bookDetailsList(
                                                  containerGetbookbycategoryApiResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty) {
                                              return RefreshIndicator(
                                                key: Key(
                                                    'RefreshIndicator_b552okc7'),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                onRefresh: () async {
                                                  safeSetState(() => _model
                                                          .apiRequestCompleter2 =
                                                      null);
                                                  await _model
                                                      .waitForApiRequestCompleted2();
                                                },
                                                child: Builder(
                                                  builder: (context) {
                                                    final bookDetailsList =
                                                        EbookGroup
                                                                .getbookbycategoryApiCall
                                                                .bookDetailsList(
                                                                  containerGetbookbycategoryApiResponse
                                                                      .jsonBody,
                                                                )
                                                                ?.toList() ??
                                                            [];

                                                    return ListView.separated(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                        0,
                                                        16.0,
                                                        0,
                                                        16.0,
                                                      ),
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      itemCount: bookDetailsList
                                                          .length,
                                                      separatorBuilder:
                                                          (_, __) => SizedBox(
                                                        height: 16.0,
                                                      ),
                                                      itemBuilder: (context,
                                                          bookDetailsListIndex) {
                                                        final bookDetailsListItem =
                                                            bookDetailsList[
                                                                bookDetailsListIndex];
                                                        return Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      16.0,
                                                                      0.0,
                                                                      16.0,
                                                                      0.0),
                                                          child: wrapWithModel(
                                                            model: _model
                                                                .listMainContainerComponentModels
                                                                .getModel(
                                                              getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString(),
                                                              bookDetailsListIndex,
                                                            ),
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                ListMainContainerComponentWidget(
                                                              key: Key(
                                                                'Keyy2y_${getJsonField(
                                                                  bookDetailsListItem,
                                                                  r'''$.name''',
                                                                ).toString()}',
                                                              ),
                                                              image:
                                                                  '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.image''',
                                                              ).toString()}',
                                                              price:
                                                                  '${getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.price''',
                                                              ).toString()}',
                                                              bookType:
                                                                  getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.type''',
                                                              )?.toString(),
                                                              discountAmount:
                                                                  getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.discount_amount''',
                                                              ).toString(),
                                                              discountPercentage:
                                                                  getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.discount_percentage''',
                                                              ).toString(),
                                                              id: getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                              name:
                                                                  getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString(),
                                                              authorName:
                                                                  getJsonField(
                                                                bookDetailsListItem,
                                                                r'''$.author.name''',
                                                              ).toString(),
                                                              averageRating:
                                                                  _parseRating(
                                                                getJsonField(
                                                                  bookDetailsListItem,
                                                                  r'''$.averageRating''',
                                                                ),
                                                              ),
                                                              isFav: functions.checkFavOrNot(
                                                                      EbookGroup.getFavouriteBookCall
                                                                          .favouriteBookDetailsList(
                                                                            containerGetFavouriteBookResponse.jsonBody,
                                                                          )
                                                                          ?.toList(),
                                                                      getJsonField(
                                                                        bookDetailsListItem,
                                                                        r'''$._id''',
                                                                      ).toString()) ==
                                                                  true,
                                                              indicator: (bookDetailsListIndex ==
                                                                      _model
                                                                          .categoryBookIndex) &&
                                                                  (_model.isCategoryBook ==
                                                                      true),
                                                              width: double
                                                                  .infinity,
                                                              isPurchased: _model
                                                                  .purchasedBookIds
                                                                  .contains(
                                                                getJsonField(
                                                                  bookDetailsListItem,
                                                                  r'''$._id''',
                                                                ).toString(),
                                                              ),
                                                              isFavAction:
                                                                  () async {
                                                                if (FFAppState()
                                                                        .isLogin ==
                                                                    true) {
                                                                  _model.isCategoryBook =
                                                                      true;
                                                                  _model.categoryBookIndex =
                                                                      bookDetailsListIndex;
                                                                  safeSetState(
                                                                      () {});
                                                                  if (functions.checkFavOrNot(
                                                                          EbookGroup.getFavouriteBookCall
                                                                              .favouriteBookDetailsList(
                                                                                containerGetFavouriteBookResponse.jsonBody,
                                                                              )
                                                                              ?.toList(),
                                                                          getJsonField(
                                                                            bookDetailsListItem,
                                                                            r'''$._id''',
                                                                          ).toString()) ==
                                                                      true) {
                                                                    _model.getPopularDetete =
                                                                        await EbookGroup
                                                                            .removeFavouritebookCall
                                                                            .call(
                                                                      userId: FFAppState()
                                                                          .userId,
                                                                      token: FFAppState()
                                                                          .token,
                                                                      bookId:
                                                                          getJsonField(
                                                                        bookDetailsListItem,
                                                                        r'''$._id''',
                                                                      ).toString(),
                                                                    );

                                                                    safeSetState(
                                                                        () {
                                                                      FFAppState()
                                                                          .clearGetFavouriteBookCacheCache();
                                                                      _model.apiRequestCompleted1 =
                                                                          false;
                                                                    });
                                                                    await _model
                                                                        .waitForApiRequestCompleted1();
                                                                    await actions
                                                                        .showCustomToastBottom(
                                                                      FFAppState()
                                                                          .unFavText,
                                                                    );
                                                                  } else {
                                                                    _model.getPopularAdd =
                                                                        await EbookGroup
                                                                            .addFavouriteBookApiCall
                                                                            .call(
                                                                      userId: FFAppState()
                                                                          .userId,
                                                                      token: FFAppState()
                                                                          .token,
                                                                      bookId:
                                                                          getJsonField(
                                                                        bookDetailsListItem,
                                                                        r'''$._id''',
                                                                      ).toString(),
                                                                    );

                                                                    safeSetState(
                                                                        () {
                                                                      FFAppState()
                                                                          .clearGetFavouriteBookCacheCache();
                                                                      _model.apiRequestCompleted1 =
                                                                          false;
                                                                    });
                                                                    await _model
                                                                        .waitForApiRequestCompleted1();
                                                                    await actions
                                                                        .showCustomToastBottom(
                                                                      FFAppState()
                                                                          .favText,
                                                                    );
                                                                  }

                                                                  FFAppState()
                                                                      .clearGetFavouriteBookCacheCache();
                                                                  _model.isCategoryBook =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  FFAppState()
                                                                          .favChange =
                                                                      true;
                                                                  FFAppState()
                                                                          .bookId =
                                                                      getJsonField(
                                                                    bookDetailsListItem,
                                                                    r'''$._id''',
                                                                  ).toString();
                                                                  FFAppState()
                                                                      .update(
                                                                          () {});

                                                                  context.pushNamed(
                                                                      SignInPageWidget
                                                                          .routeName);
                                                                }

                                                                safeSetState(
                                                                    () {});
                                                              },
                                                              onMainTap:
                                                                  () async {
                                                                if (_isAudiobook(
                                                                    bookDetailsListItem)) {
                                                                  final imagePath =
                                                                      getJsonField(
                                                                    bookDetailsListItem,
                                                                    r'''$.image''',
                                                                  )?.toString();
                                                                  // final imageUrl = (imagePath ??
                                                                  //             '')
                                                                  //         .startsWith(
                                                                  //             'http')
                                                                  //     ? imagePath
                                                                  //     : '${FFAppConstants.bookImagesUrl}${imagePath ?? ''}';
                                                                  // context
                                                                  //     .pushNamed(
                                                                  //   AudiobookDetailsPageWidget
                                                                  //       .routeName,
                                                                  //   extra: <String,
                                                                  //       dynamic>{
                                                                  //     'audiobook':
                                                                  //         {
                                                                  //       'id':
                                                                  //           getJsonField(
                                                                  //         bookDetailsListItem,
                                                                  //         r'''$._id''',
                                                                  //       )?.toString(),
                                                                  //       'title':
                                                                  //           getJsonField(
                                                                  //         bookDetailsListItem,
                                                                  //         r'''$.name''',
                                                                  //       )?.toString(),
                                                                  //       'author':
                                                                  //           getJsonField(
                                                                  //         bookDetailsListItem,
                                                                  //         r'''$.author.name''',
                                                                  //       )?.toString(),
                                                                  //       'image':
                                                                  //           imageUrl,
                                                                  //       'price':
                                                                  //           getJsonField(
                                                                  //         bookDetailsListItem,
                                                                  //         r'''$.price''',
                                                                  //       ),
                                                                  //       'raw':
                                                                  //           bookDetailsListItem,
                                                                  //     },
                                                                  //   },
                                                                  // );
                                                                } else {
                                                                  context
                                                                      .pushNamed(
                                                                    BookDetailspageWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'name':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.name''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                      'price':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.price''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                      'image':
                                                                          serializeParam(
                                                                        '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.image''',
                                                                        ).toString()}',
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                      'id':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$._id''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              );
                                            } else {
                                              return wrapWithModel(
                                                model:
                                                    _model.noCategoriesYetModel,
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: NoCategoriesYetWidget(),
                                              );
                                            }
                                          },
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    } else {
                      return Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Lottie.asset(
                          'assets/jsons/No_Wifi.json',
                          width: 150.0,
                          height: 150.0,
                          fit: BoxFit.contain,
                          animate: true,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
