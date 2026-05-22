import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/store_settings.dart';
import '../../providers/store_settings_provider.dart';

/// Danh sách ngân hàng Việt Nam thông dụng kèm BIN.
/// Nguồn: https://img.vietqr.io/image/list
const _kBanks = [
  _BankOption('BIDV',        '970418'),
  _BankOption('Vietcombank', '970436'),
  _BankOption('Vietinbank',  '970415'),
  _BankOption('Agribank',    '970405'),
  _BankOption('Techcombank', '970407'),
  _BankOption('MBBank',      '970422'),
  _BankOption('ACB',         '970416'),
  _BankOption('TPBank',      '970423'),
  _BankOption('VPBank',      '970432'),
  _BankOption('Sacombank',   '970403'),
  _BankOption('HDBank',      '970437'),
  _BankOption('VIB',         '970441'),
  _BankOption('OCB',         '970448'),
  _BankOption('MSB',         '970426'),
  _BankOption('SHB',         '970443'),
  _BankOption('SeABank',     '970440'),
  _BankOption('Eximbank',    '970431'),
  _BankOption('NCB',         '970419'),
  _BankOption('Khác',        ''),      // Cho phép nhập BIN thủ công
];

class _BankOption {
  final String name;
  final String bin;
  const _BankOption(this.name, this.bin);
}

