import '../services/supabase_service.dart';
import '../models/price.dart';

class PriceRepository {
  final SupabaseService _supabaseService;

  PriceRepository(this._supabaseService);

  /// Report a new price for a station. Returns the inserted Price.
  Future<Price> reportPrice({
    required String stationId,
    required String fuelType,
    required double price,
    double? locationLat,
    double? locationLng,
  }) async {
    final response = await _supabaseService.reportPrice(
      stationId: stationId,
      fuelType: fuelType,
      price: price,
      locationLat: locationLat,
      locationLng: locationLng,
    );
    return Price.fromJson(response);
  }
}
