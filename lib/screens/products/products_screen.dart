import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _products = await _productService.getProducts();
      _filtered = _products;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _isLoading = false);
  }

  void _search(String keyword) {
    setState(() {
      _filtered = _products.where((p) =>
      p.productName.toLowerCase().contains(keyword.toLowerCase()) ||
          (p.barcode?.contains(keyword) ?? false) ||
          (p.sku?.toLowerCase().contains(keyword.toLowerCase()) ?? false),
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
                hintText: 'Tìm theo tên, mã SKU, barcode...',
                prefixIcon: Icon(Icons.search),
              ),
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
              onPressed: _loadProducts,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(
        child: Text('Không có sản phẩm nào'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final product = _filtered[index];
          return _ProductCard(
            product: product,
            currencyFormat: _currencyFormat,
            onEdit: () => _showProductDialog(context, product: product),
            onDelete: () => _confirmDelete(context, product),
          );
        },
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(
      text: isEdit ? product.productName : '',
    );
    final skuController = TextEditingController(
      text: isEdit ? product.sku ?? '' : '',
    );
    final barcodeController = TextEditingController(
      text: isEdit ? product.barcode ?? '' : '',
    );
    final costController = TextEditingController(
      text: isEdit ? product.costPrice?.toStringAsFixed(0) ?? '' : '',
    );
    final priceController = TextEditingController(
      text: isEdit ? product.sellingPrice.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
                  validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'Mã SKU'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: barcodeController,
                  decoration: const InputDecoration(labelText: 'Barcode'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: 'Giá nhập'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Giá bán *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
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
                'productName': nameController.text.trim(),
                'sku': skuController.text.trim(),
                'barcode': barcodeController.text.trim(),
                'costPrice': double.tryParse(costController.text) ?? 0,
                'sellingPrice': double.parse(priceController.text),
              };
              try {
                if (isEdit) {
                  await _productService.updateProduct(product.productId!, data);
                } else {
                  await _productService.createProduct(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadProducts();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
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
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Xóa "${product.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _productService.deleteProduct(product.productId!);
                _loadProducts();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon sản phẩm
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_basket,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku ?? "—"}  |  ${product.barcode ?? "Chưa có barcode"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(product.sellingPrice),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton(
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
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
    );
  }
}