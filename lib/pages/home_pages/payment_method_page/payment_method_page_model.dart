import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/index.dart';
import 'payment_method_page_widget.dart' show PaymentMethodPageWidget;
import 'package:flutter/material.dart';

class PaymentMethodPageModel extends FlutterFlowModel<PaymentMethodPageWidget> {
  ///  Local state fields for this page.

  int? selectpayment = 0;

  String planmode = 'stripe';

  ///  State fields for stateful widgets in this page.

  // Model for CustomCenterAppbar component.
  late CustomCenterAppbarModel customCenterAppbarModel;
  // Stores action output result for [Backend Call - API (GetuserApi)] action in Button widget.
  ApiCallResponse? getuserR;
  // Stores action output result for [Backend Call - API (UsersubscriptionApi)] action in Button widget.
  ApiCallResponse? subscriptionR;
  // Stores action output result for [Backend Call - API (UsersubscriptionApi)] action in Button widget.
  ApiCallResponse? subscriptionrazorR;
  // Stores action output result for [Backend Call - API (UsersubscriptionApi)] action in Button widget.
  ApiCallResponse? subscriptionpayR;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
  }
}
