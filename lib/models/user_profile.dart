class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? location;

  /// Coordenadas de la parcela. O están las dos o no está ninguna: media
  /// ubicación no es una ubicación, y la base de datos lo obliga con
  /// `profiles_location_pair_check`.
  final double? locationLat;
  final double? locationLng;

  /// gps | map | search | onboarding. Se guarda aparte del valor porque un
  /// punto arrastrado a mano y uno leído del GPS no merecen la misma confianza
  /// cuando hay que auditar por qué se recomendó regar.
  final String? locationSource;
  final DateTime? locationUpdatedAt;

  final String preferredLanguage;
  final String preferredUnits;
  final String subscriptionStatus;
  final bool onboardingCompleted;
  final DateTime? onboardingCompletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.location,
    this.locationLat,
    this.locationLng,
    this.locationSource,
    this.locationUpdatedAt,
    required this.preferredLanguage,
    required this.preferredUnits,
    required this.subscriptionStatus,
    required this.onboardingCompleted,
    required this.onboardingCompletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      location: map['location'] as String?,
      locationLat: (map['location_lat'] as num?)?.toDouble(),
      locationLng: (map['location_lng'] as num?)?.toDouble(),
      locationSource: map['location_source'] as String?,
      locationUpdatedAt: parseDate(map['location_updated_at']),
      preferredLanguage: (map['preferred_language'] as String?) ?? 'es',
      preferredUnits: (map['preferred_units'] as String?) ?? 'metric',
      subscriptionStatus: (map['subscription_status'] as String?) ?? 'trial',
      onboardingCompleted: (map['onboarding_completed'] as bool?) ?? false,
      onboardingCompletedAt: parseDate(map['onboarding_completed_at']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? location,
    double? locationLat,
    double? locationLng,
    String? locationSource,
    DateTime? locationUpdatedAt,
    String? preferredLanguage,
    String? preferredUnits,
    String? subscriptionStatus,
    bool? onboardingCompleted,
    DateTime? onboardingCompletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationSource: locationSource ?? this.locationSource,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
