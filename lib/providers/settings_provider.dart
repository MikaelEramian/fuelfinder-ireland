import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    _load();
    return AppThemeMode.dark;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppThemeMode.dark,
      );
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final distanceUnitProvider =
    NotifierProvider<DistanceUnitNotifier, DistanceUnit>(
  DistanceUnitNotifier.new,
);

class DistanceUnitNotifier extends Notifier<DistanceUnit> {
  static const _key = 'distance_unit';

  @override
  DistanceUnit build() {
    _load();
    return DistanceUnit.km;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = DistanceUnit.values.firstWhere(
        (e) => e.name == value,
        orElse: () => DistanceUnit.km,
      );
    }
  }

  Future<void> setUnit(DistanceUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, unit.name);
  }
}

final defaultZoomProvider =
    NotifierProvider<DefaultZoomNotifier, double>(
  DefaultZoomNotifier.new,
);

class DefaultZoomNotifier extends Notifier<double> {
  static const _key = 'default_zoom';

  @override
  double build() {
    _load();
    return kDefaultMapZoom;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_key);
    if (value != null) state = value;
  }

  Future<void> setZoom(double zoom) async {
    state = zoom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, zoom);
  }
}
