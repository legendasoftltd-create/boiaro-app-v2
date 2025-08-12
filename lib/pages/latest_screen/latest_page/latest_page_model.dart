import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_latest_book/no_latest_book_widget.dart';
import '/index.dart';
import 'dart:async';
import 'latest_page_widget.dart' show LatestPageWidget;
import 'package:flutter/material.dart';

class LatestPageModel extends FlutterFlowModel<LatestPageWidget> {
  ///  Local state fields for this page.

  bool? isLatest = false;

  int? latestIndex = 0;

  ///  State fields for stateful widgets in this page.

  // Model for SingleAppbar component.
  late SingleAppbarModel singleAppbarModel;
  bool apiRequestCompleted1 = false;
  String? apiRequestLastUniqueKey1;
  // Models for MainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in MainBookComponent widget.
  ApiCallResponse? getPopularDetete;
  bool apiRequestCompleted2 = false;
  String? apiRequestLastUniqueKey2;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in MainBookComponent widget.
  ApiCallResponse? getPopularAdd;
  // Model for NoLatestBook component.
  late NoLatestBookModel noLatestBookModel;

  @override
  void initState(BuildContext context) {
    singleAppbarModel = createModel(context, () => SingleAppbarModel());
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
    noLatestBookModel = createModel(context, () => NoLatestBookModel());
  }

  @override
  void dispose() {
    singleAppbarModel.dispose();
    mainBookComponentModels.dispose();
    noLatestBookModel.dispose();
  }

  /// Additional helper methods.
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

  Future waitForApiRequestCompleted2({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted2;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
