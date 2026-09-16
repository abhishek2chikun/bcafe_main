import 'package:flutter/material.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/models/reward_model.dart';

/// Ten points per dollar, on delivered orders only.
const int pointsPerDollar = 10;

/// Reads the order history rather than keeping a balance of its own. It is a
/// projection, so it can never drift from the orders the customer can see.
class RewardsProvider with ChangeNotifier {
  List<RewardEntry> _entries = [];

  List<RewardEntry> get entries => [..._entries];

  int get balance => _entries.fold(0, (sum, entry) => sum + entry.points);

  RewardTier get tier => tierFor(balance);

  RewardTier? get nextTier => nextTierAfter(tier);

  /// Points still needed for the next tier; 0 at the top tier.
  int get pointsToNextTier {
    final next = nextTier;
    if (next == null) return 0;
    return next.threshold - balance;
  }

  /// Progress through the current tier, 0.0–1.0. Clamped because a customer
  /// sitting exactly on a threshold would otherwise divide by zero.
  double get tierProgress {
    final next = nextTier;
    if (next == null) return 1.0;
    final span = next.threshold - tier.threshold;
    if (span <= 0) return 1.0;
    return ((balance - tier.threshold) / span).clamp(0.0, 1.0);
  }

  void syncFromOrders(List<PastOrder> orders) {
    _entries = orders
        .where((order) => order.status == 'Delivered')
        .map((order) => RewardEntry(
              orderId: order.id,
              date: order.date,
              points: (order.totalAmount * pointsPerDollar).round(),
            ))
        .toList();
    notifyListeners();
  }
}
