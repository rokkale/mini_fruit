import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _picker = ImagePicker();

  List<Product> _products = [];
  List<Product> _filtered = [];
  List<Category> _categories = [];
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
      final results = await Future.wait([
        _productService.getProducts(),
        _categoryService.getCategories(),
      ]);
      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppSkeletonList();
    }
    if (_error != null) {
      return AppErrorState(message: _error!, onRetry: _loadProducts);
    }
    if (_filtered.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'Không có sản phẩm nào',
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
            onShowQr: () => _showQrDialog(product),
          );
        },
      ),
    );
  }

  // ── Dialog thêm / sửa sản phẩm (gộp cả chọn ảnh) ─────────────────────────
  void _showProductDialog(BuildContext context, {Product? product}) {
    final isEdit = product != null;
    final nameController     = TextEditingController(text: isEdit ? product.productName : '');
    final skuController      = TextEditingController(text: isEdit ? product.sku ?? '' : '');
    final barcodeController  = TextEditingController(text: isEdit ? product.barcode ?? '' : '');
    final costController     = TextEditingController(
        text: isEdit ? product.costPrice?.toStringAsFixed(0) ?? '' : '');
    final priceController    = TextEditingController(
        text: isEdit ? product.sellingPrice.toStringAsFixed(0) : '');
    final formKey = GlobalKey<FormState>();

    // State nội bộ dialog — closure vars, cập nhật qua setDialogState
    XFile? pickedFile;
    Uint8List? previewBytes;
    bool isSaving = false;
    Category? selectedCategory = isEdit
        ? _categories.where((c) => c.id == product.categoryId).firstOrNull
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Ảnh sản phẩm ────────────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final file = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 800,
                      );
                      if (file == null) return;
                      final bytes = await file.readAsBytes();
                      setDialogState(() {
                        pickedFile = file;
                        previewBytes = bytes;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: AppTheme.roundedMd,
                            border: Border.all(color: AppTheme.border, width: 1.5),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: AppTheme.roundedMd,
                                child: _buildImagePreview(
                                  previewBytes: previewBytes,
                                  existingUrl: isEdit ? product.imageUrl : null,
                                ),
                              ),
                              // Camera badge
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          previewBytes != null ? 'Ảnh đã chọn — nhấn để đổi' : 'Nhấn để chọn ảnh',
                          style: TextStyle(
                            fontSize: 12,
                            color: previewBytes != null ? AppTheme.primary : AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Form fields ──────────────────────────────────────────
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
                  DropdownButtonFormField<Category?>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— Không phân loại —'),
                      ),
                      ..._categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCategory = v),
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
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSaving = true);
                final data = {
                  'productName': nameController.text.trim(),
                  'sku': skuController.text.trim(),
                  'barcode': barcodeController.text.trim(),
                  'categoryId': selectedCategory?.id,
                  'costPrice': double.tryParse(costController.text) ?? 0,
                  'sellingPrice': double.parse(priceController.text),
                };
                try {
                  if (isEdit) {
                    await _productService.updateProduct(product.productId!, data);
                    if (pickedFile != null) {
                      await _productService.uploadImage(product.productId!, pickedFile!);
                    }
                  } else {
                    final created = await _productService.createProduct(data);
                    if (pickedFile != null && created.productId != null) {
                      await _productService.uploadImage(created.productId!, pickedFile!);
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadProducts();
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview ảnh trong dialog ───────────────────────────────────────────────
  Widget _buildImagePreview({Uint8List? previewBytes, String? existingUrl}) {
    if (previewBytes != null) {
      return Image.memory(previewBytes, fit: BoxFit.cover);
    }
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: AppTheme.textGrey,
          size: 32,
        ),
      ),
    );
  }

  // ── QR Code dialog ────────────────────────────────────────────────────────
  void _showQrDialog(Product product) {
    if (!mounted) return;
    final qrData = 'MNFRT:${product.productId}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Mã QR sản phẩm'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.productName,
              style: AppTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFormat.format(product.sellingPrice),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            _QrWidget(data: qrData, size: 200),
            const SizedBox(height: 12),
            Text(
              'ID: $qrData',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 8),
            Text(
              'Chụp màn hình hoặc dùng chức năng in của thiết bị để in mã',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textGrey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ── Xác nhận xóa ──────────────────────────────────────────────────────────
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
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _productService.deleteProduct(product.productId!);
                _loadProducts();
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ── Card sản phẩm ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowQr;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(child: Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  ? Image.network(
                      product.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildIconFallback(),
                    )
                  : _buildIconFallback(),
            ),
            const SizedBox(width: 12),

            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku ?? "—"}  |  ${product.barcode ?? "Chưa có barcode"}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
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

            PopupMenuButton(
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'qr',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Xem QR'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'qr') onShowQr();
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildIconFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: const Icon(Icons.shopping_basket, color: AppTheme.primary),
    );
  }
}

// ── QR widget thuần Flutter — không dùng Canvas, tương thích Flutter Web ─────
class _QrWidget extends StatelessWidget {
  final String data;
  final double size;

  const _QrWidget({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );
    final qrImage = QrImage(qrCode);
    final count = qrImage.moduleCount;

    return Container(
      width: size,
      height: size,
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final cellSize = constraints.maxWidth / count;
          return Column(
            children: List.generate(count, (row) {
              return SizedBox(
                height: cellSize,
                child: Row(
                  children: List.generate(count, (col) {
                    return SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: ColoredBox(
                        color: qrImage.isDark(row, col)
                            ? Colors.black
                            : Colors.white,
                      ),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
