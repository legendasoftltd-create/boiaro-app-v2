// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:readmore/readmore.dart';

class DescriptionWidgets extends StatefulWidget {
  const DescriptionWidgets({
    super.key,
    this.width,
    this.height,
    this.text,
  });

  final double? width;
  final double? height;
  final String? text;

  @override
  State<DescriptionWidgets> createState() => _DescriptionWidgetsState();
}

class _DescriptionWidgetsState extends State<DescriptionWidgets> {
  @override
  Widget build(BuildContext context) => Container(
        // height: widget.height,
        // width: widget.width,
        // margin: EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: ReadMoreText(
          widget.text!,
          trimLines: 4,
          trimMode: TrimMode.Line,
          trimCollapsedText: 'Read more',
          trimExpandedText: 'Read less',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'SF Pro Display',
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                useGoogleFonts: false,
                lineHeight: 1.5,
              ),
          lessStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'SF Pro Display',
                color: FlutterFlowTheme.of(context).primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                useGoogleFonts: false,
              ),
          moreStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'SF Pro Display',
                color: FlutterFlowTheme.of(context).primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                useGoogleFonts: false,
              ),
        ),
      );
}
