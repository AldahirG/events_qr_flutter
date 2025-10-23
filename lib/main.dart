import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/event.dart';
import 'app_router.dart';

Future<void> main() async {
  // 🧩 Asegura que Flutter esté inicializado antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 Cargar variables de entorno (.env)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env cargado: BASE_URL=${dotenv.env['BASE_URL']}');
  } catch (e, st) {
    debugPrint('❌ Error al cargar .env: $e');
    debugPrintStack(stackTrace: st);
  }

  // 🕓 Inicializar localización (importante para fechas)
  await initializeDateFormatting('es', null);

  // 🐝 Inicializar Hive y abrir cajas
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(EventAdapter());
  }
  await Hive.openBox<Event>('events');
  await Hive.openBox('settings');

  // 🚀 Ejecutar la app con Riverpod
  runApp(const ProviderScope(child: HalloweenFestApp()));
}

class HalloweenFestApp extends StatelessWidget {
  const HalloweenFestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Halloween Fest 🎃',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF12101C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1B2D),
          titleTextStyle: TextStyle(
            color: Color(0xFFFF6B00),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: Colors.orangeAccent),
          centerTitle: true,
          elevation: 2,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E1B2D),
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }
}
