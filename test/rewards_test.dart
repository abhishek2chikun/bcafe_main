// The reward maths, which is where a loyalty bug would actually live: the
// widget is a view over `RewardsProvider`, so the tier boundaries and the
// delivered-only rule are what is worth pinning down.

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/models/reward_model.dart';
import 'package:food_app/providers/rewards_provider.dart';

PastOrder order(String id, double total, {String status = 'Delivered'}) =>
    PastOrder(id: id, date: 'Oct 12, 2023', totalAmount: total, status: status, items: const []);

void main() {
  test('points are ten per dollar on delivered orders', () {
    final rewards = RewardsProvider()..syncFromOrders([order('ORD-1', 26.98)]);
    expect(rewards.balance, 270);
  });

  test('an order that is not delivered earns nothing', () {
    final rewards = RewardsProvider()
      ..syncFromOrders([order('ORD-1', 40.00, status: 'Cancelled')]);
    expect(rewards.balance, 0);
    expect(rewards.entries, isEmpty);
  });

  test('a customer sitting exactly on a threshold is in the higher tier', () {
    expect(tierFor(250).name, 'Silver');
    expect(tierFor(249).name, 'Bronze');
    expect(tierFor(1500).name, 'Platinum');
  });

  test('progress is bounded and the top tier is full', () {
    final top = RewardsProvider()..syncFromOrders([order('ORD-1', 500.00)]);
    expect(top.tier.name, 'Platinum');
    expect(top.nextTier, isNull);
    expect(top.tierProgress, 1.0);
    expect(top.pointsToNextTier, 0);
  });

  test('a new customer starts at Bronze with zero progress', () {
    final fresh = RewardsProvider()..syncFromOrders([]);
    expect(fresh.tier.name, 'Bronze');
    expect(fresh.balance, 0);
    expect(fresh.tierProgress, 0.0);
    expect(fresh.pointsToNextTier, 250);
  });
}
