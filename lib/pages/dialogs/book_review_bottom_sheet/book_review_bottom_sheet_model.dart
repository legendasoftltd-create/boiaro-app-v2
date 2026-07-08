import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'book_review_bottom_sheet_widget.dart' show BookReviewBottomSheetWidget;
import 'package:flutter/material.dart';

class BookReviewBottomSheetModel
    extends FlutterFlowModel<BookReviewBottomSheetWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for RatingBar widget.
  double? ratingBarValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  String? _textControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Review Field is required',
        bnText: 'রিভিউ লেখা আবশ্যক',
      );
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (AddreviewApi)] action in Button widget.
  ApiCallResponse? addReviewFunction;

  @override
  void initState(BuildContext context) {
    textControllerValidator = _textControllerValidator;
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
