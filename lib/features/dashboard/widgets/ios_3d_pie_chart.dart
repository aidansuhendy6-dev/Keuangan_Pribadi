import 'dart:math' as math;
import 'package:flutter/material.dart';

class Ios3dPieChart extends StatelessWidget {
  final double sisaBonus;
  final double totalExpense;
  final double size;

  const Ios3dPieChart({
    super.key,
    required this.sisaBonus,
    required this.totalExpense,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Ios3dPieChartPainter(
          sisaBonus: sisaBonus,
          totalExpense: totalExpense,
        ),
      ),
    );
  }
}

class _Ios3dPieChartPainter extends CustomPainter {
  final double sisaBonus;
  final double totalExpense;

  _Ios3dPieChartPainter({
    required this.sisaBonus,
    required this.totalExpense,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = sisaBonus + totalExpense;

    if (total <= 0) {
      return;
    }

    final greenPercent = sisaBonus / total;
    final redPercent = totalExpense / total;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = math.min(size.width, size.height) * 0.42;

    // ============================================================
    // PENGATURAN UTAMA
    // ============================================================

    // Ketebalan 3D.
    final depth = math.max(3.0, size.width * 0.075);

    // Jarak potongan merah dari bagian hijau.
    final redGap = math.max(4.0, size.width * 0.06);

    // Sedikit mengangkat keseluruhan chart.
    final centerY = center.dy - depth * 0.20;

    final chartCenter = Offset(
      center.dx,
      centerY,
    );

    // Mulai dari atas.
    //
    // Dengan konfigurasi ini:
    // merah berada di kanan atas,
    // hijau mengisi bagian sisanya.
    final startAngle = -math.pi / 2;

    final redSweep = redPercent * math.pi * 2;
    final greenSweep = greenPercent * math.pi * 2;

    // ============================================================
    // ANGLE
    // ============================================================

    final redStart = startAngle;
    final redEnd = redStart + redSweep;

    final greenStart = redEnd;
    final greenEnd = greenStart + greenSweep;

    // ============================================================
    // OFFSET POTONGAN
    // ============================================================

    final redMiddleAngle =
        redStart + redSweep / 2;

    final redOffset = Offset(
      math.cos(redMiddleAngle) * redGap,
      math.sin(redMiddleAngle) * redGap -5,
    );

    // ============================================================
    // 3D DEPTH
    // ============================================================

    // Gambar bagian bawah terlebih dahulu.
    _drawExtrudedSlice(
      canvas: canvas,
      center: chartCenter,
      radius: radius,
      startAngle: redStart,
      sweepAngle: redSweep,
      depth: depth,
      offset: redOffset,
      topColor: const Color(0xFFFF5A50),
      bottomColor: const Color(0xFFB71C1C),
    );

    _drawExtrudedSlice(
      canvas: canvas,
      center: chartCenter,
      radius: radius,
      startAngle: greenStart,
      sweepAngle: greenSweep,
      depth: depth,
      offset: Offset.zero,
      topColor: const Color(0xFF39D873),
      bottomColor: const Color(0xFF079447),
    );

    // ============================================================
    // TOP SURFACE
    // ============================================================

    _drawTopSlice(
      canvas: canvas,
      center: chartCenter + redOffset,
      radius: radius,
      startAngle: redStart,
      sweepAngle: redSweep,
      colors: const [
        Color(0xFFFF7268),
        Color(0xFFFF3028),
        Color(0xFFE31812),
      ],
    );

    _drawTopSlice(
      canvas: canvas,
      center: chartCenter,
      radius: radius,
      startAngle: greenStart,
      sweepAngle: greenSweep,
      colors: const [
        Color(0xFF63E88D),
        Color(0xFF20C968),
        Color(0xFF0B9F4C),
      ],
    );

    // ============================================================
    // HIGHLIGHT
    // ============================================================

    _drawHighlight(
      canvas: canvas,
      center: chartCenter,
      radius: radius,
      startAngle: greenStart,
      sweepAngle: greenSweep,
    );

    _drawHighlight(
      canvas: canvas,
      center: chartCenter + redOffset,
      radius: radius,
      startAngle: redStart,
      sweepAngle: redSweep,
    );

    // ============================================================
    // TEXT PERSENTASE
    // ============================================================

    _drawPercentage(
      canvas: canvas,
      center: chartCenter + redOffset,
      radius: radius,
      startAngle: redStart,
      sweepAngle: redSweep,
      percentage: redPercent,
      isRed: true,
    );

    _drawPercentage(
      canvas: canvas,
      center: chartCenter,
      radius: radius,
      startAngle: greenStart,
      sweepAngle: greenSweep,
      percentage: greenPercent,
      isRed: false,
    );
  }

  // ==============================================================
  // DRAW EXTRUDED / 3D
  // ==============================================================

  void _drawExtrudedSlice({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required double depth,
    required Offset offset,
    required Color topColor,
    required Color bottomColor,
  }) {
    final path = _createPiePath(
      center: center + offset,
      radius: radius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    // Shadow di bawah objek.
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        4,
      );

    canvas.drawPath(
      path.shift(const Offset(0, 2)),
      shadowPaint,
    );

    // Buat beberapa layer untuk memberikan efek
    // ketebalan 3D yang lebih natural.
    for (double y = depth; y >= 1; y -= 1) {
      final progress = 1 - (y / depth);

      final color = Color.lerp(
        bottomColor,
        topColor,
        progress * 0.35,
      )!;

      final paint = Paint()
        ..color = color;

      canvas.drawPath(
        path.shift(Offset(0, y)),
        paint,
      );
    }
  }

  // ==============================================================
  // DRAW TOP PIE
  // ==============================================================

  void _drawTopSlice({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required List<Color> colors,
  }) {
    final path = _createPiePath(
      center: center,
      radius: radius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: colors,
        stops: const [
          0.0,
          0.55,
          1.0,
        ],
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  // ==============================================================
  // CREATE PIE PATH
  // ==============================================================

  Path _createPiePath({
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final path = Path();

    path.moveTo(center.dx, center.dy);

    path.arcTo(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle,
      false,
    );

    path.close();

    return path;
  }

  // ==============================================================
  // HIGHLIGHT
  // ==============================================================

  void _drawHighlight({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final highlightSweep =
        math.min(sweepAngle, math.pi * 0.8);

    final path = _createPiePath(
      center: center,
      radius: radius * 0.98,
      startAngle: startAngle + 0.02,
      sweepAngle: highlightSweep * 0.35,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.20),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawPath(path, paint);
  }

  // ==============================================================
  // PERCENTAGE TEXT
  // ==============================================================

  void _drawPercentage({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required double percentage,
    required bool isRed,
  }) {
    final middleAngle =
        startAngle + sweepAngle / 2;

    // Posisi teks.
    //
    // Bagian merah diletakkan sedikit lebih ke tengah
    // agar tetap terbaca meskipun chart kecil.
    final textRadius = isRed
        ? radius * 0.58
        : radius * 0.55;

    final textCenter = Offset(
      center.dx + math.cos(middleAngle) * textRadius,
      center.dy + math.sin(middleAngle) * textRadius,
    );

    final value =
        '${(percentage * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

    final fontSize = math.max(
      6.0,
      math.min(11.0, radius * 0.24),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      textCenter.dx - textPainter.width / 2,
      textCenter.dy - textPainter.height / 2,
    );

    textPainter.paint(
      canvas,
      offset,
    );
  }

  @override
  bool shouldRepaint(
    covariant _Ios3dPieChartPainter oldDelegate,
  ) {
    return oldDelegate.sisaBonus != sisaBonus ||
        oldDelegate.totalExpense != totalExpense;
  }
}
