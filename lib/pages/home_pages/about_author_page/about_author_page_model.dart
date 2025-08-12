import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/index.dart';
import 'about_author_page_widget.dart' show AboutAuthorPageWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class AboutAuthorPageModel extends FlutterFlowModel<AboutAuthorPageWidget> {
  ///  Local state fields for this page.

  bool? isPopular = false;

  int? popularIndex = 0;

  ///  State fields for stateful widgets in this page.

  // Model for CustomCenterAppbar component.
  late CustomCenterAppbarModel customCenterAppbarModel;
  Completer<ApiCallResponse>? apiRequestCompleter2;
  // Models for MainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in MainBookComponent widget.
  ApiCallResponse? getPopularDetete;
  bool apiRequestCompleted1 = false;
  String? apiRequestLastUniqueKey1;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in MainBookComponent widget.
  ApiCallResponse? getPopularAdd;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
    mainBookComponentModels.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted2({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter2?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted1({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted1;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
