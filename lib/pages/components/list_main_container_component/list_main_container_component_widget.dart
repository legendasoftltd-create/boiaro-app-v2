import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'list_main_container_component_model.dart';
export 'list_main_container_component_model.dart';
import '/custom_code/actions/index.dart' as actions;

class ListMainContainerComponentWidget extends StatefulWidget {
  const ListMainContainerComponentWidget({
    super.key,
    required this.image,
    required this.name,
    required this.id,
    required this.authorName,
    required this.averageRating,
    bool? isFav,
    required this.isFavAction,
    bool? indicator,
    required this.onMainTap,
    required this.width,
     this.price="",
    this.discountAmount,
    this.discountPercentage,
    bool? isPurchased,
    // this.addToCartAction,
  })  : this.isFav = isFav ?? false,
        this.indicator = indicator ?? false,
        this.isPurchased = isPurchased ?? false;

  final String? image;
  final String? name;
  final String? id;
  final String? authorName;
  final double? averageRating;
  final bool isFav;
  final Future Function()? isFavAction;
  final bool indicator;
  final Future Function()? onMainTap;
  final double? width;
  final String? price;
  final String? discountAmount;
  final String? discountPercentage;
  final bool isPurchased;
  // final Future Function()? addToCartAction;

  @override
  State<ListMainContainerComponentWidget> createState() =>
      _ListMainContainerComponentWidgetState();
}

class _ListMainContainerComponentWidgetState
    extends State<ListMainContainerComponentWidget> {
  late ListMainContainerComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListMainContainerComponentModel());

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
        await widget.onMainTap?.call();
      },
      child: Container(
        width: widget.width,
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
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withValues(
              alpha: 0.1,
            ),
            width: 2.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0.0),
                    child: CachedNetworkImage(
                      fadeInDuration: Duration(milliseconds: 200),
                      fadeOutDuration: Duration(milliseconds: 200),
                      imageUrl: widget.image!,
                      width: 77.0,
                      height: 114.0,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment(0.0, 0.0),
                      errorWidget: (context, error, stackTrace) => Image.asset(
                        'assets/images/error_image.png',
                        width: 77.0,
                        height: 114.0,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment(0.0, 0.0),
                      ),
                    ),
                  ),
                  if (widget.isPurchased)
                    Positioned(
                      top: 4.0,
                      right: 4.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          'Purchased',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            color: FlutterFlowTheme.of(context).primaryBackground,
                          ),
                        ),
                      ),
                    ),
                   if (((double.tryParse(widget.discountAmount ?? '0')??0) > 0 ||
                      (double.tryParse(widget.discountPercentage ?? '0')??0) > 0)&&!widget.isPurchased)
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
                ],
              ),
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valueOrDefault<String>(
                          widget.name,
                          'Name',
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              lineHeight: 1.5,
                            ),
                      ),
                      Text(
                        'By ${widget.authorName}',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 15.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              lineHeight: 1.5,
                            ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(0.0),
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 20.0,
                                  height: 20.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  valueOrDefault<String>(
                                    widget.averageRating?.toString(),
                                    '5',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 15.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        lineHeight: 1.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(double.parse(widget.price??'0')>0?"${valueOrDefault<String>(
                              "৳ ${widget.price}",
                              '\$0.00',
                            )}":"Free",
                            
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).primary,
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
                                            await widget.onMainTap?.call();
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
                                                  widget.name ?? "",
                                                  widget.image ?? "",
                                                  double.parse(widget.price ?? "0"),
                                                  discountAmount: double.tryParse(widget.discountAmount ?? "0") ?? 0,
                                                  discountPercentage: double.tryParse(widget.discountPercentage ?? "0") ?? 0,
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
                                        return double.parse(widget.price??'0')>0?InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            cart.addItem(
                                              widget.id ?? "",
                                              widget.name ?? "",
                                              widget.image ?? "",
                                              double.parse(widget.price ?? "0"),
                                              discountAmount:double.tryParse(widget.discountAmount ?? "0") ?? 0,
                                              discountPercentage: double.tryParse(widget.discountPercentage ?? "0") ?? 0,
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
                    ].divide(SizedBox(height: 8.0)),
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
                                Icons.favorite_sharp,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 16.0,
                              );
                            } else {
                              return Icon(
                                Icons.favorite_border_rounded,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 16.0,
                              );
                            }
                          },
                        );
                      } else {
                        return Container(
                          width: 16.0,
                          height: 16.0,
                          child: custom_widgets.CirculatIndicator(
                            width: 16.0,
                            height: 16.0,
                          ),
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
