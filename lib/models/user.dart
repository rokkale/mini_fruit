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

  factory User.fromJson(Map<String, dynamic> json) {
    // Backend trả role là object {roleId, roleName}, branch là object {branchId, ...}
    final roleRaw = json['role'];
    final branchRaw = json['branch'];
    return User(
      userId: json['userId'] ?? json['user_id'],
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? json['full_name'],
      roleId: roleRaw is Map ? roleRaw['roleId'] as int? : (json['roleId'] ?? json['role_id']),
      role: roleRaw is Map ? roleRaw['roleName'] as String? : roleRaw as String?,
      branchId: branchRaw is Map ? branchRaw['branchId'] as int? : (json['branchId'] ?? json['branch_id']),
      status: json['status'],
    );
  }

  // Kiểm tra quyền
  bool get isAdmin => role == 'ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isStaff => role == 'STAFF';
  bool get isWarehouse => role == 'WAREHOUSE';
}