import 'package:flutter/material.dart';

// ============================================================
// GESTURE ILLUSTRATIONS — Custom painted hand signs
// Each class draws a specific hand gesture as a visual widget
// ============================================================

class GestureIllustration extends StatelessWidget {
  final String gestureName;
  final Color color;
  final double size;

  const GestureIllustration({
    super.key,
    required this.gestureName,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _getGesturePainter(gestureName, color),
      ),
    );
  }

  CustomPainter _getGesturePainter(String name, Color color) {
    switch (name.toLowerCase()) {
    // SALUTATIONS
      case 'bonjour':
        return _BonjourPainter(color);
      case 'au revoir':
        return _AuRevoirPainter(color);
      case 'merci':
        return _MerciPainter(color);
      case "s'il vous plaît":
        return _SilVousPlaitPainter(color);
      case 'excusez-moi':
        return _ExcusezMoiPainter(color);

    // URGENCE
      case 'au secours':
        return _AuSecoursPainter(color);
      case 'médecin':
        return _MedecinPainter(color);
      case 'douleur':
        return _DouleurPainter(color);
      case 'ambulance':
        return _AmbulancePainter(color);
      case 'urgence':
        return _UrgencePainter(color);

    // TRANSPORT
      case 'bus':
        return _BusPainter(color);
      case 'taxi':
        return _TaxiPainter(color);
      case 'gare':
        return _GarePainter(color);
      case 'billet':
        return _BilletPainter(color);
      case 'arrêt':
        return _ArretPainter(color);

    // HÔPITAL
      case 'infirmier':
        return _InfirmierPainter(color);
      case 'médicament':
        return _MedicamentPainter(color);
      case 'rendez-vous':
        return _RendezVousPainter(color);
      case 'opération':
        return _OperationPainter(color);

      default:
        return _DefaultHandPainter(color);
    }
  }
}

// ============================================================
// BASE HAND DRAWING UTILITIES
// ============================================================

class _HandPainterBase extends CustomPainter {
  final Color color;
  _HandPainterBase(this.color);

  Paint get fillPaint => Paint()
    ..color = color.withOpacity(0.85)
    ..style = PaintingStyle.fill;

  Paint get strokePaint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get skinPaint => Paint()
    ..color = const Color(0xFFFFE0BD)
    ..style = PaintingStyle.fill;

  Paint get skinStroke => Paint()
    ..color = const Color(0xFF8D6E63)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  // Draw a basic open hand (palm facing forward)
  void drawOpenHand(Canvas canvas, Size size, Offset center, double scale,
      {bool mirrorX = false}) {
    final s = scale;
    final cx = center.dx;
    final cy = center.dy;
    final mx = mirrorX ? -1.0 : 1.0;

    // Palm
    final palmPath = Path()
      ..moveTo(cx + mx * -18 * s, cy + 15 * s)
      ..cubicTo(cx + mx * -22 * s, cy + 5 * s, cx + mx * -20 * s, cy - 10 * s,
          cx + mx * -14 * s, cy - 18 * s)
      ..cubicTo(cx + mx * -8 * s, cy - 28 * s, cx + mx * 8 * s, cy - 30 * s,
          cx + mx * 14 * s, cy - 20 * s)
      ..cubicTo(cx + mx * 20 * s, cy - 10 * s, cx + mx * 22 * s, cy + 5 * s,
          cx + mx * 18 * s, cy + 15 * s)
      ..close();
    canvas.drawPath(palmPath, skinPaint);
    canvas.drawPath(palmPath, skinStroke);

    // Fingers
    _drawFinger(canvas, cx + mx * -14 * s, cy - 18 * s, -10 * mx * s, -22 * s, s);
    _drawFinger(canvas, cx + mx * -5 * s, cy - 22 * s, -3 * mx * s, -25 * s, s);
    _drawFinger(canvas, cx + mx * 5 * s, cy - 22 * s, 3 * mx * s, -25 * s, s);
    _drawFinger(canvas, cx + mx * 14 * s, cy - 18 * s, 10 * mx * s, -20 * s, s);
    // Thumb
    _drawThumb(canvas, cx + mx * -18 * s, cy + 5 * s, cx + mx * -28 * s,
        cy - 5 * s, s, mirrorX: mirrorX);
  }

