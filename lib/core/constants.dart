class AppConstants {
  static const String baseUrl =
      'https://minifruit-backend-production-3a79.up.railway.app/api';

  // Endpoints
  static const String login = '/auth/login';
  static const String products = '/products';
  static const String branches = '/branches';
  static const String orders = '/orders';
  static const String users = '/users';
  static const String inventory = '/inventory';
  static const String shifts = '/shifts';
  static const String categories = '/categories';

  // SharedPreferences keys
  static const String tokenKey = 'jwt_token';
  static const String usernameKey = 'username';
  static const String roleKey = 'role';
  static const String branchIdKey = 'branch_id';
  static const String userIdKey = 'user_id';

  // Shift session keys
  static const String shiftOpenKey = 'shift_is_open';
  static const String shiftStartingCashKey = 'shift_starting_cash';
  static const String shiftStartTimeKey = 'shift_start_time';
  static const String shiftBranchIdKey = 'shift_branch_id';
}