import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_store.dart';
import '../../services/external_links.dart';
import 'admin_agenda_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_forms_screen.dart';
import 'admin_payments_screen.dart';

enum DashboardPeriod { today, week, month, year, custom }

class AdminDashboardScreen extends StatefulWidget {
  final AppStore store;
  const AdminDashboardScreen({super.key, required this.store});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardPeriod period = DashboardPeriod.month;
  DateTimeRange? customRange;

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

  DateTime get rangeStart {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case DashboardPeriod.today:
        return today;
      case DashboardPeriod.week:
        return today.subtract(Duration(days: today.weekday - 1));
      case DashboardPeriod.month:
        return DateTime(now.year, now.month, 1);
      case DashboardPeriod.year:
        return DateTime(now.year, 1, 1);
      case DashboardPeriod.custom:
        return customRange?.start ?? DateTime(now.year, now.month, 1);
    }
  }

  DateTime get rangeEndExclusive {
    final now = DateTime.now();

    switch (period) {
      case DashboardPeriod.today:
        return rangeStart.add(const Duration(days: 1));
      case DashboardPeriod.week:
        return rangeStart.add(const Duration(days: 7));
      case DashboardPeriod.month:
        return DateTime(now.year, now.month + 1, 1);
      case DashboardPeriod.year:
        return DateTime(now.year + 1, 1, 1);
      case DashboardPeriod.custom:
        final end = customRange?.end ?? DateTime(now.year, now.month + 1, 1);
        return DateTime(end.year, end.month, end.day)
            .add(const Duration(days: 1));
    }
  }

  bool _inRange(DateTime value) {
    return !value.isBefore(rangeStart) && value.isBefore(rangeEndExclusive);
  }

  List<Appointment> get periodAppointments => widget.store.appointments
      .where((a) => _inRange(a.startsAt))
      .toList();

  List<Payment> get periodPayments => widget.store.payments
      .where(
        (p) =>
            p.status == 'paid' &&
            p.paidAt != null &&
            _inRange(p.paidAt!),
      )
      .toList();

  double get revenue =>
      periodPayments.fold(0.0, (sum, payment) => sum + payment.amount);

  double get expectedRevenue => periodAppointments
      .where(
        (a) =>
            a.status != 'cancelled' &&
            a.status != 'no_show' &&
            a.service.priceFrom != null,
      )
      .fold(0.0, (sum, a) => sum + (a.service.priceFrom ?? 0));

  int get completedVisits => periodAppointments
      .where((a) => a.status == 'completed')
      .length;

  double get averagePerVisit =>
      completedVisits == 0 ? 0 : revenue / completedVisits;

  List<Appointment> get upcoming {
    final list = widget.store.appointments
        .where(
          (a) =>
              a.startsAt.isAfter(DateTime.now()) &&
              a.status != 'cancelled',
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 3),
      initialDateRange: customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );

    if (picked != null) {
      setState(() {
        customRange = picked;
        period = DashboardPeriod.custom;
      });
    }
  }

  String get rangeLabel {
    final end = rangeEndExclusive.subtract(const Duration(days: 1));
    if (period == DashboardPeriod.today) {
      return DateFormat('dd-MM-yyyy').format(rangeStart);
    }
    return '${DateFormat('dd-MM-yyyy').format(rangeStart)} t/m ${DateFormat('dd-MM-yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayAppointments = widget.store.appointments
        .where(
          (a) =>
              !a.startsAt.isBefore(todayStart) &&
              a.startsAt.isBefore(todayEnd) &&
              a.status != 'cancelled',
        )
        .length;

    final pending = widget.store.appointments
        .where((a) => a.status == 'requested')
        .length;

    final unpaid = widget.store.appointments
        .where(
          (a) =>
              a.service.deposit > 0 &&
              !a.depositPaid &&
              a.status != 'cancelled',
        )
        .length;

    final missingForms = upcoming.where((a) => !a.consentReceived).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robert • Beheer'),
        actions: [
          IconButton(
            tooltip: 'Vernieuwen',
            onPressed: widget.store.adminLoading
                ? null
                : () => widget.store.loadAdminData(),
            icon: widget.store.adminLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.store.loadAdminData(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
          children: [
            const Text(
              'STUDIO OVERZICHT',
              style: TextStyle(
                color: AppColors.gold,
                letterSpacing: 2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Goedendag Robert',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.store.ownerEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.store.ownerEmail!,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 18),
            _quickStats(
              todayAppointments: todayAppointments,
              pending: pending,
              unpaid: unpaid,
              missingForms: missingForms,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultaten',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: const Text('Periode'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _periodSelector(),
            const SizedBox(height: 8),
            Text(
              rangeLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    'Ontvangen omzet',
                    '€${revenue.toStringAsFixed(0)}',
                    Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stat(
                    'Verwacht vanaf',
                    '€${expectedRevenue.toStringAsFixed(0)}',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    'Afspraken',
                    '${periodAppointments.length}',
                    Icons.event_available_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stat(
                    'Gem. per bezoek',
                    '€${averagePerVisit.toStringAsFixed(0)}',
                    Icons.analytics_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _MonthlyRevenueChart(payments: widget.store.payments),
            const SizedBox(height: 28),
            const Text(
              'Beheer',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _menu(
              Icons.calendar_month,
              'Agenda',
              'Dag-, week- en maandoverzicht van afspraken',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAgendaScreen(store: widget.store),
                ),
              ),
            ),
            _menu(
              Icons.people_alt_outlined,
              'Klanten',
              'Zoeken, historie, notities en foto’s per klant',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminCustomersScreen(store: widget.store),
                ),
              ),
            ),
            _menu(
              Icons.assignment_outlined,
              'Intakes & formulieren',
              'Controleer of toestemmingsformulieren binnen zijn',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminFormsScreen(store: widget.store),
                ),
              ),
            ),
            _menu(
              Icons.payments_outlined,
              'Betalingen',
              'Aanbetalingen, historie en omzetregistratie',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminPaymentsScreen(store: widget.store),
                ),
              ),
            ),
            _menu(
              Icons.collections_outlined,
              'Portfolio op WordPress',
              'Open de website om galerijen te beheren',
              () => ExternalLinks.openWebsite(
                'https://www.robertveldmantattoo.nl/',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Eerstvolgende',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              const Text(
                'Geen komende afspraken.',
                style: TextStyle(color: AppColors.muted),
              ),
            ...upcoming.take(4).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.gold,
                        ),
                        title: Text(a.customerName),
                        subtitle: Text(
                          '${DateFormat('dd-MM • HH:mm').format(a.startsAt)} • ${a.service.name}',
                        ),
                        trailing: Text(
                          a.statusLabel,
                          style: const TextStyle(
                            color: AppColors.goldSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            if (widget.store.adminError != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.store.adminError!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickStats({
    required int todayAppointments,
    required int pending,
    required int unpaid,
    required int missingForms,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Vandaag',
                      '$todayAppointments',
                      Icons.today_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      'Nieuwe aanvragen',
                      '$pending',
                      Icons.inbox_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Open betaling',
                      '$unpaid',
                      Icons.euro_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      'Formulier mist',
                      '$missingForms',
                      Icons.assignment_late_outlined,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _stat(
                'Vandaag',
                '$todayAppointments',
                Icons.today_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'Nieuwe aanvragen',
                '$pending',
                Icons.inbox_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'Open betaling',
                '$unpaid',
                Icons.euro_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'Formulier mist',
                '$missingForms',
                Icons.assignment_late_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _periodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _periodChip(DashboardPeriod.today, 'Vandaag'),
        _periodChip(DashboardPeriod.week, 'Week'),
        _periodChip(DashboardPeriod.month, 'Maand'),
        _periodChip(DashboardPeriod.year, 'Jaar'),
        if (period == DashboardPeriod.custom)
          const Chip(
            avatar: Icon(Icons.date_range, size: 18),
            label: Text('Aangepast'),
          ),
      ],
    );
  }

  Widget _periodChip(DashboardPeriod value, String label) {
    return ChoiceChip(
      selected: period == value,
      label: Text(label),
      onSelected: (_) => setState(() => period = value),
    );
  }

  Widget _stat(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.gold),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _MonthlyRevenueChart extends StatelessWidget {
  final List<Payment> payments;

  const _MonthlyRevenueChart({required this.payments});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final offset = 5 - index;
      return DateTime(now.year, now.month - offset, 1);
    });

    final values = months.map((month) {
      final next = DateTime(month.year, month.month + 1, 1);
      return payments
          .where(
            (p) =>
                p.status == 'paid' &&
                p.paidAt != null &&
                !p.paidAt!.isBefore(month) &&
                p.paidAt!.isBefore(next),
          )
          .fold<double>(0, (sum, p) => sum + p.amount);
    }).toList();

    final maxValue = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Omzet laatste 6 maanden',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(months.length, (index) {
                  final value = values[index];
                  final height = maxValue <= 0
                      ? 4.0
                      : (110 * (value / maxValue).clamp(.04, 1.0)).toDouble();

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            value <= 0
                                ? ''
                                : '€${value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMM').format(months[index]),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