  void _drawFinger(
      Canvas canvas, double bx, double by, double tx, double ty, double s) {
    final path = Path()
      ..moveTo(bx - 5 * s, by)
      ..cubicTo(bx - 5 * s, by + ty * 0.3, tx - 4 * s, ty + by * 0.7, tx - 4 * s, by + ty)
      ..cubicTo(tx - 4 * s, by + ty - 5 * s, tx + 4 * s, by + ty - 5 * s, tx + 4 * s, by + ty)
      ..cubicTo(tx + 4 * s, by + ty * 0.7, bx + 5 * s, by + ty * 0.3, bx + 5 * s, by)
      ..close();
    canvas.drawPath(path, skinPaint);
    canvas.drawPath(path, skinStroke);
  }

  void _drawThumb(Canvas canvas, double bx, double by, double tx, double ty,
      double s,
      {bool mirrorX = false}) {
    final mx = mirrorX ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(bx, by + 5 * s)
      ..cubicTo(bx - 3 * mx * s, by - 5 * s, tx - 3 * mx * s, ty + 5 * s, tx, ty)
      ..cubicTo(tx + 3 * mx * s, ty - 5 * s, bx + 4 * mx * s, by - 8 * s, bx + 2 * mx * s, by + 5 * s)
      ..close();
    canvas.drawPath(path, skinPaint);
    canvas.drawPath(path, skinStroke);
  }

  // Draw wrist/arm stub
  void drawWrist(Canvas canvas, Offset center, double scale) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy + 20 * scale),
          width: 28 * scale,
          height: 20 * scale),
      Radius.circular(5 * scale),
    );
    canvas.drawRRect(rect, skinPaint);
    canvas.drawRRect(rect, skinStroke);
  }

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_) => false;
}

// ============================================================
// SALUTATIONS GESTURES
// ============================================================

class _BonjourPainter extends _HandPainterBase {
  _BonjourPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.85;

    // Motion lines (movement from forehead outward)
    final motionPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(center.dx + 25 + i * 8.0, center.dy - 30 + i * 3.0),
        Offset(center.dx + 35 + i * 8.0, center.dy - 22 + i * 3.0),
        motionPaint,
      );
    }

    drawWrist(canvas, center, s);
    drawOpenHand(canvas, size, center, s);

    // Direction arrow
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx + 20, center.dy - 10),
        Offset(center.dx + 38, center.dy - 10), arrowPaint);
    canvas.drawLine(Offset(center.dx + 33, center.dy - 15),
        Offset(center.dx + 38, center.dy - 10), arrowPaint);
    canvas.drawLine(Offset(center.dx + 33, center.dy - 5),
        Offset(center.dx + 38, center.dy - 10), arrowPaint);
  }
}

class _AuRevoirPainter extends _HandPainterBase {
  _AuRevoirPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.85;

    drawWrist(canvas, center, s);
    drawOpenHand(canvas, size, center, s);

    // Wavy motion lines = waving goodbye
    final wavePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(center.dx - 38, center.dy - 5)
      ..cubicTo(center.dx - 30, center.dy - 15, center.dx - 20, center.dy + 5,
          center.dx - 10, center.dy - 5);
    canvas.drawPath(path1, wavePaint);
    canvas.drawPath(
        path1..shift(const Offset(0, 10)), wavePaint);

    // Double arrow left-right
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 35, center.dy + 28),
        Offset(center.dx + 35, center.dy + 28), arrowPaint);
    canvas.drawLine(Offset(center.dx - 30, center.dy + 23),
        Offset(center.dx - 35, center.dy + 28), arrowPaint);
    canvas.drawLine(Offset(center.dx - 30, center.dy + 33),
        Offset(center.dx - 35, center.dy + 28), arrowPaint);
    canvas.drawLine(Offset(center.dx + 30, center.dy + 23),
        Offset(center.dx + 35, center.dy + 28), arrowPaint);
    canvas.drawLine(Offset(center.dx + 30, center.dy + 33),
        Offset(center.dx + 35, center.dy + 28), arrowPaint);
  }
}

class _MerciPainter extends _HandPainterBase {
  _MerciPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    const s = 0.85;

