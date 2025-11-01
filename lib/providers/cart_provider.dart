import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? discountAmount;
  final double? discountPercentage;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.discountAmount,
    this.discountPercentage,
    this.quantity = 1,
  });

  // Calculate the actual price after discount
  double get discountedPrice {
    if (discountAmount != null && discountAmount! > 0) {
      return (price - discountAmount!).clamp(0.0, double.infinity);
    } else if (discountPercentage != null && discountPercentage! > 0) {
      final discount = price * (discountPercentage! / 100.0);
      return (price - discount).clamp(0.0, double.infinity);
    }
    return price;
  }

  // Get discount value for this item
  double get itemDiscount {
    if (discountAmount != null && discountAmount! > 0) {
      return discountAmount! * quantity;
    } else if (discountPercentage != null && discountPercentage! > 0) {
      final discount = price * (discountPercentage! / 100.0);
      return discount * quantity;
    }
    return 0.0;
  }

  // Convert a CartItem into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'quantity': quantity,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'CartItem{id: $id, name: $name, imageUrl: $imageUrl, price: $price, discountAmount: $discountAmount, discountPercentage: $discountPercentage, quantity: $quantity}';
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  // Get total amount before discounts (original price)
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // Get total amount after book discounts (but before coupon)
  double get totalAmountAfterBookDiscounts {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.discountedPrice * cartItem.quantity;
    });
    return total;
  }

  // Get total discount from all books
  double get totalBookDiscount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.itemDiscount;
    });
    return total;
  }

  void addItem(
    String productId,
    String name,
    String imageUrl,
    double price, {
    bool increment = true,
    double? discountAmount,
    double? discountPercentage,
  }) {
    if (_items.containsKey(productId)) {
      // change quantity
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          imageUrl: existingCartItem.imageUrl,
          price: existingCartItem.price,
          discountAmount: existingCartItem.discountAmount,
          discountPercentage: existingCartItem.discountPercentage,
          quantity: increment ? existingCartItem.quantity + 1 : 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(), // Unique ID for the cart item
          name: name,
          imageUrl: imageUrl,
          price: price,
          discountAmount: discountAmount,
          discountPercentage: discountPercentage,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          imageUrl: existingCartItem.imageUrl,
          price: existingCartItem.price,
          discountAmount: existingCartItem.discountAmount,
          discountPercentage: existingCartItem.discountPercentage,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
