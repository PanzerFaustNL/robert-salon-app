import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_store.dart';

class AdminPaymentsScreen extends StatefulWidget {
  final AppStore store;
  const AdminPaymentsScreen({super.key, required this.store});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double get totalPaid => widget.store.payments
      .where((p) => p.status == 'paid')
      .fold(0.0, (sum, p) => sum + p.amount);

  List<Appointment> get unpaidDeposits {
    final result = widget.store.appointments
        .where(
          (a) =>
              a.service.deposit > 0 &&
              !a.depositPaid &&
              a.status != 'cancelled',
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return result;
  }

  Future<void> _recordPayment(
    Appointment appointment, {
    required String kind,
    double? suggested,
  }) async {
    final amountController = TextEditingController(
      text: (suggested ?? 0).toStringAsFixed(2),
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          kind == 'deposit'
              ? 'Aanbetaling registreren'
              : 'Betaling registreren',
        ),
        content: TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Bedrag',
            prefixText: '€ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );

    amountController.dispose();
    if (amount == null) return;

    try {
      await widget.store.recordPayment(
        appointment: appointment,
        amount: amount,
        kind: kind,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Betaling opslaan mislukt: $error')),
        );
      }
    }
  }

  Appointment? _appointmentFor(Payment payment) {
    for (final appointment in widget.store.appointments) {
      if (appointment.id == payment.appointmentId) return appointment;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Betalingen'),
        actions: [
          IconButton(
            tooltip: 'Vernieuwen',
            onPressed:
                widget.store.adminLoading ? null : () => widget.store.loadAdminData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Ontvangen',
                  '€${totalPaid.toStringAsFixed(2)}',
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Open aanbetalingen',
                  '${unpaidDeposits.length}',
                  Icons.pending_actions_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Open aanbetalingen',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (unpaidDeposits.isEmpty)
            const Text(
              'Geen openstaande aanbetalingen.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...unpaidDeposits.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text(a.customerName),
                    subtitle: Text(
                      '${a.service.name}\n${DateFormat('dd-MM-yyyy • HH:mm').format(a.startsAt)}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () => _recordPayment(
                        a,
                        kind: 'deposit',
                        suggested: a.service.deposit,
                      ),
                      child: Text(
                        '€${a.service.deposit.toStringAsFixed(0)} betaald',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Betalingshistorie',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (widget.store.payments.isEmpty)
            const Text(
              'Nog geen betalingen geregistreerd.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...widget.store.payments.map(
              (p) {
                final a = _appointmentFor(p);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF24201A),
                        foregroundColor: AppColors.gold,
                        child: Icon(Icons.euro),
                      ),
                      title: Text(
                        '€${p.amount.toStringAsFixed(2)} • ${p.kindLabel}',
                      ),
                      subtitle: Text(
                        '${a?.customerName ?? 'Afspraak #${p.appointmentId}'}\n'
                        '${DateFormat('dd-MM-yyyy • HH:mm').format(p.paidAt ?? p.createdAt)} • ${p.provider}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        p.statusLabel,
                        style: const TextStyle(color: AppColors.goldSoft),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dit scherm registreert betalingen nu handmatig. De volgende stap is de echte iDEAL/Mollie-koppeling; die kan dezelfde payments-tabel blijven gebruiken.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