    // Flat hand — fingers together
    final palmPath = Path()
      ..moveTo(center.dx - 16, center.dy + 12)
      ..lineTo(center.dx - 18, center.dy - 5)
      ..lineTo(center.dx - 12, center.dy - 22)
      ..lineTo(center.dx - 4, center.dy - 24)
      ..lineTo(center.dx + 4, center.dy - 24)
      ..lineTo(center.dx + 12, center.dy - 22)
      ..lineTo(center.dx + 18, center.dy - 5)
      ..lineTo(center.dx + 16, center.dy + 12)
      ..close();
    canvas.drawPath(palmPath, skinPaint);
    canvas.drawPath(palmPath, skinStroke);

    drawWrist(canvas, center, s);

    // Arrow from mouth downward-forward
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy - 30),
        Offset(center.dx + 20, center.dy - 10), arrowPaint);
    canvas.drawLine(Offset(center.dx + 14, center.dy - 10),
        Offset(center.dx + 20, center.dy - 10), arrowPaint);
    canvas.drawLine(Offset(center.dx + 20, center.dy - 16),
        Offset(center.dx + 20, center.dy - 10), arrowPaint);

    // Mouth dot
    canvas.drawCircle(
        Offset(center.dx - 2, center.dy - 35), 4, skinPaint);
    canvas.drawCircle(
        Offset(center.dx - 2, center.dy - 35), 4, skinStroke);
  }
}

class _SilVousPlaitPainter extends _HandPainterBase {
  _SilVousPlaitPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.8;

    // Two open hands side by side
    drawWrist(canvas, Offset(center.dx - 18, center.dy + 5), s * 0.7);
    drawOpenHand(canvas, size, Offset(center.dx - 18, center.dy), s * 0.7);
    drawWrist(canvas, Offset(center.dx + 18, center.dy + 5), s * 0.7);
    drawOpenHand(canvas, size, Offset(center.dx + 18, center.dy), s * 0.7,
        mirrorX: true);

    // Arrow up
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy + 30),
        Offset(center.dx, center.dy + 15), arrowPaint);
    canvas.drawLine(Offset(center.dx - 5, center.dy + 20),
        Offset(center.dx, center.dy + 15), arrowPaint);
    canvas.drawLine(Offset(center.dx + 5, center.dy + 20),
        Offset(center.dx, center.dy + 15), arrowPaint);
  }
}

class _ExcusezMoiPainter extends _HandPainterBase {
  _ExcusezMoiPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.85;

    drawWrist(canvas, center, s);
    drawOpenHand(canvas, size, center, s);

    // Small head outline to show hand near head
    canvas.drawCircle(
        Offset(center.dx - 28, center.dy - 35), 10, skinPaint);
    canvas.drawCircle(
        Offset(center.dx - 28, center.dy - 35), 10, skinStroke);

    // Arrow: hand slightly moves
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 5, center.dy - 15),
        Offset(center.dx + 10, center.dy - 15), arrowPaint);
    canvas.drawLine(Offset(center.dx + 5, center.dy - 20),
        Offset(center.dx + 10, center.dy - 15), arrowPaint);
    canvas.drawLine(Offset(center.dx + 5, center.dy - 10),
        Offset(center.dx + 10, center.dy - 15), arrowPaint);
  }
}

// ============================================================
// URGENCE GESTURES
// ============================================================

class _AuSecoursPainter extends _HandPainterBase {
  _AuSecoursPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    const s = 0.68;

    // Two clearly separated raised hands.
    final left = Offset(center.dx - 24, center.dy + 4);
    final right = Offset(center.dx + 24, center.dy + 4);
    drawWrist(canvas, left, s);
    drawOpenHand(canvas, size, left, s);
    drawWrist(canvas, right, s);
    drawOpenHand(canvas, size, right, s, mirrorX: true);

    // Upward urgency arrows (clean, non-overlapping).
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawUpArrow(Offset base) {
      final tip = Offset(base.dx, base.dy - 16);
      canvas.drawLine(base, tip, arrowPaint);
      canvas.drawLine(Offset(tip.dx - 4, tip.dy + 6), tip, arrowPaint);
      canvas.drawLine(Offset(tip.dx + 4, tip.dy + 6), tip, arrowPaint);
    }

    drawUpArrow(Offset(left.dx, left.dy - 36));
    drawUpArrow(Offset(right.dx, right.dy - 36));

