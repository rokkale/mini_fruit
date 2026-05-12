class Shift {
  final int? shiftId;
  final int? userId;
  final String? username;
  final String? fullName;
  final int? branchId;
  final String? branchName;
  final String? startTime;
  final String? endTime;
  final double openingCash;
  final double cashRevenue;
  final double transferRevenue;
  final double totalRevenue;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final String? notes;
  final String? createdAt;

  Shift({
    this.shiftId,
    this.userId,
    this.username,
    this.fullName,
    this.branchId,
    this.branchName,
    this.startTime,
    this.endTime,
    required this.openingCash,
    required this.cashRevenue,
    required this.transferRevenue,
    required this.totalRevenue,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    this.notes,
    this.createdAt,
  });

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        shiftId: json['shiftId'],
        userId: json['userId'],
        username: json['username'],
        fullName: json['fullName'],
        branchId: json['branchId'],
        branchName: json['branchName'],
        startTime: json['startTime'],
        endTime: json['endTime'],
        openingCash: (json['openingCash'] as num).toDouble(),
        cashRevenue: (json['cashRevenue'] as num).toDouble(),
        transferRevenue: (json['transferRevenue'] as num).toDouble(),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        expectedCash: (json['expectedCash'] as num).toDouble(),
        actualCash: (json['actualCash'] as num).toDouble(),
        difference: (json['difference'] as num).toDouble(),
        notes: json['notes'],
        createdAt: json['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'branchId': branchId,
        'startTime': startTime,
        'openingCash': openingCash,
        'cashRevenue': cashRevenue,
        'transferRevenue': transferRevenue,
        'totalRevenue': totalRevenue,
        'expectedCash': expectedCash,
        'actualCash': actualCash,
        'difference': difference,
        'notes': notes,
      };
}
