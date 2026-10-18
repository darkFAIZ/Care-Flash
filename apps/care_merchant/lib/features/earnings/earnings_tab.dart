import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Earnings page: available balance, pending earnings, transaction history and
/// payout status, plus a withdrawal request. (FR-CM-21, FR-CM-22, FR-P-29)
class EarningsTab extends ConsumerWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(earningsProvider).value;

    if (summary == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canWithdraw =
        summary.availableBalance >= PlatformPolicy.minimumWithdrawal;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(summary: summary),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canWithdraw
                ? () => showWithdrawSheet(context, summary)
                : null,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Request withdrawal'),
          ),
          const SizedBox(height: 8),
          Text(
            'Money arrives about ${PlatformPolicy.payoutSchedule.inDays} days '
            'after a request. Minimum withdrawal is '
            '${formatIdr(PlatformPolicy.minimumWithdrawal)}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('Transaction history', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (summary.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: const [
                    Icon(Icons.inbox_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your completed sessions and payouts will appear here.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._buildHistory(summary),
        ],
      ),
    );
  }

  List<Widget> _buildHistory(EarningsSummary summary) {
    final items = <_LedgerItem>[
      for (final entry in summary.earnings)
        _LedgerItem(
          at: entry.at,
          amount: entry.amount,
          title: entry.kind.label,
          subtitle: '${entry.reference} · ${_formatDate(entry.at)}',
          icon: Icons.work_outline,
        ),
      for (final item in summary.withdrawals)
        _LedgerItem(
          at: item.requestedAt,
          amount: -item.amount,
          title: 'Withdrawal · ${item.status.label}',
          subtitle: '${item.method} · ${_formatDate(item.requestedAt)}',
          icon: Icons.account_balance_wallet_outlined,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return [
      for (final item in items)
        Card(
          child: ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            trailing: Text(
              formatIdr(item.amount),
              style: TextStyle(
                color: item.amount < 0 ? null : Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    ];
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _LedgerItem {
  const _LedgerItem({
    required this.at,
    required this.amount,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final DateTime at;
  final int amount;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Available balance',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatIdr(summary.availableBalance),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Pending',
                    value: formatIdr(summary.pendingBalance),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Total earned',
                    value: formatIdr(summary.totalEarned),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Paid out',
                    value: formatIdr(summary.totalPaidOut),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

/// Opens the withdrawal request sheet. (FR-CM-22)
Future<void> showWithdrawSheet(
  BuildContext context,
  EarningsSummary summary,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _WithdrawSheet(summary: summary),
  );
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.summary});

  final EarningsSummary summary;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.summary.availableBalance.toString(),
  );
  String _method = PlatformPolicy.payoutMethods.first;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _parsedAmount =>
      int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result =
        await ref.read(platformProvider).requestWithdrawal(_parsedAmount);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Withdrawal of ${formatIdr(result.amount)} requested via $_method. '
          'It arrives in about ${PlatformPolicy.payoutSchedule.inDays} days.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Withdraw earnings', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Available: ${formatIdr(widget.summary.availableBalance)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'IDR ',
                errorText: _error,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Payout method'),
              items: [
                for (final method in PlatformPolicy.payoutMethods)
                  DropdownMenuItem(value: method, child: Text(method)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _method = value);
                }
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Withdraw ${formatIdr(_parsedAmount)}'),
            ),
          ],
        ),
      ),
    );
  }
}
