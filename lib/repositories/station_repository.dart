import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';
import '../services/supabase_service.dart';

class StationRepository {
  final SupabaseService _supabaseService;
  static const _cacheKey = 'cached_stations';

  StationRepository(this._supabaseService);

  /// Fetch stations from Supabase within the given bounds.
  /// Caches the result locally for offline use.
  Future<List<Station>> getStationsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final stations = await _supabaseService.getStationsInBounds(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      );
      await _cacheStations(stations);
      return stations;
    } catch (e) {
      // On failure, try serving from cache
      final cached = await getCachedStations();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Load stations from local cache.
  Future<List<Station>> getCachedStations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) return [];

    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((json) => Station.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Persist stations to local cache.
  Future<void> _cacheStations(List<Station> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(stations.map((s) => s.toJson()).toList());
    await prefs.setString(_cacheKey, jsonString);
  }

  /// Clear the cache (used from settings).
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
