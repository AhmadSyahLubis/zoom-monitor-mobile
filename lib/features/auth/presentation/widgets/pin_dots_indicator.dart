import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PinDotsIndicator extends StatelessWidget {
  final int pinLength;
  final int currentLength;
  final bool isError;

  const PinDotsIndicator({
    super.key,
    this.pinLength = 6,
    required this.currentLength,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final isFilled = index < currentLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isError
                ? AppColors.statusMeeting
                : isFilled
                    ? AppColors.primary
                    : Colors.transparent,
            border: Border.all(
              color: isError
                  ? AppColors.statusMeeting
                  : isFilled
                      ? AppColors.primary
                      : AppColors.textMuted.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: isFilled && !isError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
