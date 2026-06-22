class Component {
  final String id;
  final int categoryId;
  final String name;
  final String brand;
  final String? model;
  final Map<String, dynamic> specs;
  final double price;
  final String currency;
  final String? imageUrl;
  final int? performanceScore;

  Component({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    this.model,
    required this.specs,
    required this.price,
    this.currency = 'JOD',
    this.imageUrl,
    this.performanceScore,
  });

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      specs: Map<String, dynamic>.from(json['specs']),
      price: double.tryParse(json['price'].toString()) ?? 0,
      currency: json['currency'] ?? 'JOD',
      imageUrl: json['image_url'],
      performanceScore: json['performance_score'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'brand': brand,
    'model': model,
    'specs': specs,
    'price': price,
    'currency': currency,
    'image_url': imageUrl,
    'performance_score': performanceScore,
  };
}

class Category {
  final int id;
  final String name;
  final String? icon;
  final int displayOrder;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.displayOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}
