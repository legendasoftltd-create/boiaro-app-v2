import 'dart:async';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DigitalPaymentScreen extends StatefulWidget {
  final String url;
  final bool fromWallet;
  const DigitalPaymentScreen({super.key, required this.url, this.fromWallet = false});

  @override
  DigitalPaymentScreenState createState() => DigitalPaymentScreenState();
}

class DigitalPaymentScreenState extends State<DigitalPaymentScreen> {
  String? selectedUrl;
  double value = 0.0;
  final bool _isLoading = true;

  PullToRefreshController? pullToRefreshController;
  late MyInAppBrowser browser;

  @override
  void initState() {
    super.initState();
    selectedUrl = widget.url;
    _initData();
  }

  void _initData() async {
    browser = MyInAppBrowser(context);

    final settings = InAppBrowserClassSettings(
      browserSettings: InAppBrowserSettings(hideUrlBar: false),
      webViewSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: kDebugMode,
        useShouldOverrideUrlLoading: false,
        useOnLoadResource: false,
      ),
    );

    await browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(selectedUrl ?? '')),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (val, _) => _exitApp(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Theme.of(context).cardColor,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  )
                : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }

  Future<void> _exitApp(BuildContext context) async {
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashBoardScreen()),
          (route) => false);

      showAnimatedDialog(
        context,
        OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: "Payment Cancelled",
          description: "Your payment was cancelled.",
          isFailed: true,
        ),
        dismissible: false,
        willFlip: true,
      );
    });
  }
}

class MyInAppBrowser extends InAppBrowser {
  final BuildContext context;
  MyInAppBrowser(this.context, {super.windowId, super.initialUserScripts});

  bool _canRedirect = true;

  @override
  Future onBrowserCreated() async {
    if (kDebugMode) {
      print("\n\nBrowser Created!\n\n");
    }
  }

  @override
  Future onLoadStart(url) async {
    if (kDebugMode) {
      print("\n\nStarted: $url\n\n");
    }
    bool isNewUser = getIsNewUser(url.toString());
    _pageRedirect(url.toString(), isNewUser);
  }

  @override
  Future onLoadStop(url) async {
    if (kDebugMode) {
      print("\n\nStopped: $url\n\n");
    }
    bool isNewUser = getIsNewUser(url.toString());
    _pageRedirect(url.toString(), isNewUser);
  }

  @override
  void onLoadError(url, code, message) {
    if (kDebugMode) {
      print("Can't load [$url] Error: $message");
    }
  }

  @override
  void onProgressChanged(progress) {
    if (kDebugMode) {
      print("Progress: $progress");
    }
  }

  bool getIsNewUser(String url) {
    List<String> parts = url.split('?');
    if (parts.length < 2) return false;

    String queryString = parts[1];
    List<String> queryParams = queryString.split('&');

    for (String param in queryParams) {
      List<String> keyValue = param.split('=');
      if (keyValue.length == 2 && keyValue[0] == 'new_user') {
        return keyValue[1] == '1';
      }
    }
    return false;
  }

  @override
  void onExit() {
    if (_canRedirect) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashBoardScreen()),
          (route) => false);

      showAnimatedDialog(
        context,
        OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: "Payment Failed",
          description: "Your payment has failed.",
          isFailed: true,
        ),
        dismissible: false,
        willFlip: true,
      );
    }

    if (kDebugMode) {
      print("\n\nBrowser closed!\n\n");
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      navigationAction) async {
    if (kDebugMode) {
      print("\n\nOverride ${navigationAction.request.url}\n\n");
    }
    return NavigationActionPolicy.ALLOW;
  }

  void _pageRedirect(String url, bool isNewUser) {
    if (_canRedirect) {
      bool isSuccess = url.contains('success');
      bool isFailed = url.contains('fail');
      bool isCancel = url.contains('cancel');

      if (isSuccess || isFailed || isCancel) {
        _canRedirect = false;
        close();
      }

      if (isSuccess) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
            (route) => false);

        showAnimatedDialog(
          context,
          OrderPlaceDialogWidget(
            icon: Icons.done,
            title: isNewUser
                ? "Order placed & Account Created"
                : "Order Placed",
            description: "Your order has been placed successfully.",
          ),
          dismissible: false,
          willFlip: true,
        );
      } else if (isFailed) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
            (route) => false);

        showAnimatedDialog(
          context,
          OrderPlaceDialogWidget(
            icon: Icons.clear,
            title: "Payment Failed",
            description: "Your payment has failed.",
            isFailed: true,
          ),
          dismissible: false,
          willFlip: true,
        );
      } else if (isCancel) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
            (route) => false);

        showAnimatedDialog(
          context,
          OrderPlaceDialogWidget(
            icon: Icons.clear,
            title: "Payment Cancelled",
            description: "Your payment was cancelled.",
            isFailed: true,
          ),
          dismissible: false,
          willFlip: true,
        );
      }
    }
  }
}

/// -----------------------
/// Dashboard Dummy Screen
/// -----------------------
class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Dashboard Screen")),
    );
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

  const OrderPlaceDialogWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isFailed = false,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Back to Home"),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 2.0,
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
 showAnimatedDialog(
  BuildContext context,
  Widget dialog, {
  bool dismissible = true,
  bool willFlip = false,
}) async {
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
