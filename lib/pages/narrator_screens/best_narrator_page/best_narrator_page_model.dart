import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_narrator_yet/no_narrator_yet_widget.dart';
import '/index.dart';
import 'best_narrator_page_widget.dart' show BestNarratorPageWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class BestNarratorPageModel extends FlutterFlowModel<BestNarratorPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SingleAppbar component.
  late SingleAppbarModel singleAppbarModel;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  // Models for CategoryComponent dynamic component.
  late FlutterFlowDynamicModels<CategoryComponentModel> categoryComponentModels;
  // Model for NoNarratorYet component.
  late NoNarratorYetModel noNarratorYetModel;

  @override
  void initState(BuildContext context) {
    singleAppbarModel = createModel(context, () => SingleAppbarModel());
    categoryComponentModels =
        FlutterFlowDynamicModels(() => CategoryComponentModel());
    noNarratorYetModel = createModel(context, () => NoNarratorYetModel());
  }

  @override
  void dispose() {
    singleAppbarModel.dispose();
    categoryComponentModels.dispose();
    noNarratorYetModel.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
