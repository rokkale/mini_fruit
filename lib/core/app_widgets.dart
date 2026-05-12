import 'package:flutter/material.dart';
import 'theme.dart';

// ─── HoverCard ─────────────────────────────────────────────────────────────
/// Bọc bất kỳ widget nào với hiệu ứng:
///   • Đổ bóng nâng cao khi hover (web/desktop)
///   • Phóng to nhẹ (scale 1.03) khi di chuột vào
///   • Trên mobile không có hover → hiển thị bình thường
///
/// Dùng:
///   HoverCard(child: Card(...))
class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTheme.radiusMd)),
    this.scaleOnHover = 1.03,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double scaleOnHover;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.scaleOnHover : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: _hovered ? AppTheme.shadowHover : AppTheme.shadowCard,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hiển thị khi danh sách rỗng hoặc chưa có dữ liệu.
///
/// Dùng:
///   AppEmptyState(message: 'Chưa có đơn hàng nào')
///   AppEmptyState(icon: Icons.inventory_2_outlined, message: '...', action: ...)
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.description,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? description;

  /// Tuỳ chọn: nút hành động (VD: "Thêm mới", "Thử lại")
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: AppTheme.roundedFull,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppTheme.textDisabled,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              message,
              style: AppTheme.titleSmall.copyWith(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                description!,
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spaceLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Hiển thị khi có lỗi tải dữ liệu — luôn kèm nút "Thử lại".
///
/// Dùng:
///   AppErrorState(onRetry: _loadData)
///   AppErrorState(message: 'Không thể kết nối server', onRetry: _loadData)
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message = 'Đã xảy ra lỗi',
    this.description,
    required this.onRetry,
  });

  final String message;
  final String? description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: AppTheme.roundedFull,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              message,
              style: AppTheme.titleSmall.copyWith(color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                description!,
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppTheme.spaceLg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
