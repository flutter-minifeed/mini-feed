import 'package:flutter/material.dart';

// Figma 파운데이션 146:2711의 Light 값. 화면에서는 Theme.of(context)를 사용한다.
final _colors = const ColorScheme.light().copyWith(
  primary: const Color(0xFF111111),
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: const Color(0xFFE8E8E8),
  onPrimaryContainer: const Color(0xFF111111),
  secondaryContainer: const Color(0xFFEDEDED),
  onSecondaryContainer: const Color(0xFF111111),
  surface: const Color(0xFFFFFFFF),
  onSurface: const Color(0xFF111111),
  onSurfaceVariant: const Color(0xFF5E5E5E),
  surfaceContainerLow: const Color(0xFFF7F7F7),
  surfaceContainer: const Color(0xFFF1F1F1),
  surfaceContainerHigh: const Color(0xFFEAEAEA),
  surfaceContainerHighest: const Color(0xFFE2E2E2),
  outline: const Color(0xFF8C8C8C),
  outlineVariant: const Color(0xFFE2E2E2),
  error: const Color(0xFFD93025),
  onError: const Color(0xFFFFFFFF),
  inverseSurface: const Color(0xFF2A2A2A),
  onInverseSurface: const Color(0xFFF2F2F2),
  inversePrimary: const Color(0xFFE0E0E0),
  scrim: const Color(0xFF000000),
);

TextStyle _text(double size, double lineHeight, FontWeight weight) => TextStyle(
  fontFamily: 'NotoSansKR',
  fontSize: size,
  height: lineHeight / size,
  fontWeight: weight,
  letterSpacing: 0,
);

final appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansKR',
  colorScheme: _colors,
  scaffoldBackgroundColor: _colors.surface,
  textTheme: TextTheme(
    headlineMedium: _text(28, 36, FontWeight.w700),
    headlineSmall: _text(24, 32, FontWeight.w700),
    titleLarge: _text(22, 28, FontWeight.w700),
    titleMedium: _text(16, 24, FontWeight.w700),
    titleSmall: _text(14, 20, FontWeight.w500),
    bodyLarge: _text(16, 24, FontWeight.w400),
    bodyMedium: _text(14, 20, FontWeight.w400),
    bodySmall: _text(12, 16, FontWeight.w400),
    labelLarge: _text(14, 20, FontWeight.w500),
    labelMedium: _text(12, 16, FontWeight.w500),
    labelSmall: _text(11, 16, FontWeight.w500),
  ),
  appBarTheme: AppBarThemeData(
    backgroundColor: _colors.surface,
    foregroundColor: _colors.onSurface,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: _text(
      22,
      28,
      FontWeight.w700,
    ).copyWith(color: _colors.onSurface),
  ),
);
