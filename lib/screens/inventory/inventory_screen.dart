import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_widgets.dart';
import '../../models/product_stock.dart';
import '../../models/inventory_ticket.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/branch_service.dart';
import 'inventory_create_screen.dart';
import 'inventory_ticket_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  /// readOnly = true: Staff chỉ xem tồn kho, không tạo phiếu
  final bool readOnly;
  final int? shiftBranchId;

  const InventoryScreen({super.key, this.readOnly = false, this.shiftBranchId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryService _inventoryService = InventoryService();
  final BranchService _branchService = BranchService();

  List<ProductStock> _stocks = [];
  List<InventoryTicket> _tickets = [];
  List<Branch> _branches = [];
  bool _isLoading = true;
  String? _error;

  bool get _readOnly => widget.readOnly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _readOnly ? 1 : 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final branchId = widget.shiftBranchId ?? auth.branchId;

      if (_readOnly) {
        _stocks = branchId != null
            ? await _inventoryService.getStockByBranch(branchId)
            : [];
      } else {
        final results = await Future.wait([
          branchId != null
              ? _inventoryService.getStockByBranch(branchId)
              : _inventoryService.getAllStock(),
          branchId != null
              ? _inventoryService.getTickets(branchId: branchId)
              : _inventoryService.getTickets(),
          _branchService.getBranches(),
        ]);
        _stocks = results[0] as List<ProductStock>;
        _tickets = results[1] as List<InventoryTicket>;
        _branches = results[2] as List<Branch>;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_readOnly ? 'Xem kho hàng' : 'Kho hàng'),
        bottom: _readOnly
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Tồn kho'),
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Phiếu kho'),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: _readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryCreateScreen(
                      branches: _branches,
                      stocks: _stocks,
                    ),
                  ),
                );
                if (result == true) {
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo phiếu kho thành công')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo phiếu'),
            ),
      body: _isLoading
          ? const AppSkeletonList()
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _loadData)
              : _readOnly
                  ? _buildStockTab()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStockTab(),
                        _buildTicketsTab(),
                      ],
                    ),
    );
  }

  Widget _buildStockTab() {
    if (_stocks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'Chưa có dữ liệu tồn kho',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          AppTheme.spaceMd,
          AppTheme.spaceMd,
          80,
        ),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final stock = _stocks[index];
          final isLow = stock.currentStock <= (stock.minStock ?? 10);
          final color = isLow ? AppTheme.warning : AppTheme.primary;
          final bgColor = isLow ? AppTheme.warningContainer : AppTheme.primaryContainer;

          return HoverCard(child: Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            shape: isLow
                ? RoundedRectangleBorder(
                    borderRadius: AppTheme.roundedMd,
                    side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.5)),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: AppTheme.roundedSm,
                    ),
                    child: Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.productName ?? 'Sản phẩm #${stock.productId}',
                          style: AppTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stock.branchName ?? 'Chi nhánh #${stock.branchId}',
                          style: AppTheme.bodySmall,
                        ),
                        if (isLow)
                          Text(
                            'Tồn kho thấp',
                            style: AppTheme.labelLarge.copyWith(color: AppTheme.warning),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stock.currentStock}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        'Tối thiểu: ${stock.minStock ?? 10}',
                        style: AppTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget _buildTicketsTab() {
    if (_tickets.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'Chưa có phiếu kho nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          AppTheme.spaceMd,
          AppTheme.spaceMd,
          80,
        ),
        itemCount: _tickets.length,
        itemBuilder: (context, index) =>
            _TicketCard(ticket: _tickets[index]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final InventoryTicket ticket;

  const _TicketCard({required this.ticket});

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
  Widget build(BuildContext context) {
    final color = _typeColors[ticket.ticketType] ?? AppTheme.textGrey;
    final bgColor = _typeBg[ticket.ticketType] ?? AppTheme.surfaceVariant;

    return HoverCard(child: Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: InkWell(
        borderRadius: AppTheme.roundedMd,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventoryTicketDetailScreen(ticket: ticket),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppTheme.roundedSm,
                ),
                child: Text(
                  _typeLabels[ticket.ticketType] ?? ticket.ticketType,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.branchName ?? 'Chi nhánh #${ticket.branchId}',
                      style: AppTheme.titleSmall,
                    ),
                    if (ticket.note != null && ticket.note!.isNotEmpty)
                      Text(ticket.note!, style: AppTheme.bodySmall),
                    if (ticket.createdAt != null)
                      Text(ticket.createdAt!, style: AppTheme.labelSmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    ));
  }
}
