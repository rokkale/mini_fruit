class TicketDetail {
  final int? detailId;
  final int? ticketId;
  final int productId;
  final String? productName;
  final int quantity;
  final int? actualQty;

  TicketDetail({
    this.detailId,
    this.ticketId,
    required this.productId,
    this.productName,
    required this.quantity,
    this.actualQty,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) => TicketDetail(
    detailId: json['detailId'] ?? json['detail_id'],
    ticketId: json['ticketId'] ?? json['ticket_id'],
    productId: json['productId'] ?? json['product_id'],
    productName: json['productName'],
    quantity: json['quantity'],
    actualQty: json['actualQty'] ?? json['actual_qty'],
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class InventoryTicket {
  final int? ticketId;
  final String ticketType;   // IMPORT, EXPORT, TRANSFER
  final int branchId;
  final String? branchName;
  final int? toBranchId;     // Chỉ dùng khi TRANSFER
  final int? userId;
  final String? createdAt;
  final String? note;
  final List<TicketDetail>? details;

  InventoryTicket({
    this.ticketId,
    required this.ticketType,
    required this.branchId,
    this.branchName,
    this.toBranchId,
    this.userId,
    this.createdAt,
    this.note,
    this.details,
  });

  factory InventoryTicket.fromJson(Map<String, dynamic> json) => InventoryTicket(
    ticketId: json['ticketId'] ?? json['ticket_id'],
    ticketType: json['ticketType'] ?? json['ticket_type'],
    branchId: json['branchId'] ?? json['branch_id'],
    branchName: json['branchName'],
    toBranchId: json['toBranchId'] ?? json['to_branch_id'],
    userId: json['userId'] ?? json['user_id'],
    createdAt: json['createdAt'] ?? json['created_at'],
    note: json['note'],
    details: json['details'] != null
        ? (json['details'] as List)
        .map((e) => TicketDetail.fromJson(e))
        .toList()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'ticketType': ticketType,
    'branchId': branchId,
    'toBranchId': toBranchId,
    'note': note,
    'details': details?.map((e) => e.toJson()).toList(),
  };
}