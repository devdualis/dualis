import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'app_motion.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.softIndigo,
      brightness: Brightness.light,
      primary: AppColors.softIndigo,
      secondary: AppColors.clinicalTeal,
      error: AppColors.emergencyCrimson,
      surface: AppColors.surfaceLight,
    );

    final colorScheme = baseColorScheme.copyWith(
      surface: AppColors.surfaceLight,
      error: AppColors.emergencyCrimson,
    );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600, // Inter SemiBold as mandated by Brand Manual
        height: 1.2,
        color: AppColors.dualisNavy,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600, // Inter SemiBold
        height: 1.3,
        color: AppColors.dualisNavy,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500, // Inter Medium for subtitles
        height: 1.35,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400, // Inter Regular for body
        height: 1.5,
        color: AppColors.textPrimaryLight,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Inter Regular
        height: 1.5,
        color: AppColors.textSecondaryLight,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500, // Inter Medium
        height: 1.4,
        color: AppColors.textPrimaryLight,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: appPageTransitionsTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDepth,
      dividerColor: AppColors.outlineLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDepth,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.dualisNavy,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.dualisNavy,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.softIndigo,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: AppColors.softIndigoDark,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.softIndigo,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.softIndigo, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.softIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emergencyCrimson),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emergencyCrimson, width: 2),
        ),
        errorStyle: const TextStyle(
          color: AppColors.emergencyCrimson,
          fontSize: 12,
        ),
      ),
      // Glass cards: translucent white, soft navy shadow, light edge.
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.dualisNavy.withValues(alpha: 0.35),
        elevation: 3,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassEdge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dualisSymbolBlue,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.softIndigoLight,
        disabledColor: AppColors.outlineLight,
        side: const BorderSide(color: AppColors.outlineLight),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.dualisNavy,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.dualisNavy,
        ),
        checkmarkColor: AppColors.dualisNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.surfaceLight
                : AppColors.dualisNavy.withValues(alpha: 0.08),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.dualisNavy
                : AppColors.textSecondaryLight,
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.dualisNavy,
        unselectedLabelColor: AppColors.textSecondaryLight,
        indicatorColor: AppColors.dualisSymbolBlue,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF7FFFFFF),
        modalBackgroundColor: Color(0xF7FFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: AppColors.softIndigoDark,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.dualisNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.softIndigoDark,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.dualisSymbolBlue,
      ),
    );
  }

  /// Dark theme configuration.
  ///
  /// Retains the exact same brand colors, surfaces, and typography as [lightTheme]
  /// so that the application maintains a consistent visual appearance across both
  /// light and dark system settings.
  static ThemeData get darkTheme => lightTheme;
}
