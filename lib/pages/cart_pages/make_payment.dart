import 'dart:developer';

import 'package:a_i_ebook_app/flutter_flow/flutter_flow_theme.dart';
import 'package:a_i_ebook_app/main.dart';
import 'package:a_i_ebook_app/pages/cart_pages/payment_screen.dart';
import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MakeCheckOutScreen extends StatefulWidget {
  final List<String> bookIds;
  final String jwtToken;
  final String userId;

  const MakeCheckOutScreen({
    Key? key,
    required this.bookIds,
    required this.jwtToken,
    required this.userId,
  }) : super(key: key);

  @override
  _MakeCheckOutScreenState createState() => _MakeCheckOutScreenState();
}

class _MakeCheckOutScreenState extends State<MakeCheckOutScreen> {
  late final CheckoutController _checkoutController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print("User ID: ${widget.userId}, JWT Token: ${widget.jwtToken}");
    _checkoutController = CheckoutController(
      jwtToken: widget.jwtToken,
      userId: widget.userId,
    );
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      print('Initiating payment for books: ${widget.bookIds}');

      final response = await _checkoutController.initiatePayment(widget.bookIds);
      print('Payment initiation response: $response');
      if (response['success'] == 1) {
        final tranId = response['tran_id'];
        final gatewayUrl = response['GatewayPageURL'];
        
        // Navigate to DigitalPaymentScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DigitalPaymentScreen(
              url: gatewayUrl,
              fromWallet: false, 
              tranId: tranId,
              bookIds: widget.bookIds,
              checkoutController: _checkoutController,
            ),
          ),
        );
      } else {
        setState(() {
          _error = response['message'] ?? 'Payment initiation failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('SSLCOMMERZ Payment'),
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () {
      //       Navigator.of(context).pop(false);
      //     },
      //   ),
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : const Center(child: Text('Redirecting to payment...')),
    );
  }
}


/// -----------------------
/// Checkout Controller
/// -----------------------

class CheckoutController {
  final String baseUrl = 'https://api.boiaro.com/api';
  final String jwtToken;
  final String userId;
  
  CheckoutController({
    required this.jwtToken,
    required this.userId,
  });

  // Initiate payment
  Future<Map<String, dynamic>> initiatePayment(List<String> bookIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchasebooks'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'books': bookIds,
          'paymentmode': 'SSLCOMMERZ'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment initiation error: $e');
    }
  }

  // Verify payment
  Future<Map<String, dynamic>> verifyPayment({
    required String tranId,
    required String valId,
    required List<String> bookIds,
    String cardIssuer = 'STANDARD CHARTERED BANK',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchasebooks'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'books': bookIds,
          'paymentmode': 'SSLCOMMERZ',
          'tran_id': tranId,
          'verificationData': {
            'val_id': valId,
            'card_issuer': cardIssuer,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to verify payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment verification error: $e');
    }
  }

  // Handle payment failure
  Future<Map<String, dynamic>> handlePaymentFailure({
    required String tranId,
    required List<String> bookIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchasebooks'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'books': bookIds,
          'paymentmode': 'SSLCOMMERZ',
          'tran_id': tranId,
          'status': 'FAILED'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to handle payment failure: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment failure handling error: $e');
    }
  }

  // Handle payment cancellation
  Future<Map<String, dynamic>> handlePaymentCancellation({
    required String tranId,
    required List<String> bookIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchasebooks'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'books': bookIds,
          'paymentmode': 'SSLCOMMERZ',
          'tran_id': tranId,
          'status': 'CANCELLED'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to handle payment cancellation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment cancellation handling error: $e');
    }
  }
}

/// -----------------------
/// Dialog Widget
/// -----------------------
class OrderPlaceDialogWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isFailed;
  final VoidCallback? onOkPressed;

  const OrderPlaceDialogWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isFailed = false,
    this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 60, color: isFailed ? Colors.red : Colors.green),
          const SizedBox(height: 15),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onOkPressed ?? () => Navigator.of(context).pop(),
            child:  Text("Back to Home", style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'SF Pro Display',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFailed ? Colors.red : Colors.green,
              minimumSize: Size(double.infinity, 56),
            ),
          )
        ]),
      ),
    );
  }
}

/// -----------------------
/// Animated Dialog Helper
/// -----------------------
Future<void> showAnimatedDialog(
  BuildContext context,
  Widget dialog, {
  bool dismissible = true,
  bool willFlip = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: "Dialog",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) {
      return dialog;
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        child: Opacity(opacity: anim1.value, child: child),
      );
    },
  );
}
