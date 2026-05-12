import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/shift.dart';

class ShiftService {
  Future<Shift> closeShift(Shift shift) async {
    try {
      final response = await ApiClient.dio.post(
        AppConstants.shifts,
        data: shift.toJson(),
      );
      return Shift.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể lưu ca làm việc');
    }
  }

  Future<List<Shift>> getShiftsByBranch(int branchId) async {
    try {
      final response = await ApiClient.dio.get(
        '${AppConstants.shifts}/branch/$branchId',
      );
      return (response.data as List).map((e) => Shift.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Không thể tải lịch sử bàn giao ca');
    }
  }
}
