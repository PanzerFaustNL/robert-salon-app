import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_store.dart';
import '../../services/external_links.dart';

class AdminAppointmentDetailScreen extends StatefulWidget {
  final AppStore store;
  final int appointmentId;

  const AdminAppointmentDetailScreen({
    super.key,
    required this.store,
    required this.appointmentId,
  });

  @override
  State<AdminAppointmentDetailScreen> createState() =>
      _AdminAppointmentDetailScreenState();
}

class _AdminAppointmentDetailScreenState
    extends State<AdminAppointmentDetailScreen> {
  late final TextEditingController notes;
  bool saving = false;

  Appointment? get appointment {
    for (final item in widget.store.appointments) {
      if (item.id == widget.appointmentId) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
    notes = TextEditingController(
      text: appointment?.internalNotes ?? '',
    );
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    notes.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _setStatus(String value) async {
    setState(() => saving = true);
    try {
      await widget.store.updateAppointmentStatus(widget.appointmentId, value);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => saving = true);
    try {
      await widget.store.updateAppointmentNotes(
        widget.appointmentId,
        notes.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notities opgeslagen.')),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _markDepositPaid() async {
    final a = appointment;
    if (a == null || a.service.deposit <= 0 || a.depositPaid) return;

    setState(() => saving = true);
    try {
      await widget.store.recordPayment(
        appointment: a,
        amount: a.service.deposit,
        kind: 'deposit',
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

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

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opslaan mislukt: $error'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Afspraak')),
        body: const Center(child: Text('Afspraak niet gevonden.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(a.customerName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.service.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd-MM-yyyy • HH:mm')
                        .format(a.startsAt),
                    style: const TextStyle(color: AppColors.goldSoft),
                  ),
                  const Divider(height: 26),
                  Text(a.customerName),
                  Text(a.email, style: const TextStyle(color: AppColors.muted)),
                  Text(a.phone, style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 14),
                  Text('Idee: ${a.idea}'),
                  Text(
                    'Plaats: ${a.placement}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: a.status,
            decoration: const InputDecoration(labelText: 'Afspraakstatus'),
            items: const [
              DropdownMenuItem(value: 'requested', child: Text('Aangevraagd')),
              DropdownMenuItem(value: 'confirmed', child: Text('Bevestigd')),
              DropdownMenuItem(value: 'completed', child: Text('Afgerond')),
              DropdownMenuItem(value: 'cancelled', child: Text('Geannuleerd')),
              DropdownMenuItem(value: 'no_show', child: Text('Niet verschenen')),
            ],
            onChanged: saving
                ? null
                : (value) {
                    if (value != null && value != a.status) {
                      _setStatus(value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: a.consentReceived,
                  onChanged: saving
                      ? null
                      : (value) async {
                          try {
                            await widget.store
                                .setConsentReceived(a.id, value);
                          } catch (error) {
                            _showError(error);
                          }
                        },
                  secondary: Icon(
                    a.consentReceived
                        ? Icons.verified_outlined
                        : Icons.description_outlined,
                    color: AppColors.gold,
                  ),
                  title: const Text('Toestemmingsformulier ontvangen'),
                  subtitle: const Text(
                    'Dit is de registratie dat Robert het formulier heeft ontvangen.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.open_in_new,
                    color: AppColors.gold,
                  ),
                  title: const Text('Open toestemmingsformulier'),
                  subtitle: const Text('Open Roberts formulier op de website'),
                  onTap: _openConsentForm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                a.depositPaid
                    ? Icons.check_circle_outline
                    : Icons.payments_outlined,
                color: AppColors.gold,
              ),
              title: Text(
                a.service.deposit > 0
                    ? 'Aanbetaling €${a.service.deposit.toStringAsFixed(2)}'
                    : 'Geen aanbetaling ingesteld',
              ),
              subtitle: Text(
                a.depositPaid ? 'Betaald' : 'Nog niet als betaald geregistreerd',
              ),
              trailing: a.service.deposit > 0 && !a.depositPaid
                  ? TextButton(
                      onPressed: saving ? null : _markDepositPaid,
                      child: const Text('Markeer betaald'),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Interne notities',
              hintText: 'Ontwerp, voorbereiding, bijzonderheden...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: saving ? null : _saveNotes,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Notities opslaan'),
          ),
        ],
      ),
    );
  }
}
