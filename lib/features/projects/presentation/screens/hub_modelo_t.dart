// ============================================================
// MODELO T — "TIDE"
// Ocean blues. Calma, profundidad, claridad. Para PMs que
// prefieren serenidad sobre urgencia. Inspirado en Calm app
// + Notion (blue) + Stripe Dashboard.
// Paleta: azul profundo → cyan → blanco espuma.
// ============================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _T {
  static const bg        = Color(0xFFF0F7FF);
  static const surface   = Color(0xFFFFFFFF);
  static const ocean     = Color(0xFF0C4A6E);
  static const deep      = Color(0xFF075985);
  static const mid       = Color(0xFF0284C7);
  static const wave      = Color(0xFF38BDF8);
  static const foam      = Color(0xFFE0F2FE);
  static const teal      = Color(0xFF0D9488);
  static const green     = Color(0xFF059669);
  static const amber     = Color(0xFFD97706);
  static const red       = Color(0xFFDC2626);
  static const ink       = Color(0xFF0C2340);
  static const muted     = Color(0xFF64748B);
  static const rule      = Color(0xFFDBEAFE);
}

// ── Mock data ─────────────────────────────────────────────────
const _health   = 0.74;

const _waves = [
  ('Avance físico',   0.61, _T.mid),
  ('Ppto ejecutado',  0.48, _T.teal),
  ('Cronograma',      0.55, _T.wave),
  ('Calidad',         0.80, _T.green),
  ('Seguridad',       0.95, _T.ocean),
];

const _metrics = [
  ('Restricciones',  '12', _T.red,   Icons.block_rounded),
  ('Hitos activos',  '5',  _T.amber, Icons.flag_rounded),
  ('Reuniones',      '8',  _T.mid,   Icons.groups_rounded),
  ('Días restantes', '147',_T.teal,  Icons.schedule_rounded),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloT extends StatelessWidget {
  const HubModeloT({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _OceanHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricsRow(),
                    const SizedBox(height: 20),
                    _SectionLabel('INDICADORES DE DESEMPEÑO'),
                    const SizedBox(height: 12),
                    _WaveBars(),
                    const SizedBox(height: 20),
                    _SectionLabel('MÓDULOS DE GESTIÓN'),
                    const SizedBox(height: 12),
                    _ModuleCards(),
                    const SizedBox(height: 20),
                    _SectionLabel('PRÓXIMOS EVENTOS'),
                    const SizedBox(height: 12),
                    _EventsList(),
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

// ── Ocean header ──────────────────────────────────────────────
class _OceanHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.ocean, _T.deep, _T.mid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Wave decoration
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _WavePainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waves_rounded, color: _T.wave, size: 16),
                    const SizedBox(width: 6),
                    const Text('TIDE', style: TextStyle(color: _T.wave, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showStylePicker(context),
                      child: _HeaderIcon(Icons.palette_rounded),
                    ),
                    const SizedBox(width: 8),
                    _HeaderIcon(Icons.notifications_none_rounded),
                    const SizedBox(width: 8),
                    _HeaderIcon(Icons.settings_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Torre Mirador Norte', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Actualizado hace 8 minutos', style: TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HealthRing(value: _health),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Salud del proyecto', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(
                            '${(_health * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _T.green.withAlpha(50),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _T.green.withAlpha(100)),
                            ),
                            child: const Text('DENTRO DE META', style: TextStyle(color: _T.wave, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    );
  }
}

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(painter: _RingPainter(value: value)),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value});
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 6;
    final bg = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final fg = Paint()
      ..color = _T.wave
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      math.pi * 2 * value,
      false, fg,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _T.bg;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Section label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _T.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5));
  }
}

// ── Metrics row ───────────────────────────────────────────────
class _MetricsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _metrics.asMap().entries.map((e) {
        final i = e.key;
        final (label, val, color, icon) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _T.rule),
              boxShadow: [BoxShadow(color: _T.ocean.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: _T.muted, fontSize: 8), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Wave bars ─────────────────────────────────────────────────
class _WaveBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.rule),
        boxShadow: [BoxShadow(color: _T.ocean.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: _waves.map((w) {
          final (label, pct, color) = w;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(color: _T.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: _T.foam,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Module cards ──────────────────────────────────────────────
class _ModuleCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const modules = [
      ('Restricciones', 'Gestiona bloqueos', Icons.block_rounded,    _T.red,   '12 abiertas'),
      ('Hitos',         'Control de avance', Icons.flag_rounded,      _T.amber, '3 / 8 ok'),
      ('Reuniones',     'Actas y acuerdos',  Icons.groups_rounded,   _T.mid,   '8 registradas'),
    ];
    return Column(
      children: modules.map((m) {
        final (title, sub, icon, color, badge) = m;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.rule),
            boxShadow: [BoxShadow(color: _T.ocean.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: _T.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(sub, style: const TextStyle(color: _T.muted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: _T.muted, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Events list ───────────────────────────────────────────────
class _EventsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const events = [
      ('Reunión de seguimiento',  'Hoy 15:00',    _T.mid),
      ('Vence R-039',             'Mañana',        _T.red),
      ('Revisión de presupuesto', 'Lunes 10:00',   _T.amber),
      ('Entrega planos N4',       'Miércoles',     _T.teal),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.rule),
      ),
      child: Column(
        children: events.asMap().entries.map((e) {
          final i = e.key;
          final (title, dt, color) = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < events.length - 1 ? 12 : 0),
            child: Row(
              children: [
                Container(
                  width: 3, height: 36,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(color: _T.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Text(dt, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
