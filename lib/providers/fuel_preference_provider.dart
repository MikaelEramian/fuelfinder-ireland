import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

final fuelPreferenceProvider =
    NotifierProvider<FuelPreferenceNotifier, FuelType>(
  FuelPreferenceNotifier.new,
);

class FuelPreferenceNotifier extends Notifier<FuelType> {
  static const _key = 'fuel_preference';

  @override
  FuelType build() {
    _load();
    return FuelType.both;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = FuelType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => FuelType.both,
      );
    }
  }

  Future<void> setFuelType(FuelType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, type.name);
  }

  /// Returns true if the user has previously selected a preference.
  static Future<bool> hasSelection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}
