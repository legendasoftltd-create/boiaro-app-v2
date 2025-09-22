import 'package:a_i_ebook_app/pages/login_pages/sign_in_page/sign_in_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/providers/cart_provider.dart';
import 'checkout_page_widget.dart'; // Will create this next

class CartPageWidget extends StatefulWidget {
  const CartPageWidget({super.key});

  static String routeName = 'CartPage';
  static String routePath = '/cartPage';

  @override
  State<CartPageWidget> createState() => _CartPageWidgetState();
}

class _CartPageWidgetState extends State<CartPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // No model to create for this simple page, using provider directly
  }

  @override
  void dispose() {
    super.dispose();
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
                  title: 'My Cart',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
            Expanded(
              child: cart.itemCount == 0
                  ? Center(
                      child: Text(
                        'Your cart is empty!',
                        style: FlutterFlowTheme.of(context).headlineSmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: cart.itemCount,
                      itemBuilder: (ctx, i) {
                        final cartItem = cart.items.values.toList()[i];
                        final productId = cart.items.keys.toList()[i];
                        return Container(

        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 16.0,
              color: FlutterFlowTheme.of(context).shadowColor,
              offset: Offset(
                0.0,
                4.0,
              ),
            )
          ],
          borderRadius: BorderRadius.circular(12.0),
        
        ),
                          margin:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(cartItem.imageUrl),
                              ),
                              title: Text(cartItem.name),
                              subtitle: Text(
                                  'Total: \৳${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline,color: FlutterFlowTheme.of(context).primary,),
                                    onPressed: () {
                                      cart.removeSingleItem(productId);
                                    },
                                  ),
                                  Text('${cartItem.quantity}x'),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline_outlined,color: FlutterFlowTheme.of(context).primary,),
                                    onPressed: () {
                                      cart.addItem(productId, cartItem.name,
                                          cartItem.imageUrl, cartItem.price);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (cart.itemCount > 0)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: FlutterFlowTheme.of(context).headlineSmall,
                        ),
                        Text(
                          '\৳${cart.totalAmount.toStringAsFixed(2)}',
                          style: FlutterFlowTheme.of(context).headlineSmall,
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (FFAppState().isLogin == true) {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    CheckoutPageWidget(),
                              ),
                            );
                          } else {
                            context.pushNamed(SignInPageWidget.routeName);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Proceed to Checkout',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
