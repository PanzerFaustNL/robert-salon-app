import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'services/app_store.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RobertSalonApp());
}

class RobertSalonApp extends StatefulWidget {
  const RobertSalonApp({super.key});

  @override
  State<RobertSalonApp> createState() => _RobertSalonAppState();
}

class _RobertSalonAppState extends State<RobertSalonApp> {
  final AppStore store = AppStore.seeded();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robert Veldman Tattoo & Art',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AppShell(store: store),
    );
  }
}
