import 'package:flutter/material.dart';

abstract final class ProtoColors {
  static const background = Color(0xFF10110F);
  static const surface = Color(0xFF1A1C19);
  static const elevated = Color(0xFF242722);
  static const lime = Color(0xFFD5F66C);
  static const text = Color(0xFFF5F5F0);
  static const muted = Color(0xFF9CA195);
  static const border = Color(0xFF30352C);
}

abstract final class ProtoTheme {
  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: ProtoColors.lime,
      brightness: Brightness.dark,
      primary: ProtoColors.lime,
      onPrimary: ProtoColors.background,
      surface: ProtoColors.surface,
      onSurface: ProtoColors.text,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: ProtoColors.background,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ProtoColors.text,
        displayColor: ProtoColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ProtoColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ProtoColors.text,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ProtoColors.border,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: ProtoColors.text, size: 22),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ProtoColors.lime,
          foregroundColor: ProtoColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ProtoColors.surface,
        hintStyle: const TextStyle(color: ProtoColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ProtoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ProtoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ProtoColors.lime),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: ProtoColors.surface,
        selectedColor: ProtoColors.lime,
        side: const BorderSide(color: ProtoColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ProtoColors.surface,
        showDragHandle: true,
        dragHandleColor: ProtoColors.muted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ProtoColors.elevated,
        contentTextStyle: const TextStyle(
          color: ProtoColors.text,
          fontFamily: 'Inter',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
      ),
    );
  }
}
