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

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    productId: json['productId'] ?? json['product_id'],
    sku: json['sku'],
    barcode: json['barcode'],
    productName: json['productName'] ?? json['product_name'],
    categoryId: json['categoryId'] ?? json['category_id'],
    costPrice: json['costPrice'] != null
        ? (json['costPrice'] as num).toDouble()
        : null,
    sellingPrice: (json['sellingPrice'] ?? json['selling_price'] as num).toDouble(),
    imageUrl: json['imageUrl'] ?? json['image_url'],
  );
}