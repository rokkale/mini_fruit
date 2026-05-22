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

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    // product có thể nằm trong nested object
    final product = json['product'] as Map<String, dynamic>?;
    return OrderDetail(
      orderDetailId: json['orderDetailId'] ?? json['order_detail_id'],
      orderId:       json['orderId']       ?? json['order_id'],
      productId:     product?['productId'] ?? json['productId'] ?? json['product_id'] ?? 0,
      productName:   product?['productName'] ?? product?['name']
                     ?? json['productName']   ?? json['product_name'],
      quantity:      json['quantity'] ?? 1,
      unitPrice:     ((json['unitPrice']
                     ?? json['unit_price']
                     ?? json['price']
                     ?? product?['sellingPrice']
                     ?? product?['price']
                     ?? 0) as num).toDouble(),
    );
  }

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

  factory Order.fromJson(Map<String, dynamic> json) {
    // Backend trả nested objects: branch{branchId}, user{userId}, customer{customerName}
    final branch   = json['branch']   as Map<String, dynamic>?;
    final user     = json['user']     as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    return Order(
      orderId:      json['orderId'] ?? json['order_id'],
      branchId:     branch?['branchId'] ?? json['branchId'] ?? json['branch_id'],
      branchName:   branch?['branchName'] ?? json['branchName'],
      userId:       user?['userId'] ?? json['userId'] ?? json['user_id'],
      customerId:   customer?['customerId'] ?? json['customerId'] ?? json['customer_id'],
      customerName: customer?['customerName'] ?? json['customerName'],
      totalAmount:  (json['totalAmount'] ?? json['total_amount'] ?? 0 as num).toDouble(),
      discount:     json['discount'] != null ? (json['discount'] as num).toDouble() : null,
      freeAmount:   json['freeAmount'] != null ? (json['freeAmount'] as num).toDouble() : null,
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      createdAt:    json['createdAt'] ?? json['created_at'],
      details:      _parseDetails(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    'userId': userId,
    'customerId': customerId,
    'paymentMethod': paymentMethod ?? 'CASH',
    'discount': discount ?? 0,
    'items': details?.map((e) => e.toJson()).toList(),
  };
}

/// Thử nhiều key khác nhau mà backend có thể dùng cho danh sách sản phẩm.
/// Spring Boot JPA thường trả: details / orderDetails / items / order_details
List<OrderDetail>? _parseDetails(Map<String, dynamic> json) {
  for (final key in ['details', 'orderDetails', 'order_details', 'items', 'products']) {
    final raw = json[key];
    if (raw != null && raw is List && raw.isNotEmpty) {
      return raw.map((e) => OrderDetail.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  return null;
}