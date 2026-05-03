import 'package:flutter/material.dart';

class OrdersPageWidget extends StatelessWidget {
  const OrdersPageWidget({super.key});

  static String routeName = 'OrdersPage';
  static String routePath = '/ordersPage';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: const Center(
        child: Text(
          'Orders page (dummy)\nYour hardcopy orders will appear here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
