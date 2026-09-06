import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/app_store.dart';
import 'admin_customer_detail_screen.dart';

class AdminCustomersScreen extends StatefulWidget {
  final AppStore store;
  const AdminCustomersScreen({super.key, required this.store});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
    search.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final list = widget.store.customers.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klanten'),
        actions: [
          IconButton(
            tooltip: 'Vernieuwen',
            onPressed:
                widget.store.adminLoading ? null : () => widget.store.loadAdminData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                labelText: 'Zoek klant',
                hintText: 'Naam, e-mail of telefoon',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: search.clear,
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'Geen klanten gevonden.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final count = widget.store.appointments
                          .where((a) => a.customerId == c.id)
                          .length;
                      final next = widget.store.appointments
                          .where(
                            (a) =>
                                a.customerId == c.id &&
                                a.startsAt.isAfter(DateTime.now()) &&
                                a.status != 'cancelled',
                          )
                          .toList()
                        ..sort(
                          (a, b) => a.startsAt.compareTo(b.startsAt),
                        );

                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminCustomerDetailScreen(
                                  store: widget.store,
                                  customerId: c.id,
                                ),
                              ),
                            );
                          },
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF24201A),
                            foregroundColor: AppColors.gold,
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            '${c.email}\n${c.phone}\n$count afspraak/afspraken'
                            '${next.isEmpty ? '' : ' • volgende gepland'}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
