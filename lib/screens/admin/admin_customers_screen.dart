import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/app_store.dart';

class AdminCustomersScreen extends StatelessWidget {
  final AppStore store;
  const AdminCustomersScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klanten')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: store.customers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = store.customers[i];
          final count = store.appointments.where((a) => a.email.toLowerCase() == c.email.toLowerCase()).length;
          return Card(child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF24201A), foregroundColor: AppColors.gold, child: Icon(Icons.person_outline)),
            title: Text(c.name),
            subtitle: Text('${c.email}\n${c.phone}\n$count afspraak/afspraken'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
          ));
        },
      ),
    );
  }
}
