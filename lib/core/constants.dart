class AppConstants {
  static const String baseUrl =
      'https://minifruit-backend-production-f318.up.railway.app/api';

  // Endpoints
  static const String login = '/auth/login';
  static const String products = '/products';
  static const String branches = '/branches';
  static const String orders = '/orders';
  static const String users = '/users';
  static const String inventory = '/inventory';

  // SharedPreferences keys
  static const String tokenKey = 'jwt_token';
  static const String usernameKey = 'username';
  static const String roleKey = 'role';
  static const String branchIdKey = 'branch_id';
  static const String userIdKey = 'user_id';
}