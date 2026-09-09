import 'package:flutter/material.dart';

/// Official SUNASS (Superintendencia Nacional de Servicios de Saneamiento) Palette
/// Combined with Humanitarian Emergency & Safe Water Semantics
class AppColors {
  // === SUNASS Institutional Core ===
  static const Color sunassNavy = Color(0xFF003876); // Azul Institucional Profundo SUNASS
  static const Color sunassBlue = Color(0xFF0056B3); // Azul Primario SUNASS
  static const Color sunassCyan = Color(0xFF00A3E0); // Celeste Agua / Gota SUNASS
  static const Color sunassLightCyan = Color(0xFFE0F2FE); // Celeste Claro de fondo (sky-100)
  static const Color sunassDarkNavy = Color(0xFF002244); // Azul Marino Profundo (AppBar/Headers)

  // === Emergency & Seismic Alerts (Disaster Mode) ===
  static const Color primaryRed = Color(0xFFDC2626); // red-600
  static const Color darkRed = Color(0xFF991B1B); // red-800
  static const Color deepRed = Color(0xFF450A0A); // red-950
  static const Color softRed = Color(0xFFFEF2F2); // red-50
  static const Color borderRed = Color(0xFFFECACA); // red-200

  // === Safe Water & Operational Status ===
  static const Color safeGreen = Color(0xFF00A859); // Verde SUNASS Saneamiento
  static const Color darkGreen = Color(0xFF065F46); // emerald-800
  static const Color deepGreen = Color(0xFF022C22); // emerald-950
  static const Color softGreen = Color(0xFFECFDF5); // emerald-50
  static const Color borderGreen = Color(0xFFA7F3D0); // emerald-200

  // === Warnings, Treatment Needed & Schedules ===
  static const Color warningAmber = Color(0xFFD97706); // amber-600
  static const Color darkAmber = Color(0xFF92400E); // amber-800
  static const Color softAmber = Color(0xFFFFFBEB); // amber-50
  static const Color borderAmber = Color(0xFFFDE68A); // amber-200

  // === Accent & Informational ===
  static const Color accentBlue = Color(0xFF0056B3); // SUNASS Blue
  static const Color softBlue = Color(0xFFF0F9FF); // sky-50
  static const Color borderBlue = Color(0xFFBAE6FD); // sky-200

  // === Neutrals & Slates ===
  static const Color slate950 = Color(0xFF0A1128); // Deep Navy Black
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);

  // === Cartography Canvas ===
  static const Color mapBg = Color(0xFFEAE6DC);
  static const Color mapBlock = Color(0xFFDED7CA);
  static const Color mapBlockBorder = Color(0xFFCFC7B8);
  static const Color mapRiver = Color(0xFF7DD3FC);
  static const Color mapPark = Color(0xFFC4E2BD);
  static const Color mapParkBorder = Color(0xFF9BC791);
}
