import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
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
    this.type,
  });

  final String? name;
  final String? id;
  final String? type;

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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebouncer;
  String _searchQuery = '';
  String _selectedFormat = 'all';
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _nextCursor;

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
    if (widget.type != null && widget.type!.trim().isNotEmpty) {
      final t = widget.type!.trim().toLowerCase();
      if (t == 'audiobook' || t == 'ebook' || t == 'hardcopy' || t == 'hardcover') {
        _selectedFormat = t == 'hardcover' ? 'hardcopy' : t;
      }
    }
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
    debugPrint('Category Books Scroll: pixels=${_scrollController.position.pixels}, max=${_scrollController.position.maxScrollExtent}');
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadMoreBooks({bool isFirstLoad = false}) async {
    if (_isLoading || (!_hasMore && !isFirstLoad)) return;
    debugPrint('Category Books Load: isFirstLoad=$isFirstLoad, cursor=$_nextCursor, limit=$_limit, hasMore=$_hasMore, format=$_selectedFormat, search=$_searchQuery');
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await EbookGroup.getbookbycategoryApiCall.call(
        categoryId: widget.id,
        format: _selectedFormat == 'all' ? '' : _selectedFormat,
        search: _searchQuery,
        limit: _limit,
        cursor: isFirstLoad ? null : _nextCursor,
      );
      final newBooks =
          EbookGroup.getbookbycategoryApiCall.bookDetailsList(res.jsonBody) ??
              [];
      final nextCursorVal =
          EbookGroup.getbookbycategoryApiCall.nextCursor(res.jsonBody);
      debugPrint('Category Books API Result: count=${newBooks.length}, nextCursor=$nextCursorVal');

      setState(() {
        if (isFirstLoad) {
          _books.clear();
          _offset = 0;
          _nextCursor = null;
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
        _nextCursor = nextCursorVal;
        if (newBooks.isEmpty || nextCursorVal == null || nextCursorVal.isEmpty) {
          _hasMore = false;
        }
        _offset += newBooks.length;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasMore && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0) {
          debugPrint('Category Books screen not filled, auto loading next page');
          _loadMoreBooks();
        }
      });
    } catch (e) {
      debugPrint('Error loading category books: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _model.dispose();

    super.dispose();
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

  Widget _buildFormatFilterChips() {
    final formats = [
      {'label': 'সব', 'value': 'all'},
      {'label': 'ই-বুক', 'value': 'ebook'},
      {'label': 'অডিওবুক', 'value': 'audiobook'},
      {'label': 'হার্ডকপি', 'value': 'hardcopy'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Row(
        children: formats.map((item) {
          final isSelected = _selectedFormat == item['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(
                item['label']!,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : FlutterFlowTheme.of(context).primaryText,
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: FlutterFlowTheme.of(context).primary,
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFormat = item['value']!;
                    _offset = 0;
                    _hasMore = true;
                  });
                  _loadMoreBooks(isFirstLoad: true);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchDebouncer?.cancel();
                    _searchDebouncer = Timer(const Duration(milliseconds: 400), () {
                      setState(() {
                        _searchQuery = val.trim();
                        _offset = 0;
                        _hasMore = true;
                      });
                      _loadMoreBooks(isFirstLoad: true);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: FFLocalizations.of(context).getVariableText(enText: 'Search books...', bnText: 'বই খুঁজুন...'),
                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: FlutterFlowTheme.of(context).secondaryText),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _offset = 0;
                                _hasMore = true;
                              });
                              _loadMoreBooks(isFirstLoad: true);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              _buildFormatFilterChips(),
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
                            decoration: const BoxDecoration(),
                            child: _books.isEmpty && !_isLoading
                                ? wrapWithModel(
                                    model: _model.noCategoriesYetModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: NoCategoriesYetWidget(),
                                  )
                                : RefreshIndicator(
                                    key: const Key('RefreshIndicator_b552okc7'),
                                    color: FlutterFlowTheme.of(context).primary,
                                    onRefresh: () async {
                                      setState(() {
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
                                               final booksList = _books;
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
                                                 itemCount: booksList.length,
                                                 itemBuilder: (context, bookDetailsListIndex) {
                                                   final bookDetailsListItem = booksList[bookDetailsListIndex];
                                                   return wrapWithModel(
                                                     model: _model.mainBookComponentModels.getModel(
                                                       getJsonField(bookDetailsListItem, r'''$.name''').toString(),
                                                       bookDetailsListIndex,
                                                     ),
                                                     updateCallback: () => safeSetState(() {}),
                                                     child: MainBookComponentWidget(
                                                       key: Key('Keycat_${getJsonField(bookDetailsListItem, r'''$.name''').toString()}'),
                                                       image: '${FFAppConstants.bookImagesUrl}${getJsonField(bookDetailsListItem, r'''$.image''').toString()}',
                                                       bookName: getJsonField(bookDetailsListItem, r'''$.name''').toString(),
                                                       id: getJsonField(bookDetailsListItem, r'''$._id''').toString(),
                                                       imageHeight: 155,
                                                       price: getJsonField(bookDetailsListItem, r'''$.price''').toString(),
                                                       bookType: getJsonField(bookDetailsListItem, r'''$.type''')?.toString(),
                                                       discountAmount: getJsonField(bookDetailsListItem, r'''$.discount_amount''').toString(),
                                                       discountPercentage: getJsonField(bookDetailsListItem, r'''$.discount_percentage''').toString(),
                                                       authorsName: getJsonField(bookDetailsListItem, r'''$.author.name''').toString(),
                                                       isFav: functions.checkFavOrNot(
                                                             EbookGroup.getFavouriteBookCall
                                                                 .favouriteBookDetailsList(containerGetFavouriteBookResponse.jsonBody)
                                                                 ?.toList(),
                                                             getJsonField(bookDetailsListItem, r'''$._id''').toString()) ==
                                                         true,
                                                       indicator: (bookDetailsListIndex == _model.categoryBookIndex) && (_model.isCategoryBook == true),
                                                       isFavAction: () async {
                                                         if (FFAppState().isLogin == true) {
                                                           _model.isCategoryBook = true;
                                                           _model.categoryBookIndex = bookDetailsListIndex;
                                                           safeSetState(() {});
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
                                                             _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                               userId: FFAppState().userId,
                                                               token: FFAppState().token,
                                                               bookId: getJsonField(
                                                                 bookDetailsListItem,
                                                                 r'''$._id''',
                                                               ).toString(),
                                                             );

                                                             safeSetState(() {
                                                               FFAppState().clearGetFavouriteBookCacheCache();
                                                               _model.apiRequestCompleted1 = false;
                                                             });
                                                             await _model.waitForApiRequestCompleted1();
                                                             await actions.showCustomToastBottom(
                                                               FFAppState().unFavText,
                                                             );
                                                           } else {
                                                             _model.getPopularAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                               userId: FFAppState().userId,
                                                               token: FFAppState().token,
                                                               bookId: getJsonField(
                                                                 bookDetailsListItem,
                                                                 r'''$._id''',
                                                               ).toString(),
                                                             );

                                                             safeSetState(() {
                                                               FFAppState().clearGetFavouriteBookCacheCache();
                                                               _model.apiRequestCompleted1 = false;
                                                             });
                                                             await _model.waitForApiRequestCompleted1();
                                                             await actions.showCustomToastBottom(
                                                               FFAppState().favText,
                                                             );
                                                           }

                                                           FFAppState().clearGetFavouriteBookCacheCache();
                                                           _model.isCategoryBook = false;
                                                           safeSetState(() {});
                                                         } else {
                                                           FFAppState().favChange = true;
                                                           FFAppState().bookId = getJsonField(
                                                             bookDetailsListItem,
                                                             r'''$._id''',
                                                           ).toString();
                                                           FFAppState().update(() {});

                                                           context.pushNamed(SignInPageWidget.routeName);
                                                         }

                                                         safeSetState(() {});
                                                       },
                                                       isMainTap: () async {
                                                         context.pushNamed(
                                                           BookDetailspageWidget.routeName,
                                                           queryParameters: {
                                                             'name': serializeParam(
                                                               getJsonField(
                                                                 bookDetailsListItem,
                                                                 r'''$.name''',
                                                               ).toString(),
                                                               ParamType.String,
                                                             ),
                                                             'price': serializeParam(
                                                               getJsonField(
                                                                 bookDetailsListItem,
                                                                 r'''$.price''',
                                                               ).toString(),
                                                               ParamType.String,
                                                             ),
                                                             'image': serializeParam(
                                                               '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                 bookDetailsListItem,
                                                                 r'''$.image''',
                                                               ).toString()}',
                                                               ParamType.String,
                                                             ),
                                                             'id': serializeParam(
                                                               getJsonField(
                                                                 bookDetailsListItem,
                                                                 r'''$._id''',
                                                               ).toString(),
                                                               ParamType.String,
                                                             ),
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
                                           const Center(
                                             child: Padding(
                                               padding: EdgeInsets.all(12.0),
                                               child: SizedBox(
                                                 width: 32.0,
                                                 height: 32.0,
                                                 child: CircularProgressIndicator(),
                                               ),
                                             ),
                                           ),
                                       ],
                                     ),
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
