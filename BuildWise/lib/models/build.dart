class Build {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String buildType;
  final Map<String, dynamic> components;
  final double totalPrice;
  final bool isPublic;
  final int likesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Build({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    required this.buildType,
    required this.components,
    required this.totalPrice,
    this.isPublic = false,
    this.likesCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Build.fromJson(Map<String, dynamic> json) {
    return Build(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      buildType: json['build_type'] ?? 'custom',
      components: Map<String, dynamic>.from(json['components']),
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      isPublic: json['is_public'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'build_type': buildType,
    'components': components,
    'total_price': totalPrice,
    'is_public': isPublic,
    'likes_count': likesCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class BuildType {
  static const String gaming = 'gaming';
  static const String workstation = 'workstation';
  static const String budget = 'budget';
  static const String custom = 'custom';

  static String getDisplayName(String type) {
    switch (type) {
      case gaming:
        return 'Gaming';
      case workstation:
        return 'Workstation';
      case budget:
        return 'Budget';
      default:
        return 'Custom';
    }
  }

  static List<String> getAll() => [gaming, workstation, budget, custom];
}
