import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/event.dart';
import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Cargar .env
  try {
  await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 5));
  debugPrint('✅ .env cargado. BASE_URL=${dotenv.env['BASE_URL']}');

  } catch (e, st) {
    debugPrint('No se pudo cargar .env (continuando sin él): $e');
    debugPrintStack(stackTrace: st);
  }

  // 2️⃣ Inicializar Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(EventAdapter());
  }

  // 3️⃣ Abrir boxes
  try {
    await Hive.openBox<Event>('events');
    await Hive.openBox('settings');
  } catch (e, st) {
    debugPrint('Error abriendo boxes de Hive: $e');
    debugPrintStack(stackTrace: st);
  }

  // 4️⃣ Ejecutar app en zona segura
  runZonedGuarded(
    () => runApp(const ProviderScope(child: MyApp())),
    (error, stack) {
      debugPrint('Error no capturado en la app: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
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
