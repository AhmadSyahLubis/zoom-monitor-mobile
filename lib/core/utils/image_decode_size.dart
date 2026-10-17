import 'package:flutter/material.dart';

int imageCacheWidth(
  BuildContext context,
  double logicalWidth, {
  int maxWidth = 1400,
}) {
  final physicalWidth =
      (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
  return physicalWidth.clamp(1, maxWidth);
}
