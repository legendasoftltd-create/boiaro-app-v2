import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'verifiy_email_otp_dialog_widget.dart' show VerifiyEmailOtpDialogWidget;
import 'package:flutter/material.dart';

class VerifiyEmailOtpDialogModel
    extends FlutterFlowModel<VerifiyEmailOtpDialogWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for PinCode widget.
  TextEditingController? pinCodeController;
  FocusNode? pinCodeFocusNode;
  String? Function(BuildContext, String?)? pinCodeControllerValidator;
  String? _pinCodeControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Please enter a valid OTP',
        bnText: 'অনুগ্রহ করে সঠিক OTP লিখুন',
      );
    }
    if (val.length < 4) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Requires 4 characters.',
        bnText: 'ন্যূনতম ৪টি অক্ষর প্রয়োজন।',
      );
    }
    return null;
  }

  // Stores action output result for [Backend Call - API (UserverificationApi)] action in Button widget.
  ApiCallResponse? otpVerifiedApi;

  @override
  void initState(BuildContext context) {
    pinCodeController = TextEditingController();
    pinCodeControllerValidator = _pinCodeControllerValidator;
  }

  @override
  void dispose() {
    pinCodeFocusNode?.dispose();
    pinCodeController?.dispose();
  }
}
