import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../utils/image_decode_size.dart';

class SectionPhotoBanner extends StatelessWidget {
  const SectionPhotoBanner({
    super.key,
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(
              AssetImage(asset),
              width: imageCacheWidth(context, MediaQuery.sizeOf(context).width),
            ),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.95),
                AppColors.primaryDark.withValues(alpha: 0.77),
                AppColors.primaryDark.withValues(alpha: 0.06),
              ],
              stops: const [0, 0.52, 1],
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 144),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 100, 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.section.copyWith(
                      color: Colors.white,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFE5ECF7),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
