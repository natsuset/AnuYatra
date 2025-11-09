import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color sacredSaffron = Color(0xFFFF8C42); // Primary CTA color
  static const Color deepMaroon = Color(0xFF8B2635); // Headers
  static const Color softOffWhite = Color(0xFFFAFAFA); // Background

  // WhatsApp-inspired colors
  static const Color whatsAppGreen = Color(0xFF25D366);
  static const Color whatsAppDarkGreen = Color(0xFF128C7E);
  static const Color whatsAppLightGreen = Color(0xFFDCF8C6);
  static const Color whatsAppGray = Color(0xFFECE5DD);
  static const Color whatsAppDarkGray = Color(0xFF8696A0);

  // Status colors
  static const Color statusGreen = whatsAppGreen; // Online, mutual interest
  static const Color statusRed = Color(0xFFE57373); // Not match
  static const Color statusAmber = Color(0xFFFFA726); // Saved, awaiting

  // Text colors
  static const Color primaryTextColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color lightTextColor = Color(0xFF9CA3AF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sacredSaffron,
        primary: sacredSaffron,
        secondary: deepMaroon,
        surface: softOffWhite,
        background: softOffWhite,
      ),

      // Typography using system fonts for better performance and reliability
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: deepMaroon,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: deepMaroon,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: deepMaroon,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: secondaryTextColor,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightTextColor,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: deepMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: sacredSaffron,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sacredSaffron,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: sacredSaffron,
          side: const BorderSide(color: sacredSaffron),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: whatsAppGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: whatsAppGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: sacredSaffron, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: whatsAppGray,
        thickness: 0.5,
        space: 1,
      ),
    );
  }

  // Helper methods for custom colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'interested':
      case 'mutual interest':
      case 'online':
        return statusGreen;
      case 'not match':
      case 'rejected':
        return statusRed;
      case 'saved':
      case 'awaiting response':
        return statusAmber;
      default:
        return secondaryTextColor;
    }
  }

  static Color getChatBubbleColor({required bool isSentByUser}) {
    return isSentByUser ? whatsAppLightGreen : Colors.white;
  }

  // Custom shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: sacredSaffron.withOpacity(0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
