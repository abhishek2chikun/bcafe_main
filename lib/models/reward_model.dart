/// The loyalty ledger.
///
/// Points are derived from delivered orders rather than stored separately, so
/// there is one source of truth: an order that is refunded stops counting the
/// moment it leaves the delivered set, and no reconciliation job is needed.
class RewardTier {
  final String name;
  final int threshold;
  final String perk;

  const RewardTier({
    required this.name,
    required this.threshold,
    required this.perk,
  });
}

/// Ordered low to high. `tierFor` walks it backwards, so adding a tier in the
/// middle needs no other change.
const List<RewardTier> rewardTiers = [
  RewardTier(name: 'Bronze', threshold: 0, perk: 'Free delivery over \$25'),
  RewardTier(name: 'Silver', threshold: 250, perk: '5% off every order'),
  RewardTier(name: 'Gold', threshold: 750, perk: '10% off and priority kitchen'),
  RewardTier(name: 'Platinum', threshold: 1500, perk: '15% off and a free side daily'),
];

RewardTier tierFor(int points) {
  for (final tier in rewardTiers.reversed) {
    if (points >= tier.threshold) return tier;
  }
  return rewardTiers.first;
}

/// The next tier up, or null when the customer is already at the top.
RewardTier? nextTierAfter(RewardTier current) {
  final index = rewardTiers.indexOf(current);
  if (index < 0 || index >= rewardTiers.length - 1) return null;
  return rewardTiers[index + 1];
}

class RewardEntry {
  final String orderId;
  final String date;
  final int points;

  const RewardEntry({
    required this.orderId,
    required this.date,
    required this.points,
  });
}
