// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/event.dart';
import 'app_router.dart';
import 'core/app_theme.dart';
import 'providers/app_event_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env cargado: BASE_URL=${dotenv.env['BASE_URL']}');
  } catch (e, st) {
    debugPrint('❌ Error al cargar .env: $e');
    debugPrintStack(stackTrace: st);
  }

  await initializeDateFormatting('es', null);

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(EventAdapter());
  }
  await Hive.openBox<Event>('events');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: CheckQrApp()));
}

class CheckQrApp extends ConsumerWidget {
  const CheckQrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final event = ref.watch(appEventProvider);

    return MaterialApp.router(
      title: 'CheckQR UNINTER',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: event == AppEvent.halloween ? buildHalloweenTheme() : buildAppTheme(),
    );
  }
}
