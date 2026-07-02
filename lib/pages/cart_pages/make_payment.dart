import 'dart:developer';

import 'package:a_i_ebook_app/flutter_flow/flutter_flow_theme.dart';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_util.dart';
import 'package:a_i_ebook_app/pages/cart_pages/payment_screen.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MakeCheckOutScreen extends StatefulWidget {
  /// Line items with per-format `type` (ebook / audiobook / hardcopy).
  final List<CartItem> cartLines;
  final List<String> bookIds;
  final String jwtToken;
  final String userId;
  final String? couponCode;
  final double? couponDiscount;
  final String? appliedCouponId;
  final String? shippingMethodId;
  final String? shippingMethodName;
  final String? shippingCarrier;
  final double? shippingCost;
  final String? estimatedDeliveryDays;
  final Map<String, dynamic>? shippingAddress;
  final String selectedPaymentMethod;

  const MakeCheckOutScreen({
    Key? key,
    required this.cartLines,
    required this.bookIds,
    required this.jwtToken,
    required this.userId,
    this.couponCode,
    this.couponDiscount,
    this.appliedCouponId,
    this.shippingMethodId,
    this.shippingMethodName,
    this.shippingCarrier,
    this.shippingCost,
    this.estimatedDeliveryDays,
    this.shippingAddress,
    this.selectedPaymentMethod = 'online',
  }) : super(key: key);

  @override
  _MakeCheckOutScreenState createState() => _MakeCheckOutScreenState();
}

class _MakeCheckOutScreenState extends State<MakeCheckOutScreen> {
  late final CheckoutController _checkoutController;
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    print("User ID: ${widget.userId}, JWT Token: ${widget.jwtToken}");
    print(
        "bookIds: ${widget.bookIds}, couponCode: ${widget.couponCode}, shippingAddress: ${widget.shippingAddress}, selectedPaymentMethod: ${widget.selectedPaymentMethod}");

    _checkoutController = CheckoutController(
      jwtToken: widget.jwtToken,
      userId: widget.userId,
    );
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      print('Initiating payment for books: ${widget.bookIds}');

