import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/store_settings.dart';

class StoreSettingsService {
  /// Đọc cài đặt từ SharedPreferences.
  /// Nếu chưa có → dùng giá trị mặc định từ [AppConstants].
  Future<StoreSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StoreSettings(
      storeName:     prefs.getString(AppConstants.settingsStoreNameKey)    ?? AppConstants.storeName,
      storeAddress:  prefs.getString(AppConstants.settingsStoreAddressKey) ?? AppConstants.storeAddress,
      bankId:        prefs.getString(AppConstants.settingsBankIdKey)       ?? AppConstants.bankId,
      bankBin:       prefs.getString(AppConstants.settingsBankBinKey)      ?? AppConstants.bankBin,
      bankAccount:   prefs.getString(AppConstants.settingsBankAccountKey)  ?? AppConstants.bankAccount,
      bankOwner:     prefs.getString(AppConstants.settingsBankOwnerKey)    ?? AppConstants.bankOwner,
      sePayApiToken: prefs.getString(AppConstants.settingsSePayTokenKey)   ?? '',
    );
  }

  /// Lưu cài đặt vào SharedPreferences.
  Future<void> save(StoreSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.settingsStoreNameKey,    s.storeName);
    await prefs.setString(AppConstants.settingsStoreAddressKey, s.storeAddress);
    await prefs.setString(AppConstants.settingsBankIdKey,       s.bankId);
    await prefs.setString(AppConstants.settingsBankBinKey,      s.bankBin);
    await prefs.setString(AppConstants.settingsBankAccountKey,  s.bankAccount);
    await prefs.setString(AppConstants.settingsBankOwnerKey,    s.bankOwner);
    await prefs.setString(AppConstants.settingsSePayTokenKey,   s.sePayApiToken);
  }
}
