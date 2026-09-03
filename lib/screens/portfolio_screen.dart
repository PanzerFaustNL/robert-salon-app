import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/section_title.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['Black & Grey', 'Color Realism', 'Fine Art', 'Custom Work', 'Olieverf', 'Mixed Media'];
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
        const SectionTitle(eyebrow: 'Werk', title: 'Portfolio', subtitle: 'Hier kunnen later automatisch de nieuwste werken van de WordPress-galerijen verschijnen.'),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: labels.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .82),
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF342F26)),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D1D1F + (i * 0x010101)), const Color(0xFF0B0B0C)]),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.image_outlined, color: AppColors.gold),
              const SizedBox(height: 10),
              Text(labels[i], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
          ),
        )
      ]),
    );
  }
}
