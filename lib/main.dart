import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';


import 'models/event.dart';
import 'app_router.dart';

Future<void> main() async {
  // 1️⃣ Asegura que Flutter esté inicializado antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ Cargar .env de forma segura
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env cargado. BASE_URL=${dotenv.env['BASE_URL']}');
  } catch (e, st) {
    debugPrint('❌ Error al cargar .env: $e');
    debugPrintStack(stackTrace: st);
  }

  // Inicializar localización
  await initializeDateFormatting('es', null); // 👈 importante
  // 3️⃣ Inicializar Hive y abrir cajas
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(EventAdapter());
  }
  await Hive.openBox<Event>('events');
  await Hive.openBox('settings');

  // 4️⃣ Ejecutar la app
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QrApp Flutter',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
    );
  }
}
