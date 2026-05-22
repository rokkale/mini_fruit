import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

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

      // Lấy userId từ danh sách users (backend không trả userId trong login response)
      int? userId;
      try {
        final usersResp = await ApiClient.dio.get('/users');
        final users = usersResp.data as List;
        final me = users.firstWhere(
          (u) => u['username'] == username,
          orElse: () => null,
        );
        if (me != null) {
          userId = me['userId'];
          await prefs.setInt(AppConstants.userIdKey, userId!);
        }
      } catch (_) {}

      return {'success': true, 'role': role, 'branchId': branchId, 'userId': userId};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // Đăng xuất — CHỈ xóa thông tin xác thực, GIỮ LẠI shift data
  // để nhân viên tiếp theo đăng nhập trên cùng thiết bị có thể
  // tiếp tục ca đang mở mà không cần nhập lại tiền đầu ca.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.branchIdKey);
    await prefs.remove(AppConstants.userIdKey);
    // shiftOpenKey / shiftStartingCashKey / shiftStartTimeKey / shiftBranchIdKey
    // được GIỮ LẠI → ca làm việc gắn với thiết bị (chi nhánh), không gắn với user
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey) != null;
  }

  // Lấy userId từ API nếu chưa có trong cache (session cũ chưa lưu userId)
  Future<int?> fetchAndCacheUserId(String username) async {
    try {
      final response = await ApiClient.dio.get('/users');
      final users = response.data as List;
      final me = users.firstWhere(
        (u) => u['username'] == username,
        orElse: () => null,
      );
      if (me != null) {
        final userId = me['userId'] as int?;
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(AppConstants.userIdKey, userId);
        }
        return userId;
      }
    } catch (_) {}
    return null;
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(AppConstants.usernameKey),
      'role': prefs.getString(AppConstants.roleKey),
      'branchId': prefs.getInt(AppConstants.branchIdKey),
      'userId': prefs.getInt(AppConstants.userIdKey),
    };
  }

  String _handleError(dynamic e) {
    if (e.toString().contains('401')) return 'Sai tên đăng nhập hoặc mật khẩu';
    if (e.toString().contains('connection')) return 'Không kết nối được server';
    return 'Đã xảy ra lỗi, thử lại sau';
  }
}