import 'dart:developer';
import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';


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
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: SafeArea(
        child: Column(
          children: [
            (progress < 1.0)
                ? LinearProgressIndicator(value: progress)
                : const SizedBox.shrink(),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, uri) {
                  if (uri != null) {
                    _handleUrlChange(uri.toString());
                  }
                },
                onProgressChanged: (controller, progressValue) {
                  setState(() {
                    progress = progressValue / 100;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUrlChange(String url) {
    // Success
    if (url.contains('payment-success')||url.contains('payment/sslcommerz/return')) {
      widget.checkoutController.verifyPayment(tranId: widget.tranId);
      _showSuccessDialog("Payment suceess");
      log('Success URL: $url');
      return;
    }

    // Failure
    if (url.contains('payment-fail')) {
      widget.checkoutController.verifyPayment(tranId: widget.tranId);
       _showErrorDialog('Payment failed');
      return;
    }

    // Cancel
    if (url.contains('payment-cancel')) {
      widget.checkoutController.verifyPayment(tranId: widget.tranId);
      log('Success URL: $url');
      _showCancellationDialog('Payment cancelled');
      return;
    }
  }

  void _showSuccessDialog(String message) {
    showAnimatedDialog(
      context,
      OrderPlaceDialogWidget(
        icon: Icons.check_circle_rounded,
        title: "Payment Successful",
        description: message,
        onOkPressed: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // close payment
          Navigator.of(context).pop(); // close checkout
          context.read<CartProvider>().clear();
        },
      ),
      dismissible: false,
      willFlip: true,
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
      Navigator.of(context).pop(false);
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
      Navigator.of(context).pop(false);
    });
  }
}
