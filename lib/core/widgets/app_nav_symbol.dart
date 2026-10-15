import 'package:flutter/material.dart';

enum AppNavSymbolKind { dashboard, search, calendar, recordings, accounts }

class AppNavSymbol extends StatelessWidget {
  const AppNavSymbol({
    super.key,
    required this.kind,
    required this.color,
    this.size = 22,
  });

  final AppNavSymbolKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _NavSymbolPainter(kind, color),
      );
}

class _NavSymbolPainter extends CustomPainter {
  const _NavSymbolPainter(this.kind, this.color);

  final AppNavSymbolKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    void roundRect(
        double left, double top, double right, double bottom, double radius) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          Radius.circular(radius),
        ),
        stroke,
      );
    }

    switch (kind) {
      case AppNavSymbolKind.dashboard:
        roundRect(3, 3, 10, 10, 1.6);
        roundRect(14, 3, 21, 10, 1.6);
        roundRect(3, 14, 10, 21, 1.6);
        roundRect(14, 14, 21, 21, 1.6);
        break;
      case AppNavSymbolKind.search:
        canvas.drawCircle(const Offset(10.6, 10.6), 6.6, stroke);
        canvas.drawLine(const Offset(15.6, 15.6), const Offset(21, 21), stroke);
        break;
      case AppNavSymbolKind.calendar:
        roundRect(3, 5, 21, 21, 2.5);
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), stroke);
        canvas.drawLine(const Offset(8, 3), const Offset(8, 7), stroke);
        canvas.drawLine(const Offset(16, 3), const Offset(16, 7), stroke);
        canvas.drawCircle(const Offset(8, 15), 1.1, fill);
        canvas.drawCircle(const Offset(13, 15), 1.1, fill);
        canvas.drawCircle(const Offset(8, 19), 1.1, fill);
        break;
      case AppNavSymbolKind.recordings:
        roundRect(4, 3, 20, 21, 2.7);
        final play = Path()
          ..moveTo(10, 8.5)
          ..lineTo(16, 12)
          ..lineTo(10, 15.5)
          ..close();
        canvas.drawPath(play, stroke);
        break;
      case AppNavSymbolKind.accounts:
        roundRect(3, 4, 17, 19, 2.5);
        canvas.drawCircle(const Offset(10, 9), 2.1, stroke);
        canvas.drawArc(const Rect.fromLTRB(5.8, 12.2, 14.2, 18), 3.25, 2.93,
            false, stroke);
        canvas.drawLine(const Offset(20, 8), const Offset(20, 18), stroke);
        canvas.drawLine(const Offset(18.5, 21), const Offset(20, 21), stroke);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavSymbolPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
