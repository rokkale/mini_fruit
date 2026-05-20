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
  bool _pressed = false;

  double get _scale {
    if (_hovered) return widget.scaleOnHover;
    if (_pressed) return 0.97;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: _hovered ? AppTheme.shadowHover : AppTheme.shadowCard,
            ),
            child: widget.child,
          ),
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

/// Skeleton list với shimmer — thay thế CircularProgressIndicator khi tải dữ liệu.
///
/// Dùng:
///   AppSkeletonList()
///   AppSkeletonList(itemCount: 8, hasLeading: false)
class AppSkeletonList extends StatefulWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 6,
    this.hasLeading = true,
  });

  final int itemCount;
  final bool hasLeading;

  @override
  State<AppSkeletonList> createState() => _AppSkeletonListState();
}

class _AppSkeletonListState extends State<AppSkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final gradient = LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
          colors: const [
            Color(0xFFECECEC),
            Color(0xFFF8F8F8),
            Color(0xFFECECEC),
          ],
        );
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          itemCount: widget.itemCount,
          itemBuilder: (_, __) => _SkeletonItem(
            gradient: gradient,
            hasLeading: widget.hasLeading,
          ),
        );
      },
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({required this.gradient, required this.hasLeading});

  final Gradient gradient;
  final bool hasLeading;

  Widget _box({double? width, required double height, double radius = 6}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            if (hasLeading) ...[
              _box(width: 48, height: 48, radius: AppTheme.radiusSm),
              const SizedBox(width: AppTheme.spaceMd),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(height: 14),
                  const SizedBox(height: 6),
                  _box(width: 140, height: 11),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            _box(width: 48, height: 24, radius: AppTheme.radiusSm),
          ],
        ),
      ),
    );
  }
}

/// Chuyển exception thành thông báo lỗi thân thiện.
///
///   description: AppErrorHandler.friendly(e)
class AppErrorHandler {
  AppErrorHandler._();

  static String friendly(dynamic error) {
    final s = error.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Không có kết nối mạng';
    }
    if (s.contains('401') || s.contains('Unauthorized')) {
      return 'Phiên đăng nhập hết hạn';
    }
    if (s.contains('403') || s.contains('Forbidden')) {
      return 'Không có quyền truy cập';
    }
    if (s.contains('404')) return 'Không tìm thấy dữ liệu';
    if (s.contains('500') || s.contains('502') || s.contains('503')) {
      return 'Lỗi máy chủ, thử lại sau';
    }
    if (s.contains('TimeoutException')) return 'Hết thời gian kết nối';
    return 'Đã xảy ra lỗi, thử lại sau';
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
