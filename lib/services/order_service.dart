import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/order.dart';

class OrderService {
  // Lấy tất cả đơn hàng
  Future<List<Order>> getOrders({int? branchId}) async {
    try {
      final response = await ApiClient.dio.get(
        AppConstants.orders,
        queryParameters: branchId != null ? {'branchId': branchId} : null,
      );
      return (response.data as List)
          .map((e) => Order.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách đơn hàng');
    }
  }

  // Lấy chi tiết đơn hàng
  Future<Order> getOrderById(int id) async {
    try {
      final response = await ApiClient.dio.get('${AppConstants.orders}/$id');
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể tải chi tiết đơn hàng');
    }
  }

  // Tạo đơn hàng mới (bán hàng)
  Future<Order> createOrder(Order order) async {
    try {
      final response = await ApiClient.dio.post(
        AppConstants.orders,
        data: order.toJson(),
      );
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể tạo đơn hàng');
    }
  }
}