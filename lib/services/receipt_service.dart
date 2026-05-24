import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';
import '../models/store_settings.dart';

class ReceiptService {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');

  // ─────────────────────────────────────────────────────────────
  // Public: mở print-preview / browser print dialog
  // ─────────────────────────────────────────────────────────────
  Future<void> printReceipt(Order order, StoreSettings cfg) async {
    final bytes = await _buildPdf(order, cfg);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'HoaDon_${order.orderId ?? ""}',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build PDF
  // ─────────────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf(Order order, StoreSettings cfg) async {
    final doc   = pw.Document();
    final font  = await PdfGoogleFonts.notoSansRegular();
    final fontB = await PdfGoogleFonts.notoSansBold();

    final isTransfer = order.paymentMethod == 'TRANSFER';
    final amount     = (order.freeAmount ?? order.totalAmount).toInt();
    final addInfo    = 'DH${order.orderId ?? ""}';

    // Tạo chuỗi VietQR EMV cục bộ — không cần network, không bị CORS
    final String? qrData = (isTransfer && cfg.canGenerateQr)
        ? _buildVietQrString(
            bankBin:     cfg.bankBin,
            bankAccount: cfg.bankAccount,
            accountName: cfg.bankOwner,
            amount:      amount,
            addInfo:     addInfo,
          )
        : null;

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
                cfg.storeName,
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
            if (cfg.storeAddress.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  cfg.storeAddress,
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

              // Vẽ QR trực tiếp từ chuỗi VietQR EMV — không cần network
              if (qrData != null)
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 150,
                    height: 150,
                  ),
                )
              else
                pw.Center(
                  child: pw.Text(
                    '(Chưa cấu hình tài khoản ngân hàng)',
                    style: pw.TextStyle(font: font, fontSize: 8,
                        color: PdfColors.grey),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(cfg.bankId,
                    style: pw.TextStyle(font: fontB, fontSize: 11)),
              ),
              pw.Center(
                child: pw.Text(cfg.bankAccount,
                    style: pw.TextStyle(font: fontB, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text(cfg.bankOwner,
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
  // Tạo chuỗi VietQR theo chuẩn EMVCo — không cần network
  // ─────────────────────────────────────────────────────────────
  String _buildVietQrString({
    required String bankBin,
    required String bankAccount,
    required String accountName,
    required int amount,
    required String addInfo,
  }) {
    String tlv(String tag, String value) =>
        '$tag${value.length.toString().padLeft(2, '0')}$value';

    // Tag 38 — Merchant Account Info (VietQR / NAPAS)
    final guid        = tlv('00', 'A000000727');
    final beneficiary = tlv('01', tlv('00', bankBin) + tlv('01', bankAccount));
    final service     = tlv('02', 'QRIBFTTA');
    final merchantInfo = tlv('38', guid + beneficiary + service);

    // Tag 62 — Additional Data
    final additionalData = tlv('62', tlv('05', addInfo));

    final name = accountName.isEmpty ? 'Mini Fruit' : accountName;

    var qr = '';
    qr += tlv('00', '01');         // Payload Format Indicator
    qr += tlv('01', '12');         // Dynamic QR
    qr += merchantInfo;            // Merchant Account Info
    qr += tlv('52', '0000');       // MCC
    qr += tlv('53', '704');        // VND
    qr += tlv('54', '$amount');    // Amount
    qr += tlv('58', 'VN');         // Country
    qr += tlv('59', name);         // Merchant Name
    qr += tlv('60', 'Viet Nam');   // City
    qr += additionalData;
    qr += '6304';                  // CRC placeholder

    // CRC16/CCITT (polynomial 0x1021, init 0xFFFF)
    int crc = 0xFFFF;
    for (int i = 0; i < qr.length; i++) {
      crc ^= qr.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        crc = ((crc & 0x8000) != 0)
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return qr + crc.toRadixString(16).toUpperCase().padLeft(4, '0');
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
