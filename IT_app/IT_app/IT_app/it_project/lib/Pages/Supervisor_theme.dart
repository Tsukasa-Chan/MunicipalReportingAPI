
import 'package:flutter/material.dart';

// Primary colours for users and supervisors
const supervisorPrimaryColor = Color(0xFFA94319);
const userPrimaryColor = Color(0xFFC94F1B);

// Shared application colours
const appBackgroundColor = Color(0xFFFFF8F4);
const appSurfaceColor = Color(0xFFFFFFFF);
const appTextColor = Color(0xFF292524);

// Additional styling colours
const appSecondaryTextColor = Color(0xFF78716C);
const appBorderColor = Color(0xFFE8C7B8);

// Returns the primary colour based on the user's role
Color pagePrimaryColor({required bool isSupervisor}) {
  return isSupervisor
      ? supervisorPrimaryColor
      : userPrimaryColor;
}

// Returns the background based on the user's role
BoxDecoration pageBackgroundDecoration({
  required bool isSupervisor,
}) {
  if (isSupervisor) {
    // Supervisor background - warm ivory to soft beige
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFCF8),
          Color(0xFFF7EDE4),
        ],
      ),
    );
  }

  // Regular user background - cream to peach
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF8F4),
        Color(0xFFFFE9DC),
      ],
    ),
  );
}
