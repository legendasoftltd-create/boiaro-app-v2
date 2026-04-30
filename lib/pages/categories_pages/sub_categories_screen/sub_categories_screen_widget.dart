import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_categories_yet/no_categories_yet_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'sub_categories_screen_model.dart';
export 'sub_categories_screen_model.dart';

class SubCategoriesScreenWidget extends StatefulWidget {
  const SubCategoriesScreenWidget({
    super.key,
    required this.id,
    required this.name,
  });

  final String? id;
  final String? name;

  static String routeName = 'SubCategoriesScreen';
  static String routePath = '/subCategoriesScreen';

  @override
  State<SubCategoriesScreenWidget> createState() =>
      _SubCategoriesScreenWidgetState();
}

class _SubCategoriesScreenWidgetState extends State<SubCategoriesScreenWidget> {
  late SubCategoriesScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? selectedId;
  bool isAllSelected = true;
  late Completer<ApiCallResponse> _booksCompleter;

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

  bool _isAudiobookTypeValue(String? type) {
    final normalized = (type ?? '').toLowerCase();
    return normalized.contains('audio');
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubCategoriesScreenModel());
    selectedId = widget.id; // Initialize with category id for "All"
    _booksCompleter = Completer<ApiCallResponse>()
      ..complete(
          EbookGroup.getbookbycategoryApiCall.call(categoryId: widget.id));

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

  void _selectAll() {
    setState(() {
      isAllSelected = true;
      selectedId = widget.id;
      _booksCompleter = Completer<ApiCallResponse>()
        ..complete(
            EbookGroup.getbookbycategoryApiCall.call(categoryId: widget.id));
    });
  }

