import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'providers/fuel_preference_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/fuel_selector_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final hasSelectedFuel = await FuelPreferenceNotifier.hasSelection();

  runApp(
    ProviderScope(
      child: FuelFinderApp(showFuelSelector: !hasSelectedFuel),
    ),
  );
}

class FuelFinderApp extends ConsumerWidget {
  final bool showFuelSelector;

  const FuelFinderApp({super.key, required this.showFuelSelector});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final flutterThemeMode = switch (themeMode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'FuelFinder Ireland',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      initialRoute: showFuelSelector ? '/fuel-select' : '/home',
      routes: {
        '/fuel-select': (_) => const FuelSelectorScreen(),
        '/home': (_) => const AppShell(),
      },
    );
  }
}
