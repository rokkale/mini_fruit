import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
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

  static const _typeColors = {
    'IMPORT': AppTheme.success,
    'EXPORT': AppTheme.error,
    'TRANSFER': AppTheme.info,
  };
  static const _typeLabels = {
    'IMPORT': 'Nhập kho',
    'EXPORT': 'Xuất kho',
    'TRANSFER': 'Chuyển kho',
  };
  static const _typeBg = {
    'IMPORT': AppTheme.successContainer,
    'EXPORT': AppTheme.errorContainer,
    'TRANSFER': AppTheme.infoContainer,
  };

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
    final color = _typeColors[ticket.ticketType] ?? AppTheme.textGrey;
    final bgColor = _typeBg[ticket.ticketType] ?? AppTheme.surfaceVariant;
    final label = _typeLabels[ticket.ticketType] ?? ticket.ticketType;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phiếu #${ticket.ticketId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _loadDetails)
              : ListView(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  children: [
                    // Header phiếu
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.roundedMd,
                        side: BorderSide(
                          color: color.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: AppTheme.roundedSm,
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '#${ticket.ticketId}',
                                  style: AppTheme.titleSmall.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            _InfoRow(
                              icon: Icons.store_rounded,
                              label: ticket.ticketType == 'TRANSFER'
                                  ? 'Chi nhánh nguồn'
                                  : 'Chi nhánh',
                              value: ticket.branchName ??
                                  'Chi nhánh #${ticket.branchId}',
                            ),
                            if (ticket.ticketType == 'TRANSFER' &&
                                ticket.toBranchId != null) ...[
                              const SizedBox(height: AppTheme.spaceSm),
                              _InfoRow(
                                icon: Icons.store_mall_directory_outlined,
                                label: 'Chi nhánh đích',
                                value: 'Chi nhánh #${ticket.toBranchId}',
                              ),
                            ],
                            if (ticket.createdAt != null) ...[
                              const SizedBox(height: AppTheme.spaceSm),
                              _InfoRow(
                                icon: Icons.access_time_rounded,
                                label: 'Thời gian',
                                value: ticket.createdAt!,
                              ),
                            ],
                            if (ticket.note != null &&
                                ticket.note!.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spaceSm),
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

                    const SizedBox(height: AppTheme.spaceMd),

                    // Tiêu đề danh sách
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 18, color: AppTheme.primary),
                        const SizedBox(width: AppTheme.spaceXs),
                        Text(
                          'Danh sách sản phẩm (${_details.length})',
                          style: AppTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),

                    if (_details.isEmpty)
                      const AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        message: 'Phiếu không có sản phẩm nào',
                      )
                    else
                      ...List.generate(_details.length, (i) {
                        final d = _details[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: AppTheme.roundedMd,
                            border: Border.all(color: AppTheme.divider),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceMd,
                                vertical: AppTheme.spaceSm),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: bgColor,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMd),
                                Expanded(
                                  child: Text(
                                    d.productName ?? 'Sản phẩm #${d.productId}',
                                    style: AppTheme.titleSmall,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: AppTheme.roundedSm,
                                  ),
                                  child: Text(
                                    'x${d.quantity}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
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
        const SizedBox(width: AppTheme.spaceSm),
        Text(
          '$label: ',
          style: AppTheme.bodySmall,
        ),
        Expanded(
          child: Text(value, style: AppTheme.bodyMedium),
        ),
      ],
    );
  }
}
