import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';

class RunicDivider extends StatelessWidget {
  final double height;
  final double maxWidth;
  final double opacity;

  const RunicDivider({
    super.key,
    this.height = 24,
    this.maxWidth = 214,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (maxWidth * devicePixelRatio)
        .round()
        .clamp(1, 640)
        .toInt();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: ClipRect(
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                MedievalAssets.runicDivider,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.none,
                cacheWidth: cacheWidth,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RunicFrame extends StatelessWidget {
  final Widget child;
  final Color color;
  final double opacity;
  final double cornerLength;

  const RunicFrame({
    super.key,
    required this.child,
    this.color = AppTheme.bronze,
    this.opacity = 0.55,
    this.cornerLength = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RunicFramePainter(
                color: color,
                opacity: opacity,
                cornerLength: cornerLength,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RunicGlyph extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const RunicGlyph({
    super.key,
    this.size = 10,
    this.color = AppTheme.accentYellow,
    this.opacity = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RunicGlyphPainter(color: color, opacity: opacity),
      ),
    );
  }
}

class RunicNavIcon extends StatelessWidget {
  final IconData icon;

  const RunicNavIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 0, child: RunicGlyph(size: 6, opacity: 0.95)),
          Positioned(bottom: 0, child: Icon(icon, size: 19)),
        ],
      ),
    );
  }
}

class _RunicFramePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double cornerLength;

  const _RunicFramePainter({
    required this.color,
    required this.opacity,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final length = cornerLength.clamp(4, size.shortestSide / 3).toDouble();
    final notch = (length * 0.32).clamp(2, 5).toDouble();
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.square;

    final corners = <Path>[
      Path()
        ..moveTo(0, length)
        ..lineTo(0, notch)
        ..lineTo(notch, 0)
        ..lineTo(length, 0),
      Path()
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width - notch, 0)
        ..lineTo(size.width, notch)
        ..lineTo(size.width, length),
      Path()
        ..moveTo(size.width, size.height - length)
        ..lineTo(size.width, size.height - notch)
        ..lineTo(size.width - notch, size.height)
        ..lineTo(size.width - length, size.height),
      Path()
        ..moveTo(length, size.height)
        ..lineTo(notch, size.height)
        ..lineTo(0, size.height - notch)
        ..lineTo(0, size.height - length),
    ];

    for (final path in corners) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RunicFramePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.cornerLength != cornerLength;
  }
}

class _RunicGlyphPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _RunicGlyphPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.43;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.48),
      Offset(center.dx, center.dy + radius * 0.48),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RunicGlyphPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
