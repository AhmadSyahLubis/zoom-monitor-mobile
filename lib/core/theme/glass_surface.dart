import 'package:flutter/material.dart';
import 'app_colors.dart';

class NeoDepth {
  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x80BDCADB),
      blurRadius: 10,
      offset: Offset(4, 4),
    ),
    BoxShadow(
      color: Color(0xEDFFFFFF),
      blurRadius: 10,
      offset: Offset(-4, -4),
    ),
  ];

  static const insetEdge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, 0.55, 1],
    colors: [Color(0xFFBECBDD), AppColors.neoBase, Colors.white],
  );
}

class NeoInsetSurface extends StatelessWidget {
  const NeoInsetSurface({
    super.key,
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.all(2),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: NeoDepth.insetEdge,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: padding,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.neoBase,
              borderRadius: BorderRadius.circular(radius - 2),
            ),
            child: child,
          ),
        ),
      );
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.neoBase),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: child,
        ),
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.margin,
    this.expand = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expand ? double.infinity : null,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xF2EAF0F7),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xB3FFFFFF),
          width: 1.2,
        ),
        boxShadow: NeoDepth.raised,
      ),
      child: child,
    );
  }
}

class GlassAppBarBackground extends StatelessWidget {
  const GlassAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neoBase,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class ContentSurface extends StatelessWidget {
  const ContentSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 18,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.neoBase,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xB3FFFFFF)),
        boxShadow: NeoDepth.raised,
      ),
      child: child,
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.neoBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xB3FFFFFF)),
            boxShadow: NeoDepth.raised,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 19, color: AppColors.textMain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
