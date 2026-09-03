import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;

  const SectionTitle({super.key, required this.eyebrow, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: const TextStyle(color: AppColors.gold, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 30, height: 1.05, fontWeight: FontWeight.w700, color: AppColors.text)),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(subtitle!, style: const TextStyle(color: AppColors.muted, height: 1.45)),
        ]
      ],
    );
  }
}
