import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
     this.price="",
    required this.bookName,
    required this.id,
    required this.authorsName,
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

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        await widget.isMainTap?.call();
      },
      child: Container(
        
        width: () {
          if (MediaQuery.sizeOf(context).width < 810.0) {
            return ((MediaQuery.sizeOf(context).width - 48) * 1 / 2);
          } else if ((MediaQuery.sizeOf(context).width >= 810.0) &&
              (MediaQuery.sizeOf(context).width < 1280.0)) {
            return ((MediaQuery.sizeOf(context).width - 80) * 1 / 4);
          } else if (MediaQuery.sizeOf(context).width >= 1280.0) {
            return ((MediaQuery.sizeOf(context).width - 112) * 1 / 6);
          } else {
            return ((MediaQuery.sizeOf(context).width - 144) * 1 / 8);
          }
        }(),
        height: 280.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 16.0,
              color: FlutterFlowTheme.of(context).shadowColor,
              offset: Offset(
                0.0,
                4.0,
              ),
            )
          ],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withValues(
              alpha: 0.1,
            ),
            width: 2.0,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(0.0),
                      child: CachedNetworkImage(
                        fadeInDuration: Duration(milliseconds: 200),
                        fadeOutDuration: Duration(milliseconds: 200),
                        imageUrl: widget.image!,
                        width: 96.0,
                        height: 148.0,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment(0.0, 0.0),
                        errorWidget: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/error_image.png',
                          width: 96.0,
                          height: 148.0,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment(0.0, 0.0),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    fontSize: 17.0,
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
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if(!widget.isPurchased)
                                Text((double.tryParse(widget.price ?? '0') ?? 0) > 0 ? "${valueOrDefault<String>(
                              "৳ ${widget.price}",
                              '\$0.00',
                            )}" : "Free",
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                  Consumer<CartProvider>(
                                    builder: (context, cart, child) {
                                      if (widget.isPurchased) {
                                        // Show Read Now button for purchased books
                                        return InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await widget.isMainTap?.call();
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).primary,
                                              borderRadius: BorderRadius.circular(16.0),
                                            ),
                                            child: Text(
                                              'Read Now',
                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w600,
                                                color: FlutterFlowTheme.of(context).primaryBackground,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final isInCart = cart.items.containsKey(widget.id ?? "");
                                      final quantity = isInCart ? cart.items[widget.id ?? ""]?.quantity ?? 0 : 0;

                                      if (quantity > 0) {
                                        // Show increment/decrement buttons
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Decrement button
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              onTap: () async {
                                                cart.removeSingleItem(widget.id ?? "");
                                                await actions.showCustomToastBottom('Quantity decreased!');
                                              },
                                              child: Container(
                                                width: 20.0,
                                                height: 20.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(context).primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  color: FlutterFlowTheme.of(context).primaryBackground,
                                                  size: 16.0,
                                                ),
                                              ),
                                            ),
                                            // Quantity display
                                            Container(
                                               padding: EdgeInsets.all(5),
                                              alignment: Alignment.center,
                                              child: Text(
                                                quantity.toString(),
                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                ),
                                              ),
                                            ),
                                            // Increment button
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              onTap: () async {
                                                cart.addItem(
                                                  widget.id ?? "",
                                                  widget.bookName ?? "",
                                                  widget.image ?? "",
                                                  double.tryParse(widget.price ?? "0") ?? 0,
                                                  discountAmount: double.tryParse(widget.discountAmount ?? '0'),
                                                  discountPercentage: double.tryParse(widget.discountPercentage ?? '0'),
                                                );
                                                await actions.showCustomToastBottom('Quantity increased!');
                                              },
                                              child: Container(
                                                width: 20.0,
                                                height: 20.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(context).primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: FlutterFlowTheme.of(context).primaryBackground,
                                                  size: 16.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // Show add to cart button
                                        return (double.tryParse(widget.price ?? '0') ?? 0) > 0 ? InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            cart.addItem(
                                              widget.id ?? "",
                                              widget.bookName ?? "",
                                              widget.image ?? "",
                                              double.tryParse(widget.price ?? "0") ?? 0,
                                              discountAmount: double.tryParse(widget.discountAmount ?? '0'),
                                              discountPercentage: double.tryParse(widget.discountPercentage ?? '0'),
                                            );
                                            await actions.showCustomToastBottom('Added to cart!');
                                          },
                                          child: Container(
                                            width: 32.0,
                                            height: 32.0,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.add_shopping_cart_rounded,
                                              color: FlutterFlowTheme.of(context).primaryBackground,
                                              size: 16.0,
                                            ),
                                          ),
                                        ):SizedBox();
                                      }
                                    },
                                  ),
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
                    if (((double.tryParse(widget.discountAmount ?? '0')??0) > 0 ||
                        (double.tryParse(widget.discountPercentage ?? '0')??0) > 0) && !widget.isPurchased)
                      Container(
                        margin: EdgeInsets.only(right: 8.0),
                        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          (double.tryParse(widget.discountPercentage ?? '0')??0) > 0
                              ? '${widget.discountPercentage}% OFF'
                              : '৳${widget.discountAmount} OFF',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                fontSize: 10.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        await widget.isFavAction?.call();
                      },
                      child: Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16.0,
                              color: FlutterFlowTheme.of(context).shadowColor,
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                            )
                          ],
                          shape: BoxShape.circle,
                        ),
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Builder(
                          builder: (context) {
                            if (!widget.indicator) {
                              return Builder(
                                builder: (context) {
                                  if (widget.isFav == true) {
                                    return Icon(
                                      Icons.favorite_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 16.0,
                                    );
                                  } else {
                                    return Icon(
                                      Icons.favorite_border_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 16.0,
                                    );
                                  }
                                },
                              );
                            } else {
                              return custom_widgets.CirculatIndicator(
                                width: 16.0,
                                height: 16.0,
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
