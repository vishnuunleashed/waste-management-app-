import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme-dependent surface/text tokens — these flip between the dark and
/// light palettes. Brand colors (emerald/mint/bin colors) are intentionally
/// NOT part of this since they stay constant across both themes.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surfaceCard;
  final Color surfaceCardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppColors({
    required this.background,
    required this.surfaceCard,
    required this.surfaceCardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const dark = AppColors(
    background: Color(0xFF0F172A), // Slate 900
    surfaceCard: Color(0xFF1E293B), // Slate 800
    surfaceCardBorder: Color(0xFF334155), // Slate 700
    textPrimary: Color(0xFFF8FAFC), // Slate 50
    textSecondary: Color(0xFF94A3B8), // Slate 400
    textMuted: Color(0xFF64748B), // Slate 500 — ~6.4:1 on Slate 900, passes AA
  );

  static const light = AppColors(
    background: Color(0xFFF8FAFC), // Slate 50
    surfaceCard: Color(0xFFFFFFFF),
    surfaceCardBorder: Color(0xFFE2E8F0), // Slate 200
    textPrimary: Color(0xFF0F172A), // Slate 900
    textSecondary: Color(0xFF475569), // Slate 600
    textMuted: Color(0xFF64748B), // Slate 500 — ~4.76:1 on white, passes AA
    // (was Slate 400 / #94A3B8, ~2.56:1 — failed WCAG 2.2 AA for the
    // 11-13px captions/timestamps this color is used for)
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surfaceCard,
    Color? surfaceCardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppColors(
      background: background ?? this.background,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceCardBorder: surfaceCardBorder ?? this.surfaceCardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceCardBorder: Color.lerp(surfaceCardBorder, other.surfaceCardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Ergonomic access: `context.colors.textPrimary` etc.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}

/// 4/8/12/16/24/32 spacing scale — use for padding/margins/gaps that are
/// meant to match elsewhere in the app. Genuinely one-off layout numbers
/// (hero image sizes, icon-circle diameters) don't need to fit this scale.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner-radius scale — use for card/tile/button radii.
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
}

/// App Theme & Design Tokens for Waste Classifier App
class AppTheme {
  // Brand tokens — intentionally constant across both themes.
  static const Color primaryEmerald = Color(0xFF10B981); // Emerald 500
  static const Color secondaryEmerald = Color(0xFF059669); // Emerald 600
  static const Color accentMint = Color(0xFF6EE7B7); // Emerald 300

  // Pilot Bin Color Tokens (Dublin City Council)
  static const Color greenBinRecycling = Color(0xFF16A34A); // Green bin
  static const Color brownBinCompost = Color(0xFF854D0E); // Brown bin
  static const Color blackBinGeneral = Color(0xFF334155); // Black/Grey bin
  static const Color hazardCivicAmenity = Color(0xFFB91C1C); // Hazardous/e-waste

  /// Applies the full Material 3 type scale (all 15 roles) with this
  /// theme's text colors, so screens can just use
  /// `Theme.of(context).textTheme.<role>` instead of one-off TextStyles.
  static TextTheme _textTheme(TextTheme fontTheme, AppColors colors) {
    return fontTheme.copyWith(
      displayLarge: fontTheme.displayLarge?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.bold,
      ),
      displayMedium: fontTheme.displayMedium?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.bold,
      ),
      displaySmall: fontTheme.displaySmall?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w700,
      ),
      headlineLarge: fontTheme.headlineLarge?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w700,
      ),
      headlineMedium: fontTheme.headlineMedium?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w700,
      ),
      headlineSmall: fontTheme.headlineSmall?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w700,
      ),
      titleLarge: fontTheme.titleLarge?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w600,
      ),
      titleMedium: fontTheme.titleMedium?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w600,
      ),
      titleSmall: fontTheme.titleSmall?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w600,
      ),
      bodyLarge: fontTheme.bodyLarge?.copyWith(color: colors.textPrimary),
      bodyMedium: fontTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      bodySmall: fontTheme.bodySmall?.copyWith(color: colors.textMuted),
      labelLarge: fontTheme.labelLarge?.copyWith(
        color: colors.textPrimary, fontWeight: FontWeight.w600,
      ),
      labelMedium: fontTheme.labelMedium?.copyWith(
        color: colors.textSecondary, fontWeight: FontWeight.w600,
      ),
      labelSmall: fontTheme.labelSmall?.copyWith(
        color: colors.textMuted, fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Dark Eco-Tech Theme
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final fontTheme = GoogleFonts.interTextTheme(baseTextTheme);
    const colors = AppColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: primaryEmerald,
        secondary: secondaryEmerald,
        surface: colors.surfaceCard,
        onSurface: colors.textPrimary,
        primaryContainer: const Color(0xFF064E3B),
        onPrimaryContainer: accentMint,
      ),
      extensions: const [colors],
      textTheme: _textTheme(fontTheme, colors),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceCard,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.surfaceCardBorder, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  /// Light Theme
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final fontTheme = GoogleFonts.interTextTheme(baseTextTheme);
    const colors = AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        brightness: Brightness.light,
      ).copyWith(
        surface: colors.surfaceCard,
        onSurface: colors.textPrimary,
      ),
      extensions: const [colors],
      textTheme: _textTheme(fontTheme, colors),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceCard,
        elevation: 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.surfaceCardBorder, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}
