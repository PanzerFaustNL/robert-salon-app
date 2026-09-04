import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/app_store.dart';
import 'admin_agenda_screen.dart';
import 'admin_customers_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AppStore store;
  const AdminDashboardScreen({super.key, required this.store});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() { super.initState(); widget.store.addListener(_refresh); }
  @override
  void dispose() { widget.store.removeListener(_refresh); super.dispose(); }
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.store.appointments.where((a) => a.startsAt.isAfter(DateTime.now())).toList()..sort((a,b) => a.startsAt.compareTo(b.startsAt));
    final unpaid = widget.store.appointments.where((a) => a.service.deposit > 0 && !a.depositPaid).length;
    final pending = widget.store.appointments.where((a) => a.status == 'requested').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Robert • Beheer')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
        const Text('STUDIO OVERZICHT', style: TextStyle(color: AppColors.gold, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Goedemiddag Robert', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _stat('Aanvragen', '$pending', Icons.inbox_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _stat('Open betaling', '$unpaid', Icons.euro_outlined)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _stat('Klanten', '${widget.store.customers.length}', Icons.people_outline)),
          const SizedBox(width: 10),
          Expanded(child: _stat('Komend', '${upcoming.length}', Icons.event_available_outlined)),
        ]),
        const SizedBox(height: 26),
        const Text('Beheer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _menu(context, Icons.calendar_month, 'Agenda', 'Dag- en weekoverzicht van afspraken', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAgendaScreen(store: widget.store)))),
        _menu(context, Icons.people_alt_outlined, 'Klanten', 'Klantgegevens en afspraakgeschiedenis', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCustomersScreen(store: widget.store)))),
        _menu(context, Icons.assignment_outlined, 'Intakes & formulieren', 'Toestemming en gezondheidsverklaringen', () {}),
        _menu(context, Icons.payments_outlined, 'Betalingen', 'Aanbetalingen en betaalstatus', () {}),
        _menu(context, Icons.collections_outlined, 'Portfolio', 'Foto’s en categorieën beheren', () {}),
        const SizedBox(height: 24),
        const Text('Eerstvolgende', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (upcoming.isEmpty) const Text('Geen komende afspraken.', style: TextStyle(color: AppColors.muted)),
        ...upcoming.take(3).map((a) => Card(child: ListTile(
          leading: const Icon(Icons.circle, size: 10, color: AppColors.gold),
          title: Text(a.customerName),
          subtitle: Text('${DateFormat('dd-MM • HH:mm').format(a.startsAt)} • ${a.service.name}'),
          trailing: Text(a.statusLabel, style: const TextStyle(color: AppColors.goldSoft)),
        ))),
      ]),
    );
  }

  Widget _stat(String title, String value, IconData icon) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.gold),
      const SizedBox(height: 12),
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ]),
  ));

  Widget _menu(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(child: ListTile(onTap: onTap, leading: Icon(icon, color: AppColors.gold), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right))),
  );
}
