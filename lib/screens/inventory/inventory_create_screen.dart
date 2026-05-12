import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../models/branch.dart';
import '../../models/product.dart';
import '../../models/product_stock.dart';
import '../../models/inventory_ticket.dart';
import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';

class _Item {
  final Product product;
  int quantity;
  _Item({required this.product, this.quantity = 1});
}

// Màu theo loại phiếu (semantic)
const _typeColors = {
  'IMPORT': AppTheme.success,
  'EXPORT': AppTheme.error,
  'TRANSFER': AppTheme.info,
};
const _typeBg = {
  'IMPORT': AppTheme.successContainer,
  'EXPORT': AppTheme.errorContainer,
  'TRANSFER': AppTheme.infoContainer,
};
const _typeLabels = {
  'IMPORT': 'Nhập kho',
  'EXPORT': 'Xuất kho',
  'TRANSFER': 'Chuyển kho',
};

class InventoryCreateScreen extends StatefulWidget {
  final List<Branch> branches;
  final List<ProductStock> stocks;

  const InventoryCreateScreen({
    super.key,
    required this.branches,
    required this.stocks,
  });

  @override
  State<InventoryCreateScreen> createState() => _InventoryCreateScreenState();
}

class _InventoryCreateScreenState extends State<InventoryCreateScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ProductService _productService = ProductService();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  String _ticketType = 'IMPORT';
  int? _branchId;
  int? _toBranchId;
  List<Product> _allProducts = [];
  List<Product> _searchResults = [];
  final List<_Item> _items = [];
  bool _loadingProducts = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _branchId = context.read<AuthProvider>().branchId;
    _loadProducts();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      _allProducts = await _productService.getProducts();
      _searchResults = _allProducts;
    } catch (_) {}
    setState(() => _loadingProducts = false);
  }

  void _search(String keyword) {
    final lower = keyword.toLowerCase().trim();
    setState(() {
      _searchResults = lower.isEmpty
          ? _allProducts
          : _allProducts
              .where((p) =>
                  p.productName.toLowerCase().contains(lower) ||
                  (p.barcode?.contains(lower) ?? false))
              .toList();
    });
  }

  int _stockOf(int productId) {
    if (_branchId == null) return 0;
    final s = widget.stocks
        .where((s) => s.productId == productId && s.branchId == _branchId)
        .firstOrNull;
    return s?.currentStock ?? 0;
  }

  bool _isAdded(int productId) =>
      _items.any((i) => i.product.productId == productId);

  void _addProduct(Product p) {
    if (_isAdded(p.productId!)) return;
    setState(() => _items.add(_Item(product: p)));
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _changeQty(int index, int delta) {
    setState(() {
      final item = _items[index];
      final newQty = item.quantity + delta;
      if (newQty < 1) return;
      if (_ticketType == 'EXPORT' || _ticketType == 'TRANSFER') {
        final stock = _stockOf(item.product.productId!);
        if (newQty > stock) return;
      }
      item.quantity = newQty;
    });
  }

  Future<void> _submit() async {
    if (_branchId == null) {
      _showError('Vui lòng chọn chi nhánh');
      return;
    }
    if (_ticketType == 'TRANSFER' && _toBranchId == null) {
      _showError('Vui lòng chọn chi nhánh đích');
      return;
    }
    if (_items.isEmpty) {
      _showError('Vui lòng thêm ít nhất một sản phẩm');
      return;
    }

    setState(() => _submitting = true);
    try {
      final ticket = InventoryTicket(
        ticketType: _ticketType,
        branchId: _branchId!,
        toBranchId: _toBranchId,
        note: _noteController.text.trim(),
        details: _items
            .map((i) => TicketDetail(
                  productId: i.product.productId!,
                  quantity: i.quantity,
                ))
            .toList(),
      );

      if (_ticketType == 'IMPORT') {
        await _inventoryService.createImportTicket(ticket);
      } else if (_ticketType == 'EXPORT') {
        await _inventoryService.createExportTicket(ticket);
      } else {
        await _inventoryService.createTransferTicket(ticket);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[_ticketType]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo phiếu ${_typeLabels[_ticketType]}'),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceMd),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header phiếu
          Container(
            color: AppTheme.surfaceVariant,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn loại phiếu
                Row(
                  children: ['IMPORT', 'EXPORT', 'TRANSFER'].map((type) {
                    final selected = _ticketType == type;
                    final c = _typeColors[type]!;
                    final bg = _typeBg[type]!;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _ticketType = type;
                            _toBranchId = null;
                          }),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? c : AppTheme.surface,
                              border: Border.all(
                                color: selected
                                    ? c
                                    : c.withValues(alpha: 0.4),
                              ),
                              borderRadius: AppTheme.roundedSm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (selected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white),
                                  ),
                                Text(
                                  _typeLabels[type]!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : c,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spaceSm),

                // Chi nhánh
                DropdownButtonFormField<int>(
                  value: _branchId,
                  decoration: InputDecoration(
                    labelText: _ticketType == 'TRANSFER'
                        ? 'Chi nhánh nguồn'
                        : 'Chi nhánh',
                    prefixIcon: const Icon(Icons.store_rounded),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: widget.branches
                      .map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _branchId = v),
                ),

                if (_ticketType == 'TRANSFER') ...[
                  const SizedBox(height: AppTheme.spaceSm),
                  DropdownButtonFormField<int>(
                    value: _toBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh đích',
                      prefixIcon: Icon(Icons.store_mall_directory_outlined),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: widget.branches
                        .where((b) => b.id != _branchId)
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _toBranchId = v),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceSm),

                // Ghi chú
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Sản phẩm đã chọn
          if (_items.isNotEmpty) _buildSelectedItems(color),

          // Tìm kiếm sản phẩm
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceXs,
            ),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm sản phẩm',
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.primary),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                TextField(
                  controller: _searchController,
                  onChanged: _search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên hoặc barcode...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildSelectedItems(Color color) {
    final bgColor = _typeBg[_ticketType]!;
    return Container(
      color: color.withValues(alpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceXs,
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 16, color: color),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  'Đã chọn ${_items.length} sản phẩm',
                  style: AppTheme.titleSmall.copyWith(color: color),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              final stock = _stockOf(item.product.productId!);
              return Container(
                margin: const EdgeInsets.fromLTRB(
                  AppTheme.spaceSm,
                  0,
                  AppTheme.spaceSm,
                  AppTheme.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.roundedSm,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.productName,
                              style: AppTheme.titleSmall,
                            ),
                            if (_ticketType != 'IMPORT')
                              Text(
                                'Tồn kho: $stock',
                                style: AppTheme.labelLarge,
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _QtyBtn(
                            icon: Icons.remove_rounded,
                            onTap: () => _changeQty(i, -1),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: AppTheme.titleSmall,
                            ),
                          ),
                          _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: () => _changeQty(i, 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      GestureDetector(
                        onTap: () => _removeItem(i),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceXs),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_rounded,
        message: 'Không tìm thấy sản phẩm',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceSm,
        AppTheme.spaceXs,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final p = _searchResults[i];
        final added = _isAdded(p.productId!);
        final stock = _stockOf(p.productId!);
        final outOfStock =
            (_ticketType == 'EXPORT' || _ticketType == 'TRANSFER') &&
                stock <= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceXs),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryContainer,
              child: Text(
                p.productName[0],
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(p.productName, style: AppTheme.titleSmall),
            subtitle: _ticketType != 'IMPORT'
                ? Text(
                    'Tồn: $stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: stock <= 0
                          ? AppTheme.error
                          : AppTheme.textGrey,
                    ),
                  )
                : null,
            trailing: added
                ? const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primary)
                : outOfStock
                    ? Text(
                        'Hết hàng',
                        style: AppTheme.labelLarge
                            .copyWith(color: AppTheme.error),
                      )
                    : ElevatedButton(
                        onPressed: () => _addProduct(p),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Thêm',
                            style: TextStyle(fontSize: 12)),
                      ),
            onTap: outOfStock || added ? null : () => _addProduct(p),
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.roundedXs,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: AppTheme.roundedXs,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textMedium),
      ),
    );
  }
}
