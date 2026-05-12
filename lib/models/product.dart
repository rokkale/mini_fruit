class Product {
  final int? productId;
  final String? sku;
  final String? barcode;
  final String productName;
  final int? categoryId;
  final double? costPrice;
  final double sellingPrice;
  final String? imageUrl;

  Product({
    this.productId,
    this.sku,
    this.barcode,
    required this.productName,
    this.categoryId,
    this.costPrice,
    required this.sellingPrice,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả field trực tiếp lẫn nested object từ backend
    int? catId = json['categoryId'] ?? json['category_id'];
    if (catId == null && json['category'] is Map) {
      final cat = json['category'] as Map<String, dynamic>;
      catId = cat['categoryId'] ?? cat['id'];
    }

    return Product(
      productId: json['productId'] ?? json['product_id'],
      sku: json['sku'],
      barcode: json['barcode'],
      productName: json['productName'] ?? json['product_name'],
      categoryId: catId,
      costPrice: json['costPrice'] != null
          ? (json['costPrice'] as num).toDouble()
          : null,
      sellingPrice: (json['sellingPrice'] ?? json['selling_price'] as num).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
    );
  }
}