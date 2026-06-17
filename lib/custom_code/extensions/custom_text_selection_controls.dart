// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import '/flutter_flow/flutter_flow_theme.dart';

// class CustomTextSelectionControls extends MaterialTextSelectionControls {
//   final VoidCallback onHighlight;
//   final VoidCallback onListen;

//   CustomTextSelectionControls({
//     required this.onHighlight,
//     required this.onListen,
//   });

//   @override
//   Widget buildToolbar(
//     BuildContext context,
//     Rect globalEditableRegion,
//     double textLineHeight,
//     Offset selectionMidpoint,
//     List<TextSelectionPoint> endpoints,
//     TextSelectionDelegate delegate,
//     ValueListenable<ClipboardStatus>? clipboardStatus,
//     Offset? lastSecondaryTapDownPosition,
//   ) {
//     return _CustomTextSelectionToolbar(
//       globalEditableRegion: globalEditableRegion,
//       textLineHeight: textLineHeight,
//       selectionMidpoint: selectionMidpoint,
//       endpoints: endpoints,
//       delegate: delegate,
//       clipboardStatus: clipboardStatus,
//       onHighlight: onHighlight,
//       onListen: onListen,
//     );
//   }
// }

// class _CustomTextSelectionToolbar extends StatelessWidget {
//   const _CustomTextSelectionToolbar({
//     required this.globalEditableRegion,
//     required this.textLineHeight,
//     required this.selectionMidpoint,
//     required this.endpoints,
//     required this.delegate,
//     required this.clipboardStatus,
//     required this.onHighlight,
//     required this.onListen,
//   });

//   final Rect globalEditableRegion;
//   final double textLineHeight;
//   final Offset selectionMidpoint;
//   final List<TextSelectionPoint> endpoints;
//   final TextSelectionDelegate delegate;
//   final ValueListenable<ClipboardStatus>? clipboardStatus;
//   final VoidCallback onHighlight;
//   final VoidCallback onListen;

//   @override
//   Widget build(BuildContext context) {
//     final items = <Widget>[
//       TextSelectionToolbarTextButton(
//         padding: TextSelectionToolbarTextButton.getPadding(1, 4),
//         onPressed: () {
//           delegate.selectAll(SelectionChangedCause.toolbar);
//         },
//         child: const Text('Select All',style: TextStyle(color: Colors.white)),
//       ),
//       TextSelectionToolbarTextButton(
//         padding: TextSelectionToolbarTextButton.getPadding(2, 4),
//         onPressed: () {
//           onHighlight();
//         },
//         child: const Text('Highlight',style: TextStyle(color: Colors.white)),
//       ),
//       TextSelectionToolbarTextButton(
//         padding: TextSelectionToolbarTextButton.getPadding(3, 4),
//         onPressed: () {
//           onListen();
//         },
//         child: const Text('Listen',style: TextStyle(color: Colors.white)),
//       ),
//     ];

//     return TextSelectionToolbar(
//       anchorAbove: globalEditableRegion.topCenter + selectionMidpoint,
//       anchorBelow: globalEditableRegion.bottomCenter + selectionMidpoint,
//       toolbarBuilder: (context, child) {
//         return Material(
//           color: FlutterFlowTheme.of(context).primary,
//           borderRadius: const BorderRadius.all(Radius.circular(28.0)),
//           elevation: 2.0,
//           child: child,
//         );
//       },
//       children: items,
//     );
//   }
// }