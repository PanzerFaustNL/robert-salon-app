import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_store.dart';
import 'admin/admin_dashboard_screen.dart';

class AccountScreen extends StatefulWidget {
  final AppStore store;
  const AccountScreen({super.key, required this.store});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    pin.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final dbIcon = !store.databaseConfigured
        ? Icons.link_off
        : store.databaseError != null
            ? Icons.error_outline
            : Icons.cloud_done_outlined;
    final dbTitle = !store.databaseConfigured
        ? 'Database niet ingesteld'
        : store.databaseError != null
            ? 'Databasefout'
            : 'Supabase verbonden';
    final dbSubtitle = !store.databaseConfigured
        ? 'Start de app met config/supabase.json.'
        : store.databaseError ??
            '${store.services.length} diensten geladen uit de database';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFF24201A),
          foregroundColor: AppColors.gold,
          child: Icon(Icons.person, size: 34),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'Gast / klant',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 26),
        Card(
          child: Column(children: [
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Persoonsgegevens'),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text('Gezondheidsverklaring'),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Herinneringen'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: Icon(dbIcon, color: AppColors.gold),
            title: Text(dbTitle),
            subtitle: Text(dbSubtitle),
            trailing: store.databaseConfigured
                ? IconButton(
                    tooltip: 'Vernieuwen',
                    onPressed: store.loading
                        ? null
                        : () {
                            store.refreshAll();
                          },
                    icon: store.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'BEHEER',
          style: TextStyle(
            color: AppColors.gold,
            letterSpacing: 2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Robert beheer-PIN',
            hintText: 'Demo: 2580',
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            if (pin.text == '2580') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminDashboardScreen(store: widget.store),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Onjuiste PIN. Voor de demo is de PIN 2580.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.lock_open),
          label: const Text('Open beheer'),
        ),
        const SizedBox(height: 10),
        const Text(
          'De demo-PIN is alleen bedoeld voor de prototypeversie. Voor productie wordt dit vervangen door Supabase Auth en een echte owner-rol.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ]),
    );
  }
}
