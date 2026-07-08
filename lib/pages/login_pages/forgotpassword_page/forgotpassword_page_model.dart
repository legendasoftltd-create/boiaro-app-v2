import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/index.dart';
import 'forgotpassword_page_widget.dart' show ForgotpasswordPageWidget;
import 'package:flutter/material.dart';

class ForgotpasswordPageModel
    extends FlutterFlowModel<ForgotpasswordPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for CustomCenterAppbar component.
  late CustomCenterAppbarModel customCenterAppbarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  String? _textControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter correct email address',
        bnText: 'অনুগ্রহ করে সঠিক ইমেইল ঠিকানা লিখুন',
      );
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter correct email address',
        bnText: 'অনুগ্রহ করে সঠিক ইমেইল ঠিকানা লিখুন',
      );
    }
    return null;
  }

  // Stores action output result for [Backend Call - API (ForgotpasswordApi)] action in Button widget.
  ApiCallResponse? forgotPasswordFunction;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
    textControllerValidator = _textControllerValidator;
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
