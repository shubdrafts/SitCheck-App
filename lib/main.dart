import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/controllers/restaurant_controller.dart';
import 'src/config/supabase_config.dart';
import 'src/core/session/session_controller.dart';
import 'src/services/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await LocalDatabase.instance.init();
  } catch (e) {
    // Continue with mock data fallback if local database is unavailable
    debugPrint('Skipping local database: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()),
        ChangeNotifierProvider(create: (_) => RestaurantController()),
      ],
      child: const SitCheckApp(),
    ),
  );
}