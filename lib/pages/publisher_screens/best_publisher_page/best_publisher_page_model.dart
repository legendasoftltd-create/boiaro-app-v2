import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_author_yet/no_author_yet_widget.dart';
import 'package:flutter/material.dart';

class BestPublisherPageModel extends FlutterFlowModel {
  ///  State fields for stateful widgets in this page.

  // Model for singleAppbar component.
  late SingleAppbarModel singleAppbarModel;
  // Models for categoryComponent components.
  late FlutterFlowDynamicModels<CategoryComponentModel> categoryComponentModels;
  // Model for noAuthorYet component.
  late NoAuthorYetModel noAuthorYetModel;

  /// Initialization and disposal methods.

  @override
  void initState(BuildContext context) {
    singleAppbarModel = createModel(context, () => SingleAppbarModel());
    categoryComponentModels =
        FlutterFlowDynamicModels(() => CategoryComponentModel());
    noAuthorYetModel = createModel(context, () => NoAuthorYetModel());
  }

  @override
  void dispose() {
    singleAppbarModel.dispose();
    categoryComponentModels.dispose();
    noAuthorYetModel.dispose();
  }

  /// Action blocks are added here.

  /// Additional helper methods are added here.

  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;

  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
