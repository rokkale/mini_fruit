import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../services/branch_service.dart';

// Tạm thời dùng Dio trực tiếp vì users cần thêm service
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final BranchService _branchService = BranchService();
  final _searchController = TextEditingController();

  List<User> _users = [];
  List<User> _filtered = [];
  List<Branch> _branches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiClient.dio.get(AppConstants.users),
        _branchService.getBranches(),
      ]);

      _users = (results[0] as Response).data != null
          ? ((results[0] as Response).data as List)
          .map((e) => User.fromJson(e))
          .toList()
          : [];
      _branches = results[1] as List<Branch>;
      _filtered = _users;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _isLoading = false);
  }

  void _search(String keyword) {
    setState(() {
      _filtered = _users.where((u) =>
      (u.username.toLowerCase().contains(keyword.toLowerCase())) ||
          (u.fullName?.toLowerCase().contains(keyword.toLowerCase()) ?? false),
      ).toList();
    });
  }

  String _getBranchName(int? branchId) {
    if (branchId == null) return 'Tất cả chi nhánh';
    final branch = _branches.where((b) => b.id == branchId).firstOrNull;
    return branch?.name ?? 'Chi nhánh #$branchId';
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ ADMIN mới vào được màn hình này
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nhân viên')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('Bạn không có quyền truy cập'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc username...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Thống kê nhanh
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _StatChip(
                  label: 'Tổng',
                  value: '${_users.length}',
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Admin',
                  value: '${_users.where((u) => u.role == 'ADMIN').length}',
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Manager',
                  value: '${_users.where((u) => u.role == 'MANAGER').length}',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Staff',
                  value: '${_users.where((u) => u.role == 'STAFF').length}',
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // Danh sách
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('Không có nhân viên nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final user = _filtered[index];
          return _UserCard(
            user: user,
            branchName: _getBranchName(user.branchId),
            onEdit: () => _showUserDialog(context, user: user),
            onToggleStatus: () => _toggleStatus(context, user),
          );
        },
      ),
    );
  }

  void _showUserDialog(BuildContext context, {User? user}) {
    final isEdit = user != null;
    final usernameController =
    TextEditingController(text: isEdit ? user.username : '');
    final fullNameController =
    TextEditingController(text: isEdit ? user.fullName ?? '' : '');
    final passwordController = TextEditingController();
    String selectedRole = isEdit ? (user.role ?? 'STAFF') : 'STAFF';
    int? selectedBranchId = isEdit ? user.branchId : null;
    final formKey = GlobalKey<FormState>();

    final roles = ['ADMIN', 'MANAGER', 'STAFF', 'WAREHOUSE'];
    final roleLabels = {
      'ADMIN': 'Quản trị viên',
      'MANAGER': 'Quản lý',
      'STAFF': 'Nhân viên bán hàng',
      'WAREHOUSE': 'Nhân viên kho',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa nhân viên' : 'Thêm nhân viên'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  TextFormField(
                    controller: usernameController,
                    enabled: !isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                    v!.isEmpty ? 'Không được để trống' : null,
                  ),
                  const SizedBox(height: 12),

                  // Họ tên
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mật khẩu (bắt buộc khi thêm mới)
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'Mật khẩu mới (để trống nếu không đổi)'
                          : 'Mật khẩu *',
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    validator: (v) {
                      if (!isEdit && (v == null || v.isEmpty)) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Role
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò *',
                      prefixIcon: Icon(Icons.security),
                    ),
                    items: roles.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(roleLabels[r]!),
                    )).toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v!),
                  ),
                  const SizedBox(height: 12),

                  // Chi nhánh
                  DropdownButtonFormField<int?>(
                    value: selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh',
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả chi nhánh'),
                      ),
                      ..._branches.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name),
                      )),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedBranchId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'username': usernameController.text.trim(),
                  'fullName': fullNameController.text.trim(),
                  'role': selectedRole,
                  'branchId': selectedBranchId,
                  if (passwordController.text.isNotEmpty)
                    'password': passwordController.text,
                };
                try {
                  if (isEdit) {
                    await ApiClient.dio.put(
                      '${AppConstants.users}/${user.userId}',
                      data: data,
                    );
                  } else {
                    await ApiClient.dio.post(AppConstants.users, data: data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                            e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            (user.status ?? true) ? 'Vô hiệu hóa tài khoản' : 'Kích hoạt tài khoản'),
        content: Text(
          (user.status ?? true)
              ? 'Vô hiệu hóa tài khoản "${user.username}"?'
              : 'Kích hoạt tài khoản "${user.username}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              (user.status ?? true) ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text((user.status ?? true) ? 'Vô hiệu hóa' : 'Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.dio.patch(
          '${AppConstants.users}/${user.userId}/status',
          data: {'status': !(user.status ?? true)},
        );
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final String branchName;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _UserCard({
    required this.user,
    required this.branchName,
    required this.onEdit,
    required this.onToggleStatus,
  });

  Color get _roleColor {
    switch (user.role) {
      case 'ADMIN': return Colors.red;
      case 'MANAGER': return Colors.orange;
      case 'STAFF': return Colors.blue;
      case 'WAREHOUSE': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case 'ADMIN': return 'Quản trị viên';
      case 'MANAGER': return 'Quản lý';
      case 'STAFF': return 'Nhân viên BH';
      case 'WAREHOUSE': return 'Nhân viên kho';
      default: return user.role ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user.status ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: !isActive
            ? const BorderSide(color: Colors.grey, width: 1)
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _roleColor.withOpacity(0.15),
                child: Text(
                  (user.fullName ?? user.username)[0].toUpperCase(),
                  style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.fullName ?? user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Vô hiệu',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _roleLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _roleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          branchName,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu actions
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                        style: TextStyle(
                          color: isActive ? Colors.red : Colors.green,
                        ),
                      ),
                    ]),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'toggle') onToggleStatus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}