import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Kết quả kiểm tra từ SePay
class SePayResult {
  /// Đã nhận được thanh toán khớp
  final bool isPaid;
  /// Nội dung giao dịch khớp (để debug / hiển thị)
  final String? transactionContent;
  /// Lỗi nếu có (mạng, token sai, ...)
  final String? error;

  const SePayResult({
    required this.isPaid,
    this.transactionContent,
    this.error,
  });
}

/// Service gọi SePay API để phát hiện giao dịch chuyển khoản tự động.
///
/// Cách hoạt động:
///   1. SePay kết nối với tài khoản ngân hàng của bạn (qua internet banking).
///   2. Mỗi khi có biến động, SePay lưu vào database của họ.
///   3. App gọi [checkPayment] mỗi 3 giây → nếu tìm thấy giao dịch khớp
///      → trả về [SePayResult.isPaid] = true → app tự động xác nhận đơn.
///
/// Đăng ký tại: https://my.sepay.vn
/// Lấy API token tại: Cài đặt tài khoản → API token
class SePayService {
  static const String _apiUrl =
      'https://my.sepay.vn/userapi/transactions/list';

  final Dio _dio;

  SePayService() : _dio = Dio();

  /// Kiểm tra xem có giao dịch nào khớp với đơn hàng không.
  ///
  /// Tham số:
  /// - [accountNumber]: Số tài khoản ngân hàng (giống trong cài đặt QR)
  /// - [apiToken]: API token của SePay
  /// - [expectedAmount]: Số tiền cần nhận (so khớp >= để chấp nhận)
  /// - [reference]: Nội dung chuyển khoản cần khớp (ví dụ 'DH26').
  ///   Nếu rỗng → chỉ khớp theo số tiền + thời gian
  /// - [lookbackMinutes]: Chỉ xét giao dịch trong [n] phút gần nhất (mặc định 10)
  Future<SePayResult> checkPayment({
    required String accountNumber,
    required String apiToken,
    required double expectedAmount,
    String reference = '',
    int lookbackMinutes = 10,
  }) async {
    try {
      final response = await _dio.get(
        _apiUrl,
        queryParameters: {
          'account_number': accountNumber,
          'limit_transaction': 20,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        return SePayResult(
          isPaid: false,
          error: 'SePay trả về lỗi ${response.statusCode}',
        );
      }

      final data = response.data;
      final List transactions = (data['transactions'] as List?) ?? [];

      final cutoff =
          DateTime.now().subtract(Duration(minutes: lookbackMinutes));

      for (final tx in transactions) {
        // ── Kiểm tra thời gian ─────────────────────────────────────
        final dateStr = tx['transactionDate'] as String?;
        if (dateStr == null) continue;
        // SePay trả về dạng "2024-01-15 14:30:00"
        final txTime = DateTime.tryParse(dateStr);
        if (txTime == null || txTime.isBefore(cutoff)) continue;

        // ── Kiểm tra số tiền vào ───────────────────────────────────
        final rawIn = tx['amount_in'];
        final amountIn =
            double.tryParse(rawIn?.toString() ?? '0') ?? 0.0;
        if (amountIn < expectedAmount) continue;

        // ── Kiểm tra nội dung (nếu có reference) ──────────────────
        if (reference.isNotEmpty) {
          final content =
              (tx['transaction_content'] as String? ?? '').toLowerCase();
          if (!content.contains(reference.toLowerCase())) continue;
        }

        // ── Khớp! ──────────────────────────────────────────────────
        debugPrint('[SePay] ✅ Khớp giao dịch: '
            '${tx['transaction_content']} — ${amountIn.toStringAsFixed(0)}₫');
        return SePayResult(
          isPaid: true,
          transactionContent: tx['transaction_content'] as String?,
        );
      }

      return const SePayResult(isPaid: false);
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout
          ? 'Timeout khi kết nối SePay'
          : 'Lỗi mạng: ${e.message}';
      debugPrint('[SePay] ⚠️ $msg');
      return SePayResult(isPaid: false, error: msg);
    } catch (e) {
      debugPrint('[SePay] ⚠️ $e');
      return SePayResult(isPaid: false, error: e.toString());
    }
  }
}
