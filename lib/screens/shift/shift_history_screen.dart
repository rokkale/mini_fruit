import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ShiftHistoryScreen extends StatelessWidget {
  const ShiftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu (Mock data) hiển thị lịch sử chốt ca
    final List<Map<String, dynamic>> mockHistory = [
      {
        'date': '04/05/2026',
        'time': '14:30 - 22:30',
        'staff': 'Trần Quang Dũng',
        'start_cash': 500000,
        'revenue': 2500000,
        'difference': 0,
        'status': 'Khớp quỹ'
      },
      {
        'date': '03/05/2026',
        'time': '06:00 - 14:00',
        'staff': 'Nguyễn Văn A',
        'start_cash': 500000,
        'revenue': 1800000,
        'difference': -20000,
        'status': 'Thiếu quỹ'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lịch sử bàn giao ca'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockHistory.length,
        itemBuilder: (context, index) {
          final item = mockHistory[index];
          final isMissing = item['difference'] < 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Icon(
                isMissing ? Icons.warning_amber_rounded : Icons.check_circle,
                color: isMissing ? Colors.red : Colors.green,
                size: 36,
              ),
              title: Text('${item['date']} (${item['time']})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Nhân viên: ${item['staff']}'),
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Tiền đầu ca:', '${item['start_cash']} ₫'),
                      _buildDetailRow('Doanh thu ca:', '${item['revenue']} ₫'),
                      _buildDetailRow(
                          'Chênh lệch:',
                          '${item['difference']} ₫',
                          color: isMissing ? Colors.red : Colors.green,
                          isBold: true
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Xem chi tiết phiếu (In lại bill chốt ca)
                          },
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('In lại phiếu'),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              )
          ),
        ],
      ),
    );
  }
}