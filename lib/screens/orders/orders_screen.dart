import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/branch_service.dart';
import '../../widgets/receipt_dialog.dart';

class OrdersScreen extends StatefulWidget {
  final bool isSale;
  final int? shiftBranchId;

  const OrdersScreen({super.key, required this.isSale, this.shiftBranchId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.isSale
        ? const _SaleScreen()
        : _HistoryScreen(shiftBranchId: widget.shiftBranchId);
  }
}

// ─────────────────────────────────────────
// MÀN HÌNH BÁN HÀNG
// ─────────────────────────────────────────
class _SaleScreen extends StatefulWidget {
  const _SaleScreen();

  @override
  State<_SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<_SaleScreen> {
  final ProductService _productService = ProductService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    try {
      _products = await _productService.getProducts();
      _filtered = _products;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _search(String keyword) {
    setState(() {
      _filtered = _products
          .where((p) =>
              p.productName.toLowerCase().contains(keyword.toLowerCase()) ||
              (p.barcode?.contains(keyword) ?? false))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bán hàng'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => _showCartBottomSheet(context),
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
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm sản phẩm hoặc nhập barcode...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppSkeletonList()
                : _filtered.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.search_off_rounded,
                        message: 'Không tìm thấy sản phẩm',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spaceMd,
                          0,
                          AppTheme.spaceMd,
                          AppTheme.spaceMd,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final product = _filtered[index];
                          return _ProductSaleCard(
                            product: product,
                            currencyFormat: _currencyFormat,
                            onAdd: () {
                              context.read<CartProvider>().addProduct(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã thêm ${product.productName}'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),

          // Thanh tổng tiền
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: cart.isEmpty ? 0 : 72,
                child: cart.isEmpty
                    ? const SizedBox()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMd,
                          vertical: AppTheme.spaceSm,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          boxShadow: AppTheme.shadowSm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${cart.itemCount} sản phẩm',
                                    style: AppTheme.labelLarge,
                                  ),
                                  Text(
                                    _currencyFormat.format(cart.totalAmount),
                                    style: AppTheme.priceStyle.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showCartBottomSheet(context),
                              icon: const Icon(Icons.payment_rounded, size: 18),
                              label: const Text('Thanh toán'),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CartBottomSheet(currencyFormat: _currencyFormat),
    );
  }
}

// ─────────────────────────────────────────
// CARD SẢN PHẨM TRONG MÀN HÌNH BÁN HÀNG
// ─────────────────────────────────────────
class _ProductSaleCard extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFormat;
  final VoidCallback onAdd;

  const _ProductSaleCard({
    required this.product,
    required this.currencyFormat,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(child: Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: AppTheme.roundedSm,
              ),
              child: const Icon(Icons.eco_outlined, color: AppTheme.primary),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: AppTheme.titleSmall),
                  Text(
                    currencyFormat.format(product.sellingPrice),
                    style: AppTheme.priceStyle,
                  ),
                ],
              ),
            ),
            Selector<CartProvider, int>(
              selector: (_, cart) {
                final found = cart.items.where(
                    (i) => i.product.productId == product.productId);
                return found.isEmpty ? 0 : found.first.quantity;
              },
              builder: (context, quantity, _) {
                if (quantity > 0) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: AppTheme.roundedSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded,
                              color: AppTheme.primary, size: 18),
                          onPressed: () => context
                              .read<CartProvider>()
                              .decreaseQuantity(product.productId!),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          '$quantity',
                          style: AppTheme.titleSmall.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded,
                              color: AppTheme.primary, size: 18),
                          onPressed: () => context
                              .read<CartProvider>()
                              .increaseQuantity(product.productId!),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }
                return IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppTheme.primary, size: 32),
                  padding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────
// BOTTOM SHEET GIỎ HÀNG
// ─────────────────────────────────────────
class _CartBottomSheet extends StatefulWidget {
  final NumberFormat currencyFormat;

  const _CartBottomSheet({required this.currencyFormat});

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> {
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<int?> _pickBranch() async {
    final branches = await BranchService().getBranches();
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn chi nhánh bán hàng'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: branches.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(branches[i].name),
              onTap: () => Navigator.pop(ctx, branches[i].id),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được người dùng, vui lòng đăng nhập lại'),
        ),
      );
      return;
    }

    int? branchId = auth.branchId;
    if (branchId == null) {
      branchId = await _pickBranch();
      if (branchId == null) return;
    }

    final success = await cart.checkout(branchId, userId: userId);
    if (!mounted) return;

    if (success) {
      // Phải lấy lastOrder TRƯỚC khi pop — sau khi pop context bị detach,
      // context.read() sẽ không còn truy cập được Provider
      final order = cart.lastOrder;
      Navigator.pop(context); // đóng bottom sheet
      _showReceiptDialog(order);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage ?? 'Thanh toán thất bại'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showReceiptDialog(Order? order) {
    if (order == null) return;
    ReceiptDialog.show(context, order);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: AppTheme.roundedFull,
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Row(
                  children: [
                    Text('Giỏ hàng', style: AppTheme.titleMedium),
                    const Spacer(),
                    if (!cart.isEmpty)
                      TextButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Xóa tất cả',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Danh sách
              if (cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceXl),
                  child: AppEmptyState(
                    icon: Icons.shopping_cart_outlined,
                    message: 'Giỏ hàng trống',
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: cart.items.map((item) {
                        return ListTile(
                          title: Text(item.product.productName,
                              style: AppTheme.titleSmall),
                          subtitle: Text(
                            widget.currencyFormat
                                .format(item.product.sellingPrice),
                            style: AppTheme.priceStyle.copyWith(fontSize: 13),
                          ),
                          trailing: SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: AppTheme.primary,
                                  ),
                                  onPressed: () => cart.decreaseQuantity(
                                      item.product.productId!),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: AppTheme.titleSmall,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppTheme.primary,
                                  ),
                                  onPressed: () => cart.increaseQuantity(
                                      item.product.productId!),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () => cart.removeProduct(
                                      item.product.productId!),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              if (!cart.isEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                  ),
                  child: Column(
                    children: [
                      // Giảm giá
                      Row(
                        children: [
                          Text('Giảm giá:', style: AppTheme.bodyMedium),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                suffixText: '₫',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onChanged: (v) =>
                                  cart.setDiscount(double.tryParse(v) ?? 0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSm),

                      // Phương thức
                      Row(
                        children: [
                          Text('Thanh toán:', style: AppTheme.bodyMedium),
                          const SizedBox(width: AppTheme.spaceSm),
                          Expanded(
                            child: Row(
                              children: ['CASH', 'TRANSFER'].map((method) {
                                final label = method == 'CASH'
                                    ? 'Tiền mặt'
                                    : 'Chuyển khoản';
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: ChoiceChip(
                                      label: Text(label,
                                          style:
                                              const TextStyle(fontSize: 12)),
                                      selected: cart.paymentMethod == method,
                                      selectedColor: AppTheme.primary,
                                      labelStyle: TextStyle(
                                        color: cart.paymentMethod == method
                                            ? Colors.white
                                            : AppTheme.textDark,
                                      ),
                                      onSelected: (_) =>
                                          cart.setPaymentMethod(method),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSm),

                      // Tổng tiền
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: AppTheme.roundedSm,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tạm tính:', style: AppTheme.bodyMedium),
                                Text(
                                  widget.currencyFormat
                                      .format(cart.totalAmount),
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                            if (cart.discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Giảm giá:',
                                      style: AppTheme.bodyMedium
                                          .copyWith(color: AppTheme.error)),
                                  Text(
                                    '- ${widget.currencyFormat.format(cart.discount)}',
                                    style: AppTheme.bodyMedium
                                        .copyWith(color: AppTheme.error),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Thành tiền:', style: AppTheme.titleSmall),
                                Text(
                                  widget.currencyFormat.format(cart.freeAmount),
                                  style: AppTheme.priceLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),

                      // Nút thanh toán
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: cart.isLoading
                              ? null
                              : () => _handleCheckout(cart),
                          icon: cart.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.payment_rounded),
                          label: Text(
                            cart.isLoading
                                ? 'Đang xử lý...'
                                : 'Thanh toán '
                                    '${widget.currencyFormat.format(cart.freeAmount)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// MÀN HÌNH LỊCH SỬ ĐƠN HÀNG
// ─────────────────────────────────────────
class _HistoryScreen extends StatefulWidget {
  final int? shiftBranchId;

  const _HistoryScreen({this.shiftBranchId});

  @override
  State<_HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<_HistoryScreen> {
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      // Ưu tiên branchId từ ca đang mở; fallback branchId profile
      final branchId = widget.shiftBranchId ?? auth.branchId;
      _orders = await _orderService.getOrders(branchId: branchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const AppSkeletonList()
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _loadOrders)
              : _orders.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'Chưa có đơn hàng nào',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _OrderCard(
                            order: order,
                            currencyFormat: _currencyFormat,
                            onTap: () => _showOrderDetail(context, order),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _showOrderDetail(BuildContext context, Order order) async {
    Order fullOrder = order;

    // Nếu chưa có danh sách sản phẩm → thử fetch từ /orders/{id}/details
    if (order.details == null || order.details!.isEmpty) {
      if (!context.mounted) return;

      // Hiện loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Đang tải chi tiết...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Thử endpoint /orders/{id}/details trước
        final details =
            await _orderService.getOrderDetails(order.orderId!);

        if (details != null && details.isNotEmpty) {
          // Có dữ liệu từ sub-endpoint → ghép vào order
          fullOrder = Order(
            orderId: order.orderId,
            branchId: order.branchId,
            branchName: order.branchName,
            userId: order.userId,
            customerId: order.customerId,
            customerName: order.customerName,
            totalAmount: order.totalAmount,
            discount: order.discount,
            freeAmount: order.freeAmount,
            paymentMethod: order.paymentMethod,
            createdAt: order.createdAt,
            details: details,
          );
        } else {
          // Fallback: gọi /orders/{id} (thường không có details, nhưng thử vẫn đúng)
          fullOrder = await _orderService.getOrderById(order.orderId!);
        }
      } catch (_) {
        fullOrder = order;
      }

      if (!context.mounted) return;
      Navigator.pop(context); // đóng loading
    }

    if (!context.mounted) return;
    // Hiện bill, ẩn QR (đơn đã thanh toán xong rồi)
    ReceiptDialog.show(context, fullOrder, showQr: false);
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCash = order.paymentMethod == 'CASH';
    final methodColor = isCash ? AppTheme.success : AppTheme.info;
    final methodBg = isCash ? AppTheme.successContainer : AppTheme.infoContainer;

    return HoverCard(child: Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: AppTheme.roundedSm,
          ),
          child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
        ),
        title: Text('Đơn #${order.orderId}', style: AppTheme.titleSmall),
        subtitle: Text(
          order.createdAt != null
              ? order.createdAt!.substring(0, 10)
              : 'Khách lẻ',
          style: AppTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(order.freeAmount ?? order.totalAmount),
              style: AppTheme.priceStyle,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: methodBg,
                borderRadius: AppTheme.roundedXs,
              ),
              child: Text(
                isCash ? 'Tiền mặt' : 'CK',
                style: TextStyle(fontSize: 11, color: methodColor),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

