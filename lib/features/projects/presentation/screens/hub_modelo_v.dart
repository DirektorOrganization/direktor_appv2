// ============================================================
// MODELO V — "VAPOR"
// Vaporwave — purple/pink/cyan gradients, soft glassmorphism.
// Dashboard que se siente como un videojuego de los 80s pero
// con datos reales. Para equipos creativos y tech-forward.
// Inspirado en Spotify Wrapped + Raycast + arc browser.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _V {
  static const bg1     = Color(0xFF0D0221);
  static const pink    = Color(0xFFFF2D78);
  static const pinkSft = Color(0xFFFF6B9D);
  static const purple  = Color(0xFF9B59B6);
  static const violet  = Color(0xFF6C3483);
  static const cyan    = Color(0xFF00FFFF);
  static const gold    = Color(0xFFFFD700);
  static const glass   = Color(0x18FFFFFF);
  static const border  = Color(0x30FFFFFF);
  static const white   = Color(0xFFF0E6FF);
  static const muted   = Color(0xFF9B8DBF);
}

// ── Mock data ─────────────────────────────────────────────────
const _kpis = [
  ('Avance',       '61%', _V.cyan,   Icons.trending_up_rounded),
  ('Restricciones','12',  _V.pink,   Icons.block_rounded),
  ('Hitos OK',     '3/8', _V.gold,   Icons.star_rounded),
  ('Días',         '147', _V.pinkSft,Icons.schedule_rounded),
];

const _modules = [
  ('Restricciones', Icons.block_rounded,      _V.pink,   '12 abiertas'),
  ('Hitos',         Icons.flag_rounded,        _V.cyan,   '3 completos'),
  ('Reuniones',     Icons.groups_rounded,      _V.gold,   '8 actas'),
  ('Analítica',     Icons.analytics_rounded,   _V.pinkSft,'Ver datos'),
];

const _feed = [
  ('R-039 cerrada exitosamente',    _V.cyan,   '2h',  Icons.check_circle_rounded),
  ('H-07 en riesgo de retraso',     _V.pink,   '5h',  Icons.warning_rounded),
  ('Reunión de directorio mañana',  _V.gold,   '1d',  Icons.event_rounded),
  ('Presupuesto actualizado',       _V.pinkSft,'2d',  Icons.paid_rounded),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloV extends StatelessWidget {
  const HubModeloV({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _V.bg1,
      body: Stack(
        children: [
          const _VaporBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(),
                  const SizedBox(height: 20),
                  _HeroCard(),
                  const SizedBox(height: 14),
                  _KpiRow(),
                  const SizedBox(height: 20),
                  _Label('MÓDULOS'),
                  const SizedBox(height: 10),
                  _ModuleGrid(),
                  const SizedBox(height: 20),
                  _Label('ACTIVIDAD'),
                  const SizedBox(height: 10),
                  _FeedCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vapor background ──────────────────────────────────────────
class _VaporBackground extends StatelessWidget {
  const _VaporBackground();
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _VBgPainter()));
  }
}

class _VBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    void blob(Offset c, double r, Color color) {
      canvas.drawCircle(c, r, Paint()
        ..color = color.withAlpha(70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120));
    }
    blob(Offset(s.width * 0.1,  s.height * 0.05), 180, _V.pink);
    blob(Offset(s.width * 0.9,  s.height * 0.2),  150, _V.violet);
    blob(Offset(s.width * 0.5,  s.height * 0.55), 160, _V.cyan);
    blob(Offset(s.width * 0.15, s.height * 0.85), 140, _V.purple);

    // Grid lines
    final gridPaint = Paint()..color = _V.muted.withAlpha(20)..strokeWidth = 0.5;
    for (double x = 0; x < s.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), gridPaint);
    }
    for (double y = 0; y < s.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), gridPaint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Top bar ───────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_V.pink, _V.cyan],
          ).createShader(b),
          child: const Text('VAPOR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4)),
        ),
        const SizedBox(width: 10),
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: _V.cyan, shape: BoxShape.circle),
        ),
        const Spacer(),
        _GBtn(icon: Icons.palette_rounded, onTap: () => showStylePicker(context)),
        const SizedBox(width: 8),
        _GBtn(icon: Icons.notifications_none_rounded),
        const SizedBox(width: 8),
        _GBtn(icon: Icons.person_outline_rounded),
      ],
    );
  }
}

class _GBtn extends StatelessWidget {
  const _GBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _V.glass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _V.border),
          ),
          child: Icon(icon, color: _V.muted, size: 18),
        ),
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: child) : child;
  }
}

// ── Hero card ─────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_V.pink.withAlpha(40), _V.violet.withAlpha(30), _V.cyan.withAlpha(20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _V.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Torre Mirador Norte', style: TextStyle(color: _V.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(colors: [_V.pink, _V.cyan]).createShader(b),
                      child: const Text('Salud: 74%', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                    ),
                    const SizedBox(height: 8),
                    _NeonBar(value: 0.74),
                    const SizedBox(height: 6),
                    const Text('Dentro de parámetros · actualizado hace 8 min', style: TextStyle(color: _V.muted, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 72, height: 72,
                child: CustomPaint(painter: _VRingPainter(value: 0.74)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonBar extends StatelessWidget {
  const _NeonBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: _V.glass,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_V.pink, _V.cyan]),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: _V.cyan.withAlpha(120), blurRadius: 8, spreadRadius: 1)],
          ),
        ),
      ),
    );
  }
}

class _VRingPainter extends CustomPainter {
  const _VRingPainter({required this.value});
  final double value;
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r  = s.width / 2 - 6;
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = _V.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);
    final sweep = math.pi * 2 * value;
    final grad = SweepGradient(
      colors: const [_V.pink, _V.cyan, _V.pink],
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + math.pi * 2,
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2, sweep, false,
      Paint()
        ..shader = grad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── KPI row ───────────────────────────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _V.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2));
  }
}

class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _kpis.asMap().entries.map((e) {
        final i = e.key;
        final (label, val, color, icon) = e.value;
        return Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: _V.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _V.border),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(height: 4),
                    Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withAlpha(180), blurRadius: 8)])),
                    Text(label, style: const TextStyle(color: _V.muted, fontSize: 8), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Module grid ───────────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: _modules.map((m) {
        final (label, icon, color, badge) = m;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _V.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _V.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20, shadows: [Shadow(color: color.withAlpha(200), blurRadius: 10)]),
                      const Spacer(),
                      Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  Text(label, style: const TextStyle(color: _V.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Feed card ─────────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _V.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _V.border),
          ),
          child: Column(
            children: _feed.map((f) {
              final (title, color, time, icon) = f;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 16, shadows: [Shadow(color: color.withAlpha(200), blurRadius: 8)]),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title, style: const TextStyle(color: _V.white, fontSize: 12, fontWeight: FontWeight.w500))),
                    Text(time, style: const TextStyle(color: _V.muted, fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
