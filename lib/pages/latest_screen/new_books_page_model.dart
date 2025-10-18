import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_latest_book/no_latest_book_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'new_books_page_widget.dart' show NewBooksPageWidget;
import 'package:flutter/scheduler.dart';

class NewBooksPageModel extends FlutterFlowModel<NewBooksPageWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // Models for mainBookComponent dynamic component.
  late FlutterFlowDynamicModels<MainBookComponentModel> mainBookComponentModels;
  // Stores action output result for [Backend Call - API (removeFavouritebook)] action in MainBookComponent
  ApiCallResponse? getPopularDetete;
  // Stores action output result for [Backend Call - API (addFavouriteBookApi)] action in MainBookComponent
  ApiCallResponse? getPopularAdd;
  // Model for noLatestBook component.
  late NoLatestBookModel noLatestBookModel;

  bool apiRequestCompleted1 = false;
  String? apiRequestLastUniqueKey1;
  bool apiRequestCompleted2 = false;
  String? apiRequestLastUniqueKey2;

  int newBooksIndex = 0;
  bool isNewBook = false;

  @override
  void initState(BuildContext context) {
    mainBookComponentModels =
        FlutterFlowDynamicModels(() => MainBookComponentModel());
    noLatestBookModel = createModel(context, () => NoLatestBookModel());
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    mainBookComponentModels.dispose();
    noLatestBookModel.dispose();
  }

}
