import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants.dart';
import '../models/order.dart';

class ReceiptService {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  final _dio = Dio();

  // ─────────────────────────────────────────────────────────────
  // Public: mở print-preview / browser print dialog
  // ─────────────────────────────────────────────────────────────
  Future<void> printReceipt(Order order) async {
    final bytes = await _buildPdf(order);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'HoaDon_${order.orderId ?? ""}',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build PDF
  // ─────────────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf(Order order) async {
    final doc   = pw.Document();
    final font  = await PdfGoogleFonts.notoSansRegular();
    final fontB = await PdfGoogleFonts.notoSansBold();

    final isTransfer = order.paymentMethod == 'TRANSFER';
    final amount     = (order.freeAmount ?? order.totalAmount).toInt();
    final addInfo    = 'DH${order.orderId ?? ""}';

    // Lấy ảnh VietQR nếu thanh toán chuyển khoản
    pw.ImageProvider? qrImage;
    if (isTransfer) {
      qrImage = await _fetchVietQR(amount, addInfo);
    }

    doc.addPage(
      pw.Page(
        // Khổ 80mm — chuẩn máy in nhiệt POS
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ───────────────────────────────────────
            pw.Center(
              child: pw.Text(
                AppConstants.storeName,
                style: pw.TextStyle(font: fontB, fontSize: 15),
              ),
            ),
            if (order.branchName != null && order.branchName!.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  order.branchName!,
                  style: pw.TextStyle(font: font, fontSize: 9,
                      color: PdfColors.grey700),
                ),
              ),
            if (AppConstants.storeAddress.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  AppConstants.storeAddress,
                  style: pw.TextStyle(font: font, fontSize: 9,
                      color: PdfColors.grey700),
                ),
              ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1),

            // ── THÔNG TIN ĐƠN ────────────────────────────────
            _infoRow('Hóa đơn #', '${order.orderId ?? ""}', font, fontB),
            _infoRow('Thời gian', _formatDate(order.createdAt), font, font),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),

            // ── DANH SÁCH SẢN PHẨM ───────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text('SẢN PHẨM',
                  style: pw.TextStyle(font: fontB, fontSize: 9)),
            ),
            if (order.details != null)
              ...order.details!.map(
                (d) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              d.productName ?? '',
                              style: pw.TextStyle(font: fontB, fontSize: 10),
                            ),
                          ),
                          pw.Text(
                            '${_currency.format(d.unitPrice * d.quantity)} đ',
                            style: pw.TextStyle(font: fontB, fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Text(
                        '  ${_currency.format(d.unitPrice)} đ  ×  ${d.quantity}',
                        style: pw.TextStyle(
                            font: font, fontSize: 9,
                            color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ),

            pw.Divider(thickness: 0.5, color: PdfColors.grey400),

            // ── TỔNG TIỀN ────────────────────────────────────
            _infoRow(
              'Tạm tính:',
              '${_currency.format(order.totalAmount)} đ',
              font, font,
            ),
            if ((order.discount ?? 0) > 0)
              _infoRow(
                'Giảm giá:',
                '- ${_currency.format(order.discount)} đ',
                font, font,
                valueColor: PdfColors.red,
              ),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            _infoRow(
              'THÀNH TIỀN:',
              '${_currency.format(order.freeAmount ?? order.totalAmount)} đ',
              fontB, fontB,
              fontSize: 13,
            ),
            pw.SizedBox(height: 3),
            _infoRow(
              'Thanh toán:',
              isTransfer ? 'Chuyển khoản' : 'Tiền mặt',
              font, font,
            ),

            // ── QR CHUYỂN KHOẢN ──────────────────────────────
            if (isTransfer) ...[
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.Center(
                child: pw.Text(
                  'QUÉT MÃ QR ĐỂ THANH TOÁN',
                  style: pw.TextStyle(font: fontB, fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 6),

              // Ảnh QR VietQR (nếu fetch được)
              if (qrImage != null)
                pw.Center(
                  child: pw.Image(qrImage, width: 150, height: 150),
                )
              else
                pw.Center(
                  child: pw.Text(
                    '(Không tải được mã QR — vui lòng chuyển khoản thủ công)',
                    style: pw.TextStyle(font: font, fontSize: 8,
                        color: PdfColors.grey),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(AppConstants.bankId,
                    style: pw.TextStyle(font: fontB, fontSize: 11)),
              ),
              pw.Center(
                child: pw.Text(AppConstants.bankAccount,
                    style: pw.TextStyle(font: fontB, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text(AppConstants.bankOwner,
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  'Nội dung CK: $addInfo',
                  style: pw.TextStyle(font: font, fontSize: 9,
                      color: PdfColors.grey700),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Số tiền: ${_currency.format(amount)} đ',
                  style: pw.TextStyle(font: fontB, fontSize: 10),
                ),
              ),
            ],

            // ── FOOTER ───────────────────────────────────────
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1),
            pw.Center(
              child: pw.Text(
                'Cảm ơn quý khách!',
                style: pw.TextStyle(font: fontB, fontSize: 11),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Hẹn gặp lại lần sau ^^',
                style: pw.TextStyle(font: font, fontSize: 9,
                    color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ─────────────────────────────────────────────────────────────
  // Fetch ảnh VietQR từ API công khai
  // ─────────────────────────────────────────────────────────────
  Future<pw.ImageProvider?> _fetchVietQR(int amount, String addInfo) async {
    try {
      final url =
          'https://img.vietqr.io/image/'
          '${AppConstants.bankBin}-${AppConstants.bankAccount}-compact2.png'
          '?amount=$amount'
          '&addInfo=${Uri.encodeComponent(addInfo)}'
          '&accountName=${Uri.encodeComponent(AppConstants.bankOwner)}';

      final res = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          // Cho phép mọi status để tránh exception khi VietQR trả lỗi
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        // Flutter Web: Dio có thể trả Uint8List hoặc List<int> tuỳ platform
        final dynamic raw = res.data;
        Uint8List bytes;
        if (raw is Uint8List) {
          bytes = raw;
        } else if (raw is List) {
          bytes = Uint8List.fromList(raw.cast<int>());
        } else {
          return null;
        }
        return pw.MemoryImage(bytes);
      }
    } catch (e) {
      // Offline hoặc CORS → bỏ qua, hóa đơn vẫn in được không có QR
      debugPrint('VietQR fetch error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  pw.Widget _infoRow(
    String label,
    String value,
    pw.Font labelFont,
    pw.Font valueFont, {
    double fontSize = 10,
    PdfColor? valueColor,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: labelFont, fontSize: fontSize)),
            pw.Text(value,
                style: pw.TextStyle(
                    font: valueFont,
                    fontSize: fontSize,
                    color: valueColor)),
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
