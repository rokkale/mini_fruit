import '../core/constants.dart';

/// Cấu hình cửa hàng & ngân hàng do Admin nhập.
/// Mọi trường đều có giá trị mặc định từ [AppConstants].
class StoreSettings {
  final String storeName;
  final String storeAddress;
  final String bankId;
  final String bankBin;
  final String bankAccount;
  final String bankOwner;
  /// API token của SePay (my.sepay.vn) — dùng để tự động xác nhận
  /// khi khách chuyển khoản mà không cần nhấn "Xác nhận thủ công".
  /// Để trống nếu chưa cấu hình (fallback: xác nhận thủ công).
  final String sePayApiToken;

  const StoreSettings({
    required this.storeName,
    required this.storeAddress,
    required this.bankId,
    required this.bankBin,
    required this.bankAccount,
    required this.bankOwner,
    this.sePayApiToken = '',
  });

  /// Giá trị mặc định lấy từ AppConstants (trước khi Admin cấu hình)
  factory StoreSettings.defaults() => const StoreSettings(
        storeName:    AppConstants.storeName,
        storeAddress: AppConstants.storeAddress,
        bankId:       AppConstants.bankId,
        bankBin:      AppConstants.bankBin,
        bankAccount:  AppConstants.bankAccount,
        bankOwner:    AppConstants.bankOwner,
        sePayApiToken: '',
      );

  StoreSettings copyWith({
    String? storeName,
    String? storeAddress,
    String? bankId,
    String? bankBin,
    String? bankAccount,
    String? bankOwner,
    String? sePayApiToken,
  }) =>
      StoreSettings(
        storeName:     storeName     ?? this.storeName,
        storeAddress:  storeAddress  ?? this.storeAddress,
        bankId:        bankId        ?? this.bankId,
        bankBin:       bankBin       ?? this.bankBin,
        bankAccount:   bankAccount   ?? this.bankAccount,
        bankOwner:     bankOwner     ?? this.bankOwner,
        sePayApiToken: sePayApiToken ?? this.sePayApiToken,
      );

  /// Cài đặt có đủ thông tin để tạo QR chuyển khoản không?
  bool get canGenerateQr =>
      bankBin.isNotEmpty && bankAccount.isNotEmpty && bankOwner.isNotEmpty;

  /// SePay đã được cấu hình → có thể tự động xác nhận thanh toán
  bool get sePayEnabled => sePayApiToken.isNotEmpty && canGenerateQr;
}
