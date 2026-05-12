import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/shift_service.dart';
import '../../models/shift.dart';

class ShiftCloseScreen extends StatefulWidget {
  final double startingCash;
  final DateTime startTime;
  final int? shiftBranchId;

  const ShiftCloseScreen({
    super.key,
    required this.startingCash,
    required this.startTime,
    this.shiftBranchId,
  });

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  final OrderService _orderService = OrderService();
  final ShiftService _shiftService = ShiftService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final TextEditingController _actualCashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  int _totalOrders = 0;
  double _cashRevenue = 0.0;
  double _transferRevenue = 0.0;
  double _totalRevenue = 0.0;
  double _actualCash = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final branchId = widget.shiftBranchId ?? auth.branchId;
      final orders = await _orderService.getOrders(branchId: branchId);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayOrders = orders
          .where((o) => o.createdAt != null && o.createdAt!.startsWith(todayStr))
          .toList();

      double cashRev = 0;
      double transRev = 0;
      for (var o in todayOrders) {
        final amount = (o.freeAmount ?? o.totalAmount ?? 0).toDouble();
        if (o.paymentMethod == 'TRANSFER') {
          transRev += amount;
        } else {
          cashRev += amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalOrders = todayOrders.length;
          _cashRevenue = cashRev;
          _transferRevenue = transRev;
          _totalRevenue = cashRev + transRev;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _confirmCloseShift() {
    final expectedCash = widget.startingCash + _cashRevenue;
    final difference = _actualCash - expectedCash;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            SizedBox(width: AppTheme.spaceSm),
            Text('Xác nhận chốt ca'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn chốt ca? '
          'Dữ liệu doanh thu sẽ được lưu lại hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _saveShift(expectedCash, difference);
                  },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveShift(double expectedCash, double difference) async {
    final auth = context.read<AuthProvider>();
    setState(() => _isSaving = true);

    try {
      final shift = Shift(
        userId: auth.userId,
        branchId: widget.shiftBranchId ?? auth.branchId,
        startTime: widget.startTime.toIso8601String(),
        openingCash: widget.startingCash,
        cashRevenue: _cashRevenue,
        transferRevenue: _transferRevenue,
        totalRevenue: _totalRevenue,
        expectedCash: expectedCash,
        actualCash: _actualCash,
        difference: difference,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await _shiftService.closeShift(shift);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chốt ca thành công!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expectedCash = widget.startingCash + _cashRevenue;
    final difference = _actualCash - expectedCash;
    final isShort = difference < 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chốt ca làm việc'),
        backgroundColor: AppTheme.warning,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? AppErrorState(message: _errorMessage!, onRetry: _loadShiftData)
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningContainer,
                                    borderRadius: AppTheme.roundedFull,
                                  ),
                                  child: const Icon(
                                    Icons.lock_clock_outlined,
                                    size: 36,
                                    color: AppTheme.warning,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceMd),
                                Text('Phiếu bàn giao ca', style: AppTheme.titleLarge),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceLg),

                          // Thông tin ca
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              child: Column(
                                children: [
                                  _InfoRow(
                                    label: 'Nhân viên',
                                    value: auth.username ?? 'Không rõ',
                                  ),
                                  const Divider(),
                                  _InfoRow(
                                    label: 'Tiền mặt đầu ca',
                                    value: _currencyFormat.format(widget.startingCash),
                                    isBold: true,
                                  ),
                                  const SizedBox(height: AppTheme.spaceXs),
                                  _InfoRow(
                                    label: 'Tổng số đơn hàng',
                                    value: '$_totalOrders đơn',
                                  ),
                                  const SizedBox(height: AppTheme.spaceXs),
                                  _InfoRow(
                                    label: 'Doanh thu chuyển khoản',
                                    value: _currencyFormat.format(_transferRevenue),
                                    valueColor: AppTheme.info,
                                  ),
                                  const SizedBox(height: AppTheme.spaceXs),
                                  _InfoRow(
                                    label: 'Doanh thu tiền mặt',
                                    value: _currencyFormat.format(_cashRevenue),
                                    valueColor: AppTheme.success,
                                  ),
                                  const Divider(),
                                  _InfoRow(
                                    label: 'Tổng doanh thu ca',
                                    value: _currencyFormat.format(_totalRevenue),
                                    isBold: true,
                                    valueColor: AppTheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),

                          // Két dự kiến
                          Text(
                            'Tiền mặt dự kiến trong két: '
                            '${_currencyFormat.format(expectedCash)}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.warning,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),

                          // Kiểm đếm thực tế
                          Text('Kiểm đếm tiền mặt thực tế', style: AppTheme.titleSmall),
                          const SizedBox(height: AppTheme.spaceSm),
                          TextField(
                            controller: _actualCashController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Nhập tổng tiền mặt đếm được...',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            onChanged: (val) => setState(() {
                              _actualCash = double.tryParse(val) ?? 0;
                            }),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),

                          // Chênh lệch
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: isShort
                                  ? AppTheme.errorContainer
                                  : AppTheme.successContainer,
                              borderRadius: AppTheme.roundedMd,
                              border: Border.all(
                                color: isShort
                                    ? AppTheme.error.withValues(alpha: 0.4)
                                    : AppTheme.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Chênh lệch quỹ:',
                                  style: AppTheme.titleSmall.copyWith(
                                    color: isShort ? AppTheme.error : AppTheme.success,
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(difference),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: isShort ? AppTheme.error : AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isShort)
                            Padding(
                              padding: const EdgeInsets.only(top: AppTheme.spaceXs),
                              child: Text(
                                '* Két đang thiếu tiền mặt so với hệ thống!',
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.error),
                              ),
                            ),
                          const SizedBox(height: AppTheme.spaceMd),

                          // Ghi chú
                          Text('Ghi chú (tuỳ chọn)', style: AppTheme.titleSmall),
                          const SizedBox(height: AppTheme.spaceSm),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Nhập ghi chú nếu có...',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXl),

                          // Nút chốt ca
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warning,
                              ),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.fact_check_outlined),
                              label: Text(
                                _isSaving ? 'Đang lưu...' : 'Chốt ca làm việc',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: _isSaving ? null : _confirmCloseShift,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
