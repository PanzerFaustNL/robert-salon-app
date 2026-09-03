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
  void dispose() { pin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const CircleAvatar(radius: 34, backgroundColor: Color(0xFF24201A), foregroundColor: AppColors.gold, child: Icon(Icons.person, size: 34)),
        const SizedBox(height: 14),
        const Center(child: Text('Gast / klant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
        const SizedBox(height: 26),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.person_outline), title: const Text('Persoonsgegevens'), trailing: const Icon(Icons.chevron_right)),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Gezondheidsverklaring'), trailing: const Icon(Icons.chevron_right)),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Herinneringen'), trailing: Switch(value: true, onChanged: (_) {})),
        ])),
        const SizedBox(height: 28),
        const Text('BEHEER', style: TextStyle(color: AppColors.gold, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Robert beheer-PIN', hintText: 'Demo: 2580')),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            if (pin.text == '2580') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboardScreen(store: widget.store)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onjuiste PIN. Voor de demo is de PIN 2580.')));
            }
          },
          icon: const Icon(Icons.lock_open),
          label: const Text('Open beheer'),
        ),
        const SizedBox(height: 10),
        const Text('De demo-PIN is alleen bedoeld voor de lokale prototypeversie. In productie wordt dit vervangen door echte authenticatie en rollen.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ]),
    );
  }
}
