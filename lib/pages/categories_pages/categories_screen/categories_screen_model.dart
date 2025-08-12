import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_categories_yet/no_categories_yet_widget.dart';
import '/index.dart';
import 'categories_screen_widget.dart' show CategoriesScreenWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class CategoriesScreenModel extends FlutterFlowModel<CategoriesScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SingleAppbar component.
  late SingleAppbarModel singleAppbarModel;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  // Models for CategoryComponent dynamic component.
  late FlutterFlowDynamicModels<CategoryComponentModel> categoryComponentModels;
  // Model for NoCategoriesYet component.
  late NoCategoriesYetModel noCategoriesYetModel;

  @override
  void initState(BuildContext context) {
    singleAppbarModel = createModel(context, () => SingleAppbarModel());
    categoryComponentModels =
        FlutterFlowDynamicModels(() => CategoryComponentModel());
    noCategoriesYetModel = createModel(context, () => NoCategoriesYetModel());
  }

  @override
  void dispose() {
    singleAppbarModel.dispose();
    categoryComponentModels.dispose();
    noCategoriesYetModel.dispose();
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