    // Subtle alert marks on top for readability.
    final markPaint = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 6, center.dy - 50),
      Offset(center.dx - 2, center.dy - 58),
      markPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy - 50),
      Offset(center.dx + 2, center.dy - 58),
      markPaint,
    );
  }
}

class _MedecinPainter extends _HandPainterBase {
  _MedecinPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.85;

    // Arm horizontal (wrist pulse check)
    final armPaint = Paint()
      ..color = const Color(0xFFFAD7A0)
      ..style = PaintingStyle.fill;
    final armStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final armPath = Path()
      ..moveTo(center.dx - 40, center.dy + 5)
      ..lineTo(center.dx + 10, center.dy + 5)
      ..lineTo(center.dx + 10, center.dy + 20)
      ..lineTo(center.dx - 40, center.dy + 20)
      ..close();
    canvas.drawPath(armPath, armPaint);
    canvas.drawPath(armPath, armStroke);

    // M letter = index + middle fingers extended (letter M in sign language)
    drawWrist(canvas, Offset(center.dx - 5, center.dy - 15), s * 0.8);

    // Simplified hand with 3 fingers up
    final handPaint = skinPaint;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx - 5, center.dy - 15),
                width: 22,
                height: 18),
            const Radius.circular(5)),
        handPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx - 5, center.dy - 15),
                width: 22,
                height: 18),
            const Radius.circular(5)),
        skinStroke);

    // Fingers
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  center.dx - 12 + i * 8.0, center.dy - 30, 7, 14),
              const Radius.circular(4)),
          handPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  center.dx - 12 + i * 8.0, center.dy - 30, 7, 14),
              const Radius.circular(4)),
          skinStroke);
    }

    // Pulse point indicator
    canvas.drawCircle(Offset(center.dx - 30, center.dy + 5), 5,
        Paint()..color = color..style = PaintingStyle.fill);

    // M label
    final textPainter = TextPainter(
      text: TextSpan(
          text: 'M',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx + 18, center.dy - 28));
  }
}

class _DouleurPainter extends _HandPainterBase {
  _DouleurPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.75;

    // Left index pointing right
    final leftHand = Offset(center.dx - 22, center.dy);
    // Draw arm stub
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(leftHand.dx - 12, leftHand.dy + 15), width: 18, height: 25),
            const Radius.circular(4)),
        skinPaint);
    // Index finger pointing right
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(leftHand.dx - 5, leftHand.dy - 4, 22, 8),
            const Radius.circular(4)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(leftHand.dx - 5, leftHand.dy - 4, 22, 8),
            const Radius.circular(4)),
        skinStroke);

    // Right index pointing left (mirror)
    final rightHand = Offset(center.dx + 22, center.dy);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(rightHand.dx + 12, rightHand.dy + 15), width: 18, height: 25),
            const Radius.circular(4)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rightHand.dx - 17, rightHand.dy - 4, 22, 8),
            const Radius.circular(4)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rightHand.dx - 17, rightHand.dy - 4, 22, 8),
            const Radius.circular(4)),
        skinStroke);

    // Sparks between fingers = pain
    final sparkPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 3, center.dy - 10),
        Offset(center.dx + 3, center.dy), sparkPaint);
    canvas.drawLine(Offset(center.dx + 3, center.dy),
        Offset(center.dx - 3, center.dy + 10), sparkPaint);
    canvas.drawLine(Offset(center.dx - 6, center.dy),
        Offset(center.dx + 6, center.dy), sparkPaint);
  }
}

class _AmbulancePainter extends _HandPainterBase {
  _AmbulancePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const s = 0.8;

    // Two fingers on forearm
    final armPaint = skinPaint;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx - 5, center.dy + 15), width: 50, height: 22),
            const Radius.circular(6)),
        armPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx - 5, center.dy + 15), width: 50, height: 22),
            const Radius.circular(6)),
        skinStroke);

    // Two fingers pointing down on arm
    for (int i = 0; i < 2; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(center.dx - 8 + i * 14.0, center.dy - 5, 8, 18),
              const Radius.circular(4)),
          skinPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(center.dx - 8 + i * 14.0, center.dy - 5, 8, 18),
              const Radius.circular(4)),
          skinStroke);
    }

    // Arrow forward
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx + 20, center.dy + 15),
        Offset(center.dx + 38, center.dy + 15), arrowPaint);
    canvas.drawLine(Offset(center.dx + 33, center.dy + 10),
        Offset(center.dx + 38, center.dy + 15), arrowPaint);
    canvas.drawLine(Offset(center.dx + 33, center.dy + 20),
        Offset(center.dx + 38, center.dy + 15), arrowPaint);
  }
}

