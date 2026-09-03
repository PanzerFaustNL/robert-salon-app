import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/app_store.dart';

class BookingScreen extends StatefulWidget {
  final AppStore store;
  const BookingScreen({super.key, required this.store});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int step = 0;
  SalonService? service;
  DateTime? date;
  TimeOfDay? time;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final idea = TextEditingController();
  final placement = TextEditingController();
  bool consent = false;
  bool conditions = false;

  @override
  void dispose() {
    for (final c in [name, email, phone, idea, placement]) { c.dispose(); }
    super.dispose();
  }

  bool get canContinue {
    if (step == 0) return service != null;
    if (step == 1) return date != null && time != null;
    if (step == 2) return name.text.trim().isNotEmpty && email.text.contains('@') && phone.text.trim().isNotEmpty;
    if (step == 3) return idea.text.trim().isNotEmpty && placement.text.trim().isNotEmpty;
    if (step == 4) return consent && conditions;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Afspraak aanvragen')),
      body: Stepper(
        currentStep: step,
        onStepTapped: (v) => setState(() => step = v),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: canContinue ? () => step == 5 ? _finish() : setState(() => step++) : null,
              child: Text(step == 5 ? 'Aanvraag versturen' : 'Verder'),
            )),
            if (step > 0) ...[
              const SizedBox(width: 10),
              OutlinedButton(onPressed: () => setState(() => step--), child: const Text('Terug')),
            ]
          ]),
        ),
        steps: [
          Step(title: const Text('Behandeling'), isActive: step >= 0, content: _serviceStep()),
          Step(title: const Text('Datum & tijd'), isActive: step >= 1, content: _dateStep()),
          Step(title: const Text('Jouw gegevens'), isActive: step >= 2, content: _customerStep()),
          Step(title: const Text('Tattoo-idee'), isActive: step >= 3, content: _ideaStep()),
          Step(title: const Text('Toestemming'), isActive: step >= 4, content: _consentStep()),
          Step(title: const Text('Controleren'), isActive: step >= 5, content: _summaryStep()),
        ],
      ),
    );
  }

  Widget _serviceStep() => Column(
    children: widget.store.services.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RadioListTile<SalonService>(
        value: s,
        groupValue: service,
        onChanged: (v) => setState(() => service = v),
        title: Text(s.name),
        subtitle: Text('${s.description}\n± ${s.durationMinutes} min${s.deposit > 0 ? ' • aanbetaling €${s.deposit.toStringAsFixed(0)}' : ''}'),
      ),
    )).toList(),
  );

  Widget _dateStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event, color: AppColors.gold),
      title: Text(date == null ? 'Kies een datum' : DateFormat('dd-MM-yyyy').format(date!)),
      onTap: () async {
        final picked = await showDatePicker(context: context, firstDate: DateTime.now().add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 180)));
        if (picked != null) setState(() => date = picked);
      },
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule, color: AppColors.gold),
      title: Text(time == null ? 'Kies een tijd' : time!.format(context)),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 11, minute: 0));
        if (picked != null) setState(() => time = picked);
      },
    )
  ]);

  Widget _customerStep() => Column(children: [
    TextField(controller: name, decoration: const InputDecoration(labelText: 'Naam'), onChanged: (_) => setState(() {})),
    const SizedBox(height: 10),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mailadres'), onChanged: (_) => setState(() {})),
    const SizedBox(height: 10),
    TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefoonnummer'), onChanged: (_) => setState(() {})),
  ]);

  Widget _ideaStep() => Column(children: [
    TextField(controller: idea, maxLines: 5, decoration: const InputDecoration(labelText: 'Beschrijf je tattoo-idee'), onChanged: (_) => setState(() {})),
    const SizedBox(height: 10),
    TextField(controller: placement, decoration: const InputDecoration(labelText: 'Plaats op het lichaam'), onChanged: (_) => setState(() {})),
    const SizedBox(height: 10),
    const Text('Foto-upload kan in de backend-versie worden toegevoegd; de interface is hier bewust voorbereid op een intakeflow.', style: TextStyle(color: AppColors.muted)),
  ]);

  Widget _consentStep() => Column(children: [
    CheckboxListTile(value: consent, onChanged: (v) => setState(() => consent = v ?? false), title: const Text('Ik vul vóór de afspraak de gezondheidsverklaring naar waarheid in.')),
    CheckboxListTile(value: conditions, onChanged: (v) => setState(() => conditions = v ?? false), title: const Text('Ik ga akkoord met de afspraak- en annuleringsvoorwaarden.')),
  ]);

  Widget _summaryStep() => Card(child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(service?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Text('${date == null ? '' : DateFormat('dd-MM-yyyy').format(date!)} ${time?.format(context) ?? ''}'),
      const SizedBox(height: 8),
      Text('${name.text}\n${email.text}\n${phone.text}'),
      const Divider(height: 28),
      Text('Idee: ${idea.text}'),
      Text('Plaats: ${placement.text}'),
      if ((service?.deposit ?? 0) > 0) ...[
        const SizedBox(height: 12),
        Text('Aanbetaling: €${service!.deposit.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.goldSoft, fontWeight: FontWeight.w700)),
      ]
    ]),
  ));

  void _finish() {
    final startsAt = DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);
    widget.store.addAppointment(Appointment(
      id: 'a-${DateTime.now().millisecondsSinceEpoch}',
      customerName: name.text.trim(),
      email: email.text.trim(),
      phone: phone.text.trim(),
      service: service!,
      startsAt: startsAt,
      idea: idea.text.trim(),
      placement: placement.text.trim(),
      consentComplete: consent,
      depositPaid: false,
    ));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aanvraag ontvangen'),
        content: const Text('De afspraak staat nu in de app als aanvraag. Robert kan deze vanuit het beheergedeelte beoordelen en bevestigen.'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Klaar'))],
      ),
    );
  }
}
