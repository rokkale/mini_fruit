class OrderDetail {
  final int? orderDetailId;
  final int? orderId;
  final int productId;
  final String? productName;
  final int quantity;
  final double unitPrice;

  OrderDetail({
    this.orderDetailId,
    this.orderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    orderDetailId: json['orderDetailId'] ?? json['order_detail_id'],
    orderId: json['orderId'] ?? json['order_id'],
    productId: json['productId'] ?? json['product_id'],
    productName: json['productName'],
    quantity: json['quantity'],
    unitPrice: (json['unitPrice'] ?? json['unit_price'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': unitPrice * quantity,
  };
}

class Order {
  final int? orderId;
  final int? branchId;
  final String? branchName;
  final int? userId;
  final int? customerId;
  final String? customerName;
  final double totalAmount;
  final double? discount;
  final double? freeAmount;
  final String? paymentMethod;
  final String? createdAt;
  final List<OrderDetail>? details;

  Order({
    this.orderId,
    this.branchId,
    this.branchName,
    this.userId,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    this.discount,
    this.freeAmount,
    this.paymentMethod,
    this.createdAt,
    this.details,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    orderId: json['orderId'] ?? json['order_id'],
    branchId: json['branchId'] ?? json['branch_id'],
    branchName: json['branchName'],
    userId: json['userId'] ?? json['user_id'],
    customerId: json['customerId'] ?? json['customer_id'],
    customerName: json['customerName'],
    totalAmount: (json['totalAmount'] ?? json['total_amount'] as num).toDouble(),
    discount: json['discount'] != null
        ? (json['discount'] as num).toDouble()
        : null,
    freeAmount: json['freeAmount'] != null
        ? (json['freeAmount'] as num).toDouble()
        : null,
    paymentMethod: json['paymentMethod'] ?? json['payment_method'],
    createdAt: json['createdAt'] ?? json['created_at'],
    details: json['details'] != null
        ? (json['details'] as List)
        .map((e) => OrderDetail.fromJson(e))
        .toList()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    'customerId': customerId,
    'totalAmount': totalAmount,
    'discount': discount ?? 0,
    'freeAmount': freeAmount ?? totalAmount, // ← THÊM DÒNG NÀY
    'paymentMethod': paymentMethod,
    'details': details?.map((e) => e.toJson()).toList(),
  };
}