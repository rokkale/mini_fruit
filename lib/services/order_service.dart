import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      // DEBUG: xem backend trả về key gì cho danh sách sản phẩm
      debugPrint('[OrderService] getOrderById($id) keys: ${(response.data as Map).keys.toList()}');
      debugPrint('[OrderService] raw: ${response.data}');
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể tải chi tiết đơn hàng');
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
