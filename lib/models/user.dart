class User {
  final int? userId;
  final String username;
  final String? fullName;
  final int? roleId;
  final String? role;       // ADMIN, MANAGER, STAFF, WAREHOUSE
  final int? branchId;
  final bool? status;

  User({
    this.userId,
    required this.username,
    this.fullName,
    this.roleId,
    this.role,
    this.branchId,
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['userId'] ?? json['user_id'],
    username: json['username'],
    fullName: json['fullName'] ?? json['full_name'],
    roleId: json['roleId'] ?? json['role_id'],
    role: json['role'],
    branchId: json['branchId'] ?? json['branch_id'],
    status: json['status'],
  );

  // Kiểm tra quyền
  bool get isAdmin => role == 'ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isStaff => role == 'STAFF';
  bool get isWarehouse => role == 'WAREHOUSE';
}