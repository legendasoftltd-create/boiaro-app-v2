
import 'dart:developer';

import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

/// -----------------------
/// Digital Payment Screen with InAppWebView
/// -----------------------

class DigitalPaymentScreen extends StatefulWidget {
  final String url;
  final bool fromWallet;
  final String tranId;
  final List<String> bookIds;
  final CheckoutController checkoutController;

  const DigitalPaymentScreen({
    super.key,
    required this.url,
    required this.fromWallet,
    required this.tranId,
    required this.bookIds,
    required this.checkoutController,
  });

  @override
  DigitalPaymentScreenState createState() => DigitalPaymentScreenState();
}

class DigitalPaymentScreenState extends State<DigitalPaymentScreen> {
  bool _isLoading = true;
  PullToRefreshController? pullToRefreshController;
  late InAppWebViewController webViewController;
  bool _canRedirect = true;

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        enabled: true,
      ),
      onRefresh: () async {
        webViewController.reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (val, _) => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                CustomCenterAppbarWidget(
                    title: 'Make payment',
                    backIcon: false,
                    addIcon: false,
                    onTapAdd: () async {},
                  ),
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor),
                      ),
                    )
              :
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  pullToRefreshController: pullToRefreshController,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                     log("Redirect to: $url");
                    _handleUrlChange(url.toString());
                  },
                  onLoadStop: (controller, url) {
                    pullToRefreshController?.endRefreshing();
                    // _handleUrlChange(url.toString());
                  },
                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController?.endRefreshing();
                    _showErrorDialog('WebView error: $message');
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController?.endRefreshing();
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url.toString();
                    if(url.contains('payment-success') || url.contains('payment-fail') || url.contains('payment-cancel')) {
                       setState(() {
                        _isLoading = true;
                      });
                    }
                     log("Navigating to: $url");
                    return NavigationActionPolicy.ALLOW;
                  },
                
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  void _handleUrlChange(String url) {
    if (!_canRedirect) return;
      _isLoading = true;
      setState(() {});
    // Handle success redirect
    if (url.contains('payment-success')) {
      log('Success URL: $url');
      final uri = Uri.parse(url);
      final valId = uri.queryParameters['val_id']??"";
      final cardIssuer = uri.queryParameters['card_issuer'] ?? 'STANDARD CHARTERED BANK';

      if (valId != null) {
        _canRedirect = false;
        widget.checkoutController.verifyPayment(
          tranId: widget.tranId,
          valId: valId,
          bookIds: widget.bookIds,
          cardIssuer: cardIssuer,
        ).then((result) {
           _isLoading = false;
           setState(() {});
           log('Verification result: $result');
          _showSuccessDialog('Payment Successful: ${result['message']}');
        }).catchError((e) {
           _isLoading = false;
           setState(() {});
           log('Verification error: $e');
          _showErrorDialog('Verification failed: $e');
        });
      }
      return;
    }

    // Handle failure redirect
    if (url.contains('payment-fail')) {
      final uri = Uri.parse(url);
      final failTranId = uri.queryParameters['tran_id'];

      if (failTranId != null) {
        _canRedirect = false;
        widget.checkoutController.handlePaymentFailure(
          tranId: failTranId,
          bookIds: widget.bookIds,
        ).then((result) {
          log('Verification result: $result');
          _showErrorDialog('Payment failed');
        }).catchError((e) {
          log('Verification error: $e');
          _showErrorDialog('Failure handling error: $e');
        });
      }
      return;
    }

    // Handle cancellation redirect
    if (url.contains('payment-cancel')) {
      final uri = Uri.parse(url);
      final cancelTranId = uri.queryParameters['tran_id'];

      if (cancelTranId != null) {
        _canRedirect = false;
        widget.checkoutController.handlePaymentCancellation(
          tranId: cancelTranId,
          bookIds: widget.bookIds,
        ).then((result) {
          log('Verification result: $result');
          _showCancellationDialog('Payment cancelled');
        }).catchError((e) {
          log('Verification error: $e');
          _showErrorDialog('Cancellation handling error: $e');
        });
      }
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
          // context.go('/');
        },
      ),
      dismissible: false,
      willFlip: true,
    );
  }

   _showErrorDialog(String message) {
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

   _showCancellationDialog(String message) {
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

  Future<void> _exitApp(BuildContext context) async {
    _showCancellationDialog('Payment cancelled by user');
  }
}