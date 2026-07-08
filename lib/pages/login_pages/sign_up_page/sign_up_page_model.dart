import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_page_widget.dart' show SignUpPageWidget;
import 'package:flutter/material.dart';

class SignUpPageModel extends FlutterFlowModel<SignUpPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  String? _textController1Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter valid first name',
        bnText: 'অনুগ্রহ করে সঠিক প্রথম নাম লিখুন',
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  String? _textController2Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter valid last name',
        bnText: 'অনুগ্রহ করে সঠিক শেষ নাম লিখুন',
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  String? _textController3Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter valid username',
        bnText: 'অনুগ্রহ করে সঠিক ইউজারনাম লিখুন',
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  String? _textController4Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter valid email address',
        bnText: 'অনুগ্রহ করে সঠিক ইমেইল ঠিকানা লিখুন',
      );
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter valid email address',
        bnText: 'অনুগ্রহ করে সঠিক ইমেইল ঠিকানা লিখুন',
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController5;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? textController5Validator;
  String? _textController5Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter valid password',
        bnText: 'অনুগ্রহ করে সঠিক পাসওয়ার্ড লিখুন',
      );
    }
    return null;
  }

  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // Stores action output result for [Backend Call - API (CheckregistereduserApi)] action in Button widget.
  ApiCallResponse? checkUserFunction;
  // Stores action output result for [Backend Call - API (SignupApi)] action in Button widget.
  ApiCallResponse? signupApis;

  @override
  void initState(BuildContext context) {
    textController1Validator = _textController1Validator;
    textController2Validator = _textController2Validator;
    textController3Validator = _textController3Validator;
    textController4Validator = _textController4Validator;
    passwordVisibility = false;
    textController5Validator = _textController5Validator;
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    textFieldFocusNode5?.dispose();
    textController5?.dispose();
  }
}
