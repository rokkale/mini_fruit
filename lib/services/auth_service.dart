import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  // Đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiClient.dio.post(
        AppConstants.login,
        data: {'username': username, 'password': password},
      );

      final data = response.data;
      final token = data['token'];
      final role = data['role'];
      final branchId = data['branchId'];

      // Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.usernameKey, username);
      await prefs.setString(AppConstants.roleKey, role);
      if (branchId != null) {
        await prefs.setInt(AppConstants.branchIdKey, branchId);
      }

      return {'success': true, 'role': role, 'branchId': branchId};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey) != null;
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(AppConstants.usernameKey),
      'role': prefs.getString(AppConstants.roleKey),
      'branchId': prefs.getInt(AppConstants.branchIdKey),
    };
  }

  String _handleError(dynamic e) {
    if (e.toString().contains('401')) return 'Sai tên đăng nhập hoặc mật khẩu';
    if (e.toString().contains('connection')) return 'Không kết nối được server';
    return 'Đã xảy ra lỗi, thử lại sau';
  }
}