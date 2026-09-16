import 'package:flutter/material.dart';
import '../models/item_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  /// The most of one item the kitchen will accept in a single order. Orders
  /// for a hundred of something were reaching the pass as real tickets, and a
  /// stuck "+" button could get there in a few seconds.
  static const int maxQuantityPerItem = 20;

  /// True when [productId] is already at the cap, so the screen can say why
  /// the button stopped working instead of appearing to ignore the tap.
  bool isAtQuantityLimit(String productId) {
    final existing = _items[productId];
    return existing != null && existing.quantity >= maxQuantityPerItem;
  }

  void addItem(String productId, double price, String title) {
    if (isAtQuantityLimit(productId)) {
      return;
    }
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId, // Use the item's actual ID for consistent mapping
          title: title,
          price: price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItemCompletely(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
