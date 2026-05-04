class ProductStock {
  final int? stockId;
  final int productId;
  final String? productName;
  final String? barcode;
  final int branchId;
  final String? branchName;
  final int? minStock;
  final int currentStock;

  ProductStock({
    this.stockId,
    required this.productId,
    this.productName,
    this.barcode,
    required this.branchId,
    this.branchName,
    this.minStock,
    required this.currentStock,
  });

  factory ProductStock.fromJson(Map<String, dynamic> json) {
    // Backend trả nested: { product: {productId, productName, barcode}, branch: {branchId, branchName} }
    final product = json['product'] as Map<String, dynamic>?;
    final branch  = json['branch']  as Map<String, dynamic>?;
    return ProductStock(
      stockId:     json['stockId'] ?? json['stock_id'],
      productId:   product?['productId'] ?? json['productId'] ?? json['product_id'],
      productName: product?['productName'] ?? json['productName'],
      barcode:     product?['barcode'] ?? json['barcode'],
      branchId:    branch?['branchId'] ?? json['branchId'] ?? json['branch_id'],
      branchName:  branch?['branchName'] ?? json['branchName'],
      minStock:    json['minStock'] ?? json['min_stock'],
      currentStock: json['currentStock'] ?? json['current_stock'] ?? 0,
    );
  }
}