      final response = await _checkoutController.initiatePayment(
        widget.cartLines,
        couponCode: widget.couponCode,
        couponDiscount: widget.couponDiscount,
        appliedCouponId: widget.appliedCouponId,
        shippingMethodId: widget.shippingMethodId,
        shippingMethodName: widget.shippingMethodName,
        shippingCarrier: widget.shippingCarrier,
        shippingCost: widget.shippingCost,
        estimatedDeliveryDays: widget.estimatedDeliveryDays,
        shippingAddress: widget.shippingAddress,
        paymentMethod: widget.selectedPaymentMethod,
      );
      print('Payment initiation response: $response');
      if (response['success'] == 1) {
        final orderId = response['order_id'] as String?;
        final gatewayUrl = response['GatewayPageURL'] as String?;
        if (gatewayUrl != null && gatewayUrl.trim().isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentWebView(
                url: gatewayUrl,
                orderId: orderId,
                bookIds: widget.bookIds,
                purchasedFormats: widget.cartLines.map((e) => e.type).toList(),
                checkoutController: _checkoutController,
              ),
            ),
          );
          return;
        }
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Order Successful!',
                      style: FlutterFlowTheme.of(dialogContext).headlineSmall.override(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      response['message']?.toString() ??
                          'Order placed successfully.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(dialogContext).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(dialogContext).secondaryText,
                          ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context, true); // Pop MakeCheckOutScreen with success
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(dialogContext).primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
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
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        title: Text(
          'Processing Payment',
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _successMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          _successMessage!,
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                )
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
  final String baseUrl = FFAppConstants.baseApiUrl;
  final String jwtToken;
  final String userId;

  CheckoutController({
    required this.jwtToken,
    required this.userId,
  });

  Map<String, String> get _headers => {
        'apikey': FFAppConstants.supabaseAnonApiKey,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      };

  static String _formatForApi(String? cartType) {
    final t = (cartType ?? 'ebook').toLowerCase().trim();
    if (t == 'audiobook' || t == 'audio') return 'audiobook';
    if (t == 'hardcopy' || t == 'hard' || t == 'print') return 'hardcopy';
    return 'ebook';
  }

  bool _needsShipping(Iterable<CartItem> lines) =>
      lines.any((c) => _formatForApi(c.type) == 'hardcopy');

  String? _extractOrderId(Map<String, dynamic> payload) {
    final topLevel = [
      payload['order_id'],
      payload['orderId'],
      payload['id'],
    ];
    for (final value in topLevel) {
      final id = value?.toString().trim() ?? '';
      if (id.isNotEmpty) return id;
    }

    final nestedCandidates = [
      payload['order'],
      payload['data'],
      payload['result']
    ];
    for (final candidate in nestedCandidates) {
      if (candidate is Map) {
        final nested = Map<String, dynamic>.from(candidate);
        final id = _extractOrderId(nested);
        if (id != null && id.isNotEmpty) return id;
      }
    }

    return null;
  }

  bool _isValidBookId(String input) {
    final v = input.trim();
    if (v.isEmpty) return false;

    final uuidReg = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (uuidReg.hasMatch(v)) return true;

    final objectIdReg = RegExp(r'^[0-9a-fA-F]{24}$');
    return objectIdReg.hasMatch(v);
  }

  /// BoiAro v2: [name], [address], [phone] per API docs.
  Map<String, dynamic>? _v2Shipping(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final name = raw['name']?.toString().trim().isNotEmpty == true
        ? raw['name'].toString()
        : (raw['fullName'] ?? raw['full_name'])?.toString() ?? '';
    final phone = raw['phone']?.toString() ?? '';
    final addr = raw['address']?.toString() ??
        [
          raw['addressLine1'],
          raw['addressLine2'],
          raw['city'],
          raw['state'],
          raw['postalCode'],
          raw['country'],
        ].where((e) => e != null && '$e'.trim().isNotEmpty).join(', ');
    if (name.isEmpty || addr.isEmpty || phone.isEmpty) return null;
    return {'name': name, 'address': addr, 'phone': phone};
  }

  Future<Map<String, dynamic>> initiatePayment(
    List<CartItem> cartLines, {
    String? couponCode,
    double? couponDiscount,
    String? appliedCouponId,
    String? shippingMethodId,
    String? shippingMethodName,
    String? shippingCarrier,
    double? shippingCost,
    String? estimatedDeliveryDays,
    Map<String, dynamic>? shippingAddress,
    String paymentMethod = 'online',
  }) async {
    try {
      if (cartLines.isEmpty) {
        return {'success': 0, 'message': 'Cart is empty'};
      }

      final hasInvalidBookId = cartLines.any((c) => !_isValidBookId(c.id));
      if (hasInvalidBookId) {
        return {
          'success': 0,
          'message':
              'Cart contains invalid book id. Please remove and add the item again.',
        };
      }

      final normalizedPaymentMethod = paymentMethod == 'ssl'
          ? 'online'
          : paymentMethod.toLowerCase().trim();
      final items = cartLines
          .map(
            (c) => {
              'book_id': c.id.trim(),
              'format': _formatForApi(c.type),
              'quantity': c.quantity,
              'price': c.discountedPrice,
              'book_title': c.name,
            },
          )
          .toList();

      if (normalizedPaymentMethod == 'wallet') {
        if (cartLines.any((c) => _formatForApi(c.type) == 'hardcopy')) {
          return {
            'success': 0,
            'message': 'Wallet unlock supports ebook/audiobook only.',
          };
        }
        for (final line in cartLines) {
          final format = _formatForApi(line.type);
          final coinCost = line.coinPrice ?? 0;
          if (coinCost <= 0) {
            return {
              'success': 0,
              'message':
                  'Coin price missing for ${line.name}. Please add the item again.',
            };
          }
          final unlockRes = await http.post(
            Uri.parse('$baseUrl/wallet/unlock'),
            headers: _headers,
            body: jsonEncode({
              'book_id': line.id.trim(),
              'format': format,
              'coin_cost': coinCost,
            }),
          );
          final decoded = jsonDecode(unlockRes.body);
          if (unlockRes.statusCode != 200) {
            final err = decoded is Map ? decoded['error']?.toString() : null;
            return {
              'success': 0,
              'message':
                  err ?? 'Wallet unlock failed (${unlockRes.statusCode})',
            };
          }
        }
        return {
          'success': 1,
          'message': 'Wallet unlock completed successfully.',
          'payment_method': 'wallet',
        };
      }

      if (normalizedPaymentMethod == 'cod') {
        final subtotal = cartLines.fold(0.0, (sum, item) => sum + (item.discountedPrice * item.quantity));
        final grandTotal = (subtotal - (couponDiscount ?? 0.0)) + (shippingCost ?? 0.0);

        final body = <String, dynamic>{
          'items': items,
          'payment_method': 'cod',
          'grand_total': grandTotal,
          if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
          if (couponDiscount != null && couponDiscount > 0) 'coupon_discount': couponDiscount,
          if (appliedCouponId != null && appliedCouponId.isNotEmpty) 'applied_coupon_id': appliedCouponId,
          if (shippingMethodId != null && shippingMethodId.isNotEmpty) 'shipping_method_id': shippingMethodId,
          if (shippingMethodName != null && shippingMethodName.isNotEmpty) 'shipping_method_name': shippingMethodName,
          if (shippingCarrier != null && shippingCarrier.isNotEmpty) 'shipping_carrier': shippingCarrier,
          if (shippingCost != null) 'shipping_cost': shippingCost,
          if (estimatedDeliveryDays != null && estimatedDeliveryDays.isNotEmpty) 'estimated_delivery_days': estimatedDeliveryDays,
        };

        if (_needsShipping(cartLines) && shippingAddress != null) {
          body['shipping_name'] = shippingAddress['fullName'] ?? shippingAddress['name'] ?? '';
          body['shipping_phone'] = shippingAddress['phone'] ?? '';
          body['shipping_address'] = shippingAddress['addressLine1'] ?? shippingAddress['address'] ?? '';
          body['shipping_city'] = shippingAddress['city'] ?? '';
          body['shipping_district'] = shippingAddress['city'] ?? '';
          body['shipping_area'] = shippingAddress['shipping_area'] ?? shippingAddress['state'] ?? '';
          body['shipping_area_id'] = shippingAddress['shipping_area_id'];
          body['shipping_zip'] = shippingAddress['postalCode'] ?? '';
        }

        final orderRes = await http.post(
          Uri.parse('$baseUrl/orders'),
          headers: _headers,
          body: jsonEncode(body),
        );

        final orderDecoded = jsonDecode(orderRes.body);
        log('Create order response for COD (${orderRes.statusCode}): $orderDecoded');
        if (orderRes.statusCode != 201 && orderRes.statusCode != 200) {
          final err =
              orderDecoded is Map ? orderDecoded['error']?.toString() : null;
          return {
            'success': 0,
            'message': err ?? 'Failed to create order (${orderRes.statusCode})',
          };
        }
        return {
          'success': 1,
          'message': 'Order placed successfully using Cash on Delivery.',
          'payment_method': 'cod',
          'order_id': _extractOrderId(orderDecoded),
        };
      }

      final subtotal = cartLines.fold(0.0, (sum, item) => sum + (item.discountedPrice * item.quantity));
      final grandTotal = (subtotal - (couponDiscount ?? 0.0)) + (shippingCost ?? 0.0);

      final body = <String, dynamic>{
        'items': items,
        'payment_method': normalizedPaymentMethod,
        'grand_total': grandTotal,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        if (couponDiscount != null && couponDiscount > 0) 'coupon_discount': couponDiscount,
        if (appliedCouponId != null && appliedCouponId.isNotEmpty) 'applied_coupon_id': appliedCouponId,
        if (shippingMethodId != null && shippingMethodId.isNotEmpty) 'shipping_method_id': shippingMethodId,
        if (shippingMethodName != null && shippingMethodName.isNotEmpty) 'shipping_method_name': shippingMethodName,
        if (shippingCarrier != null && shippingCarrier.isNotEmpty) 'shipping_carrier': shippingCarrier,
        if (shippingCost != null) 'shipping_cost': shippingCost,
        if (estimatedDeliveryDays != null && estimatedDeliveryDays.isNotEmpty) 'estimated_delivery_days': estimatedDeliveryDays,
      };

      if (_needsShipping(cartLines) && shippingAddress != null) {
        body['shipping_name'] = shippingAddress['fullName'] ?? shippingAddress['name'] ?? '';
        body['shipping_phone'] = shippingAddress['phone'] ?? '';
        body['shipping_address'] = shippingAddress['addressLine1'] ?? shippingAddress['address'] ?? '';
        body['shipping_city'] = shippingAddress['city'] ?? '';
        body['shipping_district'] = shippingAddress['city'] ?? ''; // District often same as city in this context
        body['shipping_area'] = shippingAddress['shipping_area'] ?? shippingAddress['state'] ?? '';
        body['shipping_area_id'] = shippingAddress['shipping_area_id'];
        body['shipping_zip'] = shippingAddress['postalCode'] ?? '';
      }

      final orderRes = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final orderDecoded = jsonDecode(orderRes.body);
      log('Create order response (${orderRes.statusCode}): $orderDecoded');
      if (orderRes.statusCode != 201 && orderRes.statusCode != 200) {
        final err =
            orderDecoded is Map ? orderDecoded['error']?.toString() : null;
        return {
          'success': 0,
          'message': err ?? 'Failed to create order (${orderRes.statusCode})',
        };
      }

      if (orderDecoded is! Map<String, dynamic>) {
        return {'success': 0, 'message': 'Invalid order response'};
      }

      final orderId = _extractOrderId(orderDecoded);
      if (orderId == null || orderId.isEmpty) {
        return {
          'success': 0,
          'message': 'Order id missing from response',
        };
      }

      final payRes = await http.post(
        Uri.parse('$baseUrl/payments/initiate'),
        headers: _headers,
        body: jsonEncode({'order_id': orderId}),
      );

      final payDecoded = jsonDecode(payRes.body);
      log('Initiate payment response (${payRes.statusCode}): $payDecoded');
      if (payRes.statusCode != 200) {
        final err = payDecoded is Map ? payDecoded['error']?.toString() : null;
        return {
          'success': 0,
          'message': err ?? 'Payment initiation failed (${payRes.statusCode})',
        };
      }

      if (payDecoded is! Map<String, dynamic>) {
        return {'success': 0, 'message': 'Invalid payment response'};
      }

      final ok = payDecoded['success'] == true || payDecoded['success'] == 1;
      final gatewayUrl = payDecoded['gateway_url']?.toString() ??
          payDecoded['GatewayPageURL']?.toString() ??
          payDecoded['url']?.toString();
      if (!ok || gatewayUrl == null || gatewayUrl.isEmpty) {
        final err = payDecoded['error']?.toString() ??
            payDecoded['message']?.toString();
        return {
          'success': 0,
          'message': err ?? 'Gateway URL not returned',
        };
      }

      return {
        'success': 1,
        'GatewayPageURL': gatewayUrl,
        'order_id': orderId,
        'session_key': payDecoded['session_key'],
      };
    } catch (e, st) {
      log('Payment initiation error: $e', stackTrace: st);
      throw Exception('Payment initiation error: $e');
    }
  }

  /// Confirm order state after SSLCommerz redirect (GET /orders/{order_id}).
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
  }) async {
    try {
      log('Verifying order: $orderId');
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Order verify: $data');
        return data is Map<String, dynamic> ? data : {'raw': data};
      } else {
        throw Exception('Failed to verify order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment verification error: $e');
    }
  }

  Future<Map<String, dynamic>> handlePaymentFailure({
    required String orderId,
    required List<String> bookIds,
  }) async {
    log('Payment failed for order $orderId (books: $bookIds)');
    try {
      await verifyPayment(orderId: orderId);
    } catch (_) {}
    return {'success': 0};
  }

  Future<Map<String, dynamic>> handlePaymentCancellation({
    required String orderId,
    required List<String> bookIds,
  }) async {
    log('Payment cancelled for order $orderId (books: $bookIds)');
    try {
      await verifyPayment(orderId: orderId);
    } catch (_) {}
    return {'success': 0};
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
  final bool isSuccess;
  final VoidCallback? onOkPressed;
  final String? successButtonText;

  const OrderPlaceDialogWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isFailed = false,
    this.isSuccess = false,
    this.onOkPressed,
    this.successButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 60, color: isFailed ? Colors.red : Colors.green),
          const SizedBox(height: 15),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onOkPressed ?? () => Navigator.of(context).pop(),
            child: Text(
                isSuccess ? (successButtonText ?? "Start Reading") : "Go Back",
                style: FlutterFlowTheme.of(context).titleMedium.override(
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
