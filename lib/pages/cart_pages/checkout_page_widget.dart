import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/app_constants.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/providers/cart_provider.dart';
import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';

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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _thanaController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  String? _appliedCouponCode;
  String? _couponErrorMessage;
  bool _isApplyingCoupon = false;
  double _discountAmount = 0.0;
  bool _isLoadingShippingData = false;
  bool _isCalculatingShipping = false;
  bool _shippingDataLoaded = false;
  String? _shippingError;
  List<dynamic> _shippingMethods = [];
  List<Map<String, dynamic>> _districts = [];
  String? _selectedDistrictName;
  bool _selectedDistrictIsDhaka = false;
  String? _selectedShippingMethodId;
  String? _selectedShippingMethodName;
  String? _selectedShippingCarrier;
  String? _estimatedDeliveryDays;
  double _shippingCost = 0.0;
  String? _appliedCouponId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _thanaController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

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
      final cart = Provider.of<CartProvider>(context, listen: false);
      final hasHardcopy = _hasHardcopy(cart);
      final hasEbook = cart.items.values
          .any((item) => (item.type).toLowerCase().contains('ebook'));
      final hasAudiobook = cart.items.values
          .any((item) => (item.type).toLowerCase().contains('audio'));

      final response = await EbookGroup.validateCouponApiCall.call(
        token: FFAppState().token,
        code: code,
        totalAmount: cartTotalAfterBookDiscounts,
        hasHardcopy: hasHardcopy,
        hasEbook: hasEbook,
        hasAudiobook: hasAudiobook,
      );

      if (response.succeeded) {
        final jb = response.jsonBody;
        if (jb is Map && jb['valid'] == true) {
          setState(() {
            _appliedCouponCode = jb['code']?.toString() ?? code;
            _appliedCouponId = jb['coupon_id']?.toString();
            _discountAmount = (jb['discount_amount'] as num).toDouble();
            _couponErrorMessage = null;
            _isApplyingCoupon = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon applied successfully!')),
          );
        } else {
          setState(() {
            _couponErrorMessage = jb is Map ? jb['message']?.toString() ?? 'Invalid coupon' : 'Invalid coupon';
            _isApplyingCoupon = false;
          });
        }
      } else {
        setState(() {
          final jb = response.jsonBody;
          _couponErrorMessage = jb is Map ? jb['message']?.toString() ?? 'Failed to apply coupon' : 'Failed to apply coupon';
          _isApplyingCoupon = false;
        });
      }
    } catch (e) {
      setState(() {
        _couponErrorMessage = 'An error occurred: $e';
        _isApplyingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _appliedCouponId = null;
      _discountAmount = 0.0;
      _couponErrorMessage = null;
      _couponController.clear();
    });
    if (_hasHardcopy(Provider.of<CartProvider>(context, listen: false))) {
      _calculateShippingCost();
    }
  }

  bool _hasHardcopy(CartProvider cart) {
    return cart.items.values
        .any((item) => (item.type).toLowerCase() == 'hardcopy');
  }

  String _formatCartType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'audiobook':
        return 'Audiobook';
      case 'hardcopy':
        return 'Hardcopy';
      default:
        return 'Ebook';
    }
  }

  Future<void> _loadShippingData() async {
    if (_isLoadingShippingData) return;
    setState(() {
      _isLoadingShippingData = true;
      _shippingError = null;
    });
    try {
      await Future.wait([
        _fetchAddresses(),
        _fetchDistricts(),
        _fetchShippingMethods(),
      ]);
      setState(() {
        _shippingDataLoaded = true;
      });
      await _calculateShippingCost();
    } catch (e) {
      setState(() {
        _shippingError = 'Failed to load shipping data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingShippingData = false;
        });
      }
    }
  }

  Future<void> _fetchAddresses() async {
    return;
  }

  Future<void> _fetchShippingMethods() async {
    final uri = Uri.parse(
      '${FFAppConstants.mobileApiBaseUrl}/shipping/methods',
    ).replace(
      queryParameters: {
        if ((_selectedDistrictName ?? '').trim().isNotEmpty)
          'districtId': _selectedDistrictName!.trim(),
      },
    );
    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (FFAppConstants.supabaseAnonApiKey.isNotEmpty)
        'apikey': FFAppConstants.supabaseAnonApiKey,
      if (FFAppState().token.isNotEmpty)
        'Authorization': 'Bearer ${FFAppState().token}',
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Shipping methods failed (${res.statusCode})');
    }
    final decoded = jsonDecode(res.body);
    final raw = decoded is List
        ? decoded
        : (decoded is Map ? decoded['methods'] : null);
    final methods = <dynamic>[];
    if (raw is List) {
      methods.addAll(raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    }
    setState(() {
      _shippingMethods = methods;
      _selectedShippingMethodId = methods.isNotEmpty
          ? (Map<String, dynamic>.from(methods.first as Map)['id']?.toString() ??
              Map<String, dynamic>.from(methods.first as Map)['_id']?.toString())
          : null;
    });
  }

  Future<void> _calculateShippingCost() async {
    if (_shippingMethods.isEmpty || _selectedShippingMethodId == null) {
      setState(() {
        _shippingCost = 0;
        _isCalculatingShipping = false;
      });
      return;
    }
    final selected = _shippingMethods
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .firstWhere(
          (m) =>
              m['id']?.toString() == _selectedShippingMethodId ||
              m['_id']?.toString() == _selectedShippingMethodId,
          orElse: () => <String, dynamic>{},
        );
    final baseCostRaw = selected['base_cost'] ?? selected['cost'] ?? 0;
    final baseCost = baseCostRaw is num
        ? baseCostRaw.toDouble()
        : double.tryParse(baseCostRaw.toString()) ?? 0.0;
    setState(() {
      _shippingCost = baseCost;
      _selectedShippingMethodName = selected['name']?.toString();
      _selectedShippingCarrier = selected['description']?.toString() ?? selected['carrier']?.toString();
      _estimatedDeliveryDays = selected['delivery_days']?.toString();
      _isCalculatingShipping = false;
    });
  }

  Future<void> _fetchDistricts() async {
    final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/shipping/districts');
    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (FFAppConstants.supabaseAnonApiKey.isNotEmpty)
        'apikey': FFAppConstants.supabaseAnonApiKey,
      if (FFAppState().token.isNotEmpty)
        'Authorization': 'Bearer ${FFAppState().token}',
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Districts failed (${res.statusCode})');
    }
    final decoded = jsonDecode(res.body);
    final raw = decoded is List
        ? decoded
        : (decoded is Map ? decoded['districts'] : null);
    final districts = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final d in raw.whereType<Map>()) {
        final m = Map<String, dynamic>.from(d);
        final name = (m['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        districts.add({
          'name': name,
          'is_dhaka_area': m['is_dhaka_area'] == true,
        });
      }
    }
    setState(() {
      _districts = districts;
      if (_districts.isNotEmpty && (_selectedDistrictName ?? '').isEmpty) {
        _selectedDistrictName = _districts.first['name']?.toString();
        _selectedDistrictIsDhaka = _districts.first['is_dhaka_area'] == true;
      }
    });
  }

  /// Shape expected by [CheckoutController] / v2 `shipping_address` (fullName-style keys OK).
  Map<String, dynamic>? _shippingAddressForOrder() {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final addressLine1 = _addressLine1Controller.text.trim();
    final city = (_selectedDistrictName ?? '').trim();
    final postalCode = _postalCodeController.text.trim();
    final state = _thanaController.text.trim();
    if (fullName.isEmpty ||
        phone.isEmpty ||
        addressLine1.isEmpty ||
        city.isEmpty ||
        state.isEmpty) {
      return null;
    }
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': _addressLine2Controller.text.trim(),
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': 'Bangladesh',
    };
  }

  Widget _buildShippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Information',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.0),
        if (_isLoadingShippingData)
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          ),
        if (!_isLoadingShippingData) ...[
          if (_shippingError != null) ...[
            Text(
              _shippingError!,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: Colors.red,
                  ),
            ),
            SizedBox(height: 12.0),
          ],
          _buildAddressSection(),
          SizedBox(height: 16.0),
          _buildShippingMethodSection(),
          if (_isCalculatingShipping) ...[
            SizedBox(height: 12.0),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Text(
                  'Calculating shipping...',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
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
            'Shipping Address',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.0),
          _buildAddressForm(),
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddressField(
          controller: _fullNameController,
          label: 'Name',
          hintText: 'e.g. Md Rahim Uddin',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _phoneController,
          label: 'Phone',
          hintText: 'e.g. 01712-345678',
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 8.0),
        if (_districts.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _selectedDistrictName,
            decoration: InputDecoration(
              labelText: 'District',
              hintText: 'Select district (e.g. Dhaka)',
              filled: true,
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              isDense: true,
            ),
            items: _districts
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d['name']?.toString(),
                    child: Text(d['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              final district = _districts.firstWhere(
                (d) => d['name']?.toString() == v,
                orElse: () => <String, dynamic>{},
              );
              setState(() {
                _selectedDistrictName = v;
                _selectedDistrictIsDhaka = district['is_dhaka_area'] == true;
              });
              await _fetchShippingMethods();
              await _calculateShippingCost();
            },
          ),
          SizedBox(height: 6.0),
          Text(
            _selectedDistrictIsDhaka ? 'Delivery Zone: Dhaka area' : 'Delivery Zone: Outside Dhaka',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _thanaController,
          label: 'Thana',
          hintText: 'e.g. Dhanmondi',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _addressLine1Controller,
          label: 'Address',
          hintText: 'Road no, house, village, area',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _postalCodeController,
          label: 'Postcode (Optional)',
          hintText: 'e.g. 1209',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildShippingMethodSection() {
    return Container(
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
            'Shipping Method',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.0),
          if (_shippingMethods.isEmpty)
            Text(
              'No shipping methods available.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          if (_shippingMethods.isNotEmpty)
            ..._shippingMethods.map((method) {
              final methodMap = Map<String, dynamic>.from(method as Map);
              final methodId =
                  methodMap['id']?.toString() ?? methodMap['_id']?.toString() ?? '';
              final name = methodMap['name']?.toString() ?? 'Shipping';
              final carrier = methodMap['description']?.toString() ??
                  methodMap['carrier']?.toString();
              final estimateText = methodMap['delivery_days']?.toString();
              return RadioListTile<String>(
                value: methodId,
                groupValue: _selectedShippingMethodId,
                onChanged: (value) {
                  setState(() {
                    _selectedShippingMethodId = value;
                  });
                  _calculateShippingCost();
                },
                contentPadding: EdgeInsets.zero,
                title: Text(
                  name,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  [carrier, estimateText].where((e) => e != null && e.isNotEmpty).join(' • '),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                activeColor: FlutterFlowTheme.of(context).primary,
              );
            }).toList(),
        ],
      ),
    );
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
                      value == 'ssl' ? Icons.credit_card :
                      value == 'wallet' ? Icons.account_balance_wallet_rounded :
                      Icons.payment,
                      color: value == 'bkash' ? Colors.pink : 
                             value == 'ssl' ? Colors.blue :
                             value == 'wallet' ? Colors.amber.shade700 : Colors.grey,
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
    final baseTotal =
        (subtotalAfterBookDiscounts - _discountAmount).clamp(0.0, double.infinity);
    final hasHardcopy = _hasHardcopy(cart);
    final finalTotal =
        hasHardcopy ? (baseTotal + _shippingCost) : baseTotal;

    if (hasHardcopy && !_shippingDataLoaded && !_isLoadingShippingData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadShippingData();
        }
      });
    }

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
                        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
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
                                                  '${_formatCartType(cartItem.type)} • Qty: ${cartItem.quantity}',
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
                            if (hasHardcopy) ...[
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Shipping:',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                  ),
                                  Text(
                                    '৳${_shippingCost.toStringAsFixed(2)}',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      color: FlutterFlowTheme.of(context).primary,
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
        
                      if (hasHardcopy) ...[
                        SizedBox(height: 24.0),
                        _buildShippingSection(),
                      ],

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
                      _buildPaymentOption(
                        'wallet',
                        'Wallet Coins',
                        'Unlock ebook/audiobook using your coin balance',
                        'assets/images/coin.png',
                      ),
        
                      SizedBox(height: 24.0),
        
                      // Digital Delivery Info
                      // Container(
                      //   padding: EdgeInsets.all(16.0),
                      //   decoration: BoxDecoration(
                      //     color: FlutterFlowTheme.of(context).accent1.withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(12.0),
                      //     border: Border.all(
                      //       color: FlutterFlowTheme.of(context).accent1.withOpacity(0.3),
                      //     ),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       Icon(
                      //         Icons.info_outline,
                      //         color: FlutterFlowTheme.of(context).primary,
                      //       ),
                      //       SizedBox(width: 12.0),
                      //       Expanded(
                      //         child: Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             Text(
                      //               'Instant Digital Delivery',
                      //               style: FlutterFlowTheme.of(context).bodyMedium.override(
                      //                 fontWeight: FontWeight.w600,
                      //               ),
                      //             ),
                      //             Text(
                      //               'Your ebook(s) will be delivered instantly to your profile after successful payment.',
                      //               style: FlutterFlowTheme.of(context).bodySmall.override(
                      //                 color: FlutterFlowTheme.of(context).secondaryText,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
                  final shippingAddress =
                      hasHardcopy ? _shippingAddressForOrder() : null;
                  // if (selectedPaymentMethod == 'wallet' && hasHardcopy) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(
                  //       content: Text(
                  //         'Wallet coins are supported for ebook/audiobook only.',
                  //       ),
                  //       backgroundColor: Colors.red,
                  //     ),
                  //   );
                  //   return;
                  // }
                  if (hasHardcopy && shippingAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please provide complete shipping details for hardcopy orders.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (hasHardcopy &&
                      (_selectedShippingMethodId == null ||
                          _selectedShippingMethodId!.trim().isEmpty)) {
                    setState(() {
                      _selectedShippingMethodId = 'standard';
                    });
                  }
                  final paid = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => MakeCheckOutScreen(
                        cartLines: cart.items.values.toList(),
                        bookIds: cart.items.keys.toList(),
                        jwtToken: FFAppState().token,
                        userId: FFAppState().userId,
                        couponCode: _appliedCouponCode,
                        couponDiscount: _discountAmount,
                        appliedCouponId: _appliedCouponId,
                        shippingMethodId: _selectedShippingMethodId,
                        shippingMethodName: _selectedShippingMethodName,
                        shippingCarrier: _selectedShippingCarrier,
                        shippingCost: _shippingCost,
                        estimatedDeliveryDays: _estimatedDeliveryDays,
                        shippingAddress: shippingAddress,
                        selectedPaymentMethod: selectedPaymentMethod,
                      ),
                    ),
                  );
                  if (paid == true && mounted) {
                    cart.clear();
                  }
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
