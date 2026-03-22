class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
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
      preferredLanguage: (map['preferred_language'] as String?) ?? 'es',
      preferredUnits: (map['preferred_units'] as String?) ?? 'metric',
      subscriptionStatus: (map['subscription_status'] as String?) ?? 'trial',
      onboardingCompleted: (map['onboarding_completed'] as bool?) ?? false,
      onboardingCompletedAt: parseDate(map['onboarding_completed_at']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}
