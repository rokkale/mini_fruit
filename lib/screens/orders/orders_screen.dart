import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class OrdersScreen extends StatefulWidget {
  final bool isSale;

  const OrdersScreen({super.key, required this.isSale});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.isSale ? const _SaleScreen() : const _HistoryScreen();
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
      _filtered = _products.where((p) =>
      p.productName.toLowerCase().contains(keyword.toLowerCase()) ||
          (p.barcode?.contains(keyword) ?? false),
      ).toList();
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
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => _showCartBottomSheet(context),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm sản phẩm hoặc nhập barcode...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Danh sách sản phẩm
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(child: Text('Không tìm thấy sản phẩm'))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        backgroundColor: AppTheme.primary,
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
                height: cart.isEmpty ? 0 : 80,
                child: cart.isEmpty
                    ? const SizedBox()
                    : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
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
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(cart.totalAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCartBottomSheet(context),
                        icon: const Icon(Icons.payment),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

            // Thông tin sản phẩm
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

            // Nút thêm vào giỏ
            Selector<CartProvider, int>(
              selector: (_, cart) {
                final found = cart.items.where(
                      (i) => i.product.productId == product.productId,
                );
                return found.isEmpty ? 0 : found.first.quantity;
              },
              builder: (context, quantity, _) {
                return SizedBox(
                  width: 110,
                  height: 40,
                  child: quantity > 0
                      ? Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 40,
                          child: IconButton(
                            icon: const Icon(Icons.remove,
                                color: AppTheme.primary, size: 16),
                            onPressed: () => context
                                .read<CartProvider>()
                                .decreaseQuantity(product.productId!),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 40,
                          child: IconButton(
                            icon: const Icon(Icons.add,
                                color: AppTheme.primary, size: 16),
                            onPressed: () => context
                                .read<CartProvider>()
                                .increaseQuantity(product.productId!),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Center(
                    child: IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_circle,
                          color: AppTheme.primary, size: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOTTOM SHEET GIỎ HÀNG + THANH TOÁN
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

  Future<void> _handleCheckout(CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    final branchId = auth.branchId ?? 1;

    final success = await cart.checkout(branchId);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage ?? 'Thanh toán thất bại'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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
            Text(
              'Thanh toán thành công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Tiêu đề
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Giỏ hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!cart.isEmpty)
                      TextButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Xóa tất cả',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),

              // Danh sách sản phẩm trong giỏ
              if (cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Giỏ hàng trống'),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                    minHeight: 0,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: cart.items.map((item) {
                        return ListTile(
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(
                            item.product.productName,
                            style:
                            const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            widget.currencyFormat
                                .format(item.product.sellingPrice),
                            style: const TextStyle(color: AppTheme.primary),
                          ),
                          trailing: SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppTheme.primary),
                                  onPressed: () => cart.decreaseQuantity(
                                      item.product.productId!),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: AppTheme.primary),
                                  onPressed: () => cart.increaseQuantity(
                                      item.product.productId!),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
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
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Giảm giá
                      Row(
                        children: [
                          const Text('Giảm giá:'),
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 12),

                      // Phương thức thanh toán
                      Row(
                        children: [
                          const Text('Thanh toán:'),
                          const SizedBox(width: 12),
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
                                          style: const TextStyle(fontSize: 12)),
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
                      const SizedBox(height: 12),

                      // Tổng tiền
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tạm tính:'),
                                Text(widget.currencyFormat
                                    .format(cart.totalAmount)),
                              ],
                            ),
                            if (cart.discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Giảm giá:',
                                      style: TextStyle(color: Colors.red)),
                                  Text(
                                    '- ${widget.currencyFormat.format(cart.discount)}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Thành tiền:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  widget.currencyFormat.format(cart.freeAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

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
                              : const Icon(Icons.payment),
                          label: Text(
                            cart.isLoading
                                ? 'Đang xử lý...'
                                : 'Thanh toán ${widget.currencyFormat.format(cart.freeAmount)}',
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
  const _HistoryScreen();

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
      _orders = await _orderService.getOrders(branchId: auth.branchId);
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : _orders.isEmpty
          ? const Center(child: Text('Chưa có đơn hàng nào'))
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
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

  void _showOrderDetail(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng #${order.orderId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _DetailRow('Chi nhánh:', order.branchName ?? '—'),
            _DetailRow('Khách hàng:', order.customerName ?? 'Khách lẻ'),
            _DetailRow('Thanh toán:', order.paymentMethod ?? '—'),
            _DetailRow(
                'Giảm giá:', _currencyFormat.format(order.discount ?? 0)),
            _DetailRow(
              'Thành tiền:',
              _currencyFormat.format(order.freeAmount ?? order.totalAmount),
              valueStyle: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (order.createdAt != null)
              _DetailRow('Thời gian:', order.createdAt!),
          ],
        ),
      ),
    );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_long, color: AppTheme.primary),
        ),
        title: Text(
          'Đơn #${order.orderId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          order.createdAt != null
              ? order.createdAt!.substring(0, 10)
              : 'Khách lẻ',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(order.freeAmount ?? order.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: order.paymentMethod == 'CASH'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.paymentMethod == 'CASH' ? 'Tiền mặt' : 'CK',
                style: TextStyle(
                  fontSize: 11,
                  color: order.paymentMethod == 'CASH'
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}