import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_store.dart';
import 'admin_appointment_detail_screen.dart';

enum AgendaViewMode { day, week, month }

class AdminAgendaScreen extends StatefulWidget {
  final AppStore store;
  const AdminAgendaScreen({super.key, required this.store});

  @override
  State<AdminAgendaScreen> createState() => _AdminAgendaScreenState();
}

class _AdminAgendaScreenState extends State<AdminAgendaScreen> {
  AgendaViewMode mode = AgendaViewMode.week;
  DateTime anchor = DateTime.now();

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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime get start {
    final d = _dateOnly(anchor);
    switch (mode) {
      case AgendaViewMode.day:
        return d;
      case AgendaViewMode.week:
        return d.subtract(Duration(days: d.weekday - 1));
      case AgendaViewMode.month:
        return DateTime(d.year, d.month, 1);
    }
  }

  DateTime get endExclusive {
    switch (mode) {
      case AgendaViewMode.day:
        return start.add(const Duration(days: 1));
      case AgendaViewMode.week:
        return start.add(const Duration(days: 7));
      case AgendaViewMode.month:
        return DateTime(start.year, start.month + 1, 1);
    }
  }

  List<Appointment> get filtered {
    final items = widget.store.appointments
        .where(
          (a) =>
              !a.startsAt.isBefore(start) &&
              a.startsAt.isBefore(endExclusive),
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return items;
  }

  void _move(int direction) {
    setState(() {
      switch (mode) {
        case AgendaViewMode.day:
          anchor = anchor.add(Duration(days: direction));
          break;
        case AgendaViewMode.week:
          anchor = anchor.add(Duration(days: 7 * direction));
          break;
        case AgendaViewMode.month:
          anchor = DateTime(anchor.year, anchor.month + direction, 1);
          break;
      }
    });
  }

  String get rangeLabel {
    if (mode == AgendaViewMode.day) {
      return DateFormat('dd-MM-yyyy').format(start);
    }
    if (mode == AgendaViewMode.week) {
      final last = endExclusive.subtract(const Duration(days: 1));
      return '${DateFormat('dd-MM').format(start)} t/m ${DateFormat('dd-MM-yyyy').format(last)}';
    }
    return DateFormat('MMMM yyyy').format(start);
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            tooltip: 'Vandaag',
            onPressed: () => setState(() => anchor = DateTime.now()),
            icon: const Icon(Icons.today),
          ),
          IconButton(
            tooltip: 'Vernieuwen',
            onPressed: widget.store.adminLoading
                ? null
                : () => widget.store.loadAdminData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Column(
              children: [
                SegmentedButton<AgendaViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: AgendaViewMode.day,
                      label: Text('Dag'),
                      icon: Icon(Icons.view_day_outlined),
                    ),
                    ButtonSegment(
                      value: AgendaViewMode.week,
                      label: Text('Week'),
                      icon: Icon(Icons.view_week_outlined),
                    ),
                    ButtonSegment(
                      value: AgendaViewMode.month,
                      label: Text('Maand'),
                      icon: Icon(Icons.calendar_month_outlined),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (value) {
                    setState(() => mode = value.first);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldSoft,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'Geen afspraken in deze periode.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminAppointmentDetailScreen(
                                    store: widget.store,
                                    appointmentId: a.id,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateFormat(
                                            'dd-MM-yyyy • HH:mm',
                                          ).format(a.startsAt),
                                          style: const TextStyle(
                                            color: AppColors.goldSoft,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Chip(label: Text(a.statusLabel)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a.customerName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    a.service.name,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _miniStatus(
                                        a.consentReceived,
                                        'Formulier',
                                      ),
                                      const SizedBox(width: 8),
                                      _miniStatus(
                                        a.depositPaid ||
                                            a.service.deposit <= 0,
                                        'Aanbetaling',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatus(bool ok, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.pending_outlined,
            size: 17,
            color: ok ? AppColors.gold : AppColors.muted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
