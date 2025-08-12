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

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic>? paymentIntentData;

Future stripeCustom(
  BuildContext context,
  String amount,
  String curency,
  Future Function() successAction,
  Future Function() failedAction,
  String secretKey,
) async {
  // Add your function code here!
  try {
    paymentIntentData = await createPaymentIntent(amount, curency, secretKey);
    print("paymentIntentData==$paymentIntentData");

    if (paymentIntentData != null) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          googlePay: const PaymentSheetGooglePay(merchantCountryCode: "IN"),
          merchantDisplayName: 'Prospects',
          customerId: paymentIntentData!['customer'],
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          customerEphemeralKeySecret: paymentIntentData!['ephemeralKey'],
        ),
      );
      displayPaymentSheet(context, successAction, failedAction);
    }
  } catch (e) {}
}

displayPaymentSheet(BuildContext context, Future Function() successAction,
    Future Function() failedAction) async {
  try {
    await Stripe.instance.presentPaymentSheet().then(
      (value) {
        print("vgalue--------${value}");
      },
    );
    // Get.snackbar('Payment', 'Payment Successful',
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: accentColor,
    //     colorText: whiteColor,
    //     margin: const EdgeInsets.all(10),
    //     duration: const Duration(seconds: 2));

    // showCustomToast("Success");
    FFAppState().update(() {
      FFAppState().paypalTransationId = paymentIntentData!['id'];
    });
    successAction.call();

    // notify(true);
    // isProcess.value = false;
  } on Exception catch (e) {
    // isProcess.value = false;
    if (e is StripeException) {
      failedAction.call();
    } else {
      failedAction.call();
    }
  } catch (e) {
    failedAction.call();
  }
}

createPaymentIntent(String amount, String currency, String secretKey) async {
  try {
    Map<String, dynamic> body = {
      'amount': calculateAmount(amount),
      'currency': currency,
      'payment_method_types[]': 'card'
    };
    var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {
          'Authorization': 'Bearer $secretKey',
          // 'Authorization': 'Bearer ${paymentGateway!.stripe!.stripeSecret}',
          'Content-Type': 'application/x-www-form-urlencoded'
        });
    return jsonDecode(response.body);
  } catch (err) {}
}

calculateAmount(String amount) {
  double a = (double.parse(amount) * 100);
  int s = a.toInt();
  return s.toString();
}
