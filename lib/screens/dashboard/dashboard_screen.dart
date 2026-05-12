import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../products/products_screen.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../users/users_screen.dart';
import '../branches/branches_screen.dart';
import '../../models/product.dart';
import '../../models/branch.dart';
import '../../services/product_service.dart';
import '../../services/branch_service.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../shift/shift_close_screen.dart';
import '../shift/shift_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProductService _productService = ProductService();
  final BranchService _branchService = BranchService();
  final CategoryService _categoryService = CategoryService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  int? _selectedCategory;

  List<Branch> _branches = [];
  Branch? _selectedBranch;

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final TextEditingController _discountController = TextEditingController();
  bool _isDiscountPercent = false;

  bool _isShiftOpen = false;
  double _startingCash = 0.0;
  DateTime _shiftStartTime = DateTime.now();
  final TextEditingController _startingCashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load branches trước, sau đó mới restore/show shift dialog
    // để dialog luôn có danh sách chi nhánh sẵn
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
      if (mounted) _restoreAndCheckShift();
    });
  }

  Future<void> _restoreAndCheckShift() async {
    final prefs = await SharedPreferences.getInstance();
    final isOpen = prefs.getBool(AppConstants.shiftOpenKey) ?? false;
    if (isOpen) {
      final cash = prefs.getDouble(AppConstants.shiftStartingCashKey) ?? 0.0;
      final startTimeMs = prefs.getInt(AppConstants.shiftStartTimeKey);
      final savedBranchId = prefs.getInt(AppConstants.shiftBranchIdKey);
      if (mounted) {
        setState(() {
          _isShiftOpen = true;
          _startingCash = cash;
          _shiftStartTime = startTimeMs != null
              ? DateTime.fromMillisecondsSinceEpoch(startTimeMs)
              : DateTime.now();
          // Khôi phục chi nhánh đã chọn khi mở ca
          if (savedBranchId != null && _branches.isNotEmpty) {
            _selectedBranch =
                _branches.where((b) => b.id == savedBranchId).firstOrNull ??
                    _selectedBranch;
          }
        });
      }
    } else {
      _checkAndShowOpenShift();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _startingCashController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _branchService.getBranches(),
        _categoryService.getCategories(),
      ]);

      final products = results[0] as List<Product>;
      final branches = results[1] as List<Branch>;
      final categories = results[2] as List<Category>;

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _categories = categories;
          _branches = branches;

          // Chỉ set branch từ profile user nếu chưa có shift branch nào
          // (tránh ghi đè branch đã chọn khi mở ca)
          final auth = context.read<AuthProvider>();
          if (_selectedBranch == null && auth.branchId != null && !_isShiftOpen) {
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
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filterProducts();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi làm mới: $e')),
      );
    }
  }

  Future<void> _selectBranch() async {
    if (_branches.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn chi nhánh làm việc'),
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
                leading: Icon(
                  Icons.store_rounded,
                  color: isSelected ? AppTheme.primary : AppTheme.textGrey,
                ),
                title: Text(
                  branch.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.primary : AppTheme.textDark,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                    : null,
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
    if (_isShiftOpen) return;

    // Pre-select: ưu tiên branch đã lưu của user, fallback branch đầu tiên
    final auth = context.read<AuthProvider>();
    Branch? defaultBranch;
    if (auth.branchId != null) {
      defaultBranch = _branches.where((b) => b.id == auth.branchId).firstOrNull;
    }
    defaultBranch ??= _branches.isNotEmpty ? _branches.first : null;

    // Khai báo NGOÀI builder để giữ giá trị qua các lần rebuild
    Branch? selectedBranch = defaultBranch;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // selectedBranch được capture từ scope ngoài, không reset khi rebuild

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.storefront_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Mở ca làm việc'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Chọn chi nhánh ──
                  if (_branches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSm),
                      decoration: BoxDecoration(
                        color: AppTheme.warningContainer,
                        borderRadius: AppTheme.roundedSm,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppTheme.warning, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Không có chi nhánh nào. Liên hệ Admin.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<Branch>(
                      value: selectedBranch,
                      decoration: const InputDecoration(
                        labelText: 'Chi nhánh làm việc hôm nay *',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      items: _branches
                          .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b.name),
                              ))
                          .toList(),
                      onChanged: (b) => setDialogState(() => selectedBranch = b),
                    ),
                  const SizedBox(height: AppTheme.spaceMd),

                  // ── Tiền đầu ca ──
                  TextField(
                    controller: _startingCashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tiền mặt đầu ca (₫)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthProvider>().logout();
                },
                child: Text('Đăng xuất',
                    style: TextStyle(color: AppTheme.error)),
              ),
              ElevatedButton(
                // Disable nếu chưa chọn chi nhánh
                onPressed: selectedBranch == null
                    ? null
                    : () async {
                        final startingValue =
                            double.tryParse(_startingCashController.text) ?? 0;
                        final now = DateTime.now();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(AppConstants.shiftOpenKey, true);
                        await prefs.setDouble(
                            AppConstants.shiftStartingCashKey, startingValue);
                        await prefs.setInt(AppConstants.shiftStartTimeKey,
                            now.millisecondsSinceEpoch);
                        await prefs.setInt(
                            AppConstants.shiftBranchIdKey, selectedBranch!.id);
                        if (!mounted) return;
                        setState(() {
                          _isShiftOpen = true;
                          _startingCash = startingValue;
                          _shiftStartTime = now;
                          _selectedBranch = selectedBranch;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Đã mở ca tại ${selectedBranch!.name}. Bắt đầu bán hàng!'),
                          ),
                        );
                      },
                child: const Text('Mở ca'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _filterProducts() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final categoryMatch =
            _selectedCategory == null || p.categoryId == _selectedCategory;
        final keywordMatch = p.productName.toLowerCase().contains(keyword) ||
            (p.sku?.toLowerCase().contains(keyword) ?? false) ||
            (p.barcode?.toLowerCase().contains(keyword) ?? false);
        return categoryMatch && keywordMatch;
      }).toList();
    });
  }

  void _addProductToCart(Product product) {
    if (!_isShiftOpen) {
      _checkAndShowOpenShift();
      return;
    }
    final cart = context.read<CartProvider>();
    cart.addProduct(product);
    _applyDiscount(cart);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${product.productName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QrScannerPage(
          onScanned: (String value) {
            Navigator.pop(context);
            if (!value.startsWith('MNFRT:')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mã QR không hợp lệ')),
              );
              return;
            }
            final id = int.tryParse(value.substring(6));
            if (id == null) return;
            final product = _products.where((p) => p.productId == id).firstOrNull;
            if (product == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không tìm thấy sản phẩm')),
              );
              return;
            }
            _addProductToCart(product);
          },
        ),
      ),
    );
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

    int? finalBranchId = _selectedBranch?.id ?? auth.branchId;

    if (finalBranchId == null) {
      await _selectBranch();
      finalBranchId = _selectedBranch?.id;
      if (finalBranchId == null) return;
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
      final errorMsg = cart.errorMessage ?? 'Thanh toán thất bại';
      final isStockError = _isStockError(errorMsg);
      if (isStockError) {
        _showStockErrorSheet(errorMsg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  bool _isStockError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('stock') ||
        lower.contains('tồn kho') ||
        lower.contains('trong kho') ||
        lower.contains('không đủ') ||
        lower.contains('insufficient') ||
        lower.contains('out of stock') ||
        lower.contains('hết hàng') ||
        lower.contains('số lượng');
  }

  void _showStockErrorSheet(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(AppTheme.spaceMd),
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.roundedLg,
          boxShadow: AppTheme.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: AppTheme.roundedMd,
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppTheme.error, size: 22),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tồn kho không đủ',
                          style: AppTheme.titleSmall
                              .copyWith(color: AppTheme.error)),
                      const SizedBox(height: 2),
                      Text(message,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textMedium)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.warehouse_outlined, size: 18),
                label: const Text('Xem kho hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  final branchId = _selectedBranch?.id;
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryScreen(
                        readOnly: auth.isStaff,
                        shiftBranchId: branchId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceConfirm(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 48, AppTheme.spaceMd, AppTheme.spaceMd,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.roundedLg,
            boxShadow: AppTheme.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                  vertical: AppTheme.spaceSm + 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                    const SizedBox(width: AppTheme.spaceSm),
                    Text(
                      'Xác nhận thanh toán',
                      style: AppTheme.titleMedium.copyWith(color: AppTheme.primary),
                    ),
                    const Spacer(),
                    Text(
                      '${cart.itemCount} sản phẩm',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),

              // Danh sách sản phẩm
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceSm,
                  ),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceXs + 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.productName,
                                  style: AppTheme.bodyMedium,
                                ),
                                Text(
                                  '${_currencyFormat.format(item.product.sellingPrice)} × ${item.quantity}',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.textGrey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(item.subtotal),
                            style: AppTheme.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Footer tổng tiền + nút
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tạm tính:', style: AppTheme.bodyMedium),
                        Text(
                          _currencyFormat.format(cart.totalAmount),
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (cart.discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giảm giá:',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.error),
                          ),
                          Text(
                            '- ${_currencyFormat.format(cart.discount)}',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.error),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Thanh toán bằng:', style: AppTheme.bodyMedium),
                        Text(
                          cart.paymentMethod == 'CASH'
                              ? '💵 Tiền mặt'
                              : '🏦 Chuyển khoản',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const Divider(height: AppTheme.spaceMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Thành tiền:', style: AppTheme.titleSmall),
                        Text(
                          _currencyFormat.format(cart.freeAmount),
                          style: AppTheme.priceLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleCheckout(cart);
                            },
                            child: const Text(
                              'Xác nhận thanh toán',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: AppTheme.roundedFull,
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 40),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text('Thanh toán thành công!', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXs),
            Text('Đơn hàng đã được lưu', style: AppTheme.bodySmall),
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
      drawer: _buildDrawer(context, auth),
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppTheme.roundedSm,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => _filterProducts(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên, mã vạch...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  ),
                ),
              )
            : const Text('MiniFruit'),
        centerTitle: false,
        actions: [
          if (!_isSearching)
            Tooltip(
              message: _isShiftOpen ? 'Chi nhánh đã chọn khi mở ca' : 'Đổi chi nhánh',
              child: TextButton.icon(
                // Khoá đổi chi nhánh trong ca — branch gắn với ca đang mở
                onPressed: _isShiftOpen ? null : _selectBranch,
                icon: Icon(
                  _isShiftOpen ? Icons.lock_rounded : Icons.storefront_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  _selectedBranch?.name ?? 'Chọn chi nhánh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
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
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét mã QR',
            onPressed: _openScanner,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
          ),
          // Giỏ hàng (mobile)
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
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: AppTheme.roundedFull,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
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
                Expanded(
                  flex: 2,
                  child: _buildMainContent(_filteredProducts, crossAxisCount: 4),
                ),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    boxShadow: AppTheme.shadowMd,
                  ),
                  child: _buildCartContent(cart),
                ),
              ],
            );
          }
          return _buildMainContent(_filteredProducts, crossAxisCount: 3);
        },
      ),
    );
  }

  Widget _buildMainContent(List<Product> products, {required int crossAxisCount}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return AppErrorState(
        message: 'Không thể tải dữ liệu',
        description: _errorMessage,
        onRetry: _loadInitialData,
      );
    }
    if (_products.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'Chưa có sản phẩm nào',
      );
    }
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
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                child: _buildCartContent(cart, setModalState: setModalState),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsArea(List<Product> products, {required int crossAxisCount}) {
    final selectedCat = _selectedCategory == null
        ? null
        : _categories.where((c) => c.id == _selectedCategory).firstOrNull;
    final categoryLabel = selectedCat?.name ?? 'Tất cả';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          color: AppTheme.surface,
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: Text(categoryLabel),
                onPressed: () => _showCategoryDialog(context),
              ),
              const Spacer(),
              Text(
                '${products.length} sản phẩm',
                style: AppTheme.labelLarge,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductCard(products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final cartActions = context.read<CartProvider>();

    void addToCart() {
      if (!_isShiftOpen) {
        _checkAndShowOpenShift();
        return;
      }
      cartActions.addProduct(product);
      _applyDiscount(cartActions);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${product.productName}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    return HoverCard(child: Card(
      child: InkWell(
        borderRadius: AppTheme.roundedMd,
        onTap: addToCart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusMd),
                        ),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTheme.textDisabled,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.eco_outlined,
                        size: 40,
                        color: AppTheme.textDisabled,
                      ),
              ),
            ),

            // Tên & giá
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceSm,
                AppTheme.spaceSm,
                AppTheme.spaceSm,
                AppTheme.spaceXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: AppTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(product.sellingPrice),
                    style: AppTheme.priceStyle,
                  ),
                ],
              ),
            ),

            // Nút thêm
            Container(
              width: double.infinity,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusMd),
                ),
              ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                onPressed: addToCart,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCartContent(CartProvider cart, {StateSetter? setModalState}) {
    return Column(
      children: [
        // Header giỏ hàng
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            children: [
              Text('Giỏ hàng', style: AppTheme.titleMedium),
              const Spacer(),
              if (!cart.isEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  tooltip: 'Xóa tất cả',
                  visualDensity: VisualDensity.compact,
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

        // Danh sách sản phẩm
        Expanded(
          child: cart.isEmpty
              ? const AppEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  message: 'Giỏ hàng trống',
                  description: 'Chọn sản phẩm để thêm vào giỏ',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: AppTheme.spaceMd),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final Product p = item.product;
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.productName, style: AppTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                _currencyFormat.format(p.sellingPrice),
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Bộ điều chỉnh số lượng
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: AppTheme.roundedSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QtyButton(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  cart.decreaseQuantity(p.productId!);
                                  _applyDiscount(cart);
                                  if (setModalState != null) setModalState(() {});
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '${item.quantity}',
                                  style: AppTheme.titleSmall,
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  cart.increaseQuantity(p.productId!);
                                  _applyDiscount(cart);
                                  if (setModalState != null) setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMd),
                        SizedBox(
                          width: 80,
                          child: Text(
                            _currencyFormat.format(p.sellingPrice * item.quantity),
                            textAlign: TextAlign.right,
                            style: AppTheme.priceStyle,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Panel thanh toán
        if (!cart.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: AppTheme.shadowSm,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Giảm giá
                  Row(
                    children: [
                      Text('Giảm giá:', style: AppTheme.bodyMedium),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (v) {
                            _applyDiscount(cart);
                            if (setModalState != null) setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      ToggleButtons(
                        isSelected: [!_isDiscountPercent, _isDiscountPercent],
                        onPressed: (index) {
                          setState(() => _isDiscountPercent = index == 1);
                          if (setModalState != null) setModalState(() {});
                          _applyDiscount(cart);
                        },
                        color: AppTheme.textGrey,
                        selectedColor: Colors.white,
                        fillColor: AppTheme.primary,
                        borderRadius: AppTheme.roundedSm,
                        constraints:
                            const BoxConstraints(minHeight: 36, minWidth: 40),
                        children: const [
                          Text('₫', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('%', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSm),

                  // Phương thức thanh toán
                  Row(
                    children: [
                      Text('Thanh toán:', style: AppTheme.bodyMedium),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: Row(
                          children: ['CASH', 'TRANSFER'].map((method) {
                            final label =
                                method == 'CASH' ? 'Tiền mặt' : 'Chuyển khoản';
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(label,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: cart.paymentMethod == method,
                                  selectedColor: AppTheme.primary,
                                  labelStyle: TextStyle(
                                    color: cart.paymentMethod == method
                                        ? Colors.white
                                        : AppTheme.textDark,
                                  ),
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

                  // QR chuyển khoản
                  if (cart.paymentMethod == 'TRANSFER') ...[
                    const SizedBox(height: AppTheme.spaceSm),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSm),
                      decoration: BoxDecoration(
                        color: AppTheme.infoContainer,
                        borderRadius: AppTheme.roundedSm,
                        border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded,
                              size: 56, color: AppTheme.info),
                          const SizedBox(width: AppTheme.spaceSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mã QR thanh toán',
                                  style: AppTheme.titleSmall
                                      .copyWith(color: AppTheme.info),
                                ),
                                Text(
                                  'Quét mã để chuyển '
                                  '${_currencyFormat.format(cart.freeAmount)}',
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceSm),

                  // Tóm tắt tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tạm tính:', style: AppTheme.bodyMedium),
                      Text(
                        _currencyFormat.format(cart.totalAmount),
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (cart.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Giảm giá:',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.error)),
                        Text(
                          '- ${_currencyFormat.format(cart.discount)}',
                          style:
                              AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: AppTheme.spaceMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thành tiền:', style: AppTheme.titleSmall),
                      Text(
                        _currencyFormat.format(cart.freeAmount),
                        style: AppTheme.priceLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMd),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: cart.isLoading ? null : () => _showInvoiceConfirm(cart),
                      child: cart.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Thanh toán',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              // +1 cho mục "Tất cả" đầu danh sách
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // index 0 = "Tất cả"
                final isAll = index == 0;
                final cat = isAll ? null : _categories[index - 1];
                final isSelected = isAll
                    ? _selectedCategory == null
                    : _selectedCategory == cat!.id;
                return ListTile(
                  title: Text(
                    isAll ? 'Tất cả' : cat!.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : AppTheme.textDark,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat?.id;
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
          _buildDrawerHeader(auth),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
              children: _buildDrawerItems(context, auth),
            ),
          ),
          _buildDrawerFooter(context, auth),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider auth) {
    final name = auth.username ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((s) => s[0].toUpperCase()).join();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        MediaQuery.of(context).padding.top + AppTheme.spaceLg,
        AppTheme.spaceMd,
        AppTheme.spaceLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar chữ cái
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),

          // Tên đăng nhập
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Badge vai trò
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppTheme.roundedFull,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              _getRoleLabel(auth.role),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Chi nhánh hiện tại (nếu có)
          if (_selectedBranch != null) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              children: [
                Icon(Icons.storefront_rounded,
                    size: 13, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  _selectedBranch!.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DrawerItem(
            icon: Icons.lock_clock_outlined,
            label: 'Chốt ca làm việc',
            iconColor: AppTheme.warning,
            onTap: () async {
              Navigator.pop(context);
              final bool? isClosed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShiftCloseScreen(
                    startingCash: _startingCash,
                    startTime: _shiftStartTime,
                    shiftBranchId: _selectedBranch?.id,
                  ),
                ),
              );
              if (isClosed == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(AppConstants.shiftOpenKey);
                await prefs.remove(AppConstants.shiftStartingCashKey);
                await prefs.remove(AppConstants.shiftStartTimeKey);
                await prefs.remove(AppConstants.shiftBranchIdKey);
                if (!mounted) return;
                setState(() {
                  _isShiftOpen = false;
                  _startingCash = 0;
                  _selectedBranch = null;
                  _startingCashController.clear();
                });
                _checkAndShowOpenShift();
              }
            },
          ),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Đăng xuất',
            iconColor: AppTheme.error,
            labelColor: AppTheme.error,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, auth);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppTheme.spaceSm),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, AuthProvider auth) {
    final items = <Widget>[];

    // Nhóm: Bán hàng
    if (auth.isAdmin || auth.isManager || auth.isStaff) {
      items.add(_DrawerSectionLabel('Bán hàng'));
      items.add(_DrawerItem(
        icon: Icons.receipt_long_outlined,
        label: 'Lịch sử đơn hàng',
        iconColor: AppTheme.info,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrdersScreen(isSale: false, shiftBranchId: _selectedBranch?.id),
          ),
        ),
      ));
      items.add(_DrawerItem(
        icon: Icons.history_rounded,
        label: 'Lịch sử bàn giao ca',
        iconColor: AppTheme.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftHistoryScreen(shiftBranchId: _selectedBranch?.id),
          ),
        ),
      ));
    }

    // Staff: chỉ xem tồn kho, không tạo phiếu
    if (auth.isStaff) {
      items.add(_DrawerItem(
        icon: Icons.inventory_2_outlined,
        label: 'Xem kho hàng',
        iconColor: const Color(0xFF6A1B9A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventoryScreen(readOnly: true, shiftBranchId: _selectedBranch?.id),
          ),
        ),
      ));
    }

    // Nhóm: Quản lý
    final hasManagement = auth.isAdmin || auth.isManager || auth.isWarehouse;
    if (hasManagement) {
      items.add(_DrawerSectionLabel('Quản lý'));
    }
    if (auth.isAdmin || auth.isManager || auth.isWarehouse) {
      items.add(_DrawerItem(
        icon: Icons.inventory_2_outlined,
        label: 'Kho hàng',
        iconColor: const Color(0xFF6A1B9A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        ),
      ));
    }
    if (auth.isAdmin || auth.isManager) {
      items.add(_DrawerItem(
        icon: Icons.shopping_basket_outlined,
        label: 'Quản lý sản phẩm',
        iconColor: AppTheme.success,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductsScreen()),
        ),
      ));
    }

    // Nhóm: Hệ thống (chỉ Admin)
    if (auth.isAdmin) {
      items.add(_DrawerSectionLabel('Hệ thống'));
      items.add(_DrawerItem(
        icon: Icons.people_outline_rounded,
        label: 'Quản lý nhân viên',
        iconColor: AppTheme.error,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UsersScreen()),
        ),
      ));
      items.add(_DrawerItem(
        icon: Icons.store_outlined,
        label: 'Quản lý chi nhánh',
        iconColor: const Color(0xFF00796B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BranchesScreen()),
        ),
      ));
    }

    return items;
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'MANAGER':
        return 'Quản lý chi nhánh';
      case 'STAFF':
        return 'Nhân viên bán hàng';
      case 'WAREHOUSE':
        return 'Nhân viên kho';
      default:
        return 'Chưa xác định';
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

// Label nhóm menu trong drawer
class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceXs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.labelMedium.copyWith(
          letterSpacing: 0.8,
          color: AppTheme.textDisabled,
        ),
      ),
    );
  }
}

// Item menu trong drawer với icon có nền màu
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: 2,
      ),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: AppTheme.roundedSm,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: AppTheme.titleSmall.copyWith(color: labelColor),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedSm),
    );
  }
}

// Widget nút tăng/giảm số lượng trong giỏ hàng
class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.roundedSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceXs,
        ),
        child: Icon(icon, size: 18, color: AppTheme.textMedium),
      ),
    );
  }
}

// ── QR Scanner Page ───────────────────────────────────────────────────────────
class _QrScannerPage extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _QrScannerPage({required this.onScanned});

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR sản phẩm')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_scanned) return;
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value == null) return;
              _scanned = true;
              widget.onScanned(value);
            },
          ),
          // Khung ngắm giữa màn hình
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 2.5),
                borderRadius: AppTheme.roundedMd,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: AppTheme.roundedSm,
                ),
                child: const Text(
                  'Hướng camera vào mã QR sản phẩm',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
