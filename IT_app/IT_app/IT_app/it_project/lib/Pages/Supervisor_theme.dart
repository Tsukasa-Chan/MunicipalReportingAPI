import 'package:flutter/material.dart';

// Shared FixMyCity visual theme inspired by the supplied reference screenshots.
const supervisorPrimaryColor = Color(0xFFC94F1B);
const userPrimaryColor = Color(0xFFC94F1B);
const appBackgroundColor = Color(0xFFF5F5F5);
const appSurfaceColor = Color(0xFFFFFFFF);
const appTextColor = Color(0xFF292929);

Color pagePrimaryColor({required bool isSupervisor}) =>
    isSupervisor ? supervisorPrimaryColor : userPrimaryColor;

BoxDecoration pageBackgroundDecoration({required bool isSupervisor}) {
  return const BoxDecoration(color: appBackgroundColor);
}
