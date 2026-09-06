import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../services/app_store.dart';
import '../../services/external_links.dart';
import 'admin_appointment_detail_screen.dart';

class AdminFormsScreen extends StatefulWidget {
  final AppStore store;
  const AdminFormsScreen({super.key, required this.store});

  @override
  State<AdminFormsScreen> createState() => _AdminFormsScreenState();
}

class _AdminFormsScreenState extends State<AdminFormsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final list = widget.store.appointments
        .where(
          (a) =>
              a.startsAt.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
              a.status != 'cancelled',
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final missing = list.where((a) => !a.consentReceived).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intakes & formulieren'),
        actions: [
          IconButton(
            tooltip: 'Open formulier',
            onPressed: () => ExternalLinks.openConsentForm(),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.assignment_outlined,
                color: AppColors.gold,
              ),
              title: Text('$missing formulier(en) nog niet ontvangen'),
              subtitle: const Text(
                'Markeer een formulier als ontvangen zodra Robert het ingevulde formulier heeft gecontroleerd.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (list.isEmpty)
            const Text(
              'Geen komende afspraken.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...list.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminAppointmentDetailScreen(
                            store: widget.store,
                            appointmentId: a.id,
                          ),
                        ),
                      );
                    },
                    leading: Icon(
                      a.consentReceived
                          ? Icons.verified_outlined
                          : Icons.pending_actions_outlined,
                      color: a.consentReceived
                          ? AppColors.gold
                          : AppColors.muted,
                    ),
                    title: Text(a.customerName),
                    subtitle: Text(
                      '${DateFormat('dd-MM-yyyy • HH:mm').format(a.startsAt)}\n${a.service.name}',
                    ),
                    isThreeLine: true,
                    trailing: Switch(
                      value: a.consentReceived,
                      onChanged: (value) async {
                        try {
                          await widget.store.setConsentReceived(a.id, value);
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opslaan mislukt: $error')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
