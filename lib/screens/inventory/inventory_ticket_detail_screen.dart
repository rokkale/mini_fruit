import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/inventory_ticket.dart';

class InventoryTicketDetailScreen extends StatefulWidget {
  final InventoryTicket ticket;

  const InventoryTicketDetailScreen({super.key, required this.ticket});

  @override
  State<InventoryTicketDetailScreen> createState() =>
      _InventoryTicketDetailScreenState();
}

class _InventoryTicketDetailScreenState
    extends State<InventoryTicketDetailScreen> {
  List<TicketDetail> _details = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.dio
          .get('${AppConstants.inventory}/tickets/${widget.ticket.ticketId}');
      final data = res.data as Map<String, dynamic>;
      final rawDetails = data['details'] as List? ?? [];
      _details = rawDetails
          .map((e) => TicketDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final typeColors = {
      'IMPORT': Colors.green,
      'EXPORT': Colors.red,
      'TRANSFER': Colors.blue,
    };
    final typeLabels = {
      'IMPORT': 'Nhập kho',
      'EXPORT': 'Xuất kho',
      'TRANSFER': 'Chuyển kho',
    };
    final color = typeColors[ticket.ticketType] ?? Colors.grey;
    final label = typeLabels[ticket.ticketType] ?? ticket.ticketType;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phiếu #${ticket.ticketId}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDetails),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetails,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header phiếu
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '#${ticket.ticketId}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.store,
                              label: ticket.ticketType == 'TRANSFER'
                                  ? 'Chi nhánh nguồn'
                                  : 'Chi nhánh',
                              value: ticket.branchName ??
                                  'Chi nhánh #${ticket.branchId}',
                            ),
                            if (ticket.ticketType == 'TRANSFER' &&
                                ticket.toBranchId != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.store_mall_directory,
                                label: 'Chi nhánh đích',
                                value: 'Chi nhánh #${ticket.toBranchId}',
                              ),
                            ],
                            if (ticket.createdAt != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.access_time,
                                label: 'Thời gian',
                                value: ticket.createdAt!,
                              ),
                            ],
                            if (ticket.note != null &&
                                ticket.note!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.note_alt_outlined,
                                label: 'Ghi chú',
                                value: ticket.note!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Danh sách sản phẩm
                    Row(
                      children: [
                        Icon(Icons.inventory_2, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Danh sách sản phẩm (${_details.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_details.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Phiếu không có sản phẩm nào',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_details.length, (i) {
                        final d = _details[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      color.withOpacity(0.1),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    d.productName ??
                                        'Sản phẩm #${d.productId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'x${d.quantity}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
