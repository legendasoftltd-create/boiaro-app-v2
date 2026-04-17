import 'dart:developer';
import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:a_i_ebook_app/index.dart';
import 'package:a_i_ebook_app/flutter_flow/nav/nav.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  /// BoiAro v2 order UUID (replaces legacy SSL `tran_id` for verification).
  final String? orderId;
  final List<String> bookIds;
  final CheckoutController checkoutController;

  const PaymentWebView({
    super.key,
    required this.url,
    required this.orderId,
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
  String _currentUrl = '';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 🚫 Prevent back navigation when payment successful
      onWillPop: () async {
        if (isPaymentSuccess) return false;
        
        // First try to go back in webview
        if (webViewController != null) {
          final canGoBack = await webViewController!.canGoBack();
          if (canGoBack) {
            webViewController!.goBack();
            return false; // Prevent screen from popping, webview handled it
          }
        }
        
        // If webview can't go back, allow screen to pop
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(112.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomCenterAppbarWidget(
                  title: "Payment",
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                  onBackPressed: () async {
                    if (webViewController != null) {
                      final canGoBack = await webViewController!.canGoBack();
                      if (canGoBack) {
                        webViewController!.goBack();
                      } else {
                        context.safePop();
                      }
                    }
                  },
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Text(
                    _currentUrl.isEmpty ? widget.url : _currentUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  setState(() {
                    _currentUrl = widget.url;
                  });
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
                onLoadStart: (controller, uri) async{
                  final url = uri?.toString() ?? '';
                  if (url.isNotEmpty) {
                    setState(() {
                      _currentUrl = url;
                    });
                  }
                  if(url.contains('payment-cancel')){
                    await controller.stopLoading();
                    _handleUrlChange(url.toString());
                  }else if(url.contains('payment-fail')){
                    await controller.stopLoading();
                    _handleUrlChange(url.toString());
                  }
                },
                onLoadStop: (controller, uri) async {
                  final url = uri?.toString() ?? '';
                  if (url.isNotEmpty) {
                    setState(() {
                      _currentUrl = url;
                    });
                  }
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
    final orderId = uri.queryParameters['order_id'] ??
        uri.queryParameters['tran_id'] ??
        widget.orderId;
    final status = uri.queryParameters['status']?.toLowerCase();

    final isSuccess = url.contains('payment-success') || status == 'success';
    final isFail = url.contains('payment-fail') || status == 'failed';
    final isCancel = url.contains('payment-cancel') || status == 'cancelled';

    // ✅ Success
    if (isSuccess) {
      if (orderId != null && orderId.isNotEmpty) {
        widget.checkoutController.verifyPayment(orderId: orderId);
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
    if (isFail) {
      if (orderId != null && orderId.isNotEmpty) {
        widget.checkoutController.handlePaymentFailure(
          orderId: orderId,
          bookIds: widget.bookIds,
        );
      }
      setState(() => isLoading = false);
      _showErrorDialog('Payment failed');
      return;
    }

    // 🚫 Cancelled
    if (isCancel) {
      if (orderId != null && orderId.isNotEmpty) {
        widget.checkoutController.handlePaymentCancellation(
          orderId: orderId,
          bookIds: widget.bookIds,
        );
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
        icon: Icons.cancel,
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
