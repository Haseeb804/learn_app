class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? color;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'color': color,
    };
  }
}