import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_store.dart';
import '../services/external_links.dart';
import 'admin/admin_dashboard_screen.dart';

class AccountScreen extends StatefulWidget {
  final AppStore store;
  const AccountScreen({super.key, required this.store});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _openConsentForm() async {
    final ok = await ExternalLinks.openConsentForm();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Het toestemmingsformulier kon niet worden geopend.'),
        ),
      );
    }
  }

  Future<void> _signIn() async {
    try {
      await widget.store.signInOwner(
        email: email.text,
        password: password.text,
      );
      if (!mounted) return;
      password.clear();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(store: widget.store),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inloggen mislukt: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
        ? 'Controleer de Supabase-configuratie van de app.'
        : store.databaseError ??
            '${store.services.where((s) => s.active && s.bookable).length} boekbare diensten beschikbaar';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFF24201A),
            foregroundColor: AppColors.gold,
            child: Icon(Icons.person, size: 34),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              store.isOwner ? 'Robert • eigenaar' : 'Gast / klant',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (store.isOwner && store.ownerEmail != null) ...[
            const SizedBox(height: 5),
            Center(
              child: Text(
                store.ownerEmail!,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ],
          const SizedBox(height: 26),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Persoonsgegevens'),
                  subtitle: Text('Klantprofiel wordt later aan klant-login gekoppeld'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Toestemmingsformulier tatoeage'),
                  subtitle: const Text(
                    'Gezondheidsverklaring en toestemming via de website',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openConsentForm,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Herinneringen'),
                  trailing: Switch(value: true, onChanged: (_) {}),
                ),
              ],
            ),
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
                      onPressed: store.loading ? null : () => store.refreshAll(),
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
          if (store.isOwner) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminDashboardScreen(store: widget.store),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Open Robert beheer'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: store.adminLoading
                  ? null
                  : () async {
                      await store.signOutOwner();
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Uitloggen als eigenaar'),
            ),
          ] else ...[
            const Text(
              'Eigenaar-login',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Alleen een Supabase-account met de owner-rol krijgt toegang tot klanten, agenda, foto’s en betalingen.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-mailadres',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Wachtwoord',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: store.adminLoading ? null : _signIn,
              icon: store.adminLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.lock_open),
              label: const Text('Inloggen'),
            ),
            if (store.adminError != null) ...[
              const SizedBox(height: 10),
              Text(
                store.adminError!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