class _UrgencePainter extends _HandPainterBase {
  _UrgencePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.85;

    // Closed fist
    final fistPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 30 * s, height: 25 * s),
          Radius.circular(8 * s)));
    canvas.drawPath(fistPath, skinPaint);
    canvas.drawPath(fistPath, skinStroke);

    // Thumb
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 12 * s, center.dy - 5 * s, 10 * s, 16 * s),
            Radius.circular(5 * s)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 12 * s, center.dy - 5 * s, 10 * s, 16 * s),
            Radius.circular(5 * s)),
        skinStroke);

    drawWrist(canvas, Offset(center.dx, center.dy + 18 * s), s);

    // Upward arrows (repeated urgence motion)
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final ay = center.dy - 22 - i * 10.0;
      canvas.drawLine(Offset(center.dx, ay + 8), Offset(center.dx, ay), arrowPaint);
      canvas.drawLine(
          Offset(center.dx - 4, ay + 5), Offset(center.dx, ay), arrowPaint);
      canvas.drawLine(
          Offset(center.dx + 4, ay + 5), Offset(center.dx, ay), arrowPaint);
    }
  }
}

// ============================================================
// TRANSPORT GESTURES
// ============================================================

class _BusPainter extends _HandPainterBase {
  _BusPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.8;

    // Two hands forming steering wheel circle
    final circlePaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final circleStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, 28 * s, circlePaint);
    canvas.drawCircle(center, 28 * s, circleStroke);
    canvas.drawCircle(center, 8 * s, skinPaint);
    canvas.drawCircle(center, 8 * s, skinStroke);

    // Left hand on wheel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx - 24 * s, center.dy),
                width: 14 * s, height: 22 * s),
            Radius.circular(6 * s)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx - 24 * s, center.dy),
                width: 14 * s, height: 22 * s),
            Radius.circular(6 * s)),
        skinStroke);

    // Right hand on wheel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx + 24 * s, center.dy),
                width: 14 * s, height: 22 * s),
            Radius.circular(6 * s)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx + 24 * s, center.dy),
                width: 14 * s, height: 22 * s),
            Radius.circular(6 * s)),
        skinStroke);

    // Arrow forward
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 8, center.dy + 38),
        Offset(center.dx + 8, center.dy + 38), arrowPaint);
    canvas.drawLine(Offset(center.dx + 3, center.dy + 33),
        Offset(center.dx + 8, center.dy + 38), arrowPaint);
    canvas.drawLine(Offset(center.dx + 3, center.dy + 43),
        Offset(center.dx + 8, center.dy + 38), arrowPaint);
  }
}

class _TaxiPainter extends _HandPainterBase {
  _TaxiPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    const s = 0.85;

    drawWrist(canvas, center, s);
    drawOpenHand(canvas, size, Offset(center.dx, center.dy - 10), s);

    // Upward arrow = arm raised
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx + 28, center.dy + 10),
        Offset(center.dx + 28, center.dy - 25), arrowPaint);
    canvas.drawLine(Offset(center.dx + 23, center.dy - 18),
        Offset(center.dx + 28, center.dy - 25), arrowPaint);
    canvas.drawLine(Offset(center.dx + 33, center.dy - 18),
        Offset(center.dx + 28, center.dy - 25), arrowPaint);
  }
}

