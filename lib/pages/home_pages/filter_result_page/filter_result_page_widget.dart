import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_filter_book/no_filter_book_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'filter_result_page_model.dart';
export 'filter_result_page_model.dart';

class FilterResultPageWidget extends StatefulWidget {
  const FilterResultPageWidget({super.key});

  static String routeName = 'FilterResultPage';
  static String routePath = '/FilterResultPage';

  @override
  State<FilterResultPageWidget> createState() => _FilterResultPageWidgetState();
}

class _FilterResultPageWidgetState extends State<FilterResultPageWidget> {
  late FilterResultPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FilterResultPageModel());
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
      final res = await EbookGroup.getLatestbooksApiCall.call(
        authorIdList: FFAppState().authorId,
        categoryIdList: FFAppState().categoryId,
        limit: _limit,
        offset: _offset,
      );
      final newBooks =
          EbookGroup.getLatestbooksApiCall.bookDetailsList(res.jsonBody) ??
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
      debugPrint('Error loading filtered books pagination: $e');
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
                  title: 'Filter',
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
                        future: (_model.apiRequestCompleter2 ??= Completer<
                                ApiCallResponse>()
                              ..complete(EbookGroup.getFavouriteBookCall.call(
                                userId: FFAppState().userId,
                                token: FFAppState().token,
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
                                    model: _model.noFilterBookModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: NoFilterBookWidget(),
                                  );
                                }

                                return RefreshIndicator(
                                  key: const Key('RefreshIndicator_d0tm108k'),
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
                                            final filterBookList = _books;

                                            return Wrap(
                                              spacing: 16.0,
                                              runSpacing: 16.0,
                                              alignment: WrapAlignment.start,
                                              crossAxisAlignment: WrapCrossAlignment.start,
                                              direction: Axis.horizontal,
                                              runAlignment: WrapAlignment.start,
                                              verticalDirection: VerticalDirection.down,
                                              clipBehavior: Clip.none,
                                              children: List.generate(
                                                  filterBookList.length,
                                                  (filterBookListIndex) {
                                                final filterBookListItem = filterBookList[filterBookListIndex];
                                                return wrapWithModel(
                                                  model: _model.mainBookComponentModels.getModel(
                                                    getJsonField(filterBookListItem, r'''$.name''').toString(),
                                                    filterBookListIndex,
                                                  ),
                                                  updateCallback: () => safeSetState(() {}),
                                                  child: MainBookComponentWidget(
                                                    key: Key('Keydgb_${getJsonField(filterBookListItem, r'''$.name''').toString()}'),
                                                    image: '${FFAppConstants.bookImagesUrl}${getJsonField(filterBookListItem, r'''$.image''').toString()}',
                                                    bookName: getJsonField(filterBookListItem, r'''$.name''').toString(),
                                                    id: getJsonField(filterBookListItem, r'''$._id''').toString(),
                                                    price: getJsonField(filterBookListItem, r'''$.price''').toString(),
                                                    bookType: getJsonField(filterBookListItem, r'''$.type''')?.toString(),
                                                    discountAmount: getJsonField(filterBookListItem, r'''$.discount_amount''').toString(),
                                                    discountPercentage: getJsonField(filterBookListItem, r'''$.discount_percentage''').toString(),
                                                    authorsName: getJsonField(filterBookListItem, r'''$.author.name''').toString(),
                                                    isFav: functions.checkFavOrNot(
                                                          EbookGroup.getFavouriteBookCall
                                                              .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                              ?.toList(),
                                                          getJsonField(filterBookListItem, r'''$._id''').toString()) ==
                                                      true,
                                                    indicator: (filterBookListIndex == _model.filterIndex) && (_model.isFiler == true),
                                                    isFavAction: () async {
                                                      if (FFAppState().isLogin == true) {
                                                        _model.isFiler = true;
                                                        _model.filterIndex = filterBookListIndex;
                                                        safeSetState(() {});
                                                        if (functions.checkFavOrNot(
                                                              EbookGroup.getFavouriteBookCall
                                                                  .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                                  ?.toList(),
                                                              getJsonField(filterBookListItem, r'''$._id''').toString()) ==
                                                          true) {
                                                          _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                            userId: FFAppState().userId,
                                                            token: FFAppState().token,
                                                            bookId: getJsonField(filterBookListItem, r'''$._id''').toString(),
                                                          );

                                                          safeSetState(() => _model.apiRequestCompleter2 = null);
                                                          await _model.waitForApiRequestCompleted2();
                                                          await actions.showCustomToastBottom(FFAppState().unFavText);
                                                        } else {
                                                          _model.getPopularAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                            userId: FFAppState().userId,
                                                            token: FFAppState().token,
                                                            bookId: getJsonField(filterBookListItem, r'''$._id''').toString(),
                                                          );

                                                          safeSetState(() => _model.apiRequestCompleter2 = null);
                                                          await _model.waitForApiRequestCompleted2();
                                                          await actions.showCustomToastBottom(FFAppState().favText);
                                                        }

                                                        FFAppState().clearGetFavouriteBookCacheCache();
                                                        _model.isFiler = false;
                                                        safeSetState(() {});
                                                      } else {
                                                        FFAppState().favChange = true;
                                                        FFAppState().bookId = getJsonField(filterBookListItem, r'''$._id''').toString();
                                                        FFAppState().update(() {});
                                                        context.pushNamed(SignInPageWidget.routeName);
                                                      }

                                                      safeSetState(() {});
                                                    },
                                                    isPurchased: _model.purchasedBookIds.contains(getJsonField(filterBookListItem, r'''$._id''').toString()),
                                                    isMainTap: () async {
                                                      context.pushNamed(
                                                        BookDetailspageWidget.routeName,
                                                        queryParameters: {
                                                          'name': serializeParam(getJsonField(filterBookListItem, r'''$.name''').toString(), ParamType.String),
                                                          'price': serializeParam(getJsonField(filterBookListItem, r'''$.price''').toString(), ParamType.String),
                                                          'image': serializeParam('${FFAppConstants.bookImagesUrl}${getJsonField(filterBookListItem, r'''$.image''').toString()}', ParamType.String),
                                                          'id': serializeParam(getJsonField(filterBookListItem, r'''$._id''').toString(), ParamType.String),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                  ),
                                                );
                                              }),
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
