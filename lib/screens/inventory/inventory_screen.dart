import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product_stock.dart';
import '../../models/inventory_ticket.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/branch_service.dart';
import 'inventory_create_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final branchId = auth.branchId;

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
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho hàng'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Tồn kho'),
            Tab(icon: Icon(Icons.receipt), text: 'Phiếu kho'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                const SnackBar(
                  content: Text('Tạo phiếu kho thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo phiếu', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildStockTab(),
          _buildTicketsTab(),
        ],
      ),
    );
  }

  // Tab tồn kho
  Widget _buildStockTab() {
    if (_stocks.isEmpty) {
      return const Center(child: Text('Không có dữ liệu tồn kho'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final stock = _stocks[index];
          final isLow = stock.currentStock <= (stock.minStock ?? 10);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isLow
                  ? const BorderSide(color: Colors.orange, width: 1.5)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isLow
                          ? Colors.orange.withOpacity(0.1)
                          : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isLow ? Icons.warning_amber : Icons.inventory_2,
                      color: isLow ? Colors.orange : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.productName ?? 'Sản phẩm #${stock.productId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stock.branchName ?? 'Chi nhánh #${stock.branchId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        if (isLow)
                          const Text(
                            '⚠ Tồn kho thấp',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
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
                          fontWeight: FontWeight.bold,
                          color: isLow ? Colors.orange : AppTheme.primary,
                        ),
                      ),
                      Text(
                        'Tối thiểu: ${stock.minStock ?? 10}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Tab phiếu kho
  Widget _buildTicketsTab() {
    if (_tickets.isEmpty) {
      return const Center(child: Text('Chưa có phiếu kho nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return _TicketCard(ticket: ticket);
        },
      ),
    );
  }

}

class _TicketCard extends StatelessWidget {
  final InventoryTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                typeLabels[ticket.ticketType] ?? ticket.ticketType,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.branchName ?? 'Chi nhánh #${ticket.branchId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (ticket.note != null && ticket.note!.isNotEmpty)
                    Text(
                      ticket.note!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textGrey),
                    ),
                  if (ticket.createdAt != null)
                    Text(
                      ticket.createdAt!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textGrey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}