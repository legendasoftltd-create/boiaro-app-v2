import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/index.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'main_book_component_model.dart';
export 'main_book_component_model.dart';
import '/custom_code/actions/index.dart' as actions;

class MainBookComponentWidget extends StatefulWidget {
  const MainBookComponentWidget({
    super.key,
    required this.image,
    this.price = "",
    required this.bookName,
    required this.id,
    required this.authorsName,
    this.bookType,
    bool? isFav,
    required this.isFavAction,
    required this.isMainTap,
    bool? indicator,
    this.discountAmount,
    this.discountPercentage,
    bool? isPurchased,
  })  : this.isFav = isFav ?? false,
        this.indicator = indicator ?? false,
        this.isPurchased = isPurchased ?? false;

  final String? image;
  final String? bookName;
  final String? id;
  final String? price;
  final String? authorsName;
  final String? bookType;
  final bool isFav;
  final Future Function()? isFavAction;
  final Future Function()? isMainTap;
  final bool indicator;
  final String? discountAmount;
  final String? discountPercentage;
  final bool isPurchased;

  @override
  State<MainBookComponentWidget> createState() =>
      _MainBookComponentWidgetState();
}

class _MainBookComponentWidgetState extends State<MainBookComponentWidget> {
  late MainBookComponentModel _model;
  bool _isFavBusy = false;

  String _normalizeFormat(String raw) {
    final t = raw.toLowerCase().trim();
    if (t.contains('audio')) return 'audiobook';
    if (t.contains('hard') || t.contains('print') || t.contains('paper')) {
      return 'hardcopy';
    }
    if (t.contains('ebook') ||
        t.contains('e-book') ||
        t.contains('epub') ||
        t.contains('pdf')) {
      return 'ebook';
    }
    return '';
  }

