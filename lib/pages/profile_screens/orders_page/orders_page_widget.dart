import 'package:a_i_ebook_app/pages/components/single_appbar/single_appbar_widget.dart';
import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/app_state.dart';
import 'package:intl/intl.dart';

class OrdersPageWidget extends StatefulWidget {
  const OrdersPageWidget({super.key});

  static String routeName = 'OrdersPage';
  static String routePath = '/ordersPage';

  @override
  State<OrdersPageWidget> createState() => _OrdersPageWidgetState();
}

class _OrdersPageWidgetState extends State<OrdersPageWidget> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await EbookGroup.getOrdersApiCall.call(
        token: FFAppState().token,
      );
      if (response.succeeded) {
        final body = response.jsonBody;
        if (body is Map && body['orders'] is List) {
          setState(() {
            _orders = body['orders'];
            _isLoading = false;
          });
        } else if (body is List) {
          setState(() {
            _orders = body;
            _isLoading = false;
          });
        } else {
          setState(() {
            _orders = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load orders: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 80),
        child: SingleAppbarWidget(title: 'My Orders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: FlutterFlowTheme.of(context).bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index] as Map<String, dynamic>;
                        return _buildOrderCard(order);
                      },
                    ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['order_number']?.toString() ??
        order['id']?.toString() ??
        order['_id']?.toString() ??
        'N/A';
    final dateStr = order['created_at']?.toString() ?? '';
    String displayDate = 'N/A';
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        displayDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
      } catch (_) {}
    }
    final status = (order['status']?.toString() ?? 'pending').toLowerCase();
    final total = order['total_amount'] ?? order['total'] ?? 0.0;
    final items = order['items'] as List? ?? [];

    Color statusColor;
    String statusLabel = status.replaceAll('_', ' ').toUpperCase();

    switch (status) {
      case 'completed':
      case 'delivered':
      case 'paid':
        statusColor = const Color(0xFF4B39EF); // Primary style success
        break;
      case 'cancelled':
      case 'failed':
        statusColor = FlutterFlowTheme.of(context).error;
        break;
      case 'processing':
      case 'shipped':
        statusColor = const Color(0xFF39D2C0); // Tertiary
        break;
      case 'awaiting_payment':
      case 'pending':
        statusColor = FlutterFlowTheme.of(context).secondary;
        break;
      default:
        statusColor = FlutterFlowTheme.of(context).secondaryText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: FlutterFlowTheme.of(context).shadowColor,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: statusColor.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      orderId,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} ${items.length == 1 ? 'Item' : 'Items'}',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                          ),
                          Text(
                            displayDate,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '৳${total.toStringAsFixed(2)}',
                            style: FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => _showOrderItems(items),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context).primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    size: 14,
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderItems(List<dynamic> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Items',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = items[index] as Map<String, dynamic>;
                    final bookFormat = item['book_format'] as Map?;
                    final book = (item['book'] ?? bookFormat?['book']) as Map?;
                    final title =
                        book?['title'] ?? item['book_id'] ?? 'Unknown Book';
                    final format =
                        (item['format']?.toString() ?? 'ebook').toUpperCase();
                    final qty = item['quantity'] ?? 1;
                    final price = item['price'] ?? 0.0;
                    final coverUrl = (book?['cover_url'] ?? book?['image'])?.toString() ?? '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: coverUrl.isNotEmpty
                              ? Image.network(
                                  coverUrl.startsWith('http')
                                      ? coverUrl
                                      : '${FFAppConstants.bookImagesUrl}$coverUrl',
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 75,
                                    color: FlutterFlowTheme.of(context).alternate,
                                    child: const Icon(Icons.book, size: 20),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 75,
                                  color: FlutterFlowTheme.of(context).alternate,
                                  child: const Icon(Icons.book, size: 20),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toString(),
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      format,
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Qty: $qty',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '৳${(price * qty).toStringAsFixed(2)}',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

