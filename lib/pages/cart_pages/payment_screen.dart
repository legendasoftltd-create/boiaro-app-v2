import 'dart:developer';
import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:a_i_ebook_app/index.dart';
import 'package:a_i_ebook_app/flutter_flow/nav/nav.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final String tranId;
  final List<String> bookIds;
  final CheckoutController checkoutController;

  const PaymentWebView({
    super.key,
    required this.url,
    required this.tranId,
    required this.bookIds,
    required this.checkoutController,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = false;
  bool isPaymentSuccess = false; // ✅ track payment success

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 🚫 Prevent back navigation when payment successful
      onWillPop: () async {
        if (isPaymentSuccess) return false;
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Payment"),
          automaticallyImplyLeading: !isPaymentSuccess, // hide back button when success
        ),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),

                onWebViewCreated: (controller) {
                  webViewController = controller;
                },

                shouldOverrideUrlLoading: (controller, action) async {
                  final uri = action.request.url;
                  if (uri != null) {
                    final url = uri.toString();
                    log('Intercepted URL: $url');

                    if (url.contains('payment-success') ||
                        url.contains('payment-fail') ||
                        url.contains('payment-cancel')) {
                      setState(() => isLoading = true);
                      _handleUrlChange(url);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },

                onProgressChanged: (controller, progressValue) {
                  setState(() {
                    progress = progressValue / 100;
                  });
                },
              ),

              // 🔄 Progress bar
              if (progress < 1.0)
                LinearProgressIndicator(value: progress),

              // 🕑 Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUrlChange(String url) {
    final uri = Uri.parse(url);
    final tranId = uri.queryParameters['tran_id'];

    // ✅ Success
    if (url.contains('payment-success')) {
      if (tranId != null) {
        widget.checkoutController.verifyPayment(tranId: tranId);
      }
      setState(() {
        isPaymentSuccess = true; // 🚫 disable back
        isLoading = false;
      });
      _showSuccessDialog("Payment successful");
      log('✅ Success URL: $url');
      return;
    }

    // ❌ Failure
    if (url.contains('payment-fail')) {
      if (tranId != null) {
        widget.checkoutController
            .handlePaymentFailure(tranId: tranId, bookIds: widget.bookIds);
      }
      setState(() => isLoading = false);
      _showErrorDialog('Payment failed');
      return;
    }

    // 🚫 Cancelled
    if (url.contains('payment-cancel')) {
      if (tranId != null) {
        widget.checkoutController
            .handlePaymentCancellation(tranId: tranId, bookIds: widget.bookIds);
      }
      setState(() => isLoading = false);
      _showCancellationDialog('Payment cancelled');
      log('❎ Cancel URL: $url');
      return;
    }
  }
void _showSuccessDialog(String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // 🚫 prevent tap outside
    builder: (context) {
      return PopScope(
        canPop: false, // 🚫 prevent back press
        child: OrderPlaceDialogWidget(
          icon: Icons.check_circle_rounded,
          title: "Payment Successful",
          description: message,
          isSuccess: true,
          onOkPressed: () {
            Navigator.of(context).pop(); // ✅ close manually
            context.read<CartProvider>().clear();
            context.goNamed(ProfilePageWidget.routeName);
            context.pushNamed(PurchaseHistoryPageWidget.routeName);
          },
        ),
      );
    },
  );
}


  void _showErrorDialog(String message) {
    showAnimatedDialog(
      context,
      OrderPlaceDialogWidget(
        icon: Icons.clear,
        title: "Payment Failed",
        description: message,
        isFailed: true,
      ),
      dismissible: false,
      willFlip: true,
    ).then((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }

  void _showCancellationDialog(String message) {
    showAnimatedDialog(
      context,
      OrderPlaceDialogWidget(
        icon: Icons.cancel,
        title: "Payment Cancelled",
        description: message,
        isFailed: true,
      ),
      dismissible: false,
      willFlip: true,
    ).then((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }
}
