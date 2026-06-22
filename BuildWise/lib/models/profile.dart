class Profile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String? description;
  final String challengeType;
  final Map<String, dynamic>? constraints;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    this.description,
    required this.challengeType,
    this.constraints,
    this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      challengeType: json['challenge_type'],
      constraints: json['constraints'] != null
          ? Map<String, dynamic>.from(json['constraints'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PriceAlert {
  final String id;
  final String userId;
  final String componentId;
  final double targetPrice;
  final bool isActive;
  final DateTime createdAt;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.componentId,
    required this.targetPrice,
    this.isActive = true,
    required this.createdAt,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      userId: json['user_id'],
      componentId: json['component_id'],
      targetPrice: double.tryParse(json['target_price'].toString()) ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
