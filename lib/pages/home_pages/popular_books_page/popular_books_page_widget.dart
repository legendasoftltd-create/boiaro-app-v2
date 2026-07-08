import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_popular_book/no_popular_book_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'popular_books_page_model.dart';
export 'popular_books_page_model.dart';

import '/flutter_flow/internationalization.dart';
class PopularBooksPageWidget extends StatefulWidget {
  const PopularBooksPageWidget({
    super.key,
    this.type,
    this.sectionKey,
    this.title,
  });

  final String? type;
  final String? sectionKey;
  final String? title;

  static String routeName = 'PopularBooksPage';
  static String routePath = '/popularBooksPage';

  @override
  State<PopularBooksPageWidget> createState() => _PopularBooksPageWidgetState();
}

class _PopularBooksPageWidgetState extends State<PopularBooksPageWidget> {
  late PopularBooksPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String get _cacheKey =>
      'popular_${widget.sectionKey ?? 'popularBooks'}_${widget.type ?? 'all'}';

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  bool _shouldShowApiMessage(ApiCallResponse response) {
    final success = EbookGroup.getPopularBooksApiCall.success(response.jsonBody);
    final message =
        EbookGroup.getPopularBooksApiCall.message(response.jsonBody) ?? '';
    return success != 1 && message.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PopularBooksPageModel());
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
      final res = await EbookGroup.getPopularBooksApiCall.call(
        type: widget.type,
        sectionKey: widget.sectionKey,
        limit: _limit,
        offset: _offset,
      );
      final newBooks =
          EbookGroup.getPopularBooksApiCall.bookDetailsList(res.jsonBody) ??
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
      debugPrint('Error loading popular books pagination: $e');
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
              wrapWithModel(
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: valueOrDefault<String>(
                    widget.title,
                    FFLocalizations.of(context).getVariableText(enText: 'Popular books', bnText: 'জনপ্রিয় বইসমূহ'),
                  ),
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
                                  return Center(
                                    child: NoPopularBookWidget(),
                                  );
                                }

                                return RefreshIndicator(
                                  key: const Key('RefreshIndicator_m9b9g2sw'),
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
                                            final popularBookList = _books;
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
                                                crossAxisSpacing: 8.0,
                                                mainAxisSpacing: 8.0,
                                                mainAxisExtent: 235.0,
                                              ),
                                              itemCount: popularBookList.length,
                                              itemBuilder: (context, popularBookListIndex) {
                                                final popularBookListItem = popularBookList[popularBookListIndex];
                                                return wrapWithModel(
                                                  model: _model.mainBookComponentModels.getModel(
                                                    getJsonField(popularBookListItem, r'''$.name''').toString(),
                                                    popularBookListIndex,
                                                  ),
                                                  updateCallback: () => safeSetState(() {}),
                                                  child: MainBookComponentWidget(
                                                    key: Key('Keyc76_${getJsonField(popularBookListItem, r'''$.name''').toString()}'),
                                                    image: '${FFAppConstants.bookImagesUrl}${getJsonField(popularBookListItem, r'''$.image''').toString()}',
                                                    imageHeight: 155,
                                                    bookName: getJsonField(popularBookListItem, r'''$.name''').toString(),
                                                    id: getJsonField(popularBookListItem, r'''$._id''').toString(),
                                                    price: getJsonField(popularBookListItem, r'''$.price''').toString(),
                                                    bookType: getJsonField(popularBookListItem, r'''$.type''')?.toString(),
                                                    discountAmount: getJsonField(popularBookListItem, r'''$.discount_amount''').toString(),
                                                    discountPercentage: getJsonField(popularBookListItem, r'''$.discount_percentage''').toString(),
                                                    authorsName: getJsonField(popularBookListItem, r'''$.author.name''').toString(),
                                                    isFav: functions.checkFavOrNot(
                                                          EbookGroup.getFavouriteBookCall
                                                              .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                              ?.toList(),
                                                          getJsonField(popularBookListItem, r'''$._id''').toString()) ==
                                                      true,
                                                    indicator: (popularBookListIndex == _model.popularBookIndex) && (_model.isPopularBook == true),
                                                    isPurchased: _model.purchasedBookIds.contains(
                                                      getJsonField(popularBookListItem, r'''$._id''').toString(),
                                                    ),
                                                    isFavAction: () async {
                                                      if (FFAppState().isLogin == true) {
                                                        _model.isPopularBook = true;
                                                        _model.popularBookIndex = popularBookListIndex;
                                                        safeSetState(() {});
                                                        if (functions.checkFavOrNot(
                                                              EbookGroup.getFavouriteBookCall
                                                                  .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                                  ?.toList(),
                                                              getJsonField(popularBookListItem, r'''$._id''').toString()) ==
                                                          true) {
                                                          _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                            userId: FFAppState().userId,
                                                            token: FFAppState().token,
                                                            bookId: getJsonField(popularBookListItem, r'''$._id''').toString(),
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
                                                            bookId: getJsonField(popularBookListItem, r'''$._id''').toString(),
                                                          );

                                                          safeSetState(() {
                                                            FFAppState().clearGetFavouriteBookCacheCache();
                                                            _model.apiRequestCompleted1 = false;
                                                          });
                                                          await _model.waitForApiRequestCompleted1();
                                                          await actions.showCustomToastBottom(FFAppState().favText);
                                                        }

                                                        FFAppState().clearGetFavouriteBookCacheCache();
                                                        _model.isPopularBook = false;
                                                        safeSetState(() {});
                                                      } else {
                                                        FFAppState().favChange = true;
                                                        FFAppState().bookId = getJsonField(popularBookListItem, r'''$._id''').toString();
                                                        FFAppState().update(() {});
                                                        context.pushNamed(SignInPageWidget.routeName);
                                                      }
                                                      safeSetState(() {});
                                                    },
                                                    isMainTap: () async {
                                                      context.pushNamed(
                                                        BookDetailspageWidget.routeName,
                                                        queryParameters: {
                                                          'name': serializeParam(getJsonField(popularBookListItem, r'''$.name''').toString(), ParamType.String),
                                                          'price': serializeParam(getJsonField(popularBookListItem, r'''$.price''').toString(), ParamType.String),
                                                          'image': serializeParam('${FFAppConstants.bookImagesUrl}${getJsonField(popularBookListItem, r'''$.image''').toString()}', ParamType.String),
                                                          'id': serializeParam(getJsonField(popularBookListItem, r'''$._id''').toString(), ParamType.String),
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
