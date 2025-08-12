import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_favorites_yet/no_favorites_yet_widget.dart';
import '/index.dart';
import 'dart:async';
import 'favourite_page_widget.dart' show FavouritePageWidget;
import 'package:flutter/material.dart';

class FavouritePageModel extends FlutterFlowModel<FavouritePageWidget> {
  ///  Local state fields for this page.

  bool? isFav = false;

  int? favIndex = 0;

  ///  State fields for stateful widgets in this page.

  // Model for CustomCenterAppbar component.
  late CustomCenterAppbarModel customCenterAppbarModel;
  Completer<ApiCallResponse>? apiRequestCompleter;
  // Models for MainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (RemoveFavouritebook)] action in MainBookComponent widget.
  ApiCallResponse? getAllPoolDetete;
  // Model for NoFavoritesYet component.
  late NoFavoritesYetModel noFavoritesYetModel;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
    noFavoritesYetModel = createModel(context, () => NoFavoritesYetModel());
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
    mainBookComponentModels.dispose();
    noFavoritesYetModel.dispose();
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
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
