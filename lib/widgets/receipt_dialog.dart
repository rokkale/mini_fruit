import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_widgets.dart';
import '../core/theme.dart';
import '../models/order.dart';
import '../providers/store_settings_provider.dart';
import '../services/receipt_service.dart';

/// Hiển thị hóa đơn sau khi thanh toán thành công, hoặc xem lại lịch sử.
/// Dùng chung cho dashboard_screen và orders_screen.
/// [showQr] = false → ẩn mã QR (dùng khi xem lại lịch sử, đơn đã thanh toán).
class ReceiptDialog extends StatelessWidget {
  final Order order;
  final bool showQr;

  const ReceiptDialog({super.key, required this.order, this.showQr = true});

  /// Mở dialog từ bất kỳ context nào
  static void show(BuildContext context, Order order, {bool showQr = true}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReceiptDialog(order: order, showQr: showQr),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đọc cài đặt cửa hàng từ Provider (Admin có thể thay đổi qua Cài đặt)
    final cfg = context.watch<StoreSettingsProvider>().settings;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final isTransfer = order.paymentMethod == 'TRANSFER';
    final amount = (order.freeAmount ?? order.totalAmount).toInt();
    final addInfo = Uri.encodeComponent('DH${order.orderId ?? ""}');
    final ownerEncoded = Uri.encodeComponent(cfg.bankOwner);
    final qrUrl = 'https://img.vietqr.io/image/'
        '${cfg.bankBin}-${cfg.bankAccount}-compact2.png'
        '?amount=$amount&addInfo=$addInfo&accountName=$ownerEncoded';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER xanh lá ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    cfg.storeName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  if (order.branchName != null && order.branchName!.isNotEmpty)
                    Text(
                      order.branchName!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),

            // ── NỘI DUNG HÓA ĐƠN ────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thông tin đơn
                    _infoRow(Icons.tag_rounded, 'Đơn hàng',
                        '#${order.orderId ?? ""}'),
                    _infoRow(Icons.access_time_rounded, 'Thời gian',
                        _formatDate(order.createdAt)),
                    const Divider(height: 20),

                    // Danh sách sản phẩm
                    if (order.details != null && order.details!.isNotEmpty) ...[
                      const Text(
                        'SẢN PHẨM',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      ...order.details!.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.productName ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${fmt.format(d.unitPrice)} đ  ×  ${d.quantity}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textGrey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${fmt.format(d.unitPrice * d.quantity)} đ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Fallback khi details null — hiển thị tổng quan
                      const AppEmptyState(
                        icon: Icons.receipt_outlined,
                        message: 'Chi tiết đơn hàng không khả dụng',
                      ),
                    ],

                    const Divider(height: 12),

                    // Tổng tiền
                    _amountRow('Tạm tính:',
                        '${fmt.format(order.totalAmount)} đ'),
                    if ((order.discount ?? 0) > 0)
                      _amountRow(
                        'Giảm giá:',
                        '- ${fmt.format(order.discount)} đ',
                        valueColor: AppTheme.error,
                      ),
                    const Divider(height: 12),
                    _amountRow(
                      'THÀNH TIỀN:',
                      '${fmt.format(order.freeAmount ?? order.totalAmount)} đ',
                      labelBold: true,
                      valueBold: true,
                      valueColor: AppTheme.primary,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 6),
                    _amountRow(
                      'Thanh toán:',
                      isTransfer ? '💳  Chuyển khoản' : '💵  Tiền mặt',
                    ),

                    // ── QR chuyển khoản (ẩn khi xem lịch sử) ────────────
                    if (isTransfer && showQr && !cfg.canGenerateQr) ...[
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppTheme.warning, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa cấu hình tài khoản ngân hàng.\nAdmin vào Cài đặt → Thông tin cửa hàng để thiết lập.',
                                style: TextStyle(fontSize: 12, color: AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isTransfer && showQr && cfg.canGenerateQr) ...[
                      const Divider(height: 24),
                      const Center(
                        child: Text(
                          'QUÉT MÃ QR ĐỂ CHUYỂN KHOẢN',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppTheme.textGrey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            qrUrl,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const SizedBox(
                                        width: 180,
                                        height: 180,
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()),
                                      ),
                            errorBuilder: (_, __, ___) => Container(
                              width: 180,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Không tải được mã QR',
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Thông tin tài khoản ngân hàng
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _bankRow('Ngân hàng:', cfg.bankId),
                            _bankRow('Số TK:', cfg.bankAccount),
                            _bankRow('Chủ TK:', cfg.bankOwner),
                            _bankRow(
                                'Nội dung:', 'DH${order.orderId ?? ""}'),
                            _bankRow(
                              'Số tiền:',
                              '${fmt.format(amount)} đ',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '🙏  Cảm ơn quý khách!',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textGrey),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── ACTION BUTTONS ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('In hóa đơn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ReceiptService().printReceipt(order, cfg);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppTheme.textGrey),
            const SizedBox(width: 6),
            Text('$label: ',
                style:
                    const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _amountRow(
    String label,
    String value, {
    Color? valueColor,
    bool labelBold = false,
    bool valueBold = false,
    double fontSize = 14,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight:
                        labelBold ? FontWeight.bold : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight:
                        valueBold ? FontWeight.bold : FontWeight.normal,
                    color: valueColor)),
          ],
        ),
      );

  Widget _bankRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textGrey)),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      );

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
