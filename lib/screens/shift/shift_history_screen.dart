import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/shift_service.dart';
import '../../models/shift.dart';

class ShiftHistoryScreen extends StatefulWidget {
  final int? shiftBranchId;

  const ShiftHistoryScreen({super.key, this.shiftBranchId});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  final ShiftService _shiftService = ShiftService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  bool _isLoading = true;
  String? _errorMessage;
  List<Shift> _shifts = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      // Ưu tiên shiftBranchId từ widget (ca đang mở); fallback prefs, rồi auth.branchId
      int? branchId = widget.shiftBranchId;
      if (branchId == null) {
        final prefs = await SharedPreferences.getInstance();
        branchId = prefs.getInt(AppConstants.shiftBranchIdKey) ?? auth.branchId;
      }
      if (branchId == null) throw Exception('Không xác định được chi nhánh');
      final shifts = await _shiftService.getShiftsByBranch(branchId);
      if (mounted) {
        setState(() {
          _shifts = shifts;
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

  String _formatDateTime(String? raw) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử bàn giao ca')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? AppErrorState(message: _errorMessage!, onRetry: _loadHistory)
              : _shifts.isEmpty
                  ? const AppEmptyState(message: 'Chưa có ca nào được chốt')
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      itemCount: _shifts.length,
                      itemBuilder: (context, index) {
                        final item = _shifts[index];
                        final isMissing = item.difference < 0;
                        final statusColor =
                            isMissing ? AppTheme.error : AppTheme.success;

                        return HoverCard(child: Card(
                          margin:
                              const EdgeInsets.only(bottom: AppTheme.spaceMd),
                          child: ExpansionTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isMissing
                                    ? AppTheme.errorContainer
                                    : AppTheme.successContainer,
                                borderRadius: AppTheme.roundedSm,
                              ),
                              child: Icon(
                                isMissing
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              _formatDateTime(item.endTime),
                              style: AppTheme.titleSmall,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.branchName != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.store_outlined, size: 12, color: AppTheme.textMedium),
                                      const SizedBox(width: 4),
                                      Text(item.branchName!, style: AppTheme.bodySmall),
                                    ],
                                  ),
                                Text(
                                  'NV: ${item.fullName ?? item.username ?? '--'}',
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                            children: [
                              const Divider(height: 1),
                              Padding(
                                padding:
                                    const EdgeInsets.all(AppTheme.spaceMd),
                                child: Column(
                                  children: [
                                    _DetailRow(
                                      'Chi nhánh:',
                                      item.branchName ?? 'Chi nhánh #${item.branchId ?? "--"}',
                                    ),
                                    _DetailRow(
                                      'Mở ca:',
                                      _formatDateTime(item.startTime),
                                    ),
                                    _DetailRow(
                                      'Tiền đầu ca:',
                                      _currencyFormat.format(item.openingCash),
                                    ),
                                    _DetailRow(
                                      'Doanh thu tiền mặt:',
                                      _currencyFormat.format(item.cashRevenue),
                                    ),
                                    _DetailRow(
                                      'Doanh thu chuyển khoản:',
                                      _currencyFormat
                                          .format(item.transferRevenue),
                                    ),
                                    _DetailRow(
                                      'Tổng doanh thu:',
                                      _currencyFormat.format(item.totalRevenue),
                                      isBold: true,
                                    ),
                                    _DetailRow(
                                      'Tiền mặt thực tế:',
                                      _currencyFormat.format(item.actualCash),
                                    ),
                                    _DetailRow(
                                      'Chênh lệch:',
                                      _currencyFormat.format(item.difference),
                                      color: statusColor,
                                      isBold: true,
                                    ),
                                    if (item.notes != null &&
                                        item.notes!.isNotEmpty)
                                      _DetailRow('Ghi chú:', item.notes!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ));
                      },
                    ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value,
      {this.color, this.isBold = false});

  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.textDark,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
