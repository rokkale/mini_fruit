import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
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
          : _allProducts.where((p) =>
              p.productName.toLowerCase().contains(lower) ||
              (p.barcode?.contains(lower) ?? false)).toList();
    });
  }

  int _stockOf(int productId) {
    if (_branchId == null) return 0;
    final s = widget.stocks.where((s) =>
        s.productId == productId && s.branchId == _branchId).firstOrNull;
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
        details: _items.map((i) => TicketDetail(
          productId: i.product.productId!,
          quantity: i.quantity,
        )).toList(),
      );

      if (_ticketType == 'IMPORT') {
        await _inventoryService.createImportTicket(ticket);
      } else if (_ticketType == 'EXPORT') {
        await _inventoryService.createExportTicket(ticket);
      } else {
        await _inventoryService.createTransferTicket(ticket);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _submitting = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      'IMPORT': Colors.green,
      'EXPORT': Colors.red,
      'TRANSFER': Colors.blue,
    };
    final typeLabels = {
      'IMPORT': 'Nhập kho',
      'EXPORT': 'Xuất kho',
      'TRANSFER': 'Chuyển kho',
    };
    final color = typeColors[_ticketType]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo phiếu ${typeLabels[_ticketType]}'),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Xác nhận',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Phần header phiếu
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loại phiếu
                Row(
                  children: ['IMPORT', 'EXPORT', 'TRANSFER'].map((type) {
                    final selected = _ticketType == type;
                    final c = typeColors[type]!;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _ticketType = type;
                            _toBranchId = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? c : Colors.white,
                              border: Border.all(color: c),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (selected)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(Icons.check, size: 14, color: Colors.white),
                                  ),
                                Text(
                                  typeLabels[type]!,
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
                const SizedBox(height: 12),

                // Chi nhánh
                DropdownButtonFormField<int>(
                  value: _branchId,
                  decoration: InputDecoration(
                    labelText: _ticketType == 'TRANSFER' ? 'Chi nhánh nguồn' : 'Chi nhánh',
                    prefixIcon: const Icon(Icons.store),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: widget.branches.map((b) => DropdownMenuItem(
                    value: b.id, child: Text(b.name),
                  )).toList(),
                  onChanged: (v) => setState(() => _branchId = v),
                ),

                // Chi nhánh đích (chỉ TRANSFER)
                if (_ticketType == 'TRANSFER') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _toBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh đích',
                      prefixIcon: Icon(Icons.store_mall_directory),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: widget.branches
                        .where((b) => b.id != _branchId)
                        .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _toBranchId = v),
                  ),
                ],
                const SizedBox(height: 8),

                // Ghi chú
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách sản phẩm đã chọn
          if (_items.isNotEmpty) _buildSelectedItems(color),

          // Divider + tiêu đề tìm kiếm
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm sản phẩm',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchController,
                  onChanged: _search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên hoặc barcode...',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách sản phẩm để chọn
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildSelectedItems(Color color) {
    return Container(
      color: color.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Icon(Icons.shopping_basket, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  'Đã chọn ${_items.length} sản phẩm',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
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
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.productName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (_ticketType != 'IMPORT')
                              Text('Tồn kho: $stock',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      // Stepper số lượng
                      Row(
                        children: [
                          _QtyButton(
                            icon: Icons.remove,
                            onTap: () => _changeQty(i, -1),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.add,
                            onTap: () => _changeQty(i, 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeItem(i),
                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Không tìm thấy sản phẩm'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final p = _searchResults[i];
        final added = _isAdded(p.productId!);
        final stock = _stockOf(p.productId!);
        final outOfStock =
            (_ticketType == 'EXPORT' || _ticketType == 'TRANSFER') && stock <= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                p.productName[0],
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(p.productName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: _ticketType != 'IMPORT'
                ? Text('Tồn: $stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: stock <= 0 ? Colors.red : Colors.grey.shade600,
                    ))
                : null,
            trailing: added
                ? Icon(Icons.check_circle, color: AppTheme.primary)
                : outOfStock
                    ? const Text('Hết hàng',
                        style: TextStyle(fontSize: 11, color: Colors.red))
                    : ElevatedButton(
                        onPressed: () => _addProduct(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Thêm',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
            onTap: outOfStock || added ? null : () => _addProduct(p),
          ),
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}
