class Price {
  final String id;
  final String stationId;
  final String fuelType;
  final double price;
  final int confidence;
  final String? reportedBy;
  final DateTime reportedAt;
  final double? reportedLocationLat;
  final double? reportedLocationLng;

  const Price({
    required this.id,
    required this.stationId,
    required this.fuelType,
    required this.price,
    this.confidence = 1,
    this.reportedBy,
    required this.reportedAt,
    this.reportedLocationLat,
    this.reportedLocationLng,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      id: json['id'] as String,
      stationId: json['station_id'] as String,
      fuelType: json['fuel_type'] as String,
      price: (json['price'] as num).toDouble(),
      confidence: json['confidence'] as int? ?? 1,
      reportedBy: json['reported_by'] as String?,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      reportedLocationLat: json['reported_location_lat'] != null
          ? (json['reported_location_lat'] as num).toDouble()
          : null,
      reportedLocationLng: json['reported_location_lng'] != null
          ? (json['reported_location_lng'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'station_id': stationId,
        'fuel_type': fuelType,
        'price': price,
        'confidence': confidence,
        'reported_by': reportedBy,
        'reported_at': reportedAt.toIso8601String(),
        'reported_location_lat': reportedLocationLat,
        'reported_location_lng': reportedLocationLng,
      };
}
