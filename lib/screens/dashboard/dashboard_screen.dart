import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../products/products_screen.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../users/users_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniFruit'),
        actions: [
          // Hiển thị tên + role
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${auth.username} (${auth.role})',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          // Nút đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, auth),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chào mừng
              Card(
                color: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.waving_hand,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${auth.username}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getRoleLabel(auth.role),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Chức năng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Grid chức năng theo role
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: _buildMenuItems(context, auth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, AuthProvider auth) {
    final items = <Widget>[];

    // Bán hàng — ADMIN, MANAGER, STAFF
    if (auth.isAdmin || auth.isManager || auth.isStaff) {
      items.add(_MenuCard(
        icon: Icons.point_of_sale,
        label: 'Bán hàng',
        color: const Color(0xFF1565C0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen(isSale: true)),
        ),
      ));
    }

    // Tồn kho — ADMIN, MANAGER, WAREHOUSE
    if (auth.isAdmin || auth.isManager || auth.isWarehouse) {
      items.add(_MenuCard(
        icon: Icons.inventory_2,
        label: 'Kho hàng',
        color: const Color(0xFF6A1B9A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        ),
      ));
    }

    // Lịch sử đơn hàng — ADMIN, MANAGER, STAFF
    if (auth.isAdmin || auth.isManager || auth.isStaff) {
      items.add(_MenuCard(
        icon: Icons.receipt_long,
        label: 'Đơn hàng',
        color: const Color(0xFF00838F),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen(isSale: false)),
        ),
      ));
    }

    // Sản phẩm — ADMIN, MANAGER
    if (auth.isAdmin || auth.isManager) {
      items.add(_MenuCard(
        icon: Icons.shopping_basket,
        label: 'Sản phẩm',
        color: const Color(0xFF2E7D32),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductsScreen()),
        ),
      ));
    }

    // Nhân viên — chỉ ADMIN
    if (auth.isAdmin) {
      items.add(_MenuCard(
        icon: Icons.people,
        label: 'Nhân viên',
        color: const Color(0xFFBF360C),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UsersScreen()),
        ),
      ));
    }

    return items;
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'ADMIN': return 'Quản trị viên';
      case 'MANAGER': return 'Quản lý chi nhánh';
      case 'STAFF': return 'Nhân viên bán hàng';
      case 'WAREHOUSE': return 'Nhân viên kho';
      default: return '';
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}