import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/earnings_bloc.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EarningsBloc>().add(const FetchEarningsRequested());
  }

  void _openWithdrawalModal(BuildContext context, int availableBalance) {
    final amountController = TextEditingController(text: '100000');
    final accountController = TextEditingController(text: '1234567890');
    String selectedBank = 'BCA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Request Bank Withdrawal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Available to withdraw: ${CurrencyFormatter.toIdr(availableBalance)}',
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedBank,
                decoration: const InputDecoration(labelText: 'Destination Bank'),
                items: const [
                  DropdownMenuItem(value: 'BCA', child: Text('Bank Central Asia (BCA)')),
                  DropdownMenuItem(value: 'Mandiri', child: Text('Bank Mandiri')),
                  DropdownMenuItem(value: 'BNI', child: Text('Bank Negara Indonesia (BNI)')),
                  DropdownMenuItem(value: 'BRI', child: Text('Bank Rakyat Indonesia (BRI)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedBank = val);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: accountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number',
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Withdrawal Amount (IDR)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text.trim()) ?? 0;
                  if (amount > 0) {
                    context.read<EarningsBloc>().add(
                          WithdrawalRequested(
                            amountIdr: amount,
                            bankName: selectedBank,
                            accountNumber: accountController.text.trim(),
                          ),
                        );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Confirm Withdrawal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payouts'),
      ),
      body: BlocConsumer<EarningsBloc, EarningsState>(
        listener: (context, state) {
          if (state is EarningsLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.safetyGreen,
                ),
              );
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.emergencyRed,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is EarningsLoading || state is EarningsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EarningsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          final ledger = (state as EarningsLoaded).ledger;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Cards
                Card(
                  color: AppColors.primaryGreen,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.toIdr(ledger.availableBalanceIdr),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pending Escrow',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  CurrencyFormatter.toIdr(ledger.pendingBalanceIdr),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lifetime Earnings',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  CurrencyFormatter.toIdr(ledger.lifetimeEarningsIdr),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openWithdrawalModal(
                    context,
                    ledger.availableBalanceIdr,
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Withdraw Funds to Bank'),
                ),
                const SizedBox(height: 28),

                // Transaction Ledger
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...ledger.transactions.map((tx) {
                  final isNegative = tx.amountIdr < 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isNegative
                            ? Colors.red.withAlpha(20)
                            : AppColors.safetyGreen.withAlpha(20),
                        child: Icon(
                          isNegative
                              ? Icons.arrow_outward
                              : Icons.arrow_downward,
                          color: isNegative
                              ? AppColors.emergencyRed
                              : AppColors.safetyGreen,
                        ),
                      ),
                      title: Text(
                        tx.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Ref: ${tx.bookingReference}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${isNegative ? '-' : '+'}${CurrencyFormatter.toIdr(tx.amountIdr.abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isNegative
                              ? AppColors.emergencyRed
                              : AppColors.safetyGreen,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
