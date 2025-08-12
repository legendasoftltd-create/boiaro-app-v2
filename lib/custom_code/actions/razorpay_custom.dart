// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions
import 'package:razorpay_flutter/razorpay_flutter.dart';

Future razorpayCustom(
  BuildContext context,
  String keyId,
  String amount,
  String name,
  String description,
  String userContect,
  String userEmail,
  Future Function() successAction,
  Future Function() errorAction,
  String currency,
) async {
  // Add your function code here!
  Razorpay razorpay = Razorpay();
  var options = {
    'key': keyId,
    'amount': calculateAmount(amount),
    'currency': currency,
    'name': name,
    'description': description,
    'retry': {'enabled': true, 'max_count': 1},
    'send_sms_hash': true,
    'prefill': {'contact': userContect, 'email': userEmail},
    // 'external': {
    //   'wallets': ['paytm']
    // }
    'method': ['upi', 'netbanking', 'debit_card', 'credit_card']
  };
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    handlePaymentErrorResponse(response, errorAction);
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse response) {
    handlePaymentSuccessResponse(response, successAction);
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
      (ExternalWalletResponse response) {
    handleExternalWalletSelected(response, context);
  });
  razorpay.open(options);
}

void handlePaymentErrorResponse(
    PaymentFailureResponse response, Future Function() errorAction) {
  /*
    * PaymentFailureResponse contains three values:
    * 1. Error Code
    * 2. Error Description
    * 3. Metadata
    * */
  print("Payment Failed====================");
  FFAppState().update(() {
    FFAppState().paymentSuccessCheck = false;
  });
  errorAction.call();

  // showAlertDialog(context, "Payment Failed",
  //     "Code: ${response.code}\nDescription: ${response.message}\nMetadata:${response.error.toString()}");
}

void handlePaymentSuccessResponse(
    PaymentSuccessResponse response, Future Function() successAction) {
  /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
  // print(response.data.toString());
  FFAppState().update(() {
    FFAppState().paymentSuccessCheck = true;
  });
  FFAppState().update(() {
    FFAppState().paypalTransationId = response.paymentId!;
  });
  print("Payment Successful====================");
  successAction.call();
  // showAlertDialog(
  //     context, "Payment Successful", "Payment ID: ${response.paymentId}");
}

void handleExternalWalletSelected(
    ExternalWalletResponse response, BuildContext context) {
  print("External Wallet Selected====================");
  showAlertDialog(
      context, "External Wallet Selected", "${response.walletName}");
}

void showAlertDialog(BuildContext context, String title, String message) {
  // set up the buttons
  Widget continueButton = ElevatedButton(
    child: const Text("Continue"),
    onPressed: () {},
  );
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
  );
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

calculateAmount(String amount) {
  double a = (double.parse(amount) * 100);
  int s = a.toInt();
  return s;
}
