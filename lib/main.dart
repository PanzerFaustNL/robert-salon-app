import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/app_theme.dart';
import 'screens/app_shell.dart';
import 'services/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SupabaseClient? database;
  // if (SupabaseConfig.isConfigured) {
  //   await Supabase.initialize(
  //     url: SupabaseConfig.url,
  //     publishableKey: SupabaseConfig.publishableKey,
  //   );
  //   database = Supabase.instance.client;
  // }

  await Supabase.initialize(
    url: 'https://zyvjpejazhxtpazprixh.supabase.co',
    publishableKey: 'sb_publishable_-amRhajxjn1XdeH-DkvG5w_Xce-1Xdy',
  );

  final database = Supabase.instance.client;

  runApp(RobertSalonApp(database: database));
}

class RobertSalonApp extends StatefulWidget {
  final SupabaseClient? database;

  const RobertSalonApp({super.key, required this.database});

  @override
  State<RobertSalonApp> createState() => _RobertSalonAppState();
}

class _RobertSalonAppState extends State<RobertSalonApp> {
  late final AppStore store;

  @override
  void initState() {
    super.initState();
    store = AppStore(database: widget.database);
    store.initialize();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

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
