import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Terminal color palette
class TermColors {
  // Background colors
  static const bg = Color(0xFF1E1E1E);
  static const titleBar = Color(0xFF2D2D2D);
  static const contentBg = Color(0xFF1E1E1E);
  
  // Terminal buttons
  static const closeBtn = Color(0xFFFF5F56);
  static const minBtn = Color(0xFFFFBD2E);
  static const maxBtn = Color(0xFF27CA40);
  
  // Text colors
  static const prompt = Color(0xFF4EC9B0);
  static const username = Color(0xFF569CD6);
  static const hostname = Color(0xFFDCDCAA);
  static const path = Color(0xFF808080);
  static const command = Color(0xFFD4D4D4);
  static const link = Color(0xFF4FC1FF);
  static const error = Color(0xFFF44747);
  static const highlight = Color(0xFFFFD700);
  static const comment = Color(0xFF6A9955);
  static const string = Color(0xFFCE9178);
  
  // Surface colors
  static const surface = Color(0xFF252526);
  static const border = Color(0xFF3C3C3C);
}

class TerminalTheme {
  static TextStyle get font => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    height: 1.5,
    color: TermColors.command,
  );
  
  static TextStyle get promptStyle => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    color: TermColors.prompt,
  );
  
  static TextStyle get linkStyle => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    color: TermColors.link,
    decoration: TextDecoration.underline,
  );
  
  static TextStyle get errorStyle => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    color: TermColors.error,
  );
}