import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/index.dart';
import 'book_detailspage_widget.dart' show BookDetailspageWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class BookDetailspageModel extends FlutterFlowModel<BookDetailspageWidget> {
  ///  Local state fields for this page.

  bool? isRelated = false;

  int? relatedIndex = 0;

  bool? isProgress = false;

  ///  State fields for stateful widgets in this page.

  bool apiRequestCompleted2 = false;
  String? apiRequestLastUniqueKey2;
  // Stores action output result for [Backend Call - API (DownloadpdfApi)] action in Container widget.
  ApiCallResponse? downloadApiFunction;
  Completer<ApiCallResponse>? apiRequestCompleter3;
  // Stores action output result for [Backend Call - API (UsersubscriptionvalidityApi)] action in Container widget.
  ApiCallResponse? userdownloadvalidity;
  // Stores action output result for [Backend Call - API (DownloadpdfApi)] action in Container widget.
  ApiCallResponse? downloadApiFunctionPaid;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in Container widget.
  ApiCallResponse? getDetailBookDetete;
  Completer<ApiCallResponse>? apiRequestCompleter1;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in Container widget.
  ApiCallResponse? getDetailBookAdd;
  // Models for MainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in MainBookComponent widget.
  ApiCallResponse? getPopularDetete;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in MainBookComponent widget.
  ApiCallResponse? getPopularAdd;
  // Stores action output result for [Backend Call - API (UsersubscriptionvalidityApi)] action in Button widget.
  ApiCallResponse? uservalidity;

  @override
  void initState(BuildContext context) {
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
  }

  @override
  void dispose() {
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
      final requestComplete = apiRequestCompleted2;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted3({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter3?.isCompleted ?? false;
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
      final requestComplete = apiRequestCompleter1?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
