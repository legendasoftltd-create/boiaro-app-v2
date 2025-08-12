import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/index.dart';
import 'dart:async';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  bool? isTrending = false;

  int? trendingIndex = 0;

  bool? isPopular = false;

  int? popularIndex = 0;

  ///  State fields for stateful widgets in this page.

  bool apiRequestCompleted1 = false;
  String? apiRequestLastUniqueKey1;
  bool apiRequestCompleted4 = false;
  String? apiRequestLastUniqueKey4;
  bool apiRequestCompleted2 = false;
  String? apiRequestLastUniqueKey2;
  bool apiRequestCompleted5 = false;
  String? apiRequestLastUniqueKey5;
  bool apiRequestCompleted3 = false;
  String? apiRequestLastUniqueKey3;
  // Models for CategoryComponent dynamic component.
  late FlutterFlowDynamicModels<CategoryComponentModel>
      categoryComponentModels1;
  // Models for MainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in MainBookComponent widget.
  ApiCallResponse? getPopularHomeDetete;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in MainBookComponent widget.
  ApiCallResponse? getPopularHomeAdd;
  // Models for CategoryComponent dynamic component.
  late FlutterFlowDynamicModels<CategoryComponentModel>
      categoryComponentModels2;
  // Models for ListMainContainerComponent dynamic component.
  late FlutterFlowDynamicModels<ListMainContainerComponentModel>
      listMainContainerComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in ListMainContainerComponent widget.
  ApiCallResponse? getPopularDetete;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in ListMainContainerComponent widget.
  ApiCallResponse? getPopularAdd;

  @override
  void initState(BuildContext context) {
    categoryComponentModels1 =
        FlutterFlowDynamicModels(() => CategoryComponentModel());
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
    categoryComponentModels2 =
        FlutterFlowDynamicModels(() => CategoryComponentModel());
    listMainContainerComponentModels =
        FlutterFlowDynamicModels(() => ListMainContainerComponentModel());
  }

  @override
  void dispose() {
    categoryComponentModels1.dispose();
    mainBookComponentModels.dispose();
    categoryComponentModels2.dispose();
    listMainContainerComponentModels.dispose();
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

  Future waitForApiRequestCompleted4({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted4;
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

  Future waitForApiRequestCompleted5({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted5;
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
      final requestComplete = apiRequestCompleted3;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
