import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  String? _username;
  String? _role;
  int? _branchId;
  int? _userId;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  String? get username => _username;
  String? get role => _role;
  int? get branchId => _branchId;
  int? get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _role == 'ADMIN';
  bool get isManager => _role == 'MANAGER';
  bool get isStaff => _role == 'STAFF';
  bool get isWarehouse => _role == 'WAREHOUSE';
  bool get isAdminOrManager => isAdmin || isManager;

  // Kiểm tra token khi mở app
  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final info = await _authService.getCurrentUserInfo();
      _username = info['username'];
      _role = info['role'];
      _branchId = info['branchId'];
      _userId = info['userId'];

      // Session cũ chưa có userId → tự fetch lại
      if (_userId == null && _username != null) {
        _userId = await _authService.fetchAndCacheUserId(_username!);
      }

      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Đăng nhập
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(username, password);

    _isLoading = false;

    if (result['success']) {
      _username = username;
      _role = result['role'];
      _branchId = result['branchId'];
      _userId = result['userId'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _authService.logout();
    _username = null;
    _role = null;
    _branchId = null;
    _userId = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}