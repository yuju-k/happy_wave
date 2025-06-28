import 'package:flutter/material.dart';

/// Configuration constants for the chat UI.
class ChatConfig {
  // Scroll settings
  static const double scrollThreshold = 100.0;
  static const Duration scrollDuration = Duration(milliseconds: 300);

  // UI dimensions
  static const double maxBubbleWidth = 0.6;
  static const double padding = 12.0;
  static const double marginVertical = 4.0;
  static const double marginHorizontal = 12.0;
  static const double borderRadius = 10.0;
  static const double spacing = 8.0;
  static const double spacingSmall = 4.0;
  static const double borderWidth = 3.0;

  // Font and icon sizes
  static const double timeFontSize = 12.0;
  static const double iconSize = 18.0;
  static const double iconSpacing = 4.0;
  static const double labelFontSize = 12.0;
  static const double messageFontSize = 14.0;

  // Colors
  static const Color myMessageColor = Color.fromARGB(255, 212, 250, 253);
  static const Color otherMessageColor = Colors.white;
  static const Color iconColor = Color(0xFF389EA9);
  static const Color originalMessageBackground = Color(0xFFF5F5F5);

  // URL detection regex
  static final RegExp urlRegExp = RegExp(
    r'(?:(?:https?|ftp):\/\/|www\.|ftp\.)(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#\/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[A-Z0-9+&@#\/%=~_|$])',
    caseSensitive: false,
  );
}
