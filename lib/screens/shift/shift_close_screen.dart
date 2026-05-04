import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class ShiftCloseScreen extends StatefulWidget {
  final double startingCash; // Nhận tiền mặt đầu ca từ Dashboard

  const ShiftCloseScreen({super.key, required this.startingCash});

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final TextEditingController _actualCashController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  int _totalOrders = 0;

  // Chi tiết doanh thu
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
    super.dispose();
  }

  Future<void> _loadShiftData() async {
    try {
      final auth = context.read<AuthProvider>();
      final orders = await _orderService.getOrders(branchId: auth.branchId);

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayOrders = orders.where((o) => o.createdAt != null && o.createdAt!.startsWith(todayStr)).toList();

      double cashRev = 0;
      double transRev = 0;

      for (var o in todayOrders) {
        double amount = (o.freeAmount ?? o.totalAmount ?? 0);
        if (o.paymentMethod == 'CASH') {
          cashRev += amount;
        } else if (o.paymentMethod == 'TRANSFER') {
          transRev += amount;
        } else {
          // Mặc định nếu không có method
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận chốt ca'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn chốt ca? Dữ liệu doanh thu sẽ được lưu lại hệ thống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Gọi API lưu phiếu chốt ca
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chốt ca thành công!'), backgroundColor: Colors.green),
              );
              // Trả về true để Dashboard biết là ca đã đóng thành công
              Navigator.pop(context, true);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Tiền mặt dự kiến trong két = Tiền đầu ca + Doanh thu Tiền mặt
    double expectedCashInDrawer = widget.startingCash + _cashRevenue;
    // Chênh lệch = Tiền đếm thực tế - Tiền dự kiến
    double difference = _actualCash - expectedCashInDrawer;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chốt ca làm việc'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_errorMessage', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadShiftData, child: const Text('Thử lại')),
          ],
        ),
      )
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(child: Icon(Icons.lock_clock, size: 64, color: Colors.orange)),
                    const SizedBox(height: 16),
                    const Center(child: Text('PHIẾU BÀN GIAO CA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        children: [
                          _buildInfoRow('Nhân viên:', auth.username ?? 'Không rõ'),
                          const Divider(height: 16),
                          _buildInfoRow('Tiền mặt đầu ca:', _currencyFormat.format(widget.startingCash), isBold: true),
                          const SizedBox(height: 8),
                          _buildInfoRow('Tổng số đơn hàng:', '$_totalOrders đơn'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Doanh thu Chuyển khoản:', _currencyFormat.format(_transferRevenue), valueColor: Colors.blue),
                          const SizedBox(height: 8),
                          _buildInfoRow('Doanh thu Tiền mặt:', _currencyFormat.format(_cashRevenue), valueColor: Colors.green),
                          const Divider(height: 16),
                          _buildInfoRow('Tổng doanh thu ca:', _currencyFormat.format(_totalRevenue), isBold: true, valueColor: AppTheme.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Chú ý: Két chỉ tính tiền mặt
                    Text('Tiền mặt dự kiến trong két: ${_currencyFormat.format(expectedCashInDrawer)}', style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),

                    const Text('Kiểm đếm tiền mặt thực tế:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _actualCashController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Nhập tổng số tiền mặt đếm được...',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _actualCash = double.tryParse(val) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: difference < 0 ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: difference < 0 ? Colors.red[200]! : Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chênh lệch quỹ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: difference < 0 ? Colors.red[700] : Colors.green[700])),
                          Text(
                            _currencyFormat.format(difference),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: difference < 0 ? Colors.red[700] : Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                    if (difference < 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('* Két đang thiếu tiền mặt so với hệ thống!', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.fact_check, color: Colors.white),
                        label: const Text('CHỐT CA LÀM VIỆC', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _confirmCloseShift,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? Colors.black87)),
      ],
    );
  }
}