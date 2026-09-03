import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/app_store.dart';
import '../widgets/section_title.dart';
import 'booking_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppStore store;
  final VoidCallback onAppointments;
  const HomeScreen({super.key, required this.store, required this.onAppointments});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            const Expanded(child: Text('ROBERT VELDMAN\nTATTOO & ART', style: TextStyle(letterSpacing: 2.2, fontSize: 15, fontWeight: FontWeight.w800))),
            Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: AppColors.gold), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 18)),
          ],
        ),
        const SizedBox(height: 26),
        Container(
          height: 340,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF3A3326)),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A241C), Color(0xFF0D0D0E)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('TATTOO • FINE ART • CUSTOM', style: TextStyle(color: AppColors.goldSoft, letterSpacing: 1.6, fontSize: 11)),
              const SizedBox(height: 10),
              const Text('Jouw verhaal.\nVertaald naar inkt.', style: TextStyle(fontSize: 36, height: 1.05, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              const Text('Persoonlijk ontwerp, aandacht voor detail en een rustige studio-ervaring.', style: TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(store: store))),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Afspraak / intake aanvragen'),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 34),
        const SectionTitle(eyebrow: 'De studio', title: 'Van eerste idee tot nazorg', subtitle: 'Alles rondom je afspraak op één plek.'),
        const SizedBox(height: 18),
        ...[
          ('01', 'Intake', 'Vertel je idee, stijl, plek en formaat.'),
          ('02', 'Afspraak', 'Kies een passende datum en tijd.'),
          ('03', 'Toestemming', 'Vul je gezondheidsverklaring digitaal in.'),
          ('04', 'Nazorg', 'Ontvang duidelijke verzorgingsinstructies.'),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Text(item.$1, style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.$3, style: const TextStyle(color: AppColors.muted)),
              ]))
            ]),
          )),
        )),
        const SizedBox(height: 22),
        OutlinedButton(onPressed: onAppointments, child: const Text('Bekijk mijn afspraken')),
      ],
    );
  }
}
