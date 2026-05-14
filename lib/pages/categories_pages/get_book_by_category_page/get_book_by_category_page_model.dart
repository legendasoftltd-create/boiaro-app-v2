import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/empty_components/no_categories_yet/no_categories_yet_widget.dart';
import '/index.dart';
import 'dart:async';
import 'get_book_by_category_page_widget.dart' show GetBookByCategoryPageWidget;
import 'package:flutter/material.dart';

class GetBookByCategoryPageModel
    extends FlutterFlowModel<GetBookByCategoryPageWidget> {
  ///  Local state fields for this page.

  bool? isCategoryBook = false;

  int? categoryBookIndex = 0;

  List<String> purchasedBookIds = [];

  ///  State fields for stateful widgets in this page.

  // Model for CustomCenterAppbar component.
  late CustomCenterAppbarModel customCenterAppbarModel;
  Completer<ApiCallResponse>? apiRequestCompleter2;
  // Models for ListMainContainerComponent dynamic component.
  late FlutterFlowDynamicModels<ListMainContainerComponentModel>
      listMainContainerComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in ListMainContainerComponent widget.
  ApiCallResponse? getPopularDetete;
  bool apiRequestCompleted1 = false;
  String? apiRequestLastUniqueKey1;
  // Stores action output result for [Backend Call - API (AddFavouriteBookApi)] action in ListMainContainerComponent widget.
  ApiCallResponse? getPopularAdd;
  // Model for NoCategoriesYet component.
  late NoCategoriesYetModel noCategoriesYetModel;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
    listMainContainerComponentModels =
        FlutterFlowDynamicModels(() => ListMainContainerComponentModel());
    noCategoriesYetModel = createModel(context, () => NoCategoriesYetModel());
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
    listMainContainerComponentModels.dispose();
    noCategoriesYetModel.dispose();
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
