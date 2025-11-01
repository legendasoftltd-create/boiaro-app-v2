import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/providers/cart_provider.dart';
import '/app_state.dart';

class CheckoutPageWidget extends StatefulWidget {
  const CheckoutPageWidget({super.key});

  static String routeName = 'CheckoutPage';
  static String routePath = '/checkoutPage';

  @override
  State<CheckoutPageWidget> createState() => _CheckoutPageWidgetState();
}

class _CheckoutPageWidgetState extends State<CheckoutPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedPaymentMethod = 'ssl';
  // final TextEditingController emailController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCouponCode;
  String? _couponErrorMessage;
  bool _isApplyingCoupon = false;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
  }

  // @override
  // void dispose() {
  //   emailController.dispose();
  //   super.dispose();
  // }

  Future<void> _applyCoupon(double cartTotalAfterBookDiscounts) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponErrorMessage = 'Please enter a coupon code';
      });
      return;
    }
    setState(() {
      _isApplyingCoupon = true;
      _couponErrorMessage = null;
    });
    try {
      final baseUrl = 'https://api.boiaro.com/api';
      final response = await http.post(
        Uri.parse('$baseUrl/getcoupondetails'),
        headers: {
          'Authorization': 'Bearer ${FFAppState().token}',
          'Content-Type': 'application/json',
        },
        body: '{"coupon_code":"$code"}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(code);
        print(data);
        final success = getJsonField(data, r'$.data.success');
        if (success == 1) {
          final couponDetails = getJsonField(data, r'$.data.couponDetails');
          final discountType = getJsonField(couponDetails, r'$.discount_type').toString();
          final discountValue = (getJsonField(couponDetails, r'$.discount_value') as num).toDouble();
          final maxDiscount = (getJsonField(couponDetails, r'$.max_discount') as num).toDouble();
          final minOrderAmount = (getJsonField(couponDetails, r'$.min_order_amount') as num).toDouble();

          if (cartTotalAfterBookDiscounts < minOrderAmount) {
            setState(() {
              _couponErrorMessage = 'Minimum order amount is ৳${minOrderAmount.toStringAsFixed(2)}';
              _isApplyingCoupon = false;
            });
            return;
          }

          double calculatedDiscount;
          if (discountType.toLowerCase() == 'percentage') {
            calculatedDiscount = cartTotalAfterBookDiscounts * (discountValue / 100.0);
          } else {
            calculatedDiscount = discountValue;
          }
          // apply max discount cap and ensure not exceeding cart total
          calculatedDiscount = calculatedDiscount.clamp(0.0, maxDiscount);
          calculatedDiscount = calculatedDiscount > cartTotalAfterBookDiscounts ? cartTotalAfterBookDiscounts : calculatedDiscount;

          setState(() {
            _appliedCouponCode = code;
            _discountAmount = double.parse(calculatedDiscount.toStringAsFixed(2));
            _couponErrorMessage = null;
            _isApplyingCoupon = false;
          });
        } else {
          final message = getJsonField(data, r'$.data.message').toString();
          setState(() {
            _couponErrorMessage = message.isNotEmpty ? message : 'Invalid coupon';
            _isApplyingCoupon = false;
          });
        }
      } else {
        setState(() {
          _couponErrorMessage = 'Failed to apply coupon (${response.statusCode})';
          _isApplyingCoupon = false;
        });
      }
    } catch (e) {
      setState(() {
        _couponErrorMessage = 'Error applying coupon: $e';
        _isApplyingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _discountAmount = 0.0;
      _couponErrorMessage = null;
      _couponController.clear();
    });
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, String imagePath) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: selectedPaymentMethod == value 
            ? FlutterFlowTheme.of(context).primary 
            : FlutterFlowTheme.of(context).alternate,
          width: selectedPaymentMethod == value ? 2.0 : 1.0,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedPaymentMethod,
        onChanged: (String? newValue) {
          setState(() {
            selectedPaymentMethod = newValue!;
          });
        },
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child:
                //  Image.asset(
                //   imagePath,
                //   fit: BoxFit.contain,
                //   errorBuilder: (context, error, stackTrace) {
                //     return
                     Icon(
                      value == 'bkash' ? Icons.account_balance_wallet :
                      value == 'ssl' ? Icons.credit_card : Icons.payment,
                      color: value == 'bkash' ? Colors.pink : 
                             value == 'ssl' ? Colors.blue : Colors.grey,
                    ),
                //   },
                // ),
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: FlutterFlowTheme.of(context).primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final originalSubtotal = cart.totalAmount;
    final subtotalAfterBookDiscounts = cart.totalAmountAfterBookDiscounts;
    final totalBookDiscount = cart.totalBookDiscount;
    final finalTotal = (subtotalAfterBookDiscounts - _discountAmount).clamp(0.0, double.infinity);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            CustomCenterAppbarWidget(
                  title: 'Checkout',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
        
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(0.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary',
                              style: FlutterFlowTheme.of(context).headlineMedium.override(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16.0),
                            ...cart.items.values.map((cartItem) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CachedNetworkImage(imageUrl: cartItem.imageUrl,height: 50,width: 30,),
                                          SizedBox(width: 12.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cartItem.name,
                                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'Digital Ebook • Qty: ${cartItem.quantity}',
                                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                  ),
                                                ),
                                                if (cartItem.itemDiscount > 0) ...[
                                                  SizedBox(height: 4.0),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '৳${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                                          decoration: TextDecoration.lineThrough,
                                                          color: FlutterFlowTheme.of(context).secondaryText,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8.0),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4.0),
                                                        ),
                                                        child: Text(
                                                          cartItem.discountPercentage != null
                                                              ? '${cartItem.discountPercentage!.toStringAsFixed(0)}% OFF'
                                                              : '৳${cartItem.discountAmount!.toStringAsFixed(0)} OFF',
                                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 11.0,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              if (cartItem.itemDiscount > 0)
                                                Text(
                                                  '৳${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                                    decoration: TextDecoration.lineThrough,
                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                  ),
                                                ),
                                              Text(
                                                '৳${(cartItem.discountedPrice * cartItem.quantity).toStringAsFixed(2)}',
                                                style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                  fontWeight: FontWeight.w600,
                                                  color: FlutterFlowTheme.of(context).primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )).toList(),
                            Divider(height: 24.0, thickness: 1.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal:',
                                  style: FlutterFlowTheme.of(context).bodyLarge,
                                ),
                                Text(
                                  '৳${originalSubtotal.toStringAsFixed(2)}',
                                  style: FlutterFlowTheme.of(context).bodyLarge,
                                ),
                              ],
                            ),
                            if (totalBookDiscount > 0.0) ...[
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Book Discount:',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                  ),
                                  Text(
                                    '-৳${totalBookDiscount.toStringAsFixed(2)}',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (totalBookDiscount > 0.0) ...[
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal after discounts:',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '৳${subtotalAfterBookDiscounts.toStringAsFixed(2)}',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_discountAmount > 0.0) ...[
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Coupon Discount${_appliedCouponCode != null ? ' (${_appliedCouponCode!.toUpperCase()})' : ''}:',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                  ),
                                  Text(
                                    '-৳${_discountAmount.toStringAsFixed(2)}',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '৳${finalTotal.toStringAsFixed(2)}',
                                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24.0),
                      // Coupon Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Have a coupon?',
                              style: FlutterFlowTheme.of(context).headlineMedium.override(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12.0),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _couponController,
                                    enabled: _appliedCouponCode == null,
                                    decoration: InputDecoration(
                                      hintText: 'Enter coupon code',
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.0),
                                if (_appliedCouponCode == null)
                                  ElevatedButton(
                                    onPressed: _isApplyingCoupon ? null : () => _applyCoupon(subtotalAfterBookDiscounts),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                      minimumSize: Size(110, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: _isApplyingCoupon
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Apply',
                                            style: FlutterFlowTheme.of(context).titleMedium.override(
                                              fontFamily: 'SF Pro Display',
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  )
                                else
                                  OutlinedButton(
                                    onPressed: _removeCoupon,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size(110, 48),
                                      side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: Text(
                                      'Remove',
                                      style: FlutterFlowTheme.of(context).titleMedium.override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context).primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_couponErrorMessage != null) ...[
                              SizedBox(height: 8.0),
                              Text(
                                _couponErrorMessage!,
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                  color: Colors.red,
                                ),
                              ),
                            ],
                            if (_appliedCouponCode != null && _couponErrorMessage == null) ...[
                              SizedBox(height: 8.0),
                              Text(
                                'Applied: ${_appliedCouponCode!.toUpperCase()} (−৳${_discountAmount.toStringAsFixed(2)})',
                                style: FlutterFlowTheme.of(context).bodySmall,
                              ),
                            ]
                          ],
                        ),
                      ),
        
                      // Email for Digital Receipt Section
                      // Text(
                      //   'Email for Digital Receipt',
                      //   style: FlutterFlowTheme.of(context).headlineMedium.override(
                      //     fontSize: 18.0,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                      // SizedBox(height: 12.0),
                      // TextFormField(
                      //   controller: emailController,
                      //   decoration: InputDecoration(
                      //     hintText: 'Enter your email address',
                      //     prefixIcon: Icon(Icons.email_outlined),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12.0),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12.0),
                      //       borderSide: BorderSide(
                      //         color: FlutterFlowTheme.of(context).alternate,
                      //       ),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12.0),
                      //       borderSide: BorderSide(
                      //         color: FlutterFlowTheme.of(context).primary,
                      //       ),
                      //     ),
                      //     filled: true,
                      //     fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                      //   ),
                      //   keyboardType: TextInputType.emailAddress,
                      // ),
                      
                      // SizedBox(height: 24.0),
        
                      // Payment Method Section
                      Text(
                        'Choose Payment Method',
                        style: FlutterFlowTheme.of(context).headlineMedium.override(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      
                      // _buildPaymentOption(
                      //   'bkash',
                      //   'bKash',
                      //   'Pay with your bKash mobile wallet',
                      //   'assets/images/bkash_logo.png',
                      // ),
                      
                      _buildPaymentOption(
                        'ssl',
                        'SSLCommerz',
                        'Credit Card, Debit Card & Bank Transfer',
                        'assets/images/ssl_logo.png',
                      ),
        
                      SizedBox(height: 24.0),
        
                      // Digital Delivery Info
                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).accent1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).accent1.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                            SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instant Digital Delivery',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Your ebook(s) will be delivered instantly to your profile after successful payment.',
                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Confirm Order Button
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -2),
                    blurRadius: 8.0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MakeCheckOutScreen(
                        bookIds: cart.items.keys.toList(),
                        jwtToken: FFAppState().token,
                        userId: FFAppState().userId,
                        couponCode: _appliedCouponCode,

                      ),
                    ),
                  );
                  // if (emailController.text.isEmpty) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content: Text('Please enter your email address'),
                  //       backgroundColor: Colors.red,
                  //     ),
                  //   );
                  //   return;
                  // }
        
                  // Show processing dialog
                  // showDialog(
                  //   context: context,
                  //   barrierDismissible: false,
                  //   builder: (BuildContext context) {
                  //     return AlertDialog(
                  //       content: Column(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           CircularProgressIndicator(),
                  //           SizedBox(height: 16.0),
                  //           Text('Processing your payment...'),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // );
        
                  // // Simulate payment processing
                  // await Future.delayed(Duration(seconds: 2));
                  // Navigator.pop(context); // Close processing dialog
        
                  // // Clear cart and show success
                  // cart.clear();
                  // await showDialog(
                  //   context: context,
                  //   builder: (alertDialogContext) {
                  //     return AlertDialog(
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(16.0),
                  //       ),
                  //       title: Row(
                  //         children: [
                  //           Icon(
                  //             Icons.check_circle,
                  //             color: Colors.green,
                  //             size: 32.0,
                  //           ),
                  //           SizedBox(width: 12.0),
                  //           Text('Order Successful!'),
                  //         ],
                  //       ),
                  //       content: Column(
                  //         mainAxisSize: MainAxisSize.min,
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Text('Your ebook purchase has been completed successfully.'),
                  //           SizedBox(height: 12.0),
                  //           Text(
                  //             'Digital receipt and download links have been sent to:',
                  //             style: TextStyle(fontWeight: FontWeight.w500),
                  //           ),
                  //           Text(
                  //             emailController.text,
                  //             style: TextStyle(
                  //               color: FlutterFlowTheme.of(context).primary,
                  //               fontWeight: FontWeight.w600,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       actions: [
                  //         TextButton(
                  //           onPressed: () => Navigator.pop(alertDialogContext),
                  //           child: Text('Continue Shopping'),
                  //         ),
                  //       ],
                  //     );
                  //   },
                  // );
                  // context.goNamed('HomePage');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 2.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon( Icons.credit_card,
                      color: Colors.white,
                      size: 25.0,
                    ),
                    SizedBox(width: 12.0),
                    Text(
                      'Pay ৳${finalTotal.toStringAsFixed(2)}',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'SF Pro Display',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
