class RJProfile {
  final String? userId;
  final String stageName;
  final String? avatarUrl;
  final String? bio;
  final String? specialty;

  RJProfile({
    this.userId,
    required this.stageName,
    this.avatarUrl,
    this.bio,
    this.specialty,
  });

  factory RJProfile.fromJson(Map<String, dynamic> json) {
    return RJProfile(
      userId: json['user_id']?.toString() ?? json['id']?.toString(),
      stageName: json['stage_name']?.toString() ?? json['rj_stage_name']?.toString() ?? 'RJ',
      avatarUrl: json['avatar_url']?.toString() ?? json['rj_avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      specialty: json['specialty']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'stage_name': stageName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'specialty': specialty,
    };
  }
}
