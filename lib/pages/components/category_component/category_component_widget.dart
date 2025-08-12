import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'category_component_model.dart';
export 'category_component_model.dart';

class CategoryComponentWidget extends StatefulWidget {
  const CategoryComponentWidget({
    super.key,
    required this.image,
    required this.name,
    required this.onMainTap,
    bool? isSmall,
  }) : this.isSmall = isSmall ?? false;

  final String? image;
  final String? name;
  final Future Function()? onMainTap;
  final bool isSmall;

  @override
  State<CategoryComponentWidget> createState() =>
      _CategoryComponentWidgetState();
}

class _CategoryComponentWidgetState extends State<CategoryComponentWidget> {
  late CategoryComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryComponentModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (widget.isSmall == true) {
          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await widget.onMainTap?.call();
            },
            child: Container(
              width: () {
                if (MediaQuery.sizeOf(context).width < 810.0) {
                  return ((MediaQuery.sizeOf(context).width - 80) * 1 / 4);
                } else if ((MediaQuery.sizeOf(context).width >= 810.0) &&
                    (MediaQuery.sizeOf(context).width < 1280.0)) {
                  return ((MediaQuery.sizeOf(context).width - 112) * 1 / 6);
                } else if (MediaQuery.sizeOf(context).width >= 1280.0) {
                  return ((MediaQuery.sizeOf(context).width - 144) * 1 / 8);
                } else {
                  return ((MediaQuery.sizeOf(context).width - 176) * 1 / 10);
                }
              }(),
              height: 85.0,
              decoration: BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 58.0,
                      height: 58.0,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: CachedNetworkImage(
                        fadeInDuration: Duration(milliseconds: 200),
                        fadeOutDuration: Duration(milliseconds: 200),
                        imageUrl: widget.image!,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/error_image.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      valueOrDefault<String>(
                        widget.name,
                        'Name',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 15.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            lineHeight: 1.2,
                          ),
                    ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ),
          );
        } else {
          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await widget.onMainTap?.call();
            },
            child: Container(
              width: () {
                if (MediaQuery.sizeOf(context).width < 810.0) {
                  return ((MediaQuery.sizeOf(context).width - 68) * 1 / 3);
                } else if ((MediaQuery.sizeOf(context).width >= 810.0) &&
                    (MediaQuery.sizeOf(context).width < 1280.0)) {
                  return ((MediaQuery.sizeOf(context).width - 104) * 1 / 5);
                } else if (MediaQuery.sizeOf(context).width >= 1280.0) {
                  return ((MediaQuery.sizeOf(context).width - 140) * 1 / 7);
                } else {
                  return ((MediaQuery.sizeOf(context).width - 176) * 1 / 9);
                }
              }(),
              height: 117.0,
              decoration: BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 90.0,
                      height: 90.0,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: CachedNetworkImage(
                        fadeInDuration: Duration(milliseconds: 200),
                        fadeOutDuration: Duration(milliseconds: 200),
                        imageUrl: widget.image!,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/error_image.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AutoSizeText(
                      valueOrDefault<String>(
                        widget.name,
                        'Name',
                      ).maybeHandleOverflow(
                        maxChars: 10,
                        replacement: '…',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 15.0,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            lineHeight: 1.2,
                          ),
                    ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ),
          );
        }
      },
    );
  }
}
