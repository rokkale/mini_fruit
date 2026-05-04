import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/branch.dart';

class BranchService {
  Future<List<Branch>> getBranches() async {
    try {
      final response = await ApiClient.dio.get(AppConstants.branches);
      return (response.data as List)
          .map((e) => Branch.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách chi nhánh');
    }
  }
}