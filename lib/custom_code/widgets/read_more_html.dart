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
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class ReadMoreHtml extends StatefulWidget {
  const ReadMoreHtml({
    super.key,
    this.width,
    this.height,
    this.htmlContent,
    this.maxLength,
  });

  final double? width;
  final double? height;
  final String? htmlContent;
  final int? maxLength;

  @override
  State<ReadMoreHtml> createState() => _ReadMoreHtmlState();
}

class _ReadMoreHtmlState extends State<ReadMoreHtml> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.htmlContent ?? '';
    final maxLength = widget.maxLength ?? content.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HtmlWidget(
          _isExpanded
              ? content
              : (content.length > maxLength
                  ? '${content.substring(0, maxLength)}...'
                  : content),
          onTapUrl: (url) {
            launchURL(url);
            return true;
          },
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(left: 0),
            child: Text(
              _isExpanded ? 'Read Less' : 'Read More',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'SF Pro Display',
                    color: FlutterFlowTheme.of(context).primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: false,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
// bool _isExpanded = false;

//   String _getTruncatedContent(String content, int maxLength) {
//     if (content.length <= maxLength) {
//       return content;
//     } else {
//       return '${content.substring(0, maxLength)}...';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Html(
//           data: _isExpanded
//               ? widget.htmlContent!
//               : _getTruncatedContent(widget.htmlContent!, widget.maxLength!),
//           onLinkTap: (url, attributes, element) {
//             launchURL(url!);
//           },
//           style: {
//             "p": Style(
//               color: FlutterFlowTheme.of(context).primaryText,
//               fontSize: FontSize(16),
//               fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
//               letterSpacing: 0.16,
//               fontWeight: FontWeight.w400,
//             ),
//             "strong": Style(
//               color: FlutterFlowTheme.of(context).primaryText,
//               fontSize: FontSize(16),
//               fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
//               letterSpacing: 0.16,
//               fontWeight: FontWeight.w600,
//             ),
//             "h2": Style(
//               color: FlutterFlowTheme.of(context).primaryText,
//               fontSize: FontSize(20),
//               fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
//               letterSpacing: 0.20,
//               fontWeight: FontWeight.w600,
//             ),
//             "h3": Style(
//               color: FlutterFlowTheme.of(context).primaryText,
//               fontSize: FontSize(18),
//               fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
//               letterSpacing: 0.18,
//               fontWeight: FontWeight.w500,
//             ),
//           },
//         ),
//         widget.htmlContent!.length >= widget.maxLength!
//             ? GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _isExpanded = !_isExpanded;
//                   });
//                 },
//                 child: Padding(
//                   padding: EdgeInsets.zero,
//                   child: Text(
//                     _isExpanded ? '  Read Less' : '  Read More',
//                     style: FlutterFlowTheme.of(context).bodyMedium.override(
//                           fontFamily: 'SF Pro Display',
//                           color: FlutterFlowTheme.of(context).primary,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           useGoogleFonts: false,
//                         ),
//                   ),
//                 ),
//               )
//             : SizedBox(),
//       ],
//     );
//   }
// }
