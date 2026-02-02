import 'dart:math';
import 'dart:ui' show MaskFilter, BlurStyle;
import 'package:flutter/material.dart';
import 'game_controller.dart';

class DishPainter extends CustomPainter {
  final GameController c;
  final bool isDark;
  DishPainter(this.c, {this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    _drawDishBackground(canvas, size, rect);
    _drawHoverPreview(canvas, size);

    // pulses
    for (final p in c.pulses) {
      final t = (p.ttl / p.maxTtl).clamp(0.0, 1.0);
      final radius = _lerp(size.width * 0.02, size.width * 0.10, (1 - t));
      canvas.drawCircle(
        Offset(p.pos.dx * size.width, p.pos.dy * size.height),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = p.color.withOpacity(0.26 * t),
      );
    }

    // particles
    for (final p in c.particles) {
      final o = p.ttl.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.pos.dx * size.width, p.pos.dy * size.height),
        max(1.0, p.r * size.width),
        Paint()..color = p.color.withOpacity(0.55 * o),
      );
    }

    // support aura rings
    for (final s in c.cells.where((x) => x.type == CellType.support)) {
      final range = (CellType.support.baseRange + c.supportAuraRangeBonus) * size.width;
      final pos = Offset(s.x * size.width, s.y * size.height);
      canvas.drawCircle(
        pos,
        range,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = CellType.support.color.withOpacity(0.12),
      );

      canvas.drawCircle(
        pos,
        range * 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withOpacity(0.08),
      );
    }

    // cells
    for (final cell in c.cells) {
      final pos = Offset(cell.x * size.width, cell.y * size.height);
      _drawCell(canvas, pos, size, cell, c.renderTime);
    }

