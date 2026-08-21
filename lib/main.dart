import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/route_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RouteRepository.instance.init();
  runApp(const RoutePerformanceTrackerApp());
}

class RoutePerformanceTrackerApp extends StatelessWidget {
  const RoutePerformanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Route Performance Tracker',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: HomeScreen(repository: RouteRepository.instance),
    );
  }
}