class _GarePainter extends _HandPainterBase {
  _GarePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);

    // Two index fingers parallel = railway tracks
    final trackPaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(center.dx - 30, center.dy - 8),
        Offset(center.dx + 30, center.dy - 8), trackPaint);
    canvas.drawLine(Offset(center.dx - 30, center.dy + 8),
        Offset(center.dx + 30, center.dy + 8), trackPaint);

    // Crossties
    final tiePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2;
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(Offset(center.dx + i * 9.0, center.dy - 12),
          Offset(center.dx + i * 9.0, center.dy + 12), tiePaint);
    }

    // Hands at each end
    final leftFinger = Offset(center.dx - 38, center.dy);
    final rightFinger = Offset(center.dx + 38, center.dy);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: leftFinger, width: 10, height: 22),
            const Radius.circular(5)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: leftFinger, width: 10, height: 22),
            const Radius.circular(5)),
        skinStroke);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: rightFinger, width: 10, height: 22),
            const Radius.circular(5)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: rightFinger, width: 10, height: 22),
            const Radius.circular(5)),
        skinStroke);

    // Arrow forward
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy + 25),
        Offset(center.dx + 20, center.dy + 25), arrowPaint);
    canvas.drawLine(Offset(center.dx + 15, center.dy + 20),
        Offset(center.dx + 20, center.dy + 25), arrowPaint);
    canvas.drawLine(Offset(center.dx + 15, center.dy + 30),
        Offset(center.dx + 20, center.dy + 25), arrowPaint);
  }
}

class _BilletPainter extends _HandPainterBase {
  _BilletPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);

    // Ticket/paper between fingers
    final paperPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paperStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paper = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 5), width: 32, height: 20),
        const Radius.circular(4));
    canvas.drawRRect(paper, paperPaint);
    canvas.drawRRect(paper, paperStroke);

    // Lines on ticket
    canvas.drawLine(Offset(center.dx - 10, center.dy - 8),
        Offset(center.dx + 10, center.dy - 8), paperStroke);
    canvas.drawLine(Offset(center.dx - 10, center.dy - 3),
        Offset(center.dx + 10, center.dy - 3), paperStroke);

    // Thumb + index holding
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 20, center.dy + 5, 10, 18),
            const Radius.circular(5)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 20, center.dy + 5, 10, 18),
            const Radius.circular(5)),
        skinStroke);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 12, center.dy + 5, 10, 18),
            const Radius.circular(5)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 12, center.dy + 5, 10, 18),
            const Radius.circular(5)),
        skinStroke);

    // Arrow forward (presenting)
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy + 30),
        Offset(center.dx + 18, center.dy + 30), arrowPaint);
    canvas.drawLine(Offset(center.dx + 13, center.dy + 25),
        Offset(center.dx + 18, center.dy + 30), arrowPaint);
    canvas.drawLine(Offset(center.dx + 13, center.dy + 35),
        Offset(center.dx + 18, center.dy + 30), arrowPaint);
  }
}

class _ArretPainter extends _HandPainterBase {
  _ArretPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.85;

    drawWrist(canvas, center, s);
    // Open palm facing forward = STOP
    final palmPath = Path()
      ..moveTo(center.dx - 16, center.dy + 10)
      ..lineTo(center.dx - 18, center.dy - 8)
      ..cubicTo(center.dx - 18, center.dy - 20, center.dx - 12, center.dy - 22,
          center.dx - 8, center.dy - 22)
      ..lineTo(center.dx - 8, center.dy - 28)
      ..cubicTo(center.dx - 8, center.dy - 34, center.dx + 8, center.dy - 34,
          center.dx + 8, center.dy - 28)
      ..lineTo(center.dx + 8, center.dy - 22)
      ..lineTo(center.dx + 12, center.dy - 22)
      ..cubicTo(center.dx + 18, center.dy - 22, center.dx + 18, center.dy - 8,
          center.dx + 16, center.dy + 10)
      ..close();
    canvas.drawPath(palmPath, skinPaint);
    canvas.drawPath(palmPath, skinStroke);

    // STOP label
    final textPainter = TextPainter(
      text: TextSpan(
          text: 'STOP',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas,
        Offset(center.dx - textPainter.width / 2, center.dy + 20));
  }
}

// ============================================================
// HÔPITAL GESTURES
// ============================================================

class _InfirmierPainter extends _HandPainterBase {
  _InfirmierPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.8;

