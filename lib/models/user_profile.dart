class UserProfile {
  final String id;
  final String? displayName;
  final bool isPremium;
  final DateTime? premiumUntil;
  final double totalSaved;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.isPremium = false,
    this.premiumUntil,
    this.totalSaved = 0,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      premiumUntil: json['premium_until'] != null
          ? DateTime.parse(json['premium_until'] as String)
          : null,
      totalSaved: (json['total_saved'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'is_premium': isPremium,
        'premium_until': premiumUntil?.toIso8601String(),
        'total_saved': totalSaved,
        'created_at': createdAt.toIso8601String(),
      };
}