  void _selectSubcategory(String id, String name) {
    setState(() {
      isAllSelected = false;
      selectedId = id;
      _booksCompleter = Completer<ApiCallResponse>()
        ..complete(
            EbookGroup.getbookbysubcategoryApiCall.call(subcategoryId: id));
    });
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
                        future: (_model.apiRequestCompleter ??=
                                Completer<ApiCallResponse>()
                                  ..complete(EbookGroup
                                      .getsubcategoriesbycategoryApiCall
                                      .call(
                                    categoryId: widget.id,
                                  )))
                            .future,
                        builder: (context, snapshot) {
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
                          final subcategoriesResponse = snapshot.data!;

                          final subcategoryList = EbookGroup
                              .getsubcategoriesbycategoryApiCall
                              .subcategoryDetailsList(
                                  subcategoriesResponse.jsonBody)
                              ?.toList();

                          final hasSubcategories = subcategoryList != null &&
                              subcategoryList.isNotEmpty;

                          return Column(
                            children: [
                              // Only show horizontal categories list if subcategories exist
                              if (hasSubcategories) ...[
                                Container(
                                  height: 40.0,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    children: [
                                      // "All" button
                                      GestureDetector(
                                        onTap: _selectAll,
                                        child: Container(
                                          margin: EdgeInsets.only(right: 10.0),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 8.0),
                                          decoration: BoxDecoration(
                                            color: isAllSelected
                                                ? FlutterFlowTheme.of(context)
                                                    .primary
                                                : FlutterFlowTheme.of(context)
                                                    .gray100,
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'All',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    color: isAllSelected
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Subcategories
                                      ...subcategoryList
                                          .map((subcategory) => GestureDetector(
                                                onTap: () => _selectSubcategory(
                                                  getJsonField(subcategory,
                                                          r'''$._id''')
                                                      .toString(),
                                                  getJsonField(subcategory,
                                                          r'''$.name''')
                                                      .toString(),
                                                ),
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      right: 10.0),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 8.0),
                                                  decoration: BoxDecoration(
                                                    color: !isAllSelected &&
                                                            selectedId ==
                                                                getJsonField(
                                                                        subcategory,
                                                                        r'''$._id''')
                                                                    .toString()
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .primary
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .gray100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      getJsonField(subcategory,
                                                              r'''$.name''')
                                                          .toString(),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                color: !isAllSelected &&
                                                                        selectedId ==
                                                                            getJsonField(subcategory, r'''$._id''')
                                                                                .toString()
                                                                    ? FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                    ),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ],
                              // Books section with favourites
                              Expanded(
                                child: FutureBuilder<ApiCallResponse>(
                                  future: FFAppState().getFavouriteBookCache(
                                    requestFn: () =>
                                        EbookGroup.getFavouriteBookCall.call(
                                      userId: FFAppState().userId,
                                      token: FFAppState().token,
                                    ),
                                  ),
                                  builder: (context, favouritesSnapshot) {
                                    return FutureBuilder<ApiCallResponse>(
                                      future: _booksCompleter.future,
                                      builder: (context, booksSnapshot) {
                                        if (!booksSnapshot.hasData) {
                                          return Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                              ),
                                            ),
                                          );
                                        }
                                        final booksResponse =
                                            booksSnapshot.data!;

                                        final success = isAllSelected
                                            ? EbookGroup
                                                .getbookbycategoryApiCall
                                                .success(booksResponse.jsonBody)
                                            : EbookGroup
                                                .getbookbysubcategoryApiCall
                                                .success(
                                                    booksResponse.jsonBody);

                                        if (success == 2) {
                                          return Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              child: Text(
                                                valueOrDefault<String>(
                                                  isAllSelected
                                                      ? EbookGroup
                                                          .getbookbycategoryApiCall
                                                          .message(booksResponse
                                                              .jsonBody)
                                                      : EbookGroup
                                                          .getbookbysubcategoryApiCall
                                                          .message(booksResponse
                                                              .jsonBody),
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
                                          final bookDetailsList = isAllSelected
                                              ? EbookGroup
                                                  .getbookbycategoryApiCall
                                                  .bookDetailsList(
                                                      booksResponse.jsonBody)
                                                  ?.toList()
                                              : EbookGroup
                                                  .getbookbysubcategoryApiCall
                                                  .bookDetailsList(
                                                      booksResponse.jsonBody)
                                                  ?.toList();

                                          if (bookDetailsList == null ||
                                              bookDetailsList.isEmpty) {
                                            return Center(
                                                child: NoCategoriesYetWidget());
                                          }

                                          return RefreshIndicator(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            onRefresh: () async {
                                              safeSetState(() {
                                                FFAppState()
                                                    .clearGetFavouriteBookCacheCache();
                                              });
                                              await FFAppState()
                                                  .getFavouriteBookCache(
                                                requestFn: () => EbookGroup
                                                    .getFavouriteBookCall
                                                    .call(
                                                  userId: FFAppState().userId,
                                                  token: FFAppState().token,
                                                ),
                                              );
                                              if (isAllSelected) {
                                                _selectAll();
                                              } else {
                                                _selectSubcategory(
                                                    selectedId!, 'Reload');
                                              }
                                            },
                                            child: Builder(
                                              builder: (context) {
                                                final screenWidth =
                                                    MediaQuery.sizeOf(context)
                                                        .width;
                                                final screenHeight =
                                                    MediaQuery.sizeOf(context)
                                                        .height;
                                                final crossAxisCount =
                                                    screenWidth < 810.0
                                                        ? 3
                                                        : screenWidth < 1280.0
                                                            ? 4
                                                            : 6;
                                                final cardHeight =
                                                    screenHeight / screenWidth <
                                                            1.78
                                                        ? 235.0
                                                        : 230.0;
                                                final horizontalPadding = 32.0;
                                                final totalSpacing =
                                                    (crossAxisCount - 1) * 16.0;
                                                final cardWidth = (screenWidth -
                                                        horizontalPadding -
                                                        totalSpacing) /
                                                    crossAxisCount;

                                                return GridView.builder(
                                                  padding: EdgeInsets.fromLTRB(
                                                      16.0, 16.0, 16.0, 16.0),
                                                  physics:
                                                      AlwaysScrollableScrollPhysics(),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount:
                                                        crossAxisCount,
                                                    crossAxisSpacing: 10.0,
                                                    mainAxisSpacing: 10.0,
                                                    mainAxisExtent: 240,
                                                    // childAspectRatio:
                                                    //     cardWidth / cardHeight,
                                                  ),
                                                  itemCount:
                                                      bookDetailsList.length,
                                                  itemBuilder:
                                                      (context, bookIndex) {
                                                    final bookItem =
                                                        bookDetailsList[
                                                            bookIndex];
                                                    final bookTypeValue =
                                                        (getJsonField(
                                                                  bookItem,
                                                                  r'''$.type''',
                                                                ) ??
                                                                getJsonField(
                                                                  bookItem,
                                                                  r'''$.bookType''',
                                                                ) ??
                                                                getJsonField(
                                                                  bookItem,
                                                                  r'''$.book_type''',
                                                                ))
                                                            ?.toString();
                                                    return MainBookComponentWidget(
                                                      key: Key(
                                                          'Key_${getJsonField(bookItem, r'''$._id''').toString()}'),
                                                      image:
                                                          '${isAllSelected ? FFAppConstants.bookImagesUrl : FFAppConstants.bookImagesUrl}${getJsonField(bookItem, r'''$.image''').toString()}',
                                                      price:
                                                          '${getJsonField(bookItem, r'''$.price''').toString()}',
                                                      bookType: bookTypeValue,
                                                      discountAmount: getJsonField(
                                                              bookItem,
                                                              r'''$.discount_amount''')
                                                          .toString(),
                                                      discountPercentage:
                                                          getJsonField(bookItem,
                                                                  r'''$.discount_percentage''')
                                                              .toString(),
                                                      id: '${getJsonField(bookItem, r'''$._id''').toString()}',
                                                      bookName: getJsonField(
                                                              bookItem,
                                                              r'''$.name''')
                                                          .toString(),
                                                      authorsName: getJsonField(
                                                              bookItem,
                                                              r'''$.author.name''')
                                                          .toString(),
                                                      isFav: functions
                                                              .checkFavOrNot(
                                                            EbookGroup
                                                                .getFavouriteBookCall
                                                                .favouriteBookDetailsList(
                                                                  favouritesSnapshot
                                                                      .data
                                                                      ?.jsonBody,
                                                                )
                                                                ?.toList(),
                                                            getJsonField(
                                                                    bookItem,
                                                                    r'''$._id''')
                                                                .toString(),
                                                          ) ==
                                                          true,
                                                      indicator: false,
                                                      isFavAction: () async {
                                                        if (FFAppState()
                                                                .isLogin ==
                                                            true) {
                                                          if (functions
                                                                  .checkFavOrNot(
                                                                EbookGroup
                                                                    .getFavouriteBookCall
                                                                    .favouriteBookDetailsList(
                                                                      favouritesSnapshot
                                                                          .data
                                                                          ?.jsonBody,
                                                                    )
                                                                    ?.toList(),
                                                                getJsonField(
                                                                        bookItem,
                                                                        r'''$._id''')
                                                                    .toString(),
                                                              ) ==
                                                              true) {
                                                            await EbookGroup
                                                                .removeFavouritebookCall
                                                                .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                              bookId: getJsonField(
                                                                      bookItem,
                                                                      r'''$._id''')
                                                                  .toString(),
                                                            );
                                                            safeSetState(() {
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCache();
                                                            });
                                                            await actions
                                                                .showCustomToastBottom(
                                                              FFAppState()
                                                                  .unFavText,
                                                            );
                                                          } else {
                                                            await EbookGroup
                                                                .addFavouriteBookApiCall
                                                                .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                              bookId: getJsonField(
                                                                      bookItem,
                                                                      r'''$._id''')
                                                                  .toString(),
                                                            );
                                                            safeSetState(() {
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCache();
                                                            });
                                                            await actions
                                                                .showCustomToastBottom(
                                                              FFAppState()
                                                                  .favText,
                                                            );
                                                          }
                                                        } else {
                                                          FFAppState()
                                                              .favChange = true;
                                                          FFAppState().bookId =
                                                              getJsonField(
                                                                      bookItem,
                                                                      r'''$._id''')
                                                                  .toString();
                                                          FFAppState()
                                                              .update(() {});
                                                          context.pushNamed(
                                                              SignInPageWidget
                                                                  .routeName);
                                                        }
                                                      },
                                                      isPurchased: _model
                                                          .purchasedBookIds
                                                          .contains(getJsonField(
                                                                  bookItem,
                                                                  r'''$._id''')
                                                              .toString()),
                                                      isMainTap: () async {
                                                        if (_isAudiobookTypeValue(
                                                            bookTypeValue)) {
                                                          final imagePath =
                                                              getJsonField(
                                                            bookItem,
                                                            r'''$.image''',
                                                          )?.toString();
                                                          final imageUrl =
                                                              (imagePath ?? '')
                                                                      .startsWith(
                                                                          'http')
                                                                  ? imagePath
                                                                  : '${FFAppConstants.bookImagesUrl}${imagePath ?? ''}';
                                                          context.pushNamed(
                                                            AudiobookDetailsPageWidget
                                                                .routeName,
                                                            extra: <String,
                                                                dynamic>{
                                                              'audiobook': {
                                                                'id':
                                                                    getJsonField(
                                                                  bookItem,
                                                                  r'''$._id''',
                                                                )?.toString(),
                                                                'title':
                                                                    getJsonField(
                                                                  bookItem,
                                                                  r'''$.name''',
                                                                )?.toString(),
                                                                'author':
                                                                    getJsonField(
                                                                  bookItem,
                                                                  r'''$.author.name''',
                                                                )?.toString(),
                                                                'image':
                                                                    imageUrl,
                                                                'price':
                                                                    getJsonField(
                                                                  bookItem,
                                                                  r'''$.price''',
                                                                ),
                                                                'raw': bookItem,
                                                              },
                                                            },
                                                          );
                                                        } else {
                                                          context.pushNamed(
                                                            BookDetailspageWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'name': serializeParam(
                                                                  getJsonField(
                                                                    bookItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  ParamType.String),
                                                              'price': serializeParam(
                                                                  getJsonField(
                                                                    bookItem,
                                                                    r'''$.price''',
                                                                  ).toString(),
                                                                  ParamType.String),
                                                              'image': serializeParam(
                                                                  '${isAllSelected ? FFAppConstants.bookImagesUrl : FFAppConstants.imageUrl}${getJsonField(bookItem, r'''$.image''').toString()}',
                                                                  ParamType
                                                                      .String),
                                                              'id': serializeParam(
                                                                  getJsonField(
                                                                    bookItem,
                                                                    r'''$._id''',
                                                                  ).toString(),
                                                                  ParamType.String),
                                                            }.withoutNulls,
                                                          );
                                                        }
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
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
