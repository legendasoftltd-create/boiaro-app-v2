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

import 'package:flutter_paypal/flutter_paypal.dart';
import '/flutter_flow/custom_functions.dart' as functions;

Future paypalCustom(
  BuildContext context,
  String clientId,
  String secretKey,
  String total,
  String currency,
  Future Function() onSuccessAction,
  Future Function() onErrorAction,
  Future Function() onCancelAction,
) async {
  // Add your function code here!
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (BuildContext context) => UsePaypal(
          sandboxMode: true,
          clientId: clientId,
          secretKey: secretKey,
          returnURL: "https://samplesite.com/return",
          cancelURL: "https://samplesite.com/cancel",
          transactions: [
            {
              "amount": {
                "total": total,
                "currency": currency,
                //  "details": {
                //"subtotal": subtotal,
                //"shipping": shipping,
                //"shipping_discount": 0
                //  }
              },
              "description": "The payment transaction description.",
              // "payment_options": {
              //   "allowed_payment_method":
              //       "INSTANT_FUNDING_SOURCE"
              // },
              //"item_list": {
              //  "items": functions.getPaypalItemsLine(itemsList),

              // shipping address is not required though
              //"shipping_address": {
              //"recipient_name":
              //"${shippingAddress['first_name']} ${shippingAddress['last_name']}",
              //  "line1": shippingAddress['address_1'],
              //   "line2": shippingAddress['address_2'],
              //      "city": shippingAddress['city'],
              //       "country_code": shippingAddress['country'],
              //    "postal_code": shippingAddress['postcode'],
              //      "phone": shippingAddress['phone'],
              //   "state": shippingAddress['state']
              //    },
              //   }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            print("onSuccess: $params");
            FFAppState().update(() {
              FFAppState().paypalTransationId = params["paymentId"];
            });
            FFAppState().update(() {
              FFAppState().paymentSuccessCheck = true;
            });
            onSuccessAction.call();
          },
          onError: (error) {
            print("onError: $error");
            FFAppState().update(() {
              FFAppState().paymentSuccessCheck = false;
            });
            onErrorAction.call();
          },
          onCancel: (params) {
            print('cancelled: $params');
            FFAppState().update(() {
              FFAppState().paymentSuccessCheck = false;
            });
            onCancelAction.call();
          }),
    ),
  );
}
