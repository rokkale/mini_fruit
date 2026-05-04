import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product_stock.dart';
import '../models/inventory_ticket.dart';

class InventoryService {
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.userIdKey);
  }

  // Lấy tồn kho theo chi nhánh — backend: GET /inventory/stock/{branchId} (path param)
  Future<List<ProductStock>> getStockByBranch(int branchId) async {
    try {
      final response = await ApiClient.dio
          .get('${AppConstants.inventory}/stock/$branchId');
      return (response.data as List)
          .map((e) => ProductStock.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải tồn kho');
    }
  }

  // Backend không có endpoint GET /inventory/stock (không có branchId)
  // ADMIN không có branchId — trả về rỗng, cần chọn chi nhánh cụ thể
  Future<List<ProductStock>> getAllStock() async {
    return [];
  }

  // Backend không có endpoint GET /inventory/tickets
  // Trả về danh sách rỗng để tránh crash
  Future<List<InventoryTicket>> getTickets({int? branchId}) async {
    return [];
  }

  // Tạo phiếu nhập kho — backend: { branchId, userId, note, items }
  Future<bool> createImportTicket(InventoryTicket ticket) async {
    try {
      final userId = ticket.userId ?? await _getUserId();
      await ApiClient.dio.post(
        '${AppConstants.inventory}/import',
        data: {
          'branchId': ticket.branchId,
          'userId': userId,
          'note': ticket.note ?? '',
          'items': ticket.details?.map((e) => e.toJson()).toList(),
        },
      );
      return true;
    } catch (e) {
      throw Exception('Không thể tạo phiếu nhập');
    }
  }

  // Tạo phiếu xuất kho — backend: { branchId, userId, note, items }
  Future<bool> createExportTicket(InventoryTicket ticket) async {
    try {
      final userId = ticket.userId ?? await _getUserId();
      await ApiClient.dio.post(
        '${AppConstants.inventory}/export',
        data: {
          'branchId': ticket.branchId,
          'userId': userId,
          'note': ticket.note ?? '',
          'items': ticket.details?.map((e) => e.toJson()).toList(),
        },
      );
      return true;
    } catch (e) {
      throw Exception('Không thể tạo phiếu xuất');
    }
  }

  // Chuyển kho — backend: { fromBranchId, toBranchId, userId, note, items }
  Future<bool> createTransferTicket(InventoryTicket ticket) async {
    try {
      final userId = ticket.userId ?? await _getUserId();
      await ApiClient.dio.post(
        '${AppConstants.inventory}/transfer',
        data: {
          'fromBranchId': ticket.branchId,
          'toBranchId': ticket.toBranchId,
          'userId': userId,
          'note': ticket.note ?? '',
          'items': ticket.details?.map((e) => e.toJson()).toList(),
        },
      );
      return true;
    } catch (e) {
      throw Exception('Không thể tạo phiếu chuyển');
    }
  }
}
