class Station {
  final String id;
  final String name;
  final String? brand;
  final String address;
  final String? county;
  final String? phone;
  final String? brandLogoUrl;
  final double latitude;
  final double longitude;
  final double? petrolPrice;
  final DateTime? petrolUpdatedAt;
  final double? dieselPrice;
  final DateTime? dieselUpdatedAt;

  const Station({
    required this.id,
    required this.name,
    this.brand,
    required this.address,
    this.county,
    this.phone,
    this.brandLogoUrl,
    required this.latitude,
    required this.longitude,
    this.petrolPrice,
    this.petrolUpdatedAt,
    this.dieselPrice,
    this.dieselUpdatedAt,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      address: json['address'] as String,
      county: json['county'] as String?,
      phone: json['phone'] as String?,
      brandLogoUrl: json['brand_logo_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      petrolPrice: json['petrol_price'] != null
          ? (json['petrol_price'] as num).toDouble()
          : null,
      petrolUpdatedAt: json['petrol_updated_at'] != null
          ? DateTime.parse(json['petrol_updated_at'] as String)
          : null,
      dieselPrice: json['diesel_price'] != null
          ? (json['diesel_price'] as num).toDouble()
          : null,
      dieselUpdatedAt: json['diesel_updated_at'] != null
          ? DateTime.parse(json['diesel_updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'address': address,
        'county': county,
        'phone': phone,
        'brand_logo_url': brandLogoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'petrol_price': petrolPrice,
        'petrol_updated_at': petrolUpdatedAt?.toIso8601String(),
        'diesel_price': dieselPrice,
        'diesel_updated_at': dieselUpdatedAt?.toIso8601String(),
      };

  /// Return a copy with updated prices.
  Station copyWith({
    double? petrolPrice,
    DateTime? petrolUpdatedAt,
    double? dieselPrice,
    DateTime? dieselUpdatedAt,
  }) {
    return Station(
      id: id,
      name: name,
      brand: brand,
      address: address,
      county: county,
      phone: phone,
      brandLogoUrl: brandLogoUrl,
      latitude: latitude,
      longitude: longitude,
      petrolPrice: petrolPrice ?? this.petrolPrice,
      petrolUpdatedAt: petrolUpdatedAt ?? this.petrolUpdatedAt,
      dieselPrice: dieselPrice ?? this.dieselPrice,
      dieselUpdatedAt: dieselUpdatedAt ?? this.dieselUpdatedAt,
    );
  }
}
