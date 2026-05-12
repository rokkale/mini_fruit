class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    final id = json['categoryId'] ?? json['category_id'] ?? json['id'];
    final name = json['categoryName'] ?? json['category_name'] ?? json['name'] ?? 'Danh mục $id';
    return Category(id: id, name: name);
  }
}