    // beams
    for (final b in c.beams) {
      final a = b.ttl.clamp(0.0, 1.0);
      final p1 = Offset(b.from.dx * size.width, b.from.dy * size.height);
      final p2 = Offset(b.to.dx * size.width, b.to.dy * size.height);

      final baseWidth = b.style == BeamStyle.laser ? 3.2 : 5.0;

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = b.color.withOpacity(0.35 + 0.65 * a)
          ..strokeWidth = baseWidth
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withOpacity(0.18 * a)
          ..strokeWidth = baseWidth * 2.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // viruses
    for (final v in c.viruses) {
      final pos = Offset(v.x * size.width, v.y * size.height);
      _drawVirusUnique(canvas, pos, size, v, c.renderTime);
    }

    // impacts
    for (final i in c.impacts) {
      final t = i.ttl.clamp(0.0, 1.0);
      final pos = Offset(i.pos.dx * size.width, i.pos.dy * size.height);
      canvas.drawCircle(pos, size.width * 0.010, Paint()..color = i.color.withOpacity(0.18 * t));
      canvas.drawCircle(
        pos,
        size.width * 0.024,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = i.color.withOpacity(0.14 * t),
      );
    }

    final label = c.gameOver
        ? (c.victory ? "VICTORY — You defended the organism!" : "DEFEAT — Infection overwhelmed tissue!")
        : (c.rewardPending
            ? "Choose an upgrade (or open Research)."
            : (c.waveActive ? "Wave ${c.wave} — Containment in progress" : "Build Phase — Place cells freely"));

    final labelColor = isDark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.62);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, const Offset(12, 10));
  }

  void _drawDishBackground(Canvas canvas, Size size, Rect rect) {
    final bg = RadialGradient(
      center: const Alignment(0.15, -0.2),
      radius: 1.25,
      colors: isDark
          ? const [
              Color(0xFF0B101C),
              Color(0xFF121A2D),
              Color(0xFF1A253A),
              Color(0xFF212C3F),
            ]
          : const [
              Color(0xFF122345),
              Color(0xFF17305A),
              Color(0xFF1E3C6C),
              Color(0xFF23467A),
            ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = bg.createShader(rect));

    // Tissue depth vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withOpacity(isDark ? 0.24 : 0.16)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );

    final r = Random(1337);
    final skinThickness = 0.07;
    final vesselThickness = 0.07;

    Rect _edgeRect(BoardEdge edge, double thickness) {
      switch (edge) {
        case BoardEdge.left:
          return Rect.fromLTWH(0, 0, size.width * thickness, size.height);
        case BoardEdge.right:
          return Rect.fromLTWH(size.width * (1 - thickness), 0, size.width * thickness, size.height);
        case BoardEdge.top:
          return Rect.fromLTWH(0, 0, size.width, size.height * thickness);
        case BoardEdge.bottom:
          return Rect.fromLTWH(0, size.height * (1 - thickness), size.width, size.height * thickness);
      }
    }

    // Skin-like tissue (spawn edge)
    final skinRect = _edgeRect(c.boardPreset.spawnEdge, skinThickness);
    canvas.drawRect(
      skinRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF1C7B2).withOpacity(isDark ? 0.18 : 0.32),
            const Color(0xFFD89A83).withOpacity(isDark ? 0.16 : 0.26),
          ],
        ).createShader(skinRect),
    );
    final skinSpeck = Paint()..color = Colors.white.withOpacity(isDark ? 0.06 : 0.10);
    for (int i = 0; i < 70; i++) {
      final x = skinRect.left + r.nextDouble() * skinRect.width;
      final y = skinRect.top + r.nextDouble() * skinRect.height;
      final rr = 0.6 + r.nextDouble() * 1.6;
      canvas.drawCircle(Offset(x, y), rr, skinSpeck);
    }

    // Vessel wall (exit edge) + lumen glow inward
    final wallPaint = Paint()
      ..color = const Color(0xFF8A1B26).withOpacity(isDark ? 0.45 : 0.58);
    final vesselRect = _edgeRect(c.boardPreset.exitEdge, vesselThickness);
    canvas.drawRect(vesselRect, wallPaint);

    Rect lumenRect;
    Alignment lumenBegin;
    Alignment lumenEnd;
    switch (c.boardPreset.exitEdge) {
      case BoardEdge.right:
        lumenRect = Rect.fromLTWH(size.width * 0.85, 0, size.width * 0.08, size.height);
        lumenBegin = Alignment.centerRight;
        lumenEnd = Alignment.centerLeft;
        break;
      case BoardEdge.left:
        lumenRect = Rect.fromLTWH(size.width * 0.07, 0, size.width * 0.08, size.height);
        lumenBegin = Alignment.centerLeft;
        lumenEnd = Alignment.centerRight;
        break;
      case BoardEdge.top:
        lumenRect = Rect.fromLTWH(0, size.height * 0.07, size.width, size.height * 0.08);
        lumenBegin = Alignment.topCenter;
        lumenEnd = Alignment.bottomCenter;
        break;
      case BoardEdge.bottom:
        lumenRect = Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.08);
        lumenBegin = Alignment.bottomCenter;
        lumenEnd = Alignment.topCenter;
        break;
    }
    canvas.drawRect(
      lumenRect,
      Paint()
        ..shader = LinearGradient(
          begin: lumenBegin,
          end: lumenEnd,
          colors: [
            const Color(0xFF6B0F1B).withOpacity(isDark ? 0.28 : 0.40),
            Colors.transparent,
          ],
        ).createShader(lumenRect),
    );

    // Floating blood cells (soft discs)
    final cellPaint = Paint()..color = const Color(0xFF9E1C2B).withOpacity(isDark ? 0.30 : 0.40);
    final cellRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withOpacity(isDark ? 0.06 : 0.10);
    for (int i = 0; i < 18; i++) {
      final x = size.width * (0.18 + r.nextDouble() * 0.78);
      final y = size.height * r.nextDouble();
      final rr = size.width * (0.013 + r.nextDouble() * 0.010);
      canvas.drawCircle(Offset(x, y), rr, cellPaint);
      canvas.drawCircle(Offset(x, y), rr * 0.70, Paint()..color = Colors.black.withOpacity(0.04));
      if (i.isEven) canvas.drawCircle(Offset(x, y), rr * 0.88, cellRim);
    }

    // Bio glow dust
    final speckPaint = Paint()..color = Colors.white.withOpacity(isDark ? 0.06 : 0.10);
    for (int i = 0; i < 140; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final rr = 0.4 + r.nextDouble() * 1.4;
      canvas.drawCircle(Offset(x, y), rr, speckPaint);
    }

    // Light streaks (immune energy)
    final streak = Paint()
      ..color = const Color(0xFF7FDBFF).withOpacity(isDark ? 0.16 : 0.22)
      ..strokeWidth = size.width * 0.008
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.30 + i * 0.22);
      canvas.drawLine(Offset(size.width * 0.25, y), Offset(size.width * 0.90, y - size.height * 0.06), streak);
    }

    _drawExitHighlight(canvas, size);

    // Subtle membrane edge
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withOpacity(0.18),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black.withOpacity(0.08),
    );
  }

  void _drawExitHighlight(Canvas canvas, Size size) {
    final exit = c.boardPreset.exitEdge;
    final highlightColor = const Color(0xFFFF9AA5);

    Rect rect;
    Alignment begin;
    Alignment end;
    List<Offset> chevrons = [];

    switch (exit) {
      case BoardEdge.right:
        rect = Rect.fromLTWH(size.width * 0.92, 0, size.width * 0.08, size.height);
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        for (int i = 0; i < 7; i++) {
          final cy = size.height * (0.10 + i * 0.13);
          final cx = size.width * 0.95;
          chevrons.addAll([Offset(cx - 8, cy - 6), Offset(cx, cy), Offset(cx - 8, cy + 6)]);
        }
        break;
      case BoardEdge.left:
        rect = Rect.fromLTWH(0, 0, size.width * 0.08, size.height);
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        for (int i = 0; i < 7; i++) {
          final cy = size.height * (0.10 + i * 0.13);
          final cx = size.width * 0.05;
          chevrons.addAll([Offset(cx + 8, cy - 6), Offset(cx, cy), Offset(cx + 8, cy + 6)]);
        }
        break;
      case BoardEdge.top:
        rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.08);
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        for (int i = 0; i < 7; i++) {
          final cx = size.width * (0.10 + i * 0.13);
          final cy = size.height * 0.05;
          chevrons.addAll([Offset(cx - 6, cy + 8), Offset(cx, cy), Offset(cx + 6, cy + 8)]);
        }
        break;
      case BoardEdge.bottom:
        rect = Rect.fromLTWH(0, size.height * 0.92, size.width, size.height * 0.08);
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        for (int i = 0; i < 7; i++) {
          final cx = size.width * (0.10 + i * 0.13);
          final cy = size.height * 0.95;
          chevrons.addAll([Offset(cx - 6, cy - 8), Offset(cx, cy), Offset(cx + 6, cy - 8)]);
        }
        break;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: begin,
          end: end,
          colors: [
            Colors.transparent,
            highlightColor.withOpacity(isDark ? 0.30 : 0.22),
            highlightColor.withOpacity(isDark ? 0.50 : 0.38),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    final chevronPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.32 : 0.20)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i + 2 < chevrons.length; i += 3) {
      canvas.drawLine(chevrons[i], chevrons[i + 1], chevronPaint);
      canvas.drawLine(chevrons[i + 1], chevrons[i + 2], chevronPaint);
    }
  }

  void _drawHoverPreview(Canvas canvas, Size size) {
    final hp = c.hoverPos;
    if (hp == null) return;

    final can = c.canPlaceAt(hp);
    final p = Offset(hp.dx * size.width, hp.dy * size.height);
    final range = (c.selectedCell.baseRange +
            (c.selectedCell == CellType.killer ? c.killerRangeBonus : 0.0)) *
        size.width;

    canvas.drawCircle(
      p,
      range,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c.selectedCell.color.withOpacity(0.14),
    );

    canvas.drawCircle(p, size.width * 0.010, Paint()..color = (can ? Colors.teal : Colors.red).withOpacity(0.65));
    canvas.drawCircle(
      p,
      size.width * 0.018,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (can ? Colors.teal : Colors.red).withOpacity(0.25),
    );
  }

  /// ===============================
  /// Cell graphics
  /// ===============================
  void _drawCell(Canvas canvas, Offset pos, Size size, CellUnit cell, double t) {
    final baseR = size.width * 0.018 * (1 + (cell.tier - 1) * 0.22);

    canvas.drawCircle(
      pos.translate(0, baseR * 0.26),
      baseR * 1.05,
      Paint()
        ..color = Colors.black.withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    if (cell.tier > 1) {
      final pulse = 0.85 + 0.15 * sin(t * 3.0 + cell.x * 30);
      canvas.drawCircle(
        pos,
        baseR * (1.55 + 0.10 * cell.tier) * pulse,
        Paint()
          ..color = cell.type.color.withOpacity(0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    switch (cell.type) {
      case CellType.killer:
        _drawKiller(canvas, pos, baseR, cell.tier, t);
        break;
      case CellType.macrophage:
        _drawMacrophage(canvas, pos, baseR, cell.tier, t);
        break;
      case CellType.support:
        _drawSupport(canvas, pos, baseR, cell.tier, t);
        break;
      case CellType.sentinel:
        _drawSentinel(canvas, pos, baseR, cell.tier, t);
        break;
      case CellType.cleaner:
        _drawCleaner(canvas, pos, baseR, cell.tier, t);
        break;
    }

    if (cell.type != CellType.support) {
      final range =
          (cell.range + (cell.type == CellType.killer ? c.killerRangeBonus : 0.0)) * size.width;
      canvas.drawCircle(
        pos,
        range,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = cell.type.color.withOpacity(0.10),
      );
    }

    if (cell.tier > 1) {
      final badge = pos.translate(baseR * 0.95, -baseR * 0.95);
      canvas.drawCircle(badge, baseR * 0.45, Paint()..color = Colors.black.withOpacity(0.22));
      final tp = TextPainter(
 text: TextSpan(
          text: "T${cell.tier}",
          style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w900, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, badge - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawKiller(Canvas canvas, Offset c, double r, int tier, double t) {
    canvas.drawCircle(c, r, Paint()..color = Colors.teal.withOpacity(0.92));
    canvas.drawCircle(
      c,
      r * 1.03,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.22),
    );

    canvas.drawCircle(c, r * 0.78, Paint()..color = Colors.teal.shade700.withOpacity(0.22));

    final nucleus = c.translate(r * 0.12, -r * 0.10);
    canvas.drawCircle(nucleus, r * 0.45, Paint()..color = Colors.teal.shade900.withOpacity(0.55));

    final gPaint = Paint()..color = Colors.white.withOpacity(0.24);
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi + t * 0.6;
      final p = c + Offset(cos(a) * r * 0.45, sin(a) * r * 0.35);
      canvas.drawCircle(p, r * 0.08, gPaint);
    }

    canvas.drawCircle(
      c.translate(-r * 0.28, -r * 0.28),
      r * 0.14,
      Paint()..color = Colors.white.withOpacity(0.35),
    );

    if (tier >= 3) {
      final hornPaint = Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final p1 = c.translate(-r * 0.65, -r * 0.15);
      final p2 = c.translate(-r * 0.95, -r * 0.45);
      final p3 = c.translate(-r * 0.55, -r * 0.55);
      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy), hornPaint);

      final q1 = c.translate(r * 0.65, -r * 0.15);
      final q2 = c.translate(r * 0.95, -r * 0.45);
      final q3 = c.translate(r * 0.55, -r * 0.55);
      canvas.drawPath(Path()..moveTo(q1.dx, q1.dy)..lineTo(q2.dx, q2.dy)..lineTo(q3.dx, q3.dy), hornPaint);
    }
  }

  void _drawMacrophage(Canvas canvas, Offset c, double r, int tier, double t) {
    final steps = 14;
    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final ang = (i / steps) * 2 * pi;
      final wobble = 0.12 * sin(t * 1.9 + i * 0.8) + 0.06 * sin(t * 3.2 + i * 1.3);
      final rr = r * (1.0 + wobble);
      final p = c + Offset(cos(ang) * rr, sin(ang) * rr);
      if (i == 0) path.moveTo(p.dx, p.dy);
      else path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, Paint()..color = Colors.orange.withOpacity(0.90));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.22),
    );

    canvas.drawCircle(c.translate(r * 0.12, r * 0.06), r * 0.40, Paint()..color = Colors.brown.withOpacity(0.25));

    final bubble = Paint()..color = Colors.white.withOpacity(0.16);
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * 2 * pi + t * 0.5;
      final p = c + Offset(cos(a) * r * 0.35, sin(a) * r * 0.28);
      canvas.drawCircle(p, r * 0.14, bubble);
    }

    if (tier >= 2) {
      canvas.drawCircle(
        c,
        r * 1.25,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.orangeAccent.withOpacity(0.10),
      );
    }
  }

  void _drawSupport(Canvas canvas, Offset c, double r, int tier, double t) {
    canvas.drawCircle(c, r, Paint()..color = Colors.indigo.withOpacity(0.92));
    canvas.drawCircle(
      c,
      r * 1.03,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.22),
    );

    final coreR = r * 0.55;
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi + t * 0.25;
      final p = c + Offset(cos(a) * coreR, sin(a) * coreR);
      if (i == 0) hex.moveTo(p.dx, p.dy);
      else hex.lineTo(p.dx, p.dy);
    }
    hex.close();

    canvas.drawPath(hex, Paint()..color = Colors.indigo.shade900.withOpacity(0.35));

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.15);

    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.85), -pi / 2 + t * 0.4, pi * 0.65, false, arcPaint);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.72), pi / 2 - t * 0.35, pi * 0.55, false, arcPaint);

    if (tier >= 3) {
      canvas.drawCircle(
        c,
        r * 1.6,
        Paint()
          ..color = Colors.indigoAccent.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  void _drawSentinel(Canvas canvas, Offset c, double r, int tier, double t) {
    canvas.drawCircle(c, r, Paint()..color = Colors.cyan.withOpacity(0.90));
    canvas.drawCircle(
      c,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.22),
    );

    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-r * 0.55, 0), c.translate(r * 0.55, 0), crossPaint);
    canvas.drawLine(c.translate(0, -r * 0.55), c.translate(0, r * 0.55), crossPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.cyanAccent.withOpacity(0.18);
    canvas.drawCircle(c, r * (0.55 + 0.05 * sin(t * 2.4)), ringPaint);

    if (tier >= 2) {
      canvas.drawCircle(
        c,
        r * 1.35,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.cyanAccent.withOpacity(0.10),
      );
    }
  }

  void _drawCleaner(Canvas canvas, Offset c, double r, int tier, double t) {
    canvas.drawCircle(c, r, Paint()..color = Colors.green.withOpacity(0.90));
    canvas.drawCircle(
      c,
      r * 1.05,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.22),
    );

    final core = Paint()..color = Colors.greenAccent.withOpacity(0.22);
    canvas.drawCircle(c, r * 0.55, core);

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withOpacity(0.18);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.75), t * 0.7, pi * 0.7, false, wavePaint);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.55), -t * 0.6, pi * 0.6, false, wavePaint);

    if (tier >= 3) {
      canvas.drawCircle(
        c,
        r * 1.45,
        Paint()
          ..color = Colors.greenAccent.withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  /// ===============================
  /// VIRUS GRAPHICS — UNIQUE PER TYPE
  /// ===============================
  void _drawVirusUnique(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    switch (v.type) {
      case VirusType.swarm:
        _drawSwarmVirus(canvas, pos, size, v, t);
        break;
      case VirusType.tank:
        _drawTankVirus(canvas, pos, size, v, t);
        break;
      case VirusType.stealth:
        _drawStealthVirusFading(canvas, pos, size, v, t);
        break;
      case VirusType.boss:
        _drawBossVirus(canvas, pos, size, v, t);
        break;
      case VirusType.leech:
        _drawLeechVirus(canvas, pos, size, v, t);
        break;
      case VirusType.spore:
        _drawSporeVirus(canvas, pos, size, v, t);
        break;
    }
  }

  void _drawSwarmVirus(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    final r = size.width * 0.0125;
    final jitter = 0.25 + 0.15 * sin(t * 6.0 + v.y * 20.0);
    final sync = (0.60 + 0.40 * sin(t * 3.2 + v.x * 8.0)).clamp(0.0, 1.0);

    // Soft underglow
    canvas.drawCircle(
      pos,
      r * 1.60,
      Paint()
        ..color = v.type.color.withOpacity(0.14 + 0.12 * sync)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    canvas.drawCircle(
      pos.translate(0, r * 0.22),
      r * 1.15,
      Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final spikes = 11;
    for (int i = 0; i < spikes; i++) {
      final a = (i / spikes) * 2 * pi + t * 0.6;
      final len = r * (0.65 + 0.40 * sin(i * 1.7 + t * 2.2)) * sync;
      final p1 = pos + Offset(cos(a) * r * 1.05, sin(a) * r * 1.05);
      final p2 = pos + Offset(cos(a) * (r * 1.05 + len), sin(a) * (r * 1.05 + len));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = v.type.color.withOpacity(0.70)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(p2, r * 0.11, Paint()..color = Colors.white.withOpacity(0.18));
    }

    canvas.drawCircle(pos, r, Paint()..color = v.type.color.withOpacity(0.88));

    // Biomechanical plating ring + micro vents
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white.withOpacity(0.22 + 0.16 * sync);
    canvas.drawCircle(pos, r * (1.18 + 0.14 * sync), ringPaint);
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi + t * 0.4;
      final p = pos + Offset(cos(a) * r * 0.85, sin(a) * r * 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: r * 0.32, height: r * 0.16),
          Radius.circular(r * 0.08),
        ),
        Paint()..color = Colors.black.withOpacity(0.10),
      );
    }

    // Inner lattice lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * 2 * pi + t * 0.25;
      final p1 = pos + Offset(cos(a) * r * 0.15, sin(a) * r * 0.15);
      final p2 = pos + Offset(cos(a) * r * 0.65, sin(a) * r * 0.65);
      canvas.drawLine(p1, p2, linePaint);
    }

    final core = pos.translate(sin(t * 5 + v.x * 10) * r * 0.14, cos(t * 4 + v.y * 12) * r * 0.14);
    canvas.drawCircle(
      core,
      r * (0.43 + 0.08 * jitter),
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawCircle(core, r * 0.22, Paint()..color = Colors.white.withOpacity(0.18));

    _drawHpRing(canvas, pos, r, v, boss: false);
    _drawShieldIfAny(canvas, pos, r, v, t);
    _drawStatusMarkers(canvas, pos, r, v, t);
  }

  void _drawTankVirus(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    final r = size.width * 0.0185;
    final piston = (0.45 + 0.55 * sin(t * 2.0 + v.y * 10.0)).clamp(0.0, 1.0);

    // Heavy glow + shadow
    canvas.drawCircle(
      pos,
      r * 1.75,
      Paint()
        ..color = v.type.color.withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    canvas.drawCircle(
      pos.translate(0, r * 0.25),
      r * 1.25,
      Paint()
        ..color = Colors.black.withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      pos,
      r * (1.03 + 0.07 * piston),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = v.type.color.withOpacity(0.85),
    );

    // Inner gear ring
    canvas.drawCircle(
      pos,
      r * 0.66,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = Colors.white.withOpacity(0.26),
    );

    final panels = 6;
    for (int i = 0; i < panels; i++) {
      final a = (i / panels) * 2 * pi + t * 0.15;
      final p = pos + Offset(cos(a) * r * 0.55, sin(a) * r * 0.55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: r * 0.55, height: r * (0.28 + 0.22 * piston)),
          Radius.circular(r * 0.15),
        ),
        Paint()..color = Colors.black.withOpacity(0.10 + 0.14 * piston),
      );
    }

    // Biomechanical "armor plates"
    for (int i = 0; i < 5; i++) {
      final a = (i / 5) * 2 * pi - t * 0.25;
      final plate = pos + Offset(cos(a) * r * 0.22, sin(a) * r * 0.22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: plate, width: r * 0.55, height: r * (0.16 + 0.12 * piston)),
          Radius.circular(r * 0.10),
        ),
        Paint()..color = Colors.white.withOpacity(0.10 + 0.14 * piston),
      );
    }

    // Rivet dots
    for (int i = 0; i < 8; i++) {
      final a = (i / 8) * 2 * pi + t * 0.2;
      final p = pos + Offset(cos(a) * r * 0.78, sin(a) * r * 0.78);
      canvas.drawCircle(p, r * 0.07, Paint()..color = Colors.black.withOpacity(0.20));
    }

    final spikes = 10;
    for (int i = 0; i < spikes; i++) {
      final a = (i / spikes) * 2 * pi - t * 0.10;
      final len = r * 0.55;
      final p1 = pos + Offset(cos(a) * r * 1.02, sin(a) * r * 1.02);
      final p2 = pos + Offset(cos(a) * (r * 1.02 + len), sin(a) * (r * 1.02 + len));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = v.type.color.withOpacity(0.75)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(pos, r, Paint()..color = v.type.color.withOpacity(0.78));

    canvas.drawCircle(
      pos,
      r * 0.50,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    _drawHpRing(canvas, pos, r, v, boss: false);
    _drawShieldIfAny(canvas, pos, r, v, t);
    _drawStatusMarkers(canvas, pos, r, v, t);
  }

  /// ✅ NEW: real fading stealth virus (goes almost invisible but distortion remains)
  void _drawStealthVirusFading(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    final r = size.width * 0.0145;

    // Fade oscillation (0..1)
    final osc = 0.5 + 0.5 * sin(t * 2.2 + v.x * 11.0 + v.y * 17.0);

    // Body alpha ramps low/high (nearly vanishes)
    final bodyAlpha = _lerp(0.08, 0.62, osc);

    // Distortion alpha stays visible even when "invisible"
    final distortAlpha = _lerp(0.10, 0.22, 1 - osc);

    // Glassy halo
    canvas.drawCircle(
      pos,
      r * 1.75,
      Paint()
        ..color = Colors.white.withOpacity(0.10 * bodyAlpha + 0.12 * distortAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Afterimage shimmer (soft trail feel)
    for (int k = 0; k < 2; k++) {
      final off = Offset(-r * (0.20 + 0.18 * k), sin(t * 2.0 + k) * r * 0.10);
      canvas.drawCircle(
        pos + off,
        r * (1.10 + 0.05 * k),
        Paint()
          ..color = v.type.color.withOpacity(0.08 * bodyAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    // Haze shadow
    canvas.drawCircle(
      pos.translate(0, r * 0.18),
      r * 1.40,
      Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Distortion rings
    for (int k = 0; k < 3; k++) {
      final rr = r * (1.25 + k * 0.35) * (0.90 + 0.12 * sin(t * 2.0 + k));
      canvas.drawCircle(
        pos.translate(sin(t * 1.5 + k) * r * 0.10, cos(t * 1.4 + k) * r * 0.10),
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withOpacity(distortAlpha),
      );
    }

    // Circuit-like arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.16 * bodyAlpha + 0.18 * distortAlpha);
    canvas.drawArc(Rect.fromCircle(center: pos, radius: r * 0.85), t * 0.4, pi * 0.65, false, arcPaint);
    canvas.drawArc(Rect.fromCircle(center: pos, radius: r * 0.65), -t * 0.35, pi * 0.55, false, arcPaint);

    // Biomechanical stealth panels (phase shimmer)
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * 2 * pi + t * 0.5;
      final p = pos + Offset(cos(a) * r * 0.55, sin(a) * r * 0.55);
      final shimmer = (0.45 + 0.55 * sin(t * 6.0 + i * 1.7 + v.x * 9.0)).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: r * 0.38, height: r * (0.10 + 0.20 * shimmer)),
          Radius.circular(r * 0.08),
        ),
        Paint()..color = Colors.white.withOpacity(0.06 * bodyAlpha + 0.12 * shimmer),
      );
    }

    // Soft spikes (fade heavily)
    final spikes = 8;
    for (int i = 0; i < spikes; i++) {
      final a = (i / spikes) * 2 * pi + t * 0.35;
      final len = r * 0.55 * (0.75 + 0.25 * osc);
      final p1 = pos + Offset(cos(a) * r * 1.0, sin(a) * r * 1.0);
      final p2 = pos + Offset(cos(a) * (r * 1.0 + len), sin(a) * (r * 1.0 + len));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = v.type.color.withOpacity(0.22 * bodyAlpha)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Main ghost body (this is what disappears)
    canvas.drawCircle(
      pos,
      r,
      Paint()..color = v.type.color.withOpacity(bodyAlpha),
    );

    // Core glint (still faintly visible)
    canvas.drawCircle(
      pos.translate(r * 0.10, -r * 0.08),
      r * 0.35,
      Paint()
        ..color = Colors.white.withOpacity(0.12 * bodyAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    _drawHpRing(canvas, pos, r, v, boss: false);
    _drawShieldIfAny(canvas, pos, r, v, t);
    _drawStatusMarkers(canvas, pos, r, v, t);
  }

  void _drawBossVirus(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    final r = size.width * 0.028;
    final pulse = 0.80 + 0.20 * sin(t * 2.2);

    // Massive glow
    canvas.drawCircle(
      pos,
      r * 2.4,
      Paint()
        ..color = v.type.color.withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    canvas.drawCircle(
      pos.translate(0, r * 0.30),
      r * 1.65,
      Paint()
        ..color = Colors.black.withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawCircle(
      pos,
      r * 2.35 * pulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.redAccent.withOpacity(0.12),
    );

    final spikes = 18;
    for (int i = 0; i < spikes; i++) {
      final a = (i / spikes) * 2 * pi + t * 0.12;
      final len = r * (0.95 + 0.22 * sin(t * 1.9 + i));
      final p1 = pos + Offset(cos(a) * r * 1.05, sin(a) * r * 1.05);
      final p2 = pos + Offset(cos(a) * (r * 1.05 + len), sin(a) * (r * 1.05 + len));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = v.type.color.withOpacity(0.85)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(p2, r * 0.11, Paint()..color = Colors.white.withOpacity(0.18));
    }

    canvas.drawCircle(pos, r, Paint()..color = v.type.color.withOpacity(0.85));
    canvas.drawCircle(
      pos,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withOpacity(0.18),
    );
    canvas.drawCircle(
      pos,
      r * 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withOpacity(0.10),
    );

    // Biomechanical spine + ports
    final spinePaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos.translate(-r * 0.65, 0), pos.translate(r * 0.65, 0), spinePaint);
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi + t * 0.2;
      final p = pos + Offset(cos(a) * r * 0.95, sin(a) * r * 0.95);
      canvas.drawCircle(
        p,
        r * 0.10,
        Paint()..color = Colors.black.withOpacity(0.12),
      );
    }

    // Inner core capsule
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: r * 0.95, height: r * 0.55),
        Radius.circular(r * 0.22),
      ),
      Paint()..color = Colors.white.withOpacity(0.16),
    );

    final veinPaint = Paint()
      ..color = Colors.black.withOpacity(0.12 + 0.06 * sin(t * 3))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi + t * 0.3;
      final p1 = pos + Offset(cos(a) * r * 0.15, sin(a) * r * 0.15);
      final p2 = pos + Offset(cos(a) * r * 0.62, sin(a) * r * 0.62);
      canvas.drawLine(p1, p2, veinPaint);
    }

    canvas.drawCircle(
      pos,
      r * (0.52 + 0.06 * sin(t * 3.0)),
      Paint()
        ..color = Colors.white.withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    _drawHpRing(canvas, pos, r, v, boss: true);
    _drawShieldIfAny(canvas, pos, r, v, t);
    _drawStatusMarkers(canvas, pos, r, v, t);
  }

  void _drawLeechVirus(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    final r = size.width * 0.0135;
    final pulse = 0.85 + 0.15 * sin(t * 3.6 + v.y * 12);

    canvas.drawCircle(
      pos.translate(0, r * 0.22),
      r * 1.25,
      Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(pos, r, Paint()..color = v.type.color.withOpacity(0.85));
    canvas.drawCircle(
      pos,
      r * 0.62 * pulse,
      Paint()..color = Colors.white.withOpacity(0.12),
    );

    final tendril = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.greenAccent.withOpacity(0.35);
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * 2 * pi + t * 0.5;
      final p1 = pos + Offset(cos(a) * r * 0.7, sin(a) * r * 0.7);
      final p2 = pos + Offset(cos(a) * r * 1.2, sin(a) * r * 1.2);
      canvas.drawLine(p1, p2, tendril);
    }

    _drawHpRing(canvas, pos, r, v, boss: false);
    _drawShieldIfAny(canvas, pos, r, v, t);
    _drawStatusMarkers(canvas, pos, r, v, t);
  }

  void _drawSporeVirus(Canvas canvas, Offset pos, Size size, VirusUnit v, double t) {
    final r = size.width * 0.0155;
    final wobble = 0.10 * sin(t * 2.8 + v.x * 9);

    canvas.drawCircle(
      pos.translate(0, r * 0.20),
      r * 1.30,
      Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(pos, r, Paint()..color = v.type.color.withOpacity(0.82));
    for (int i = 0; i < 7; i++) {
      final a = (i / 7) * 2 * pi + t * 0.4;
      final p = pos + Offset(cos(a) * r * (0.9 + wobble), sin(a) * r * (0.9 + wobble));
      canvas.drawCircle(p, r * 0.14, Paint()..color = Colors.white.withOpacity(0.12));
    }

    canvas.drawCircle(
      pos,
      r * 0.55,
      Paint()..color = Colors.white.withOpacity(0.10),
    );

    _drawHpRing(canvas, pos, r, v, boss: false);
    _drawShieldIfAny(canvas, pos, r, v, t);
    _drawStatusMarkers(canvas, pos, r, v, t);
  }

  void _drawHpRing(Canvas canvas, Offset pos, double r, VirusUnit v, {required bool boss}) {
    final pct = (v.hp / v.maxHp).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: r * (boss ? 1.70 : 1.55)),
      -pi / 2,
      2 * pi * pct,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = boss ? 3.0 : 2.2
        ..color = Colors.white.withOpacity(0.45),
    );
  }

  void _drawShieldIfAny(Canvas canvas, Offset pos, double r, VirusUnit v, double t) {
    if (v.shieldHp <= 0) return;

    final shieldPct = min(1.0, v.shieldHp / (v.maxHp * 0.45));
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.cyanAccent.withOpacity(0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: r * 1.95),
      -pi / 2 + sin(t * 1.8 + v.x * 8) * 0.14,
      2 * pi * shieldPct,
      false,
      glow,
    );

    canvas.drawCircle(
      pos,
      r * 2.05,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = Colors.white.withOpacity(0.06),
    );
  }

  void _drawStatusMarkers(Canvas canvas, Offset pos, double r, VirusUnit v, double t) {
    if (v.slowTimer > 0 && !v.traits.immuneToSlow) {
      canvas.drawCircle(
        pos,
        r * 2.1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.lightBlueAccent.withOpacity(0.22),
      );
    }

    if (v.weakenTimer > 0) {
      canvas.drawCircle(
        pos.translate(r * 0.95, -r * 0.95),
        r * 0.35,
        Paint()..color = Colors.amber.withOpacity(0.85),
      );
    }

    if (v.traits.rageSprint && v.hp < v.maxHp * 0.45) {
      final flicker = 0.40 + 0.35 * sin(t * 10.0 + v.y * 20);
      canvas.drawCircle(
        pos,
        r * 2.25,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.redAccent.withOpacity(0.10 + 0.12 * flicker),
      );
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant DishPainter oldDelegate) => true;
}
