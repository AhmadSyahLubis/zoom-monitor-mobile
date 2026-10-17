import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/glass_surface.dart';
import '../utils/image_decode_size.dart';

class EmptyStateWidget extends StatelessWidget {
  final String artwork;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.artwork,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ContentSurface(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            artwork,
            cacheWidth: imageCacheWidth(context, 236, maxWidth: 560),
            width: 236,
            height: 144,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
