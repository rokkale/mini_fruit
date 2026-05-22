import 'package:flutter/material.dart';
import '../models/store_settings.dart';
import '../services/store_settings_service.dart';

class StoreSettingsProvider extends ChangeNotifier {
  final _service = StoreSettingsService();

  StoreSettings _settings = StoreSettings.defaults();
  bool _isLoading = false;

  StoreSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// Gọi khi khởi động app — nạp cài đặt từ SharedPreferences
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _service.load();
    _isLoading = false;
    notifyListeners();
  }

  /// Lưu cài đặt mới (chỉ Admin mới được gọi)
  Future<void> save(StoreSettings newSettings) async {
    await _service.save(newSettings);
    _settings = newSettings;
    notifyListeners();
  }
}
