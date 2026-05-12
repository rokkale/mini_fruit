import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../models/user.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../services/branch_service.dart';

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
  String? _selectedRoleFilter;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.dio.get(AppConstants.users),
        _branchService.getBranches(),
      ]);

      if (!mounted) return;
      _users = (results[0] as Response).data != null
          ? ((results[0] as Response).data as List)
              .map((e) => User.fromJson(e))
              .toList()
          : [];
      _branches = results[1] as List<Branch>;
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilters() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final matchesRole =
            _selectedRoleFilter == null || u.role == _selectedRoleFilter;
        final matchesKeyword =
            u.username.toLowerCase().contains(keyword) ||
                (u.fullName?.toLowerCase().contains(keyword) ?? false);
        return matchesRole && matchesKeyword;
      }).toList();
    });
  }

  void _onRoleFilterTapped(String? role) {
    if (_selectedRoleFilter == role) return;
    _selectedRoleFilter = role;
    _applyFilters();
  }

  String _getBranchName(int? branchId) {
    if (branchId == null) return 'Tất cả chi nhánh';
    final branch = _branches.where((b) => b.id == branchId).firstOrNull;
    return branch?.name ?? 'Chi nhánh #$branchId';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nhân viên')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          message: 'Không có quyền truy cập',
          description: 'Chỉ quản trị viên mới có thể xem trang này',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(context),
        child: const Icon(Icons.person_add_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc username...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),

          // Bộ lọc vai trò
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            child: Row(
              children: [
                _RoleChip(
                  label: 'Tổng',
                  count: _users.length,
                  color: AppTheme.primary,
                  isSelected: _selectedRoleFilter == null,
                  onTap: () => _onRoleFilterTapped(null),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                _RoleChip(
                  label: 'Admin',
                  count: _users.where((u) => u.role == 'ADMIN').length,
                  color: AppTheme.error,
                  isSelected: _selectedRoleFilter == 'ADMIN',
                  onTap: () => _onRoleFilterTapped('ADMIN'),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                _RoleChip(
                  label: 'Manager',
                  count: _users.where((u) => u.role == 'MANAGER').length,
                  color: AppTheme.warning,
                  isSelected: _selectedRoleFilter == 'MANAGER',
                  onTap: () => _onRoleFilterTapped('MANAGER'),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                _RoleChip(
                  label: 'Staff',
                  count: _users.where((u) => u.role == 'STAFF').length,
                  color: AppTheme.info,
                  isSelected: _selectedRoleFilter == 'STAFF',
                  onTap: () => _onRoleFilterTapped('STAFF'),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                _RoleChip(
                  label: 'Kho',
                  count: _users.where((u) => u.role == 'WAREHOUSE').length,
                  color: const Color(0xFF6A1B9A),
                  isSelected: _selectedRoleFilter == 'WAREHOUSE',
                  onTap: () => _onRoleFilterTapped('WAREHOUSE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return AppErrorState(message: _error!, onRetry: _loadData);
    }
    if (_filtered.isEmpty) {
      return const AppEmptyState(
        icon: Icons.people_outline_rounded,
        message: 'Không có nhân viên nào phù hợp',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          0,
          AppTheme.spaceMd,
          80,
        ),
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
    final usernameCtrl =
        TextEditingController(text: isEdit ? user.username : '');
    final fullNameCtrl =
        TextEditingController(text: isEdit ? user.fullName ?? '' : '');
    final passwordCtrl = TextEditingController();
    String selectedRole = isEdit ? (user.role ?? 'STAFF') : 'STAFF';
    int? selectedBranchId = isEdit ? user.branchId : null;
    final formKey = GlobalKey<FormState>();

    const roles = ['ADMIN', 'MANAGER', 'STAFF', 'WAREHOUSE'];
    const roleLabels = {
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
                  TextFormField(
                    controller: usernameCtrl,
                    enabled: !isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Không được để trống' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextFormField(
                    controller: fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'Mật khẩu mới (để trống nếu không đổi)'
                          : 'Mật khẩu *',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (v) {
                      if (!isEdit && (v == null || v.isEmpty)) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò *',
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
                    items: roles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(roleLabels[r]!),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v!),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  DropdownButtonFormField<int?>(
                    value: selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh',
                      prefixIcon: Icon(Icons.store_rounded),
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
                  'username': usernameCtrl.text.trim(),
                  'fullName': fullNameCtrl.text.trim(),
                  'role': selectedRole,
                  'branchId': selectedBranchId,
                  if (passwordCtrl.text.isNotEmpty)
                    'password': passwordCtrl.text,
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
    final isActive = user.status ?? true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? 'Vô hiệu hóa tài khoản' : 'Kích hoạt tài khoản'),
        content: Text(
          isActive
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
              backgroundColor: isActive ? AppTheme.error : AppTheme.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.dio.patch(
          '${AppConstants.users}/${user.userId}/status',
          data: {'status': !isActive},
        );
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
            ),
          );
        }
      }
    }
  }
}

// ─────────────────────────────────────────
// USER CARD
// ─────────────────────────────────────────
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
      case 'ADMIN':
        return AppTheme.error;
      case 'MANAGER':
        return AppTheme.warning;
      case 'STAFF':
        return AppTheme.info;
      case 'WAREHOUSE':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.textGrey;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'MANAGER':
        return 'Quản lý';
      case 'STAFF':
        return 'Nhân viên BH';
      case 'WAREHOUSE':
        return 'Nhân viên kho';
      default:
        return user.role ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user.status ?? true;

    return HoverCard(child: Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      shape: !isActive
          ? RoundedRectangleBorder(
              borderRadius: AppTheme.roundedMd,
              side: const BorderSide(color: AppTheme.border),
            )
          : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _roleColor.withValues(alpha: 0.12),
                child: Text(
                  (user.fullName ?? user.username)[0].toUpperCase(),
                  style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.fullName ?? user.username,
                          style: AppTheme.titleSmall,
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: AppTheme.spaceSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: AppTheme.roundedXs,
                            ),
                            child: Text(
                              'Vô hiệu',
                              style: AppTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('@${user.username}', style: AppTheme.bodySmall),
                    const SizedBox(height: AppTheme.spaceXs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.1),
                            borderRadius: AppTheme.roundedXs,
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
                        const SizedBox(width: AppTheme.spaceSm),
                        Text(branchName, style: AppTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(
                        isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color: isActive ? AppTheme.error : AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                        style: TextStyle(
                          color: isActive ? AppTheme.error : AppTheme.success,
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
    ));
  }
}

// ─────────────────────────────────────────
// CHIP LỌC VAI TRÒ
// ─────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: AppTheme.roundedFull,
          border: isSelected
              ? null
              : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$count ',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
