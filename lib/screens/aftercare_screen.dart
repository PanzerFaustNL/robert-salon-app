import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/section_title.dart';

class AftercareScreen extends StatelessWidget {
  const AftercareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('De eerste uren', 'Volg Roberts instructie voor folie of beschermfolie. Raak de tattoo alleen aan met schone handen.'),
      ('Reinigen', 'Was voorzichtig met lauw water en een milde, ongeparfumeerde zeep. Niet schrobben.'),
      ('Drogen', 'Dep de huid voorzichtig droog met schoon keukenpapier of laat aan de lucht drogen.'),
      ('Verzorgen', 'Gebruik alleen een dun laagje van het geadviseerde verzorgingsproduct.'),
      ('Niet krabben', 'Velletjes en korstjes niet lostrekken. Laat de huid zelf herstellen.'),
      ('Zon & water', 'Vermijd zwemmen, sauna en langdurig weken tijdens de genezing. Bescherm genezen tattoos tegen zon.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Nazorg')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
        const SectionTitle(eyebrow: 'Na je afspraak', title: 'Goede nazorg maakt verschil', subtitle: 'Algemene richtlijnen. De persoonlijke instructie van de studio gaat altijd voor.'),
        const SizedBox(height: 20),
        ...steps.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(backgroundColor: const Color(0xFF2A241A), foregroundColor: AppColors.goldSoft, child: Text('${e.key + 1}')),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 5),
                Text(e.value.$2, style: const TextStyle(color: AppColors.muted, height: 1.4)),
              ])),
            ]),
          )),
        )),
        const SizedBox(height: 10),
        const Text('Bij twijfel over genezing, roodheid, zwelling of andere klachten: neem contact op met de studio en zo nodig met een arts.', style: TextStyle(color: AppColors.muted)),
      ]),
    );
  }
}
