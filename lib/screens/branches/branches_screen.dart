import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../services/branch_service.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final BranchService _branchService = BranchService();
  final _searchController = TextEditingController();

  List<Branch> _branches = [];
  List<Branch> _filtered = [];
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final branches = await _branchService.getBranches();
      if (!mounted) return;
      _branches = branches;
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final kw = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _branches.where((b) {
        return b.name.toLowerCase().contains(kw) ||
            (b.address?.toLowerCase().contains(kw) ?? false) ||
            (b.phone?.toLowerCase().contains(kw) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý chi nhánh')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          message: 'Không có quyền truy cập',
          description: 'Chức năng này chỉ dành cho Quản trị viên.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chi nhánh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBranchDialog(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: const Text('Thêm chi nhánh', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceMd,
              AppTheme.spaceMd,
              AppTheme.spaceSm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên, địa chỉ, SĐT...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: _SummaryChip(count: _branches.length),
            ),
          const SizedBox(height: AppTheme.spaceSm),
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
      return AppErrorState(
        message: _error!,
        onRetry: _loadData,
      );
    }
    if (_filtered.isEmpty) {
      return AppEmptyState(
        icon: Icons.store_mall_directory_outlined,
        message: _branches.isEmpty
            ? 'Chưa có chi nhánh nào'
            : 'Không tìm thấy chi nhánh phù hợp',
        description: _branches.isEmpty ? 'Nhấn "+ Thêm chi nhánh" để tạo mới.' : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          0,
          AppTheme.spaceMd,
          100,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final branch = _filtered[index];
          return _BranchCard(
            branch: branch,
            onEdit: () => _showBranchDialog(context, branch: branch),
            onDelete: () => _confirmDelete(context, branch),
          );
        },
      ),
    );
  }

  void _showBranchDialog(BuildContext context, {Branch? branch}) {
    final isEdit = branch != null;
    final nameCtrl = TextEditingController(text: branch?.name ?? '');
    final addressCtrl = TextEditingController(text: branch?.address ?? '');
    final phoneCtrl = TextEditingController(text: branch?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_location_alt_outlined : Icons.add_business_outlined,
                color: AppTheme.primary,
                size: 22,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Text(isEdit ? 'Sửa chi nhánh' : 'Thêm chi nhánh'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên chi nhánh *',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final data = {
                        'branchName': nameCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                      };

                      try {
                        if (isEdit) {
                          await _branchService.updateBranch(branch.id, data);
                        } else {
                          await _branchService.createBranch(data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              isEdit ? 'Cập nhật chi nhánh thành công' : 'Thêm chi nhánh thành công',
                            ),
                            backgroundColor: Colors.green,
                          ));
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppTheme.error,
                          ));
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Branch branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xóa chi nhánh'),
          ],
        ),
        content: Text(
          'Xóa chi nhánh "${branch.name}"?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _branchService.deleteBranch(branch.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ));
        }
      }
    }
  }
}

class _BranchCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(child: Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.roundedMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: AppTheme.roundedMd,
              ),
              child: const Icon(
                Icons.store_rounded,
                color: AppTheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch.name, style: AppTheme.titleSmall),
                  if (branch.address != null && branch.address!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceXs),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch.address!,
                            style: AppTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (branch.phone != null && branch.phone!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceXs),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Text(branch.phone!, style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
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
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: AppTheme.error)),
                  ]),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    ));
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  const _SummaryChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: AppTheme.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.store_rounded, size: 16, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceXs),
          Text(
            '$count chi nhánh',
            style: AppTheme.labelMedium.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
