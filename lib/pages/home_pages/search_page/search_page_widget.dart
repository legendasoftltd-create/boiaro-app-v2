import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/empty_components/no_result_book_found/no_result_book_found_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/custom_code/actions/debounce_action.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'search_page_model.dart';
export 'search_page_model.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({super.key});

  static String routeName = 'SearchPage';
  static String routePath = '/searchPage';

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> {
  late SearchPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  double _parseRating(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SearchPageModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textFieldFocusNode!.addListener(
      () async {
        _model.focus = true;
        safeSetState(() {});
      },
    );
    _searchDebouncer = DebounceAction(
      delay: Duration(milliseconds: 500),
      onDebounce: () async {
        if (_model.textController.text == '') {
          _model.focus = false;
          safeSetState(() {});
          safeSetState(() => _model.apiRequestCompleter2 = null);
          await _model.waitForApiRequestCompleted2();
        } else {
          _model.focus = true;
          safeSetState(() {});
          safeSetState(() => _model.apiRequestCompleter2 = null);
          await _model.waitForApiRequestCompleted2();
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
      }
      await _loadCategories();
      if (mounted) {
        _model.textFieldFocusNode?.requestFocus();
      }
      safeSetState(() {});
    });
  }

  String? _selectedFormat;
  String? _selectedSort = 'newest';
  String? _selectedCategoryId;
  int _pageSize = 10;
  List<dynamic> _categoriesList = [];
  Future<void> _loadCategories() async {
    if (!mounted) return;
    try {
      final res = await EbookGroup.getcategoriesApiCall.call(
        token: FFAppState().token,
      );
      if (res.statusCode == 200 && res.jsonBody != null) {
        final List? cats = EbookGroup.getcategoriesApiCall.categoryDetailsList(res.jsonBody);
        if (cats != null && mounted) {
          setState(() {
            _categoriesList = cats;
          });
        }
      }
    } catch (_) {}
  }

  Widget _buildFormatChip(String? format, String label) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      label: Text(
        FFLocalizations.of(context).getVariableText(
          enText: label,
          bnText: label == 'All' ? 'সব' : (label == 'Ebook' ? 'ই-বই' : (label == 'Audiobook' ? 'অডিওবুক' : 'হার্ডকপি')),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFormat = format;
          _model.apiRequestCompleter2 = null;
        });
      },
      showCheckmark: false,
      labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
            fontFamily: 'SF Pro Display',
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).secondaryText,
            fontWeight: FontWeight.bold,
          ),
      selectedColor: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  Widget _buildSortChip(String sortValue, String label) {
    final isSelected = _selectedSort == sortValue;
    return ChoiceChip(
      label: Text(
        FFLocalizations.of(context).getVariableText(
          enText: label,
          bnText: label == 'Newest' ? 'নতুনতম' : (label == 'Popular' ? 'জনপ্রিয়' : (label == 'Price: Low-High' ? 'মূল্য: নিম্ন-উচ্চ' : 'মূল্য: উচ্চ-নিম্ন')),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedSort = sortValue;
          _model.apiRequestCompleter2 = null;
        });
      },
      showCheckmark: false,
      labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
            fontFamily: 'SF Pro Display',
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).secondaryText,
            fontWeight: FontWeight.bold,
          ),
      selectedColor: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  Future<void> _loadPurchasedBooks() async {
    try {
      final response = await EbookGroup.userBookPurchaseRecordsApiCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      );
      
      if (EbookGroup.userBookPurchaseRecordsApiCall.success(
            response?.jsonBody ?? '',
          ) ==
          1) {
        final bookIds = EbookGroup.userBookPurchaseRecordsApiCall.bookId(
          response?.jsonBody ?? '',
        );
        _model.purchasedBookIds = bookIds ?? [];
        safeSetState(() {});
      }
    } catch (e) {
      debugPrint('Error loading purchased books: $e');
    }
  }

  late DebounceAction _searchDebouncer;

  @override
  void dispose() {
    _model.dispose();
    _searchDebouncer.dispose();
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).black20,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        16.0, 0.0, 16.0, 0.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0.0),
                      child: SvgPicture.asset(
                        'assets/images/search.svg',
                        width: 24.0,
                        height: 24.0,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            FlutterFlowTheme.of(context).primaryText,
                            BlendMode.srcIn),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _model.textController,
                      focusNode: _model.textFieldFocusNode,
                      onChanged: (_) => _searchDebouncer.run(),
                      onFieldSubmitted: (_) async {
                        if (_model.textController.text.trim().isNotEmpty) {
                          FFAppState()
                              .addToSearchList(_model.textController.text);
                          FFAppState().update(() {});
                        }
                        safeSetState(
                            () => _model.apiRequestCompleter2 = null);
                        await _model.waitForApiRequestCompleted2();
                      },
                      autofocus: true,
                      obscureText: false,
                      decoration: InputDecoration(
                        hintText: FFLocalizations.of(context).getVariableText(enText: 'Search', bnText: 'অনুসন্ধান করুন'),
                        hintStyle: FlutterFlowTheme.of(context)
                            .labelMedium
                            .override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 17.0,
                              letterSpacing: 0.0,
                              lineHeight: 1.5,
                            ),
                        errorStyle: FlutterFlowTheme.of(context)
                            .bodyMedium
                            .override(
                              fontFamily: 'SF Pro Display',
                              color: FlutterFlowTheme.of(context).error,
                              fontSize: 15.0,
                              letterSpacing: 0.0,
                              lineHeight: 1.2,
                            ),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      style:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                fontSize: 17.0,
                                letterSpacing: 0.0,
                                lineHeight: 1.5,
                              ),
                      cursorColor: FlutterFlowTheme.of(context).primary,
                      validator: _model.textControllerValidator
                          .asValidator(context),
                    ),
                  ),
                  if (_model.textController.text != '')
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          16.0, 0.0, 16.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          safeSetState(() {
                            _model.textController?.clear();
                          });
                          _model.focus = false;
                          safeSetState(() {});
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: SvgPicture.asset(
                            'assets/images/close_ic.svg',
                            width: 24.0,
                            height: 24.0,
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                                FlutterFlowTheme.of(context).primaryText,
                                BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // // Filters Section
              // Container(
              //   padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       // Format selector
              //       Row(
              //         children: [
              //           Text(
              //             FFLocalizations.of(context).getVariableText(enText: 'Format:', bnText: 'ফরম্যাট:'),
              //             style: FlutterFlowTheme.of(context).bodyMedium.override(
              //                   fontFamily: 'SF Pro Display',
              //                   fontWeight: FontWeight.bold,
              //                   fontSize: 13,
              //                 ),
              //           ),
              //           const SizedBox(width: 8),
              //           Expanded(
              //             child: SingleChildScrollView(
              //               scrollDirection: Axis.horizontal,
              //               child: Row(
              //                 children: [
              //                   _buildFormatChip(null, 'All'),
              //                   const SizedBox(width: 6),
              //                   _buildFormatChip('ebook', 'Ebook'),
              //                   const SizedBox(width: 6),
              //                   _buildFormatChip('audiobook', 'Audiobook'),
              //                   const SizedBox(width: 6),
              //                   _buildFormatChip('hardcopy', 'Hardcopy'),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 8),
              //       // Sort Selector
              //       Row(
              //         children: [
              //           Text(
              //             FFLocalizations.of(context).getVariableText(enText: 'Sort:', bnText: 'সাজান:'),
              //             style: FlutterFlowTheme.of(context).bodyMedium.override(
              //                   fontFamily: 'SF Pro Display',
              //                   fontWeight: FontWeight.bold,
              //                   fontSize: 13,
              //                 ),
              //           ),
              //           const SizedBox(width: 8),
              //           Expanded(
              //             child: SingleChildScrollView(
              //               scrollDirection: Axis.horizontal,
              //               child: Row(
              //                 children: [
              //                   _buildSortChip('newest', 'Newest'),
              //                   const SizedBox(width: 6),
              //                   _buildSortChip('popular', 'Popular'),
              //                   const SizedBox(width: 6),
              //                   _buildSortChip('price_asc', 'Price: Low-High'),
              //                   const SizedBox(width: 6),
              //                   _buildSortChip('price_desc', 'Price: High-Low'),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 8),
              //       // Category & Page Size Row
              //       Row(
              //         children: [
              //           // Category Dropdown
              //           Expanded(
              //             child: Container(
              //               height: 38,
              //               padding: const EdgeInsets.symmetric(horizontal: 10.0),
              //               decoration: BoxDecoration(
              //                 color: FlutterFlowTheme.of(context).secondaryBackground,
              //                 borderRadius: BorderRadius.circular(8.0),
              //                 border: Border.all(
              //                   color: FlutterFlowTheme.of(context).alternate,
              //                 ),
              //               ),
              //               child: DropdownButtonHideUnderline(
              //                 child: DropdownButton<String?>(
              //                   value: _selectedCategoryId,
              //                   hint: Text(
              //                     FFLocalizations.of(context).getVariableText(enText: 'All Categories', bnText: 'সব ক্যাটাগরি'),
              //                     style: FlutterFlowTheme.of(context).bodySmall.override(
              //                           fontFamily: 'SF Pro Display',
              //                           color: FlutterFlowTheme.of(context).secondaryText,
              //                         ),
              //                   ),
              //                   isExpanded: true,
              //                   icon: Icon(
              //                     Icons.arrow_drop_down_rounded,
              //                     color: FlutterFlowTheme.of(context).secondaryText,
              //                     size: 20,
              //                   ),
              //                   items: [
              //                     DropdownMenuItem<String?>(
              //                       value: null,
              //                       child: Text(
              //                         FFLocalizations.of(context).getVariableText(enText: 'All Categories', bnText: 'সব ক্যাটাগরি'),
              //                         style: FlutterFlowTheme.of(context).bodySmall,
              //                       ),
              //                     ),
              //                     ..._categoriesList.map((cat) {
              //                       final id = getJsonField(cat, r'''$._id''')?.toString();
              //                       final name = getJsonField(cat, r'''$.name''')?.toString() ?? 'Category';
              //                       return DropdownMenuItem<String?>(
              //                         value: id,
              //                         child: Text(
              //                           name,
              //                           style: FlutterFlowTheme.of(context).bodySmall,
              //                         ),
              //                       );
              //                     }).toList(),
              //                   ],
              //                   onChanged: (val) {
              //                     setState(() {
              //                       _selectedCategoryId = val;
              //                       _model.apiRequestCompleter2 = null;
              //                     });
              //                   },
              //                 ),
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
             
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Builder(
                    builder: (context) {
                      if (_model.textController.text.trim().length < 2) {
                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (FFAppState().searchList.isNotEmpty)
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 24.0, 16.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getVariableText(enText: 'Recent search', bnText: 'সাম্প্রতিক অনুসন্ধান'),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 16.0,
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
                                        FFAppState().searchList = [];
                                        FFAppState().update(() {});
                                      },
                                      child: Text(FFLocalizations.of(context).getVariableText(enText: 'Clear all', bnText: 'সব মুছুন'),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20.0, 0.0, 20.0, 0.0),
                                child: Builder(
                                  builder: (context) {
                                    final searchList =
                                        FFAppState().searchList.toList();
                                    if (searchList.isEmpty) {
                                      return Center(
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: NoResultBookFoundWidget(),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        24.0,
                                        0,
                                        24.0,
                                      ),
                                      scrollDirection: Axis.vertical,
                                      itemCount: searchList.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 24.0),
                                      itemBuilder: (context, searchListIndex) {
                                        final searchListItem =
                                            searchList[searchListIndex];
                                        return Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                              child: SvgPicture.asset(
                                                'assets/images/search.svg',
                                                width: 24.0,
                                                height: 24.0,
                                                fit: BoxFit.cover,
                                                colorFilter: ColorFilter.mode(
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    BlendMode.srcIn),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 0.0, 0.0, 0.0),
                                                child: InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                     setState(() {
                                                       _model.textController.text = searchListItem;
                                                       _model.focus = true;
                                                       _model.apiRequestCompleter2 = null;
                                                     });
                                                     _model.textController?.selection = TextSelection.fromPosition(
                                                       TextPosition(offset: searchListItem.length),
                                                     );
                                                   },
                                                  child: Text(
                                                    searchListItem,
                                                    maxLines: 1,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                FFAppState()
                                                    .removeAtIndexFromSearchList(
                                                        searchListIndex);
                                                FFAppState().update(() {});
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0.0),
                                                child: Image.asset(
                                                  'assets/images/Plus.png',
                                                  width: 20.0,
                                                  height: 20.0,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return FutureBuilder<ApiCallResponse>(
                          future: FFAppState()
                              .getFavouriteBookCache(
                            uniqueQueryKey: FFAppState().userId,
                            requestFn: () =>
                                EbookGroup.getFavouriteBookCall.call(
                              userId: FFAppState().userId,
                              token: FFAppState().token,
                            ),
                          )
                              .then((result) {
                            try {
                              _model.apiRequestCompleted1 = true;
                              _model.apiRequestLastUniqueKey1 =
                                  FFAppState().userId;
                            } finally {}
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
                              decoration: BoxDecoration(),
                              child: Builder(
                                builder: (context) {
                                  if (FFAppState().connected) {
                                    return FutureBuilder<ApiCallResponse>(
                                      future: (_model.apiRequestCompleter2 ??=
                                              Completer<ApiCallResponse>()
                                                ..complete(EbookGroup
                                                    .searchApiCall
                                                    .call(
                                                  search: _model
                                                      .textController.text,
                                                  token: FFAppState().token,
                                                  pageSize: _pageSize,
                                                  format: _selectedFormat,
                                                  sort: _selectedSort,
                                                  categoryId: _selectedCategoryId,
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final listViewSearchApiResponse =
                                            snapshot.data!;

                                        return Builder(
                                          builder: (context) {
                                            final seachFilterList =
                                                EbookGroup.searchApiCall
                                                        .bookDetailsList(
                                                          listViewSearchApiResponse
                                                              .jsonBody,
                                                        )
                                                        ?.toList() ??
                                                    [];
                                            if (seachFilterList.isEmpty) {
                                              return Center(
                                                child: Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  child:
                                                      NoResultBookFoundWidget(),
                                                ),
                                              );
                                            }

                                            return ListView.separated(
                                              padding: EdgeInsets.fromLTRB(
                                                0,
                                                24.0,
                                                0,
                                                24.0,
                                              ),
                                              scrollDirection: Axis.vertical,
                                              itemCount: seachFilterList.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(height: 16.0),
                                              itemBuilder: (context,
                                                  seachFilterListIndex) {
                                                final seachFilterListItem =
                                                    seachFilterList[
                                                        seachFilterListIndex];
                                                return Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          16.0, 0.0, 16.0, 0.0),
                                                  child: wrapWithModel(
                                                    model: _model
                                                        .listMainContainerComponentModels
                                                        .getModel(
                                                      getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.name''',
                                                      ).toString(),
                                                      seachFilterListIndex,
                                                    ),
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child:
                                                        ListMainContainerComponentWidget(
                                                      key: Key(
                                                        'Key2xe_${getJsonField(
                                                          seachFilterListItem,
                                                          r'''$.name''',
                                                        ).toString()}',
                                                      ),
                                                      image:
                                                          '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.image''',
                                                      ).toString()}',
                                                      price:
                                                          '${getJsonField(
                                                        seachFilterListItem,
                                                         r'''$.price''',
                                                      ).toString()}',
                                                      bookType: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.type''',
                                                      )?.toString(),
                                                      discountAmount: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.discount_amount''',
                                                      ).toString(),
                                                      discountPercentage: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.discount_percentage''',
                                                      ).toString(),
                                                      name: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.name''',
                                                      ).toString(),
                                                      id: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$._id''',
                                                      ).toString(),
                                                      authorName: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.author.name''',
                                                      ).toString(),
                                                      averageRating:
                                                          _parseRating(
                                                        getJsonField(
                                                          seachFilterListItem,
                                                          r'''$.averageRating''',
                                                        ),
                                                      ),
                                                      isFav: functions.checkFavOrNot(
                                                              EbookGroup.getFavouriteBookCall
                                                                  .favouriteBookDetailsList(
                                                                    containerGetFavouriteBookResponse
                                                                        .jsonBody,
                                                                  )
                                                                  ?.toList(),
                                                              getJsonField(
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString()) ==
                                                          true,
                                                      indicator:
                                                          (seachFilterListIndex ==
                                                                  _model
                                                                      .searchIndex) &&
                                                              (_model.isSearch ==
                                                                  true),
                                                      width: double.infinity,
                                                      isPurchased: _model.purchasedBookIds.contains(
                                                        getJsonField(
                                                          seachFilterListItem,
                                                          r'''$._id''',
                                                        ).toString(),
                                                      ),
                                                      isFavAction: () async {
                                                        if (FFAppState()
                                                                .isLogin ==
                                                            true) {
                                                          _model.isSearch =
                                                              true;
                                                          _model.searchIndex =
                                                              seachFilterListIndex;
                                                          safeSetState(() {});
                                                          if (functions.checkFavOrNot(
                                                                  EbookGroup.getFavouriteBookCall
                                                                      .favouriteBookDetailsList(
                                                                        containerGetFavouriteBookResponse
                                                                            .jsonBody,
                                                                      )
                                                                      ?.toList(),
                                                                  getJsonField(
                                                                    seachFilterListItem,
                                                                    r'''$._id''',
                                                                  ).toString()) ==
                                                              true) {
                                                            _model.getSeachDetete =
                                                                await EbookGroup
                                                                    .removeFavouritebookCall
                                                                    .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                              bookId:
                                                                  getJsonField(
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                            );

                                                            safeSetState(() {
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCacheKey(
                                                                      _model
                                                                          .apiRequestLastUniqueKey1);
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
                                                            _model.getSearchAdd =
                                                                await EbookGroup
                                                                    .addFavouriteBookApiCall
                                                                    .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                              bookId:
                                                                  getJsonField(
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                            );

                                                            safeSetState(() {
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCacheKey(
                                                                      _model
                                                                          .apiRequestLastUniqueKey1);
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
                                                          _model.isSearch =
                                                              false;
                                                          safeSetState(() {});
                                                        } else {
                                                          FFAppState()
                                                              .favChange = true;
                                                          FFAppState().bookId =
                                                              getJsonField(
                                                            seachFilterListItem,
                                                            r'''$._id''',
                                                          ).toString();
                                                          FFAppState()
                                                              .update(() {});

                                                          context.pushNamed(
                                                              SignInPageWidget
                                                                  .routeName);
                                                        }

                                                        safeSetState(() {});
                                                      },
                                                      onMainTap: () async {
                                                        context.pushNamed(
                                                          BookDetailspageWidget
                                                              .routeName,
                                                          queryParameters: {
                                                            'name':
                                                                serializeParam(
                                                              getJsonField(
                                                                seachFilterListItem,
                                                                r'''$.name''',
                                                              ).toString(),
                                                              ParamType.String,
                                                            ),
                                                            'price':
                                                                serializeParam(
                                                              getJsonField(
                                                                seachFilterListItem,
                                                                r'''$.price''',
                                                              ).toString(),
                                                              ParamType.String,
                                                            ),
                                                            'image':
                                                                serializeParam(
                                                              '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                seachFilterListItem,
                                                                r'''$.image''',
                                                              ).toString()}',
                                                              ParamType.String,
                                                            ),
                                                            'id':
                                                                serializeParam(
                                                              getJsonField(
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                              ParamType.String,
                                                            ),
                                                          }.withoutNulls,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
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
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
