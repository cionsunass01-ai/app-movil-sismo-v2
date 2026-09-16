import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/water_point.dart';

class VectorMapPainter extends CustomPainter {
  final List<WaterPoint> points;
  final bool isEmergency;
  final bool showRoute;
  final String? activePointId;

  const VectorMapPainter({
    required this.points,
    required this.isEmergency,
    required this.showRoute,
    this.activePointId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 400.0;
    final double scaleY = size.height / 380.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Background Fill
    final bgPaint = Paint()..color = AppColors.mapBg;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 380), bgPaint);

    // 2. Urban Blocks
    final blockPaint = Paint()..color = AppColors.mapBlock;
    final blockBorderPaint = Paint()
      ..color = AppColors.mapBlockBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(20, 20, 75, 65),
      blockPaint,
      blockBorderPaint,
    );
    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(110, 20, 95, 65),
      blockPaint,
      blockBorderPaint,
    );
    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(220, 20, 160, 50),
      blockPaint,
      blockBorderPaint,
    );
    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(20, 220, 80, 80),
      blockPaint,
      blockBorderPaint,
    );
    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(250, 220, 130, 80),
      blockPaint,
      blockBorderPaint,
    );

    // 3. Rio Moquegua (River channel across city)
    final riverPath = Path()
      ..moveTo(-10, 170)
      ..cubicTo(80, 160, 160, 210, 240, 240)
      ..cubicTo(280, 260, 330, 280, 420, 290);

    final riverPaint = Paint()
      ..color = AppColors.mapRiver
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverPaint);

    final riverDashPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(riverPath, riverDashPaint);

    // River Text
    _drawText(
      canvas,
      'RÍO MOQUEGUA',
      const Offset(300, 265),
      fontSize: 7,
      color: const Color(0xFF0369A1),
    );

    // 4. Safe Green Gathering Parks
    final parkPaint = Paint()..color = AppColors.mapPark;
    final parkBorderPaint = Paint()
      ..color = AppColors.mapParkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Alameda & Plaza area
    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(120, 100, 130, 90),
      parkPaint,
      parkBorderPaint,
    );
    _drawText(
      canvas,
      'PARQUE LA ALAMEDA',
      const Offset(135, 140),
      fontSize: 7.5,
      color: const Color(0xFF166534),
      isBold: true,
    );

    // Chen Chen park area
    _drawRoundedBlock(
      canvas,
      const Rect.fromLTWH(240, 75, 140, 80),
      parkPaint,
      parkBorderPaint,
    );
    _drawText(
      canvas,
      'ZONA PARQUE CHEN CHEN',
      const Offset(250, 115),
      fontSize: 7.5,
      color: const Color(0xFF166534),
      isBold: true,
    );

    // 5. Main Avenues / Grid Roads
    final roadPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawLine(const Offset(105, 0), const Offset(105, 380), roadPaint);
    canvas.drawLine(const Offset(225, 0), const Offset(225, 380), roadPaint);
    canvas.drawLine(const Offset(0, 92), const Offset(400, 92), roadPaint);
    canvas.drawLine(const Offset(0, 200), const Offset(400, 200), roadPaint);
    canvas.drawLine(const Offset(0, 310), const Offset(400, 310), roadPaint);

    // Road dashed centerlines
    final roadLinePaint = Paint()
      ..color = AppColors.mapBlockBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(105, 0),
      const Offset(105, 380),
      roadLinePaint,
    );
    canvas.drawLine(
      const Offset(225, 0),
      const Offset(225, 380),
      roadLinePaint,
    );

    // 6. Safe Pedestrian Evacuation Route
    if (showRoute) {
      final routePath = Path()
        ..moveTo(60, 250)
        ..lineTo(105, 250)
        ..lineTo(105, 145)
        ..lineTo(175, 145);

      final routeBasePaint = Paint()
        ..color = AppColors.safeGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(routePath, routeBasePaint);

      final routeWhiteLine = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(routePath, routeWhiteLine);
    }

    // 7. User GPS Location Marker (translate 60, 250)
    final gpsCenter = const Offset(60, 250);
    // Ping ring
    canvas.drawCircle(
      gpsCenter,
      13,
      Paint()
        ..color = (isEmergency ? AppColors.primaryRed : AppColors.sunassCyan)
            .withValues(alpha: 0.25),
    );
    // Outer border
    canvas.drawCircle(gpsCenter, 8, Paint()..color = AppColors.slate900);
    canvas.drawCircle(
      gpsCenter,
      8,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Center point
    canvas.drawCircle(gpsCenter, 3.5, Paint()..color = const Color(0xFF38BDF8));
    // Pill label
    final labelBg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(38, 262, 44, 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      labelBg,
      Paint()..color = AppColors.slate900.withValues(alpha: 0.9),
    );
    _drawText(
      canvas,
      'TÚ AQUÍ',
      const Offset(43, 264),
      fontSize: 7,
      color: AppColors.white,
      isBold: true,
    );

    // 8. Water Distribution Points on Map
    _drawPointMarker(
      canvas,
      id: 'MOQ-PE-003',
      name: 'Mariscal Nieto (180m)',
      position: const Offset(175, 145),
      color: AppColors.safeGreen,
      isActive: true,
      hasPulse: true,
    );

    _drawPointMarker(
      canvas,
      id: 'MOQ-PE-004',
      name: 'La Alameda (290m)',
      position: const Offset(145, 175),
      color: AppColors.sunassBlue,
      isActive: true,
    );

    _drawPointMarker(
      canvas,
      id: 'MOQ-PE-008',
      name: 'Surtidor Chen Chen (24h)',
      position: const Offset(310, 65),
      color: AppColors.safeGreen,
      isActive: true,
    );

    _drawPointMarker(
      canvas,
      id: 'MOQ-PE-001',
      name: 'Óvalo Bolívar (Sin agua)',
      position: const Offset(70, 310),
      color: AppColors.primaryRed,
      isActive: false,
    );

    _drawPointMarker(
      canvas,
      id: 'MOQ-PE-006',
      name: 'San Antonio (1.4 km)',
      position: const Offset(320, 330),
      color: AppColors.safeGreen,
      isActive: true,
    );

    canvas.restore();
  }

  void _drawRoundedBlock(Canvas canvas, Rect rect, Paint fill, Paint stroke) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
  }

  void _drawPointMarker(
    Canvas canvas, {
    required String id,
    required String name,
    required Offset position,
    required Color color,
    required bool isActive,
    bool hasPulse = false,
  }) {
    if (hasPulse) {
      canvas.drawCircle(
        position,
        15,
        Paint()..color = color.withValues(alpha: 0.25),
      );
    }

    // Outer Circle
    canvas.drawCircle(position, 10, Paint()..color = color);
    canvas.drawCircle(
      position,
      10,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Inner white dot
    canvas.drawCircle(position, 3.5, Paint()..color = AppColors.white);

    // Text Badge Above
    final double badgeWidth = (name.length * 4.8) + 12;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(position.dx, position.dy - 18),
        width: badgeWidth,
        height: 14,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = (color == AppColors.primaryRed
            ? const Color(0xFF7F1D1D)
            : const Color(0xFF064E3B)),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _drawText(
      canvas,
      name,
      Offset(position.dx - (badgeWidth / 2) + 6, position.dy - 24),
      fontSize: 7.5,
      color: AppColors.white,
      isBold: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant VectorMapPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.isEmergency != isEmergency ||
        oldDelegate.showRoute != showRoute ||
        oldDelegate.activePointId != activePointId;
  }
}
