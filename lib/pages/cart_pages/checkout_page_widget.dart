import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
  }

  // @override
  // void dispose() {
  //   emailController.dispose();
  //   super.dispose();
  // }

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
                                  child: Row(
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
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '৳${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                          fontWeight: FontWeight.w600,
                                          color: FlutterFlowTheme.of(context).primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                            Divider(height: 24.0, thickness: 1.0),
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
                                  '৳${cart.totalAmount.toStringAsFixed(2)}',
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
                      'Pay ৳${cart.totalAmount.toStringAsFixed(2)}',
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