/// Màn hình cài đặt thông tin cửa hàng & ngân hàng.
/// Chỉ Admin mới được điều hướng tới màn hình này.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _storeNameCtrl;
  late TextEditingController _storeAddressCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _bankOwnerCtrl;
  late TextEditingController _bankBinCtrl; // dùng khi chọn "Khác"
  late TextEditingController _sePayTokenCtrl;

  _BankOption? _selectedBank;
  bool _isSaving = false;
  bool _qrPreviewKey = false; // toggle để force rebuild QR preview
  bool _sePayTokenVisible = false; // ẩn/hiện token

  @override
  void initState() {
    super.initState();
    final s = context.read<StoreSettingsProvider>().settings;

    _storeNameCtrl    = TextEditingController(text: s.storeName);
    _storeAddressCtrl = TextEditingController(text: s.storeAddress);
    _bankAccountCtrl  = TextEditingController(text: s.bankAccount);
    _bankOwnerCtrl    = TextEditingController(text: s.bankOwner);
    _bankBinCtrl      = TextEditingController();
    _sePayTokenCtrl   = TextEditingController(text: s.sePayApiToken);

    // Xác định ngân hàng đang chọn từ BIN hiện tại
    _selectedBank = _kBanks.firstWhere(
      (b) => b.bin == s.bankBin && b.bin.isNotEmpty,
      orElse: () {
        _bankBinCtrl.text = s.bankBin;
        return _kBanks.last; // "Khác"
      },
    );
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _storeAddressCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankOwnerCtrl.dispose();
    _bankBinCtrl.dispose();
    _sePayTokenCtrl.dispose();
    super.dispose();
  }

  String get _effectiveBin =>
      _selectedBank?.bin.isNotEmpty == true ? _selectedBank!.bin : _bankBinCtrl.text.trim();

  void _launchSePayUrl() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng ký SePay'),
        content: const SelectableText(
          'Truy cập địa chỉ sau trên trình duyệt:\n\nhttps://my.sepay.vn\n\nSau khi đăng ký và kết nối tài khoản ngân hàng, vào mục "API Token" để lấy token dán vào đây.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final bin = _effectiveBin;
    if (bin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã BIN ngân hàng')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newSettings = StoreSettings(
        storeName:     _storeNameCtrl.text.trim(),
        storeAddress:  _storeAddressCtrl.text.trim(),
        bankId:        _selectedBank?.name ?? 'Khác',
        bankBin:       bin,
        bankAccount:   _bankAccountCtrl.text.trim(),
        bankOwner:     _bankOwnerCtrl.text.trim(),
        sePayApiToken: _sePayTokenCtrl.text.trim(),
      );
      await context.read<StoreSettingsProvider>().save(newSettings);
      if (!mounted) return;
      setState(() => _qrPreviewKey = !_qrPreviewKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu cài đặt: $e')),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt cửa hàng & thanh toán'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Lưu cài đặt',
              onPressed: _save,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SECTION: Thông tin cửa hàng ──────────────────────────
                  _SectionHeader(
                    icon: Icons.storefront_rounded,
                    title: 'Thông tin cửa hàng',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextFormField(
                    controller: _storeNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên cửa hàng *',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập tên cửa hàng' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _storeAddressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ (tuỳ chọn)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceLg),

                  // ── SECTION: Tài khoản ngân hàng ─────────────────────────
                  _SectionHeader(
                    icon: Icons.account_balance_rounded,
                    title: 'Tài khoản nhận thanh toán',
                    color: AppTheme.info,
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSm),
                    decoration: BoxDecoration(
                      color: AppTheme.infoContainer,
                      borderRadius: AppTheme.roundedSm,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.info),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Thông tin này dùng để tạo mã QR VietQR khi khách thanh toán chuyển khoản.',
                            style: TextStyle(fontSize: 12, color: AppTheme.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),

                  // Chọn ngân hàng
                  DropdownButtonFormField<_BankOption>(
                    value: _selectedBank,
                    decoration: const InputDecoration(
                      labelText: 'Ngân hàng *',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    items: _kBanks
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.bin.isNotEmpty
                                  ? '${b.name}  (${b.bin})'
                                  : b.name),
                            ))
                        .toList(),
                    onChanged: (b) => setState(() {
                      _selectedBank = b;
                      if (b != null && b.bin.isNotEmpty) _bankBinCtrl.clear();
                    }),
                    validator: (v) => v == null ? 'Chọn ngân hàng' : null,
                  ),

                  // Nhập BIN thủ công khi chọn "Khác"
                  if (_selectedBank == _kBanks.last) ...[
                    const SizedBox(height: AppTheme.spaceSm),
                    TextFormField(
                      controller: _bankBinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mã BIN ngân hàng *',
                        hintText: 'Ví dụ: 970418',
                        prefixIcon: Icon(Icons.dialpad_rounded),
                        helperText: 'Tra cứu BIN tại img.vietqr.io/image/list',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập mã BIN'
                          : null,
                    ),
                  ],

                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _bankAccountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản *',
                      prefixIcon: Icon(Icons.credit_card_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập số tài khoản' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _bankOwnerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản *',
                      hintText: 'Ví dụ: NGUYEN VAN A',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      helperText: 'Nhập IN HOA, không dấu để QR hiển thị đúng',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập tên chủ tài khoản' : null,
                  ),

                  const SizedBox(height: AppTheme.spaceLg),

                  // ── PREVIEW MÃ QR ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Xem trước mã QR',
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _QrPreview(
                    key: ValueKey(_qrPreviewKey),
                    bin: _effectiveBin,
                    account: _bankAccountCtrl.text.trim(),
                    owner: _bankOwnerCtrl.text.trim(),
                    bankName: _selectedBank?.name ?? '',
                    storeName: _storeNameCtrl.text.trim(),
                  ),

                  const SizedBox(height: AppTheme.spaceLg),

                  // ── SECTION: Tự động xác nhận chuyển khoản (SePay) ───────
                  _SectionHeader(
                    icon: Icons.bolt_rounded,
                    title: 'Tự động xác nhận chuyển khoản',
                    color: AppTheme.warning,
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSm),
                    decoration: BoxDecoration(
                      color: AppTheme.warningContainer,
                      borderRadius: AppTheme.roundedSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: AppTheme.warning),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Khi khách chuyển khoản, app sẽ tự động phát hiện và xác nhận đơn hàng — không cần nhân viên nhấn nút.',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _launchSePayUrl(),
                          child: const Text(
                            '▶ Đăng ký miễn phí tại my.sepay.vn',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.info,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _sePayTokenCtrl,
                    obscureText: !_sePayTokenVisible,
                    decoration: InputDecoration(
                      labelText: 'SePay API Token (tuỳ chọn)',
                      hintText: 'Dán token từ my.sepay.vn',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      helperText:
                          'Để trống nếu chưa dùng SePay — nhân viên xác nhận thủ công',
                      suffixIcon: IconButton(
                        icon: Icon(_sePayTokenVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _sePayTokenVisible = !_sePayTokenVisible),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceXl),

                  // ── NÚT LƯU ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving ? 'Đang lưu...' : 'Lưu cài đặt',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget xem trước QR ──────────────────────────────────────────────────────
class _QrPreview extends StatelessWidget {
  final String bin;
  final String account;
  final String owner;
  final String bankName;
  final String storeName;

  const _QrPreview({
    super.key,
    required this.bin,
    required this.account,
    required this.owner,
    required this.bankName,
    required this.storeName,
  });

  bool get _canPreview => bin.isNotEmpty && account.isNotEmpty && owner.isNotEmpty;

  String get _qrUrl {
    final ownerEnc = Uri.encodeComponent(owner);
    return 'https://img.vietqr.io/image/'
        '$bin-$account-compact2.png'
        '?amount=100000&addInfo=Preview&accountName=$ownerEnc';
  }

  @override
  Widget build(BuildContext context) {
    if (!_canPreview) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: AppTheme.roundedMd,
          border: Border.all(color: AppTheme.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppTheme.textDisabled, size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nhập đầy đủ thông tin ngân hàng để xem trước mã QR',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.infoContainer,
        borderRadius: AppTheme.roundedMd,
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            storeName.isNotEmpty ? storeName : 'Cửa hàng',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quét mã QR để thanh toán (preview 100.000₫)',
            style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _qrUrl,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
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
                  'Không tải được QR — kiểm tra lại BIN & số tài khoản',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(bankName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(account,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(owner,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        ],
      ),
    );
  }
}

// ── Section header dùng chung ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppTheme.roundedSm,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.titleSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
