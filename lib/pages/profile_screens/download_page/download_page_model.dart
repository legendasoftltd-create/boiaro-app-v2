import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_download_yet/no_download_yet_widget.dart';
import '/index.dart';
import 'dart:async';
import 'download_page_widget.dart' show DownloadPageWidget;
import 'package:flutter/material.dart';

class DownloadPageModel extends FlutterFlowModel<DownloadPageWidget> {
  ///  Local state fields for this page.

  bool? isDownload = false;

  int? downloadIndex = 0;

  ///  State fields for stateful widgets in this page.

  // Model for CustomCenterAppbar component.
  late CustomCenterAppbarModel customCenterAppbarModel;
  Completer<ApiCallResponse>? apiRequestCompleter1;
  // Models for MainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in MainBookComponent widget.
  ApiCallResponse? getPopularDetete;
  bool apiRequestCompleted2 = false;
  String? apiRequestLastUniqueKey2;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in MainBookComponent widget.
  ApiCallResponse? getPopularAdd;
  // Model for NoDownloadYet component.
  late NoDownloadYetModel noDownloadYetModel;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
    noDownloadYetModel = createModel(context, () => NoDownloadYetModel());
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
    mainBookComponentModels.dispose();
    noDownloadYetModel.dispose();
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
      final requestComplete = apiRequestCompleter1?.isCompleted ?? false;
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