  List<String> _extractFormats(String? rawType) {
    final raw = (rawType ?? '').toLowerCase().trim();
    if (raw.isEmpty) return const <String>[];
    final parts = raw.split(RegExp(r'[,\s|/]+'));
    final set = <String>{};
    for (final p in parts) {
      final n = _normalizeFormat(p);
      if (n.isNotEmpty) set.add(n);
    }
    return set.toList();
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainBookComponentModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  Future<void> _toggleWishlist() async {
    if (_isFavBusy) return;
    if (!FFAppState().isLogin) {
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    safeSetState(() => _isFavBusy = true);
    try {
      if (widget.isFav) {
        final response = await EbookGroup.removeFavouritebookCall.call(
          bookId: widget.id,
          userId: FFAppState().userId,
          token: FFAppState().token,
        );
        if (response.succeeded) {
          await actions.showCustomToastBottom(FFAppState().unFavText);
        }
      } else {
        final response = await EbookGroup.addFavouriteBookApiCall.call(
          bookId: widget.id,
          userId: FFAppState().userId,
          token: FFAppState().token,
        );
        if (response.succeeded) {
          await actions.showCustomToastBottom(FFAppState().favText);
        }
      }
    } finally {
      if (mounted) {
        safeSetState(() => _isFavBusy = false);
      }
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formats = _extractFormats(widget.bookType);
    final formatIcons = <IconData>[
      if (formats.contains('ebook')) Icons.menu_book_rounded,
      if (formats.contains('audiobook')) Icons.headphones_rounded,
      if (formats.contains('hardcopy')) Icons.local_library_rounded,
    ];
    if (formatIcons.isEmpty && (widget.bookType ?? '').trim().isNotEmpty) {
      formatIcons.add(Icons.menu_book_rounded);
    }

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        await widget.isMainTap?.call();
      },
      child: Container(
        margin: EdgeInsets.all(2.0),
        width: () {
          if (MediaQuery.sizeOf(context).width < 810.0) {
            return ((MediaQuery.sizeOf(context).width - 40) / 3);
          } else if ((MediaQuery.sizeOf(context).width >= 810.0) &&
              (MediaQuery.sizeOf(context).width < 1280.0)) {
            return ((MediaQuery.sizeOf(context).width - 96) / 4);
          } else if (MediaQuery.sizeOf(context).width >= 1280.0) {
            return ((MediaQuery.sizeOf(context).width - 128) / 6);
          } else {
            return ((MediaQuery.sizeOf(context).width - 160) / 8);
          }
        }(),
        height: () {
          double screenHeight = MediaQuery.sizeOf(context).height;
          double screenWidth = MediaQuery.sizeOf(context).width;
          if (screenHeight / screenWidth < 1.78) {
            return 235.0;
          }
          return 230.0;
        }(),
        // decoration: BoxDecoration(
        //   color: FlutterFlowTheme.of(context).secondaryBackground,
        //   boxShadow: [
        //     BoxShadow(
        //       blurRadius: 16.0,
        //       color: FlutterFlowTheme.of(context).shadowColor,
        //       offset: Offset(
        //         0.0,
        //         4.0,
        //       ),
        //     )
        //   ],
        //   borderRadius: BorderRadius.circular(12.0),
        //   border: Border.all(
        //     color: FlutterFlowTheme.of(context).primary.withValues(
        //       alpha: 0.1,
        //     ),
        //     width: 2.0,
        //   ),
        // ),
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(5.0),
                            // topLeft: Radius.circular(10.0),
                            // topRight: Radius.circular(10.0),
                          ),
                          child: CachedNetworkImage(
                            fadeInDuration: Duration(milliseconds: 200),
                            fadeOutDuration: Duration(milliseconds: 200),
                            imageUrl: widget.image!,
                            width: double.infinity,
                            height: 160.0,
                            fit: BoxFit.fill,
                            alignment: Alignment(0.0, 0.0),
                            errorWidget: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/images/error_image.png',
                              width: 84.0,
                              height: 128.0,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment(0.0, 0.0),
                            ),
                          ),
                        ),
                        if (formatIcons.isNotEmpty)
                          Positioned(
                            right: 6.0,
                            bottom: 6.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 8.0,
                                    color: FlutterFlowTheme.of(context)
                                        .shadowColor,
                                    offset: Offset(0.0, 2.0),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: formatIcons
                                    .map(
                                      (ic) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 1.0,
                                        ),
                                        child: Icon(
                                          ic,
                                          size: 15.0,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.bookName,
                                'BookName',
                              ),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Text(
                              valueOrDefault<String>(
                                widget.authorsName,
                                'AuthorName',
                              ),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Expanded(
                              child: Row(
                                // mainAxisSize: MainAxisSize.max,

                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (!widget.isPurchased)
                                    Text(
                                      (double.tryParse(widget.price ?? '0') ??
                                                  0) >
                                              0
                                          ? "${valueOrDefault<String>(
                                              "৳ ${widget.price}",
                                              '\$0.00',
                                            )}"
                                          : "Free",
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 13.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            lineHeight: 1.2,
                                          ),
                                    ),
                                  // Consumer<CartProvider>(
                                  //   builder: (context, cart, child) {
                                  //     if (widget.isPurchased) {
                                  //       // Show Read Now button for purchased books
                                  //       return InkWell(
                                  //         splashColor: Colors.transparent,
                                  //         focusColor: Colors.transparent,
                                  //         hoverColor: Colors.transparent,
                                  //         highlightColor: Colors.transparent,
                                  //         onTap: () async {
                                  //           await widget.isMainTap?.call();
                                  //         },
                                  //         child: Container(
                                  //           padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                  //           decoration: BoxDecoration(
                                  //             color: FlutterFlowTheme.of(context).primary,
                                  //             borderRadius: BorderRadius.circular(16.0),
                                  //           ),
                                  //           child: Text(
                                  //             'Read Now',
                                  //             style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  //               fontFamily: 'SF Pro Display',
                                  //               fontSize: 12.0,
                                  //               fontWeight: FontWeight.w600,
                                  //               color: FlutterFlowTheme.of(context).primaryBackground,
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       );
                                  //     }

                                  //     final isInCart = cart.items.containsKey(widget.id ?? "");
                                  //     final quantity = isInCart ? cart.items[widget.id ?? ""]?.quantity ?? 0 : 0;

                                  //     if (quantity > 0) {
                                  //       // Show increment/decrement buttons
                                  //       return Row(
                                  //         mainAxisSize: MainAxisSize.min,
                                  //         children: [
                                  //           // Decrement button
                                  //           InkWell(
                                  //             splashColor: Colors.transparent,
                                  //             focusColor: Colors.transparent,
                                  //             hoverColor: Colors.transparent,
                                  //             highlightColor: Colors.transparent,
                                  //             onTap: () async {
                                  //               cart.removeSingleItem(widget.id ?? "");
                                  //               await actions.showCustomToastBottom('Quantity decreased!');
                                  //             },
                                  //             child: Container(
                                  //               width: 18.0,
                                  //               height: 18.0,
                                  //               decoration: BoxDecoration(
                                  //                 color: FlutterFlowTheme.of(context).primary,
                                  //                 shape: BoxShape.circle,
                                  //               ),
                                  //               child: Icon(
                                  //                 Icons.remove,
                                  //                 color: FlutterFlowTheme.of(context).primaryBackground,
                                  //                 size: 13.0,
                                  //               ),
                                  //             ),
                                  //           ),
                                  //           // Quantity display
                                  //           Container(
                                  //              padding: EdgeInsets.symmetric(horizontal: 5),
                                  //             alignment: Alignment.center,
                                  //             child: Text(
                                  //               quantity.toString(),
                                  //               style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  //                 fontFamily: 'SF Pro Display',
                                  //                 fontSize: 12.0,
                                  //                 fontWeight: FontWeight.bold,
                                  //                 color: FlutterFlowTheme.of(context).primaryText,
                                  //               ),
                                  //             ),
                                  //           ),
                                  //           // Increment button
                                  //           InkWell(
                                  //             splashColor: Colors.transparent,
                                  //             focusColor: Colors.transparent,
                                  //             hoverColor: Colors.transparent,
                                  //             highlightColor: Colors.transparent,
                                  //             onTap: () async {
                                  //               cart.addItem(
                                  //                 widget.id ?? "",
                                  //                 widget.bookName ?? "",
                                  //                 widget.image ?? "",
                                  //                 double.tryParse(widget.price ?? "0") ?? 0,
                                  //                 discountAmount: double.tryParse(widget.discountAmount ?? '0'),
                                  //                 discountPercentage: double.tryParse(widget.discountPercentage ?? '0'),
                                  //                 type: widget.bookType,
                                  //               );
                                  //               await actions.showCustomToastBottom('Quantity increased!');
                                  //             },
                                  //             child: Container(
                                  //               width: 18.0,
                                  //               height: 18.0,
                                  //               decoration: BoxDecoration(
                                  //                 color: FlutterFlowTheme.of(context).primary,
                                  //                 shape: BoxShape.circle,
                                  //               ),
                                  //               child: Icon(
                                  //                 Icons.add,
                                  //                 color: FlutterFlowTheme.of(context).primaryBackground,
                                  //                 size: 13.0,
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ],
                                  //       );
                                  //     } else {
                                  //       // Show add to cart button
                                  //       return (double.tryParse(widget.price ?? '0') ?? 0) > 0 ? InkWell(
                                  //         splashColor: Colors.transparent,
                                  //         focusColor: Colors.transparent,
                                  //         hoverColor: Colors.transparent,
                                  //         highlightColor: Colors.transparent,
                                  //         onTap: () async {
                                  //           cart.addItem(
                                  //             widget.id ?? "",
                                  //             widget.bookName ?? "",
                                  //             widget.image ?? "",
                                  //             double.tryParse(widget.price ?? "0") ?? 0,
                                  //             discountAmount: double.tryParse(widget.discountAmount ?? '0'),
                                  //             discountPercentage: double.tryParse(widget.discountPercentage ?? '0'),
                                  //             type: widget.bookType,
                                  //           );
                                  //           await actions.showCustomToastBottom('Added to cart!');
                                  //         },
                                  //         child: Container(
                                  //           width: 26.0,
                                  //           height: 26.0,
                                  //           decoration: BoxDecoration(
                                  //             color: FlutterFlowTheme.of(context).primary,
                                  //             shape: BoxShape.circle,
                                  //           ),
                                  //           child: Icon(
                                  //             Icons.add_shopping_cart_rounded,
                                  //             color: FlutterFlowTheme.of(context).primaryBackground,
                                  //             size: 14.0,
                                  //           ),
                                  //         ),
                                  //       ):SizedBox();
                                  //     }
                                  //   },
                                  // ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(height: 5.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(1.0, -1.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 8.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (((double.tryParse(widget.discountAmount ?? '0') ?? 0) >
                                0 ||
                            (double.tryParse(
                                        widget.discountPercentage ?? '0') ??
                                    0) >
                                0) &&
                        !widget.isPurchased)
                      Container(
                        margin: EdgeInsets.only(right: 8.0),
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          (double.tryParse(widget.discountPercentage ?? '0') ??
                                      0) >
                                  0
                              ? '${widget.discountPercentage}% OFF'
                              : '৳${widget.discountAmount} OFF',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    fontSize: 10.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    // InkWell(
                    //   splashColor: Colors.transparent,
                    //   focusColor: Colors.transparent,
                    //   hoverColor: Colors.transparent,
                    //   highlightColor: Colors.transparent,
                    //   onTap: () async {
                    //     if (widget.isFavAction != null) {
                    //       await widget.isFavAction?.call();
                    //     } else {
                    //       await _toggleWishlist();
                    //     }
                    //   },
                    //   child: Container(
                    //     width: 28.0,
                    //     height: 28.0,
                    //     decoration: BoxDecoration(
                    //       color: FlutterFlowTheme.of(context).primaryBackground,
                    //       boxShadow: [
                    //         BoxShadow(
                    //           blurRadius: 16.0,
                    //           color: FlutterFlowTheme.of(context).shadowColor,
                    //           offset: Offset(
                    //             0.0,
                    //             4.0,
                    //           ),
                    //         )
                    //       ],
                    //       shape: BoxShape.circle,
                    //     ),
                    //     alignment: AlignmentDirectional(0.0, 0.0),
                    //     child: Builder(
                    //       builder: (context) {
                    //         if (!widget.indicator && !_isFavBusy) {
                    //           return Builder(
                    //             builder: (context) {
                    //               if (widget.isFav == true) {
                    //                 return Icon(
                    //                   Icons.favorite_rounded,
                    //                   color: FlutterFlowTheme.of(context)
                    //                       .primaryText,
                    //                   size: 16.0,
                    //                 );
                    //               } else {
                    //                 return Icon(
                    //                   Icons.favorite_border_rounded,
                    //                   color: FlutterFlowTheme.of(context)
                    //                       .primaryText,
                    //                   size: 16.0,
                    //                 );
                    //               }
                    //             },
                    //           );
                    //         } else {
                    //           return custom_widgets.CirculatIndicator(
                    //             width: 16.0,
                    //             height: 16.0,
                    //           );
                    //         }
                    //       },
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            if (widget.isPurchased)
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Purchased',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
