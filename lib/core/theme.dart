import 'package:flutter/material.dart';

/// Hệ thống thiết kế MiniFruit — Material 3
/// ─────────────────────────────────────────────────────────────────────────────
/// Cách dùng:
///   Màu    → AppTheme.primary, AppTheme.surface …
///   Text   → AppTheme.titleMedium, AppTheme.bodySmall …
///   Space  → AppTheme.spaceMd (16), AppTheme.spaceSm (8) …
///   Radius → AppTheme.radiusMd, AppTheme.roundedMd (BorderRadius) …
///   Shadow → AppTheme.shadowSm, AppTheme.shadowMd …
/// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ───────────────────────────── COLOR TOKENS ──────────────────────────────

  // Brand — giữ nguyên để backward-compatible với code cũ
  static const Color primary      = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark  = Color(0xFF005005);
  static const Color accent       = Color(0xFFFF8F00);

  // Brand containers (nền nhạt cho chip, badge, icon bg …)
  static const Color primaryContainer = Color(0xFFB7F0B1);
  static const Color accentContainer  = Color(0xFFFFECB3);

  // Surface & Background
  static const Color background      = Color(0xFFF5F5F5); // giữ nguyên
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF2F5F1); // card trên nền xám
  static const Color white           = Colors.white;      // giữ nguyên alias

  // Text — 4 mức rõ ràng
  static const Color textDark     = Color(0xFF1A1C19); // heading
  static const Color textMedium   = Color(0xFF404942); // body
  static const Color textGrey     = Color(0xFF757575); // giữ nguyên — label, hint
  static const Color textDisabled = Color(0xFFB0B7AF); // placeholder

  // Semantic
  static const Color success          = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFB7F0B1);
  static const Color error            = Color(0xFFBA1A1A);
  static const Color errorContainer   = Color(0xFFFFDAD6);
  static const Color warning          = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color info             = Color(0xFF1565C0);
  static const Color infoContainer    = Color(0xFFBBDEFB);

  // UI chrome
  static const Color divider = Color(0xFFE4E9E0);
  static const Color border  = Color(0xFFCDD4C8);

  // ───────────────────────────── SPACING ───────────────────────────────────

  static const double spaceXs  = 4;
  static const double spaceSm  = 8;
  static const double spaceMd  = 16;
  static const double spaceLg  = 24;
  static const double spaceXl  = 32;
  static const double spaceXxl = 48;

  // ───────────────────────────── BORDER RADIUS ─────────────────────────────

  static const double radiusXs   = 4;
  static const double radiusSm   = 8;
  static const double radiusMd   = 12;
  static const double radiusLg   = 16;
  static const double radiusXl   = 24;
  static const double radiusFull = 100;

  // Shortcut BorderRadius objects
  static BorderRadius get roundedXs   => BorderRadius.circular(radiusXs);
  static BorderRadius get roundedSm   => BorderRadius.circular(radiusSm);
  static BorderRadius get roundedMd   => BorderRadius.circular(radiusMd);
  static BorderRadius get roundedLg   => BorderRadius.circular(radiusLg);
  static BorderRadius get roundedXl   => BorderRadius.circular(radiusXl);
  static BorderRadius get roundedFull => BorderRadius.circular(radiusFull);

  // ───────────────────────────── TEXT STYLES ───────────────────────────────

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: textDark, height: 1.2, letterSpacing: -0.5,
  );

  // Titles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: textDark, height: 1.3, letterSpacing: 0,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: textDark, height: 1.4,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: textDark, height: 1.4,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: textMedium, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: textMedium, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: textGrey, height: 1.4,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: textGrey, height: 1.3, letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: textGrey, height: 1.3, letterSpacing: 0.2,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: textDisabled, height: 1.2, letterSpacing: 0.3,
  );

  // Giá tiền — dùng primary thay vì redAccent
  static const TextStyle priceStyle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: primary, height: 1.3,
  );
  static const TextStyle priceLarge = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800,
    color: primary, height: 1.2,
  );

  // ───────────────────────────── SHADOWS ───────────────────────────────────

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Shadow mặc định cho card — hiển thị thường trực
  static List<BoxShadow> get shadowCard => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.07),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Shadow nâng cao khi hover — xanh nhạt + tối sâu hơn
  static List<BoxShadow> get shadowHover => [
    BoxShadow(
      color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
      blurRadius: 28,
      offset: const Offset(0, 10),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.12),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];

  // ───────────────────────────── THEME DATA ────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,

    // ColorScheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: white,
      primaryContainer: primaryContainer,
      secondary: accent,
      secondaryContainer: accentContainer,
      surface: surface,
      onSurface: textDark,
      error: error,
      errorContainer: errorContainer,
      brightness: Brightness.light,
    ),

    // Scaffold
    scaffoldBackgroundColor: background,

    // ── AppBar ──────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Color(0x1A000000),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      iconTheme: IconThemeData(color: white, size: 22),
      actionsIconTheme: IconThemeData(color: white, size: 22),
    ),

    // ── Card ────────────────────────────────────────────────────────────────
    // elevation: 0 + border = gọn gàng hơn elevation + shadow (M3 style)
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: const Color(0x14000000),
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: divider, width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── ElevatedButton ──────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        disabledBackgroundColor: border,
        disabledForegroundColor: textDisabled,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // ── Input ────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
      labelStyle: const TextStyle(color: textGrey, fontSize: 14),
      errorStyle: const TextStyle(color: error, fontSize: 12),
      prefixIconColor: textGrey,
    ),

    // ── Divider ─────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 0.8,
      space: 0,
    ),

    // ── SnackBar ────────────────────────────────────────────────────────────
    // Floating toàn cục — không cần set lại ở từng màn hình
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1A1C19),
      contentTextStyle: const TextStyle(
        color: white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      actionTextColor: primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 4,
    ),

    // ── ListTile ────────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      iconColor: textGrey,
      titleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        color: textGrey,
      ),
    ),

    // ── Dialog ──────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: 0,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: textMedium,
        height: 1.5,
      ),
    ),

    // ── Chip ────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariant,
      selectedColor: primary,
      disabledColor: surfaceVariant,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        side: const BorderSide(color: border),
      ),
      showCheckmark: true,
      checkmarkColor: white,
    ),

    // ── FloatingActionButton ─────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // ── BottomSheet ──────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusLg),
        ),
      ),
      showDragHandle: false,
      dragHandleColor: border,
    ),

    // ── Switch ───────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? white : textDisabled,
      ),
      trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? primary : border,
      ),
    ),

    // ── PopupMenu ────────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        color: textDark,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ── TabBar ───────────────────────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      indicatorColor: white,
      labelColor: white,
      unselectedLabelColor: Color(0xB3FFFFFF), // white 70%
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
    ),
  );
}
