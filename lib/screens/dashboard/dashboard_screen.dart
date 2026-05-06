import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../products/products_screen.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../users/users_screen.dart';
import '../../models/product.dart';
import '../../models/branch.dart'; // ĐÃ THÊM IMPORT MODEL BRANCH
import '../../services/product_service.dart';
import '../../services/branch_service.dart';

import '../shift/shift_close_screen.dart';
import '../shift/shift_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProductService _productService = ProductService();
  final BranchService _branchService = BranchService(); // Khởi tạo service
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<int?> _categories = [null];
  int? _selectedCategory;

  // --- TRẠNG THÁI CHI NHÁNH ---
  List<Branch> _branches = [];
  Branch? _selectedBranch;

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final TextEditingController _discountController = TextEditingController();
  bool _isDiscountPercent = false;

  // --- TRẠNG THÁI CA LÀM VIỆC ---
  bool _isShiftOpen = false;
  double _startingCash = 0.0;
  final TextEditingController _startingCashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Gọi hàm gộp chung load sản phẩm và chi nhánh

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOpenShift();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _startingCashController.dispose();
    super.dispose();
  }

  // --- TẢI DỮ LIỆU BAN ĐẦU (SẢN PHẨM & CHI NHÁNH) ---
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tải song song cả sản phẩm và chi nhánh cho nhanh
      final results = await Future.wait([
        _productService.getProducts(),
        _branchService.getBranches(),
      ]);

      final products = results[0] as List<Product>;
      final branches = results[1] as List<Branch>;

      final Set<int?> categoriesSet = {null};
      for (var p in products) {
        if (p.categoryId != null) {
          categoriesSet.add(p.categoryId);
        }
      }

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _categories = categoriesSet.toList();
          _branches = branches;

          // Lấy chi nhánh mặc định của nhân viên từ AuthProvider
          final auth = context.read<AuthProvider>();
          if (_selectedBranch == null && auth.branchId != null) {
            _selectedBranch = _branches.where((b) => b.id == auth.branchId).firstOrNull;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    // Giữ lại hàm này cho nút Refresh riêng lẻ
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filterProducts();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi làm mới: $e')));
    }
  }

  // --- CHỌN CHI NHÁNH ---
  Future<void> _selectBranch() async {
    if (_branches.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn chi nhánh làm việc', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _branches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final branch = _branches[i];
              final isSelected = _selectedBranch?.id == branch.id;
              return ListTile(
                leading: Icon(Icons.store, color: isSelected ? AppTheme.primary : Colors.grey),
                title: Text(
                    branch.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : Colors.black87,
                    )
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                onTap: () => Navigator.pop(ctx, branch.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );

    if (selectedId != null && mounted) {
      setState(() {
        _selectedBranch = _branches.firstWhere((b) => b.id == selectedId);
      });
    }
  }

  void _checkAndShowOpenShift() {
    if (!_isShiftOpen) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.storefront, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Mở ca làm việc mới'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chào mừng bạn đến với ca làm việc. Vui lòng kiểm đếm và nhập số tiền mặt hiện có trong két.'),
              const SizedBox(height: 16),
              TextField(
                controller: _startingCashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tiền mặt đầu ca (₫)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthProvider>().logout();
              },
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                double startingValue = double.tryParse(_startingCashController.text) ?? 0;
                setState(() {
                  _isShiftOpen = true;
                  _startingCash = startingValue;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã mở ca thành công! Bắt đầu bán hàng.'), backgroundColor: Colors.green),
                );
              },
              child: const Text('MỞ CA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _filterProducts() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        bool categoryMatch = _selectedCategory == null || p.categoryId == _selectedCategory;
        bool keywordMatch = p.productName.toLowerCase().contains(keyword) ||
            (p.sku?.toLowerCase().contains(keyword) ?? false) ||
            (p.barcode?.toLowerCase().contains(keyword) ?? false);
        return categoryMatch && keywordMatch;
      }).toList();
    });
  }

  void _applyDiscount(CartProvider cart) {
    double val = double.tryParse(_discountController.text) ?? 0;
    double actualDiscount = 0;

    if (_isDiscountPercent) {
      if (val > 100) val = 100;
      actualDiscount = (cart.totalAmount * val) / 100;
    } else {
      actualDiscount = val;
    }

    cart.setDiscount(actualDiscount);
  }

  Future<void> _handleCheckout(CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
      );
      return;
    }

    // Đã thay đổi: Ưu tiên lấy ID chi nhánh đang hiển thị trên thanh AppBar
    int? finalBranchId = _selectedBranch?.id ?? auth.branchId;

    if (finalBranchId == null) {
      // Nếu vẫn chưa có chi nhánh nào, bắt buộc chọn
      await _selectBranch();
      finalBranchId = _selectedBranch?.id;
      if (finalBranchId == null) return; // Nếu user ấn hủy thì dừng thanh toán
    }

    final success = await cart.checkout(finalBranchId, userId: userId);

    if (!mounted) return;

    if (success) {
      if (MediaQuery.of(context).size.width < 800 && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _discountController.clear();
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage ?? 'Thanh toán thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 12),
            Text('Thanh toán thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đơn hàng đã được lưu'),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(context, auth),
      appBar: AppBar(
        title: _isSearching
            ? Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (_) => _filterProducts(),
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Tìm tên, mã vạch...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        )
            : const Text('Mini fruit'),
        centerTitle: false,
        actions: [
          // HIỂN THỊ NÚT CHỌN CHI NHÁNH KHI KHÔNG TÌM KIẾM
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _selectBranch,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _selectedBranch?.name ?? 'Chọn chi nhánh',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterProducts();
                }
              });
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInitialData),
          LayoutBuilder(
            builder: (context, constraints) {
              if (MediaQuery.of(context).size.width < 800) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () => _showMobileCartBottomSheet(cart),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      )
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 800;
          if (isTablet) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildMainContent(_filteredProducts, crossAxisCount: 4)),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-2, 0))],
                  ),
                  child: _buildCartContent(cart),
                ),
              ],
            );
          } else {
            return _buildMainContent(_filteredProducts, crossAxisCount: 3);
          }
        },
      ),
    );
  }

  Widget _buildMainContent(List<Product> products, {required int crossAxisCount}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadInitialData, child: const Text('Thử lại'))
          ],
        ),
      );
    }
    if (_products.isEmpty) return const Center(child: Text('Không có sản phẩm nào.'));

    return _buildProductsArea(products, crossAxisCount: crossAxisCount);
  }

  void _showMobileCartBottomSheet(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.90,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _buildCartContent(cart, setModalState: setModalState),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildProductsArea(List<Product> products, {required int crossAxisCount}) {
    final categoryLabel = _selectedCategory == null ? 'Tất cả' : 'Danh mục $_selectedCategory';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_list, size: 20),
                label: Text(categoryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showCategoryDialog(context),
              ),
              const Spacer(),
              Text('${products.length} sản phẩm', style: TextStyle(color: Colors.grey[600], fontSize: 14))
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final cartActions = context.read<CartProvider>();

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!_isShiftOpen) {
            _checkAndShowOpenShift();
            return;
          }

          cartActions.addProduct(product);
          _applyDiscount(cartActions);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm ${product.productName}'), duration: const Duration(seconds: 1), backgroundColor: AppTheme.primary),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey)))
                    : const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_currencyFormat.format(product.sellingPrice), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 36,
              decoration: const BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Thêm', style: TextStyle(fontSize: 12, color: Colors.white)),
                onPressed: () {
                  if (!_isShiftOpen) {
                    _checkAndShowOpenShift();
                    return;
                  }
                  cartActions.addProduct(product);
                  _applyDiscount(cartActions);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm ${product.productName}'), duration: const Duration(seconds: 1), backgroundColor: AppTheme.primary));
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartProvider cart, {StateSetter? setModalState}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giỏ hàng hiện tại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (!cart.isEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Xóa tất cả',
                  onPressed: () {
                    cart.clearCart();
                    _discountController.clear();
                    _applyDiscount(cart);
                    if (setModalState != null) setModalState(() {});
                  },
                ),
            ],
          ),
        ),

        Expanded(
          child: cart.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Chưa có sản phẩm nào', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              final Product p = item.product;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(_currencyFormat.format(p.sellingPrice), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            cart.decreaseQuantity(p.productId!);
                            _applyDiscount(cart);
                            if (setModalState != null) setModalState(() {});
                          },
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.remove, size: 18)),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () {
                            cart.increaseQuantity(p.productId!);
                            _applyDiscount(cart);
                            if (setModalState != null) setModalState(() {});
                          },
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.add, size: 18)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(_currencyFormat.format(p.sellingPrice * item.quantity), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                ],
              );
            },
          ),
        ),

        if (!cart.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Giảm giá:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (v) {
                            _applyDiscount(cart);
                            if (setModalState != null) setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: [!_isDiscountPercent, _isDiscountPercent],
                        onPressed: (index) {
                          setState(() => _isDiscountPercent = index == 1);
                          if (setModalState != null) setModalState(() {});
                          _applyDiscount(cart);
                        },
                        color: Colors.grey,
                        selectedColor: Colors.white,
                        fillColor: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 40),
                        children: const [
                          Text('₫', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text('Thanh toán:'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: ['CASH', 'TRANSFER'].map((method) {
                            final label = method == 'CASH' ? 'Tiền mặt' : 'Chuyển khoản';
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(label, style: const TextStyle(fontSize: 12)),
                                  selected: cart.paymentMethod == method,
                                  selectedColor: AppTheme.primary,
                                  labelStyle: TextStyle(color: cart.paymentMethod == method ? Colors.white : AppTheme.textDark),
                                  onSelected: (_) {
                                    cart.setPaymentMethod(method);
                                    if (setModalState != null) setModalState(() {});
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (cart.paymentMethod == 'TRANSFER')
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_2, size: 70, color: Colors.blue),
                          const SizedBox(height: 4),
                          const Text('MÃ QR THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                          Text('Quét mã để chuyển ${_currencyFormat.format(cart.freeAmount)}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tạm tính:'),
                      Text(_currencyFormat.format(cart.totalAmount)),
                    ],
                  ),
                  if (cart.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giảm giá:', style: TextStyle(color: Colors.red)),
                        Text('- ${_currencyFormat.format(cart.discount)}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thành tiền:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        _currencyFormat.format(cart.freeAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: cart.isLoading ? null : () => _handleCheckout(cart),
                      child: cart.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('THANH TOÁN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn phân loại'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final catId = _categories[index];
                final label = catId == null ? 'Tất cả' : 'Danh mục $catId';

                return ListTile(
                  title: Text(label, style: TextStyle(fontWeight: _selectedCategory == catId ? FontWeight.bold : FontWeight.normal, color: _selectedCategory == catId ? AppTheme.primary : Colors.black87)),
                  trailing: _selectedCategory == catId ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = catId;
                      _filterProducts();
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            accountName: Text('${auth.username} (${auth.role})', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_getRoleLabel(auth.role)),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: AppTheme.primary)),
          ),
          Expanded(child: ListView(padding: EdgeInsets.zero, children: _buildDrawerItems(context, auth))),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.lock_clock, color: Colors.orange),
            title: const Text('Chốt ca làm việc', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () async {
              Navigator.pop(context);

              final bool? isClosed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShiftCloseScreen(startingCash: _startingCash)),
              );

              if (isClosed == true) {
                setState(() {
                  _isShiftOpen = false;
                  _startingCash = 0;
                  _startingCashController.clear();
                });
                _checkAndShowOpenShift();
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, auth);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, AuthProvider auth) {
    final items = <Widget>[];
    if (auth.isAdmin || auth.isManager || auth.isStaff) {
      items.add(ListTile(leading: const Icon(Icons.receipt_long, color: Color(0xFF00838F)), title: const Text('Lịch sử đơn hàng'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(isSale: false)))));
      items.add(ListTile(leading: const Icon(Icons.history, color: Colors.teal), title: const Text('Lịch sử bàn giao ca'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftHistoryScreen()))));
    }
    if (auth.isAdmin || auth.isManager || auth.isWarehouse) {
      items.add(ListTile(leading: const Icon(Icons.inventory_2, color: Color(0xFF6A1B9A)), title: const Text('Kho hàng'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()))));
    }
    if (auth.isAdmin || auth.isManager) {
      items.add(ListTile(leading: const Icon(Icons.shopping_basket, color: Color(0xFF2E7D32)), title: const Text('Quản lý sản phẩm'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))));
    }
    if (auth.isAdmin) {
      items.add(ListTile(leading: const Icon(Icons.people, color: Color(0xFFBF360C)), title: const Text('Nhân viên'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()))));
    }
    return items;
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'ADMIN': return 'Quản trị viên';
      case 'MANAGER': return 'Quản lý chi nhánh';
      case 'STAFF': return 'Nhân viên bán hàng';
      case 'WAREHOUSE': return 'Nhân viên kho';
      default: return 'Chưa xác định';
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}