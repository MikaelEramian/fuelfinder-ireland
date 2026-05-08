import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/station.dart';
import '../utils/helpers.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  /// Fetch stations within map bounds via RPC, with retry.
  Future<List<Station>> getStationsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    return withRetry(() async {
      final response = await client.rpc('get_stations_in_bounds', params: {
        'min_lat': minLat,
        'max_lat': maxLat,
        'min_lng': minLng,
        'max_lng': maxLng,
      });
      final data = response as List<dynamic>;
      return data
          .map((json) => Station.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Insert a reported price.
  Future<Map<String, dynamic>> reportPrice({
    required String stationId,
    required String fuelType,
    required double price,
    double? locationLat,
    double? locationLng,
  }) async {
    return withRetry(() async {
      final response = await client.from('prices').insert({
        'station_id': stationId,
        'fuel_type': fuelType,
        'price': price,
        'reported_location_lat': locationLat,
        'reported_location_lng': locationLng,
      }).select().single();
      return response;
    });
  }

  /// Get the 60-day national average for petrol and diesel.
  Future<Map<String, double>> getNationalAverage() async {
    return withRetry(() async {
      final response = await client.rpc('get_national_average');
      final data = response as Map<String, dynamic>;
      return {
        'petrol': (data['petrol'] as num).toDouble(),
        'diesel': (data['diesel'] as num).toDouble(),
      };
    });
  }
}
