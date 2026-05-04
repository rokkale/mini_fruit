import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product_stock.dart';
import '../models/inventory_ticket.dart';

class InventoryService {
  // Lấy tồn kho theo chi nhánh
  Future<List<ProductStock>> getStockByBranch(int branchId) async {
    try {
      final response = await ApiClient.dio.get(
        '${AppConstants.inventory}/stock',
        queryParameters: {'branchId': branchId},
      );
      return (response.data as List)
          .map((e) => ProductStock.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải tồn kho');
    }
  }

  // Lấy tất cả tồn kho
  Future<List<ProductStock>> getAllStock() async {
    try {
      final response = await ApiClient.dio.get('${AppConstants.inventory}/stock');
      return (response.data as List)
          .map((e) => ProductStock.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải tồn kho');
    }
  }

  // Lấy danh sách phiếu kho
  Future<List<InventoryTicket>> getTickets({int? branchId}) async {
    try {
      final response = await ApiClient.dio.get(
        '${AppConstants.inventory}/tickets',
        queryParameters: branchId != null ? {'branchId': branchId} : null,
      );
      return (response.data as List)
          .map((e) => InventoryTicket.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải phiếu kho');
    }
  }

  // Tạo phiếu nhập kho
  Future<bool> createImportTicket(InventoryTicket ticket) async {
    try {
      await ApiClient.dio.post(
        '${AppConstants.inventory}/import',
        data: ticket.toJson(),
      );
      return true;
    } catch (e) {
      throw Exception('Không thể tạo phiếu nhập');
    }
  }

  // Tạo phiếu xuất kho
  Future<bool> createExportTicket(InventoryTicket ticket) async {
    try {
      await ApiClient.dio.post(
        '${AppConstants.inventory}/export',
        data: ticket.toJson(),
      );
      return true;
    } catch (e) {
      throw Exception('Không thể tạo phiếu xuất');
    }
  }

  // Chuyển kho
  Future<bool> createTransferTicket(InventoryTicket ticket) async {
    try {
      await ApiClient.dio.post(
        '${AppConstants.inventory}/transfer',
        data: ticket.toJson(),
      );
      return true;
    } catch (e) {
      throw Exception('Không thể tạo phiếu chuyển');
    }
  }
}