import 'package:flutter/material.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/helpers/db_helper.dart';
import 'package:intl/intl.dart';

class OrderProvider with ChangeNotifier {
  List<PastOrder> _orders = [];

  List<PastOrder> get orders => [..._orders];

  /// How many orders this account has placed. The Orders screen puts this in
  /// its title, which is otherwise the only screen in the app that gives no
  /// indication of how much is on it before you scroll.
  int get orderCount => _orders.length;

  /// What those orders came to. Read by the rewards balance and by the title.
  double get totalSpent =>
      _orders.fold(0.0, (sum, order) => sum + order.totalAmount);

  Future<void> fetchOrders(String userId) async {
    final orderData = await DBHelper.getData('orders', where: 'userId = ?', whereArgs: [userId]);
    
    List<PastOrder> loadedOrders = [];
    
    for (var order in orderData) {
      final itemData = await DBHelper.getData('order_items', where: 'orderId = ?', whereArgs: [order['id']]);
      
      loadedOrders.add(
        PastOrder(
          id: order['id'],
          date: order['date'],
          totalAmount: order['total'],
          status: order['status'],
          items: itemData.map((item) => OrderItem(
            id: item['id'].toString(),
            title: item['title'],
            price: item['price'],
            quantity: item['quantity'],
          )).toList(),
        ),
      );
    }
    
    _orders = loadedOrders.reversed.toList(); // Newest first
    notifyListeners();
  }

  Future<void> addOrder(String userId, double total, List<OrderItem> items) async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final date = DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now());

    // 1. Save to DB
    await DBHelper.insert('orders', {
      'id': orderId,
      'userId': userId,
      'date': date,
      'total': total,
      'status': 'Delivered',
    });

    for (var item in items) {
      await DBHelper.insert('order_items', {
        'orderId': orderId,
        'title': item.title,
        'price': item.price,
        'quantity': item.quantity,
      });
    }

    // 2. Local Update
    _orders.insert(0, PastOrder(
      id: orderId,
      date: date,
      totalAmount: total,
      status: 'Delivered',
      items: items,
    ));
    
    notifyListeners();
  }
}
