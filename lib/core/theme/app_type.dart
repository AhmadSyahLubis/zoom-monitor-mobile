import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppType {
  static const section = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textMain,
  );

  static const cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    color: AppColors.textMain,
  );

  static const metric = TextStyle(
    fontFamily: 'Inter',
    fontSize: 27,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.primaryDark,
  );
}
