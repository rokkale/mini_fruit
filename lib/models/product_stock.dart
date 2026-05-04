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

  factory ProductStock.fromJson(Map<String, dynamic> json) => ProductStock(
    stockId: json['stockId'] ?? json['stock_id'],
    productId: json['productId'] ?? json['product_id'],
    productName: json['productName'],
    barcode: json['barcode'],
    branchId: json['branchId'] ?? json['branch_id'],
    branchName: json['branchName'],
    minStock: json['minStock'] ?? json['min_stock'],
    currentStock: json['currentStock'] ?? json['current_stock'],
  );
}