import 'dart:convert';

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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _appliedCouponCode;
  String? _couponErrorMessage;
  bool _isApplyingCoupon = false;
  double _discountAmount = 0.0;
  bool _showAddressForm = false;
  bool _setAsDefault = false;
  bool _isLoadingShippingData = false;
  bool _isSubmittingAddress = false;
  bool _isCalculatingShipping = false;
  bool _shippingDataLoaded = false;
  String? _shippingError;
  List<dynamic> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  String? _selectedAddressId;
  List<dynamic> _shippingMethods = [];
  Map<String, dynamic>? _selectedShippingMethod;
  String? _selectedShippingMethodId;
  double _shippingCost = 0.0;

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
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
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
      
      final response = await http.post(
        Uri.parse('${FFAppConstants.baseApiUrl}/getcoupondetails'),
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
          if (maxDiscount > 0) {
            calculatedDiscount = calculatedDiscount.clamp(0.0, maxDiscount);
          }
          calculatedDiscount = calculatedDiscount > cartTotalAfterBookDiscounts ? cartTotalAfterBookDiscounts : calculatedDiscount;

          setState(() {
            _appliedCouponCode = code;
            _discountAmount = double.parse(calculatedDiscount.toStringAsFixed(2));
            _couponErrorMessage = null;
            _isApplyingCoupon = false;
          });
          if (_hasHardcopy(Provider.of<CartProvider>(context, listen: false))) {
            await _calculateShippingCost();
          }
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
    final response = await http.post(
      Uri.parse('${FFAppConstants.baseApiUrl}/getaddresses'),
      headers: {
        'Authorization': 'Bearer ${FFAppState().token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': FFAppState().userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch addresses (${response.statusCode})');
    }

    final payload = jsonDecode(response.body);
    final data = payload['data'];
    List<dynamic> addresses = [];
    if (data is List) {
      addresses = data;
    } else if (data is Map && data['addresses'] is List) {
      addresses = data['addresses'] as List<dynamic>;
    }

    Map<String, dynamic>? defaultAddress;
    for (final item in addresses) {
      if (item is Map && item['isDefault'] == true) {
        defaultAddress = Map<String, dynamic>.from(item);
        break;
      }
    }

    setState(() {
      _addresses = addresses;
      if (addresses.isEmpty) {
        _selectedAddress = null;
        _selectedAddressId = null;
        _showAddressForm = true;
      } else {
        final selected = defaultAddress ??
            Map<String, dynamic>.from(addresses.first as Map);
        _selectedAddress = selected;
        _selectedAddressId = selected['_id']?.toString();
      }
    });
  }

  Future<void> _fetchShippingMethods() async {
    final response = await http.post(
      Uri.parse('${FFAppConstants.baseApiUrl}/shipping-methods'),
      headers: {
        'Authorization': 'Bearer ${FFAppState().token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch shipping methods (${response.statusCode})');
    }

    final payload = jsonDecode(response.body);
    final data = payload['data'];
    final methods = data is List ? data : <dynamic>[];

    setState(() {
      _shippingMethods = methods;
      if (methods.isNotEmpty) {
        final selected = Map<String, dynamic>.from(methods.first as Map);
        _selectedShippingMethod = selected;
        _selectedShippingMethodId = selected['_id']?.toString();
      }
    });
  }

  Future<void> _calculateShippingCost() async {
    if (_selectedAddressId == null || _selectedShippingMethodId == null) {
      return;
    }
    setState(() {
      _isCalculatingShipping = true;
      _shippingError = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${FFAppConstants.baseApiUrl}/shipping/calculate'),
        headers: {
          'Authorization': 'Bearer ${FFAppState().token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'shippingMethodId': _selectedShippingMethodId,
          'addressId': _selectedAddressId,
          'cartTotal': (_getBaseTotal()).toDouble(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to calculate shipping (${response.statusCode})');
      }

      final payload = jsonDecode(response.body);
      final data = payload['data'] ?? {};
      final shippingCost =
          data['shippingCost'] ?? data['cost'] ?? data['shipping_cost'];
      setState(() {
        _shippingCost = (shippingCost is num)
            ? shippingCost.toDouble()
            : double.tryParse(shippingCost?.toString() ?? '0') ?? 0.0;
      });
    } catch (e) {
      setState(() {
        _shippingError = 'Failed to calculate shipping: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingShipping = false;
        });
      }
    }
  }

  double _getBaseTotal() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final subtotalAfterBookDiscounts = cart.totalAmountAfterBookDiscounts;
    return (subtotalAfterBookDiscounts - _discountAmount)
        .clamp(0.0, double.infinity);
  }

  Future<void> _submitAddress() async {
    if (_isSubmittingAddress) return;
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final addressLine1 = _addressLine1Controller.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final country = _countryController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        addressLine1.isEmpty ||
        city.isEmpty ||
        postalCode.isEmpty ||
        country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required address fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingAddress = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${FFAppConstants.baseApiUrl}/addaddress'),
        headers: {
          'Authorization': 'Bearer ${FFAppState().token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': FFAppState().userId,
          'addressType':'home',
          'email': 'Rayhan476666ahmed@gmail.com',
          'fullName': fullName,
          'phone': phone,
          'addressLine1': addressLine1,
          'addressLine2': _addressLine2Controller.text.trim(),
          'city': city,
          'state': _stateController.text.trim(),
          'postalCode': postalCode,
          'country': country,
          'isDefault': _setAsDefault,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add address (${response.statusCode})');
      }

      _fullNameController.clear();
      _phoneController.clear();
      _addressLine1Controller.clear();
      _addressLine2Controller.clear();
      _cityController.clear();
      _stateController.clear();
      _postalCodeController.clear();
      _countryController.clear();
      _setAsDefault = false;
      _showAddressForm = false;

      await _fetchAddresses();
      await _calculateShippingCost();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAddress = false;
        });
      }
    }
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
          if (_addresses.isEmpty && !_showAddressForm)
            Text(
              'No saved addresses found.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          if (_addresses.isNotEmpty && !_showAddressForm)
            ..._addresses.map((address) {
              final addressMap = Map<String, dynamic>.from(address as Map);
              final addressId = addressMap['_id']?.toString() ?? '';
              return RadioListTile<String>(
                value: addressId,
                groupValue: _selectedAddressId,
                onChanged: (value) {
                  setState(() {
                    _selectedAddressId = value;
                    _selectedAddress = addressMap;
                  });
                  _calculateShippingCost();
                },
                contentPadding: EdgeInsets.zero,
                title: Text(
                  addressMap['fullName']?.toString() ?? 'Unnamed',
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  _formatAddressLine(addressMap),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                activeColor: FlutterFlowTheme.of(context).primary,
              );
            }).toList(),
          if (_showAddressForm) _buildAddressForm(),
          if (_addresses.isNotEmpty && !_showAddressForm)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAddressForm = true;
                  });
                },
                child: Text(
                  'Add New Address',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: FlutterFlowTheme.of(context).primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
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
          label: 'Full Name',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _phoneController,
          label: 'Phone',
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _addressLine1Controller,
          label: 'Address Line 1',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _addressLine2Controller,
          label: 'Address Line 2 (Optional)',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _cityController,
          label: 'City',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _stateController,
          label: 'State (Optional)',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _postalCodeController,
          label: 'Postal Code',
        ),
        SizedBox(height: 8.0),
        _buildAddressField(
          controller: _countryController,
          label: 'Country',
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _setAsDefault,
          onChanged: (value) {
            setState(() {
              _setAsDefault = value ?? false;
            });
          },
          title: Text(
            'Set as default',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmittingAddress ? null : _submitAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isSubmittingAddress
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Address',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'SF Pro Display',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
            SizedBox(width: 12.0),
            if (_addresses.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showAddressForm = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(110, 48),
                  side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'SF Pro Display',
                        color: FlutterFlowTheme.of(context).primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
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
              final methodId = methodMap['_id']?.toString() ?? '';
              final name = methodMap['name']?.toString() ?? 'Shipping';
              final carrier = methodMap['carrier']?.toString();
              final estimatedDays = methodMap['estimatedDays'];
              String? estimateText;
              if (estimatedDays is Map) {
                final min = estimatedDays['min']?.toString();
                final max = estimatedDays['max']?.toString();
                if (min != null && max != null) {
                  estimateText = '$min-$max days';
                }
              }
              return RadioListTile<String>(
                value: methodId,
                groupValue: _selectedShippingMethodId,
                onChanged: (value) {
                  setState(() {
                    _selectedShippingMethodId = value;
                    _selectedShippingMethod = methodMap;
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
                  [carrier, estimateText].where((e) => e != null && e!.isNotEmpty).join(' • '),
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

  String _formatAddressLine(Map<String, dynamic> address) {
    final parts = [
      address['addressLine1']?.toString(),
      address['addressLine2']?.toString(),
      address['city']?.toString(),
      address['state']?.toString(),
      address['postalCode']?.toString(),
      address['country']?.toString(),
      address['phone']?.toString(),
    ].where((value) => value != null && value!.trim().isNotEmpty);
    return parts.join(', ');
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
                  if (hasHardcopy &&
                      (_selectedAddressId == null ||
                          _selectedShippingMethodId == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a shipping address and method'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MakeCheckOutScreen(
                        bookIds: cart.items.keys.toList(),
                        jwtToken: FFAppState().token,
                        userId: FFAppState().userId,
                        couponCode: _appliedCouponCode,
                        shippingMethodId: hasHardcopy ? _selectedShippingMethodId : null,
                        shippingAddressId: hasHardcopy ? _selectedAddressId : null,
                        shippingAddress: hasHardcopy ? _selectedAddress : null,
                        cartTotal: hasHardcopy ? baseTotal : null,

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
