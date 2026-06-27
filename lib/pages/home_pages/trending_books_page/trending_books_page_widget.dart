import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_trending_book_yet/no_trending_book_yet_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'trending_books_page_model.dart';
export 'trending_books_page_model.dart';

class TrendingBooksPageWidget extends StatefulWidget {
  const TrendingBooksPageWidget({
    super.key,
    this.type,
    this.title,
  });

  final String? type;
  final String? title;

  static String routeName = 'TrendingBooksPage';
  static String routePath = '/trendingBooksPage';

  @override
  State<TrendingBooksPageWidget> createState() =>
      _TrendingBooksPageWidgetState();
}

class _TrendingBooksPageWidgetState extends State<TrendingBooksPageWidget> {
  late TrendingBooksPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String get _cacheKey => 'trending_${widget.type ?? 'all'}';

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  bool _shouldShowApiMessage(ApiCallResponse response) {
    final success =
        EbookGroup.getTrendingBooksApiCall.success(response.jsonBody);
    final message =
        EbookGroup.getTrendingBooksApiCall.message(response.jsonBody) ?? '';
    return success != 1 && message.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrendingBooksPageModel());
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
      final res = await EbookGroup.getTrendingBooksApiCall.call(
        type: widget.type,
        limit: _limit,
        offset: _offset,
      );
      final newBooks =
          EbookGroup.getTrendingBooksApiCall.bookDetailsList(res.jsonBody) ??
              [];
      if (newBooks.length < _limit) {
        _hasMore = false;
      }
      setState(() {
        if (isFirstLoad) {
          _books.clear();
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
      });
    } catch (e) {
      debugPrint('Error loading trending books pagination: $e');
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
      debugPrint('Error loading purchased books: $e');
    }
  }

  @override
  void dispose() {
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 21.0, 16.0, 18.0),
                  child: Row(
                     mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.safePop();
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGrey,
                            shape: BoxShape.circle,
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/arrow_back_appbar_ic.svg',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        valueOrDefault<String>(
                          widget.title,
                          'Trending books',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 24.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              lineHeight: 1.5,
                            ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          FFAppState().authorId = [];
                          FFAppState().categoryId = [];
                          FFAppState().update(() {});

                          context.pushNamed(FilterPageWidget.routeName);
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGrey,
                            shape: BoxShape.circle,
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/filter.svg',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
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
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                            ),
                            child: Builder(
                              builder: (context) {
                                if (_books.isEmpty && _isLoading) {
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
                                if (_books.isEmpty) {
                                  return wrapWithModel(
                                    model: _model.noTrendingBookYetModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: const NoTrendingBookYetWidget(),
                                  );
                                }

                                return RefreshIndicator(
                                  key: const Key('RefreshIndicator_hjida7o9'),
                                  color: FlutterFlowTheme.of(context).primary,
                                  onRefresh: () async {
                                    setState(() {
                                      _books.clear();
                                      _offset = 0;
                                      _hasMore = true;
                                    });
                                    await _loadMoreBooks(isFirstLoad: true);
                                  },
                                  child: ListView(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 16.0),
                                    scrollDirection: Axis.vertical,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                        child: Builder(
                                          builder: (context) {
                                            final trendingBooksList = _books;
                                            final screenWidth = MediaQuery.sizeOf(context).width;
                                            final crossAxisCount = screenWidth < 810.0
                                                ? 3
                                                : screenWidth < 1280.0
                                                    ? 4
                                                    : 6;

                                            return GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                crossAxisSpacing: 16.0,
                                                mainAxisSpacing: 16.0,
                                                mainAxisExtent: 240.0,
                                              ),
                                              itemCount: trendingBooksList.length,
                                              itemBuilder: (context, trendingBooksListIndex) {
                                                final trendingBooksListItem = trendingBooksList[trendingBooksListIndex];
                                                return wrapWithModel(
                                                  model: _model.mainBookComponentModels.getModel(
                                                    getJsonField(trendingBooksListItem, r'''$.name''').toString(),
                                                    trendingBooksListIndex,
                                                  ),
                                                  updateCallback: () => safeSetState(() {}),
                                                  child: MainBookComponentWidget(
                                                    key: Key('Keyush_${getJsonField(trendingBooksListItem, r'''$.name''').toString()}'),
                                                    image: '${FFAppConstants.bookImagesUrl}${getJsonField(trendingBooksListItem, r'''$.image''').toString()}',
                                                    bookName: getJsonField(trendingBooksListItem, r'''$.name''').toString(),
                                                    id: getJsonField(trendingBooksListItem, r'''$._id''').toString(),
                                                    price: getJsonField(trendingBooksListItem, r'''$.price''').toString(),
                                                    bookType: getJsonField(trendingBooksListItem, r'''$.type''')?.toString(),
                                                    discountAmount: getJsonField(trendingBooksListItem, r'''$.discount_amount''').toString(),
                                                    discountPercentage: getJsonField(trendingBooksListItem, r'''$.discount_percentage''').toString(),
                                                    authorsName: getJsonField(trendingBooksListItem, r'''$.author.name''').toString(),
                                                    isFav: functions.checkFavOrNot(
                                                          EbookGroup.getFavouriteBookCall
                                                              .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                              ?.toList(),
                                                          getJsonField(trendingBooksListItem, r'''$._id''').toString()) ==
                                                      true,
                                                    indicator: (trendingBooksListIndex == _model.trendingIndex) && (_model.isTrendingBook == true),
                                                    isFavAction: () async {
                                                      if (FFAppState().isLogin == true) {
                                                        _model.isTrendingBook = true;
                                                        _model.trendingIndex = trendingBooksListIndex;
                                                        safeSetState(() {});
                                                        if (functions.checkFavOrNot(
                                                              EbookGroup.getFavouriteBookCall
                                                                  .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                                  ?.toList(),
                                                              getJsonField(trendingBooksListItem, r'''$._id''').toString()) ==
                                                          true) {
                                                          _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                            userId: FFAppState().userId,
                                                            token: FFAppState().token,
                                                            bookId: getJsonField(trendingBooksListItem, r'''$._id''').toString(),
                                                          );

                                                          safeSetState(() {
                                                            FFAppState().clearGetFavouriteBookCacheCache();
                                                            _model.apiRequestCompleted1 = false;
                                                          });
                                                          await _model.waitForApiRequestCompleted1();
                                                          await actions.showCustomToastBottom(FFAppState().unFavText);
                                                        } else {
                                                          _model.getPopularAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                            userId: FFAppState().userId,
                                                            token: FFAppState().token,
                                                            bookId: getJsonField(trendingBooksListItem, r'''$._id''').toString(),
                                                          );

                                                          safeSetState(() {
                                                            FFAppState().clearGetFavouriteBookCacheCache();
                                                            _model.apiRequestCompleted1 = false;
                                                          });
                                                          await _model.waitForApiRequestCompleted1();
                                                          await actions.showCustomToastBottom(FFAppState().favText);
                                                        }

                                                        FFAppState().clearGetFavouriteBookCacheCache();
                                                        _model.isTrendingBook = false;
                                                        safeSetState(() {});
                                                      } else {
                                                        FFAppState().favChange = true;
                                                        FFAppState().bookId = getJsonField(trendingBooksListItem, r'''$._id''').toString();
                                                        FFAppState().update(() {});
                                                        context.pushNamed(SignInPageWidget.routeName);
                                                      }
                                                      safeSetState(() {});
                                                    },
                                                    isPurchased: _model.purchasedBookIds.contains(getJsonField(trendingBooksListItem, r'''$._id''').toString()),
                                                    isMainTap: () async {
                                                      context.pushNamed(
                                                        BookDetailspageWidget.routeName,
                                                        queryParameters: {
                                                          'name': serializeParam(getJsonField(trendingBooksListItem, r'''$.name''').toString(), ParamType.String),
                                                          'price': serializeParam(getJsonField(trendingBooksListItem, r'''$.price''').toString(), ParamType.String),
                                                          'image': serializeParam('${FFAppConstants.bookImagesUrl}${getJsonField(trendingBooksListItem, r'''$.image''').toString()}', ParamType.String),
                                                          'id': serializeParam(getJsonField(trendingBooksListItem, r'''$._id''').toString(), ParamType.String),
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Center(
                                            child: SizedBox(
                                              width: 30.0,
                                              height: 30.0,
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
