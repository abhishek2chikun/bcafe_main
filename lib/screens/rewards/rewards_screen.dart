import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/models/reward_model.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/order_provider.dart';
import 'package:food_app/providers/rewards_provider.dart';

/// The loyalty screen.
///
/// It pulls the order history on first build and projects points from it, so
/// the balance a customer sees always matches the orders on the Orders tab.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Deferred: providers cannot be read during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final orders = Provider.of<OrderProvider>(context, listen: false);
    if (userId != null) {
      await orders.fetchOrders(userId);
    }
    if (!mounted) return;
    Provider.of<RewardsProvider>(context, listen: false)
        .syncFromOrders(orders.orders);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final rewards = Provider.of<RewardsProvider>(context);

    return Scaffold(
      key: const Key('rewards_scaffold'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        key: const Key('rewards_app_bar'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.cyan, Colors.amber]),
          ),
        ),
        title: const Text("Rewards", style: TextStyle(fontSize: 24)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              key: Key('rewards_loading'),
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              key: const Key('rewards_refresh'),
              onRefresh: _load,
              child: ListView(
                key: const Key('rewards_list'),
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(rewards: rewards),
                  const SizedBox(height: 20),
                  const Text(
                    "Tiers",
                    key: Key('rewards_tiers_heading'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...rewardTiers.map(
                    (tier) => _TierRow(
                      tier: tier,
                      reached: rewards.balance >= tier.threshold,
                      current: tier.name == rewards.tier.name,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Points earned",
                    key: Key('rewards_history_heading'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (rewards.entries.isEmpty)
                    const Padding(
                      key: Key('rewards_empty_state'),
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "No points yet. Your first delivered order starts the clock.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...rewards.entries.map(
                      (entry) => ListTile(
                        key: Key('rewards_entry_${entry.orderId}'),
                        leading: const Icon(Icons.local_activity, color: Colors.amber),
                        title: Text(entry.orderId),
                        subtitle: Text(entry.date),
                        trailing: Text(
                          "+${entry.points}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final RewardsProvider rewards;

  const _BalanceCard({required this.rewards});

  @override
  Widget build(BuildContext context) {
    final next = rewards.nextTier;
    return Card(
      key: const Key('rewards_balance_card'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${rewards.balance} points",
              key: const Key('rewards_balance_value'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${rewards.tier.name} • ${rewards.tier.perk}",
              key: const Key('rewards_tier_label'),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              key: const Key('rewards_tier_progress'),
              value: rewards.tierProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: Colors.amber,
            ),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? "Top tier reached."
                  : "${rewards.pointsToNextTier} points to ${next.name}",
              key: const Key('rewards_next_tier_hint'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final RewardTier tier;
  final bool reached;
  final bool current;

  const _TierRow({
    required this.tier,
    required this.reached,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('rewards_tier_${tier.name.toLowerCase()}'),
      leading: Icon(
        reached ? Icons.check_circle : Icons.radio_button_unchecked,
        color: reached ? Colors.amber : Colors.grey,
      ),
      title: Text(
        tier.name,
        style: TextStyle(fontWeight: current ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Text(tier.perk),
      trailing: Text("${tier.threshold} pts"),
    );
  }
}
