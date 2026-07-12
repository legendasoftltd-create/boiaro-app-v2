import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubCategoriesScreenModel());
    selectedId = widget.id; // Initialize with category id for "All"
    _scrollController.addListener(_onScroll);
    _loadMoreBooks(isFirstLoad: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
      }
      safeSetState(() {});
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadMoreBooks({bool isFirstLoad = false}) async {
    if (_isLoading || (!_hasMore && !isFirstLoad)) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final ApiCallResponse res;
      if (isAllSelected) {
        res = await EbookGroup.getbookbycategoryApiCall.call(
          categoryId: widget.id,
          limit: _limit,
          cursor: isFirstLoad ? null : _nextCursor,
        );
      } else {
        res = await EbookGroup.getbookbysubcategoryApiCall.call(
          subcategoryId: selectedId,
          limit: _limit,
          cursor: isFirstLoad ? null : _nextCursor,
        );
      }

      final newBooks = (isAllSelected
              ? EbookGroup.getbookbycategoryApiCall.bookDetailsList(res.jsonBody)
              : EbookGroup.getbookbysubcategoryApiCall.bookDetailsList(res.jsonBody)) ??
          [];
      final nextCursorVal = isAllSelected
          ? EbookGroup.getbookbycategoryApiCall.nextCursor(res.jsonBody)
          : EbookGroup.getbookbysubcategoryApiCall.nextCursor(res.jsonBody);

      setState(() {
        if (isFirstLoad) {
          _books.clear();
          _offset = 0;
        }
        final existingIds = _books
            .map((book) => getJsonField(book, r'''$._id''')?.toString())
            .where((id) => id != null)
            .toSet();
        for (final book in newBooks) {
          final bookId = getJsonField(book, r'''$._id''')?.toString();
          if (bookId == null || !existingIds.contains(bookId)) {
            _books.add(book);
            if (bookId != null) {
              existingIds.add(bookId);
            }
          }
        }
        _offset += newBooks.length;
        _nextCursor = nextCursorVal;
        if (_nextCursor == null || _nextCursor!.isEmpty) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }
      });

      // Auto load next page if content doesn't fill screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasMore && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0) {
          _loadMoreBooks();
        }
      });
    } catch (e) {
      // Error loading subcategories books
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      // Error loading purchased books
    }
  }

  void _selectAll() {
    setState(() {
      isAllSelected = true;
      selectedId = widget.id;
      _offset = 0;
      _nextCursor = null;
      _hasMore = true;
    });
    _loadMoreBooks(isFirstLoad: true);
  }

  void _selectSubcategory(String id, String name) {
    setState(() {
      isAllSelected = false;
      selectedId = id;
      _offset = 0;
      _nextCursor = null;
      _hasMore = true;
    });
    _loadMoreBooks(isFirstLoad: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
                                            child: Text(FFLocalizations.of(context).getVariableText(enText: 'All', bnText: 'সব'),
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
                                    if (_books.isEmpty && _isLoading) {
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

                                    if (_books.isEmpty) {
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
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Builder(
                                              builder: (context) {
                                                final screenWidth =
                                                    MediaQuery.sizeOf(context)
                                                        .width;
                                                final crossAxisCount =
                                                    screenWidth < 810.0
                                                        ? 3
                                                        : screenWidth < 1280.0
                                                            ? 4
                                                            : 6;

                                                return GridView.builder(
                                                  controller: _scrollController,
                                                  padding: EdgeInsets.fromLTRB(
                                                      16.0, 16.0, 16.0, 16.0),
                                                  physics:
                                                      AlwaysScrollableScrollPhysics(),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount:
                                                        crossAxisCount,
                                                    crossAxisSpacing: 8.0,
                                                    mainAxisSpacing: 8.0,
                                                    mainAxisExtent: 235,
                                                  ),
                                                  itemCount: _books.length,
                                                  itemBuilder: (context,
                                                      bookDetailsListIndex) {
                                                    final bookItem =
                                                        _books[
                                                            bookDetailsListIndex];
                                                    return wrapWithModel(
                                                      model: _model
                                                          .mainBookComponentModels
                                                          .getModel(
                                                        getJsonField(
                                                                bookItem,
                                                                r'''$.name''')
                                                            .toString(),
                                                        bookDetailsListIndex,
                                                      ),
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          MainBookComponentWidget(
                                                        key: Key(
                                                          'Key59m_${getJsonField(bookItem, r'''$.name''').toString()}',
                                                        ),
                                                        imageHeight: 155.0,
                                                        image:
                                                            '${isAllSelected ? FFAppConstants.bookImagesUrl : FFAppConstants.imageUrl}${getJsonField(bookItem, r'''$.image''').toString()}',
                                                        bookName: getJsonField(
                                                                bookItem,
                                                                r'''$.name''')
                                                            .toString(),
                                                        id: getJsonField(
                                                                bookItem,
                                                                r'''$._id''')
                                                            .toString(),
                                                        price: getJsonField(
                                                                bookItem,
                                                                r'''$.price''')
                                                            .toString(),
                                                        bookType: getJsonField(
                                                                bookItem,
                                                                r'''$.type''')
                                                            ?.toString(),
                                                        discountPercentage:
                                                            getJsonField(
                                                                    bookItem,
                                                                    r'''$.discount_percentage''')
                                                                .toString(),
                                                        discountAmount:
                                                            getJsonField(
                                                                    bookItem,
                                                                    r'''$.discount_amount''')
                                                                .toString(),
                                                        authorsName:
                                                            'By ${getJsonField(bookItem, r'''$.author.name''').toString()}',
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
                                                        isFavAction:
                                                            () async {
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
                                                                  ParamType.String),
                                                              'id': serializeParam(
                                                                  getJsonField(
                                                                    bookItem,
                                                                    r'''$._id''',
                                                                  ).toString(),
                                                                  ParamType.String),
                                                            }.withoutNulls,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          if (_isLoading)
                                            Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: SizedBox(
                                                  width: 32.0,
                                                  height: 32.0,
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      FlutterFlowTheme.of(context).primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
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
