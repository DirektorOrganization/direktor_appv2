// ============================================================
// MODELO R — "ROUGE"
// Crimson + gold + marfil. Estética de lujo editorial.
// Tipografía bold dominante, jerarquía clara, datos como arte.
// Inspirado en Bloomberg Wealth + FT Weekend + Monocle.
// ============================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _R {
  static const bg        = Color(0xFFFAF7F2);
  static const surface   = Color(0xFFFFFFFF);
  static const crimson   = Color(0xFFC0392B);
  static const gold      = Color(0xFFB7860D);
  static const ink       = Color(0xFF1A1208);
  static const inkMid    = Color(0xFF4A3728);
  static const muted     = Color(0xFF9E8C7A);
  static const rule      = Color(0xFFE8DDD0);
  static const green     = Color(0xFF1A6B3A);
}

// ── Mock data ─────────────────────────────────────────────────
const _projectName = 'Torre Mirador Norte';
const _advance     = 0.61;
const _budget      = 0.48;
const _schedule    = 0.55;

const _indicators = [
  ('SPI', '0.94', 'Índice cronograma', _R.crimson),
  ('CPI', '1.02', 'Índice costos',     _R.green),
  ('EAC', '\$4.8M', 'Estimado al cierre', _R.gold),
  ('SV',  '-\$120K', 'Varianza cronograma', _R.crimson),
];

const _headlines = [
  ('Restricciones críticas en permisos municipales bloquean avance de N3', _R.crimson),
  ('Hito H-04 Instalaciones al 62% — en riesgo de retraso 8 días', _R.gold),
  ('Reunión de directorio convocada para revisión presupuestaria', _R.ink),
  ('3 restricciones cerradas esta semana — desempeño mejora', _R.green),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloR extends StatelessWidget {
  const HubModeloR({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _R.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Masthead(),
              _HorizontalRule(thick: true),
              _MarqueeBar(),
              _HorizontalRule(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _LeadSection(),
                    const SizedBox(height: 4),
                    _HorizontalRule(),
                    const SizedBox(height: 16),
                    _IndicatorsRow(),
                    const SizedBox(height: 4),
                    _HorizontalRule(),
                    const SizedBox(height: 16),
                    _SectionHead(label: 'SEGUIMIENTO DEL PROYECTO'),
                    const SizedBox(height: 12),
                    _GaugeRow(),
                    const SizedBox(height: 20),
                    _HorizontalRule(),
                    const SizedBox(height: 16),
                    _SectionHead(label: 'NOTICIAS DEL PROYECTO'),
                    const SizedBox(height: 12),
                    _HeadlinesList(),
                    const SizedBox(height: 20),
                    _HorizontalRule(),
                    const SizedBox(height: 16),
                    _BottomModules(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Masthead ──────────────────────────────────────────────────
class _Masthead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _R.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: _R.crimson,
                child: const Text('ROUGE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
              const SizedBox(width: 10),
              Text('Marzo 27, 2026', style: TextStyle(color: _R.muted, fontSize: 11)),
              const Spacer(),
              GestureDetector(
                onTap: () => showStylePicker(context),
                child: Icon(Icons.palette_rounded, color: _R.muted, size: 20),
              ),
              const SizedBox(width: 8),
              Icon(Icons.notifications_none_rounded, color: _R.muted, size: 20),
              const SizedBox(width: 8),
              Icon(Icons.person_outline_rounded, color: _R.muted, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'DIREKTOR',
            style: TextStyle(
              color: _R.ink,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _projectName.toUpperCase(),
            style: TextStyle(color: _R.crimson, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _HorizontalRule extends StatelessWidget {
  const _HorizontalRule({this.thick = false});
  final bool thick;

  @override
  Widget build(BuildContext context) {
    if (!thick) return Container(height: 1, color: _R.rule);
    return Column(
      children: [
        Container(height: 3, color: _R.ink),
        const SizedBox(height: 1),
        Container(height: 1, color: _R.ink),
      ],
    );
  }
}

// ── Marquee bar ───────────────────────────────────────────────
class _MarqueeBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _R.crimson,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Row(
        children: [
          const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Avance 61% · Presupuesto 48% · 12 restricciones abiertas · Próximo hito: H-05 Tabiquería',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section head ──────────────────────────────────────────────
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: _R.ink,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}

// ── Lead section ──────────────────────────────────────────────
class _LeadSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Salud del proyecto: SATISFACTORIO',
          style: TextStyle(color: _R.ink, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(color: _R.inkMid, fontSize: 13, height: 1.5),
            children: [
              TextSpan(text: 'El proyecto avanza con una salud general del '),
              TextSpan(text: '74%', style: TextStyle(fontWeight: FontWeight.w800, color: _R.ink)),
              TextSpan(text: '. El índice de costo CPI supera 1.0, aunque el cronograma presenta presión en los hitos de terminaciones.'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Indicators row ────────────────────────────────────────────
class _IndicatorsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _indicators.map((ind) {
        final (key, val, label, color) = ind;
        final isLast = _indicators.last == ind;
        return Expanded(
          child: Container(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            decoration: BoxDecoration(
              border: Border(right: isLast ? BorderSide.none : BorderSide(color: _R.rule, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key, style: const TextStyle(color: _R.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: _R.muted, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Gauge row ─────────────────────────────────────────────────
class _GaugeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GaugeItem(label: 'AVANCE', value: _advance, color: _R.green),
        const SizedBox(width: 16),
        _GaugeItem(label: 'PRESUPUESTO', value: _budget, color: _R.gold),
        const SizedBox(width: 16),
        _GaugeItem(label: 'CRONOGRAMA', value: _schedule, color: _R.crimson),
      ],
    );
  }
}

class _GaugeItem extends StatelessWidget {
  const _GaugeItem({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(painter: _SemicirclePainter(value: value, color: color)),
          ),
          const SizedBox(height: 4),
          Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _R.muted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _SemicirclePainter extends CustomPainter {
  const _SemicirclePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.75;
    final r  = size.width / 2 - 5;
    final bg = Paint()
      ..color = _R.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi, math.pi, false, bg);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi, math.pi * value, false, fg);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Headlines list ────────────────────────────────────────────
class _HeadlinesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: _headlines.asMap().entries.map((e) {
        final idx = e.key;
        final (title, color) = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 3,
                height: 36,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: _R.ink, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 2),
                    Text('Actualizado hace ${idx + 1}h', style: const TextStyle(color: _R.muted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Bottom modules ────────────────────────────────────────────
class _BottomModules extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const modules = [
      ('Restricciones', '12 abiertas', Icons.block_rounded, _R.crimson),
      ('Hitos', '3 completados', Icons.flag_rounded, _R.gold),
      ('Reuniones', '2 esta semana', Icons.groups_rounded, _R.green),
    ];
    return Column(
      children: modules.map((m) {
        final (label, sub, icon, color) = m;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _R.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _R.rule),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: _R.ink, fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(sub, style: const TextStyle(color: _R.muted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _R.muted),
            ],
          ),
        );
      }).toList(),
    );
  }
}