    // Arm
    final armPath = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(center.dx - 5, center.dy + 15), width: 50, height: 22),
        const Radius.circular(6));
    canvas.drawRRect(armPath, skinPaint);
    canvas.drawRRect(armPath, skinStroke);

    // Index tracing a cross
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx - 5, center.dy - 5), width: 8, height: 28),
            const Radius.circular(4)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx - 5, center.dy - 5), width: 8, height: 28),
            const Radius.circular(4)),
        skinStroke);

    // Cross symbol on arm
    final crossPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 25, center.dy + 15),
        Offset(center.dx - 15, center.dy + 15), crossPaint);
    canvas.drawLine(Offset(center.dx - 20, center.dy + 10),
        Offset(center.dx - 20, center.dy + 20), crossPaint);
  }
}

class _MedicamentPainter extends _HandPainterBase {
  _MedicamentPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    const s = 0.8;

    // Pill between thumb and index
    final pillPaint = Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.fill;
    final pillStroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;

    canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 20, height: 12),
        pillPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 20, height: 12),
        pillStroke);

    // Line through pill
    canvas.drawLine(Offset(center.dx - 10, center.dy - 10),
        Offset(center.dx + 10, center.dy - 10), pillStroke);

    // Thumb
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 20, center.dy, 14, 10),
            const Radius.circular(5)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 20, center.dy, 14, 10),
            const Radius.circular(5)),
        skinStroke);

    // Index
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 8, center.dy, 12, 10),
            const Radius.circular(5)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 8, center.dy, 12, 10),
            const Radius.circular(5)),
        skinStroke);

    // Arrow toward mouth
    final mouthPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Mouth symbol
    canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + 30, center.dy - 15), width: 18, height: 12),
        0.3, 2.5, false, mouthPaint);

    canvas.drawLine(Offset(center.dx + 12, center.dy + 5),
        Offset(center.dx + 22, center.dy - 10), mouthPaint);
    canvas.drawLine(Offset(center.dx + 17, center.dy - 8),
        Offset(center.dx + 22, center.dy - 10), mouthPaint);
    canvas.drawLine(Offset(center.dx + 20, center.dy - 4),
        Offset(center.dx + 22, center.dy - 10), mouthPaint);
  }
}

class _RendezVousPainter extends _HandPainterBase {
  _RendezVousPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);

    // Calendar/agenda shape
    final calPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final calStroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;

    final calRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy), width: 42, height: 38),
        const Radius.circular(6));
    canvas.drawRRect(calRect, calPaint);
    canvas.drawRRect(calRect, calStroke);

    // Calendar header
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 21, center.dy - 19, 42, 12),
            const Radius.circular(4)),
        Paint()..color = color..style = PaintingStyle.fill);

    // Grid lines
    final gridPaint = Paint()..color = color.withOpacity(0.3)..strokeWidth = 1;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawCircle(
            Offset(center.dx - 10 + c * 10.0, center.dy - 2 + r * 8.0), 2,
            Paint()..color = color.withOpacity(0.5)..style = PaintingStyle.fill);
      }
    }

    // Index finger pointing at calendar
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 18, center.dy - 5, 8, 18),
            const Radius.circular(4)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 18, center.dy - 5, 8, 18),
            const Radius.circular(4)),
        skinStroke);
  }
}

class _OperationPainter extends _HandPainterBase {
  _OperationPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);

    // Arm
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + 15), width: 55, height: 22),
            const Radius.circular(6)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + 15), width: 55, height: 22),
            const Radius.circular(6)),
        skinStroke);

    // Index sliding along arm (operation gesture)
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 18, center.dy, 8, 14),
            const Radius.circular(4)),
        skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 18, center.dy, 8, 14),
            const Radius.circular(4)),
        skinStroke);

    // Slide motion arrow
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 14, center.dy + 7),
        Offset(center.dx + 14, center.dy + 7), arrowPaint);
    canvas.drawLine(Offset(center.dx + 9, center.dy + 2),
        Offset(center.dx + 14, center.dy + 7), arrowPaint);
    canvas.drawLine(Offset(center.dx + 9, center.dy + 12),
        Offset(center.dx + 14, center.dy + 7), arrowPaint);

    // Dashed incision line on arm
    final dashPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(center.dx - 15 + i * 7.0, center.dy + 15),
          Offset(center.dx - 11 + i * 7.0, center.dy + 15),
          dashPaint);
    }
  }
}

class _DefaultHandPainter extends _HandPainterBase {
  _DefaultHandPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    drawWrist(canvas, center, 0.85);
    drawOpenHand(canvas, size, center, 0.85);
  }
}