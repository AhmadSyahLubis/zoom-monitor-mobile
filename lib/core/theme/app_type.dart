import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppType {
  static const section = TextStyle(
    fontFamily: 'Inter',
    fontSize: 21,
    height: 1.15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    color: AppColors.textMain,
  );

  static const cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.textMain,
  );

  static const metric = TextStyle(
    fontFamily: 'Inter',
    fontSize: 30,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.primaryDark,
  );
}
