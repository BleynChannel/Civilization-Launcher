import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration getTextFieldDecoration() {
  return InputDecoration(
    hintStyle: GoogleFonts.nunitoSans(
      color: Colors.white54,
      fontWeight: FontWeight.bold,
    ),
    fillColor: Colors.black.withOpacity(0.1),
    filled: true,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.white60,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.white,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
