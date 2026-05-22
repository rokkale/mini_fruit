import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/order.dart';

class OrderService {
  // Lấy đơn hàng theo chi nhánh — backend chỉ có /orders/branch/{branchId}
  Future<List<Order>> getOrders({int? branchId}) async {
    try {
      final endpoint = branchId != null
          ? '${AppConstants.orders}/branch/$branchId'
          : AppConstants.orders;
      final response = await ApiClient.dio.get(endpoint);
      return (response.data as List).map((e) => Order.fromJson(e)).toList();
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

  /// Lấy danh sách sản phẩm của đơn hàng từ endpoint phụ /orders/{id}/details
  /// Trả về null nếu endpoint không tồn tại hoặc không có dữ liệu.
  Future<List<OrderDetail>?> getOrderDetails(int id) async {
    try {
      final response =
          await ApiClient.dio.get('${AppConstants.orders}/$id/details');
      final data = response.data;
      if (data == null) return null;
      if (data is List) {
        if (data.isEmpty) return null;
        return data
            .map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Một số backend bọc trong {"data": [...]} hoặc {"orderDetails": [...]}
      if (data is Map) {
        for (final key in [
          'data',
          'details',
          'orderDetails',
          'order_details',
          'items'
        ]) {
          final raw = data[key];
          if (raw != null && raw is List && raw.isNotEmpty) {
            return raw
                .map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return null;
    } catch (_) {
      // Endpoint không tồn tại → trả null, không throw
      return null;
    }
  }

  // Tạo đơn hàng mới — backend yêu cầu: branchId, userId, customerId, paymentMethod, discount, items
  Future<Order> createOrder(Order order) async {
    try {
      final response = await ApiClient.dio.post(
        AppConstants.orders,
        data: order.toJson(),
      );
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      // Đọc message thật từ backend response thay vì throw chung chung
      final data = e.response?.data;
      String message = 'Không thể tạo đơn hàng';
      if (data is Map) {
        message = data['message'] ?? data['error'] ?? data['msg'] ?? message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Không thể tạo đơn hàng');
    }
  }
}
