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

  Future<Branch> createBranch(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.post(AppConstants.branches, data: data);
      return Branch.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể tạo chi nhánh');
    }
  }

  Future<Branch> updateBranch(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.put('${AppConstants.branches}/$id', data: data);
      return Branch.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể cập nhật chi nhánh');
    }
  }

  Future<void> deleteBranch(int id) async {
    try {
      await ApiClient.dio.delete('${AppConstants.branches}/$id');
    } catch (e) {
      throw Exception('Không thể xóa chi nhánh');
    }
  }
}