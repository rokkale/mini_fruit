import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.sellingPrice * quantity;

  // Tạo bản copy mới khi thay đổi quantity
  CartItem copyWith({int? quantity}) => CartItem(
    product: product,
    quantity: quantity ?? this.quantity,
  );
}

class CartProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  // Dùng List.from() để tạo list mới mỗi khi thay đổi
  List<CartItem> _items = [];
  String _paymentMethod = 'CASH';
  double _discount = 0;
  int? _customerId;
  bool _isLoading = false;
  String? _errorMessage;
  Order? _lastOrder;

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  String get paymentMethod => _paymentMethod;
  double get discount => _discount;
  int? get customerId => _customerId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Order? get lastOrder => _lastOrder;
  bool get isEmpty => _items.isEmpty;

  double get totalAmount =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  double get freeAmount => totalAmount - _discount;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // Thêm sản phẩm vào giỏ
  void addProduct(Product product) {
    final index = _items.indexWhere(
          (item) => item.product.productId == product.productId,
    );

    if (index >= 0) {
      // Tạo list mới với item được update
      final newItems = List<CartItem>.from(_items);
      newItems[index] = newItems[index].copyWith(
        quantity: newItems[index].quantity + 1,
      );
      _items = newItems;
    } else {
      // Thêm sản phẩm mới vào list mới
      _items = [..._items, CartItem(product: product)];
    }
    notifyListeners();
  }

  // Tăng số lượng
  void increaseQuantity(int productId) {
    final index = _items.indexWhere(
          (item) => item.product.productId == productId,
    );
    if (index >= 0) {
      final newItems = List<CartItem>.from(_items);
      newItems[index] = newItems[index].copyWith(
        quantity: newItems[index].quantity + 1,
      );
      _items = newItems;
      notifyListeners();
    }
  }

  // Giảm số lượng
  void decreaseQuantity(int productId) {
    final index = _items.indexWhere(
          (item) => item.product.productId == productId,
    );
    if (index >= 0) {
      final newItems = List<CartItem>.from(_items);
      if (newItems[index].quantity > 1) {
        newItems[index] = newItems[index].copyWith(
          quantity: newItems[index].quantity - 1,
        );
        _items = newItems;
      } else {
        newItems.removeAt(index);
        _items = newItems;
      }
      notifyListeners();
    }
  }

  // Xóa sản phẩm
  void removeProduct(int productId) {
    _items = _items
        .where((item) => item.product.productId != productId)
        .toList();
    notifyListeners();
  }

  // Xóa toàn bộ giỏ
  void clearCart() {
    _items = [];
    _discount = 0;
    _customerId = null;
    _paymentMethod = 'CASH';
    _lastOrder = null;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value > totalAmount ? totalAmount : value;
    notifyListeners();
  }

  void setCustomerId(int? id) {
    _customerId = id;
    notifyListeners();
  }

  // Thanh toán
  Future<bool> checkout(int branchId) async {
    if (_items.isEmpty) {
      _errorMessage = 'Giỏ hàng trống';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = Order(
        branchId: branchId,
        customerId: _customerId,
        totalAmount: totalAmount,
        discount: _discount,
        freeAmount: freeAmount,
        paymentMethod: _paymentMethod,
        details: _items
            .map((item) => OrderDetail(
          productId: item.product.productId!,
          productName: item.product.productName,
          quantity: item.quantity,
          unitPrice: item.product.sellingPrice,
        ))
            .toList(),
      );

      _lastOrder = await _orderService.createOrder(order);
      _isLoading = false;
      clearCart();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}