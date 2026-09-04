import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/app_store.dart';

class AdminAgendaScreen extends StatelessWidget {
  final AppStore store;
  const AdminAgendaScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final list = [...store.appointments]..sort((a,b) => a.startsAt.compareTo(b.startsAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final a = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(DateFormat('dd-MM-yyyy • HH:mm').format(a.startsAt), style: const TextStyle(color: AppColors.goldSoft, fontWeight: FontWeight.w700))),
                  Chip(label: Text(a.statusLabel)),
                ]),
                const SizedBox(height: 6),
                Text(a.customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(a.service.name, style: const TextStyle(color: AppColors.muted)),
                const Divider(height: 24),
                Text(a.idea),
                Text('Plaats: ${a.placement}', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  Chip(avatar: Icon(a.consentComplete ? Icons.check_circle : Icons.pending, size: 16), label: const Text('Toestemming')),
                  Chip(avatar: Icon(a.depositPaid ? Icons.check_circle : Icons.pending, size: 16), label: const Text('Aanbetaling')),
                ])
              ]),
            )),
          );
        },
      ),
    );
  }
}
