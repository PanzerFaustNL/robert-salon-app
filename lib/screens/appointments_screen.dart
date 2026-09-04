import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../services/app_store.dart';
import '../services/external_links.dart';
import 'booking_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final AppStore store;
  const AppointmentsScreen({super.key, required this.store});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final list = [...widget.store.appointments]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Mijn afspraken')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(store: widget.store),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nieuwe afspraak'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final a = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24201A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd').format(a.startsAt),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldSoft,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(a.startsAt).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.service.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${DateFormat('HH:mm').format(a.startsAt)} • ${a.statusLabel}',
                            style: const TextStyle(color: AppColors.gold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.idea,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _openConsentForm,
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Toestemmingsformulier'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
