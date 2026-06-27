import '/flutter_flow/flutter_flow_util.dart';
import 'rate_app_dialog_widget.dart' show RateAppDialogWidget;
import 'package:flutter/material.dart';

class RateAppDialogModel extends FlutterFlowModel<RateAppDialogWidget> {
  ///  State fields for stateful widgets in this component.
  int selectedStars = 5;
  bool showFeedbackField = false;
  
  // Model for feedback text input.
  FocusNode? feedbackFocusNode;
  TextEditingController? feedbackTextController;
  String? Function(BuildContext, String?)? feedbackTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    feedbackFocusNode?.dispose();
    feedbackTextController?.dispose();
  }
}
