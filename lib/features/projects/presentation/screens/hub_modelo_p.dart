// ============================================================
// MODELO P — "PRISM"
// Glassmorphism + gradient mesh background. Cards translúcidas
// con backdrop blur. Inspirado en iOS 17 + Raycast + Craft.
// Paleta: índigo profundo → violeta → azul eléctrico.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _P {
  static const bg1          = Color(0xFF0D0B2B);
  static const mesh1        = Color(0xFF3B1FA8);
  static const mesh2        = Color(0xFF0E4BCC);
  static const mesh3        = Color(0xFF7C2FD9);
  static const glass        = Color(0x1AFFFFFF);
  static const glassBorder  = Color(0x33FFFFFF);
  static const accent       = Color(0xFF7B61FF);
  static const accentBright = Color(0xFFA78BFA);
  static const neon         = Color(0xFF22D3EE);
  static const textLight    = Color(0xFFF8FAFF);
  static const muted        = Color(0xFF94A3C8);
  static const green        = Color(0xFF34D399);
  static const red          = Color(0xFFF87171);
  static const gold         = Color(0xFFFBBF24);
}

// ── Mock data ─────────────────────────────────────────────────
const _projectName = 'Torre Mirador Norte';
const _health      = 0.74;
const _advance     = 0.61;
const _budget      = 0.48;
const _schedule    = 0.55;

const _kpis = [
  ('Avance', '61%', _P.green,  Icons.trending_up_rounded),
  ('Presupuesto', '48%', _P.gold, Icons.account_balance_wallet_rounded),
  ('Restricciones', '12', _P.red, Icons.block_rounded),
  ('Hitos', '3/8', _P.neon, Icons.flag_rounded),
];

const _modules = [
  ('Restricciones', Icons.block_rounded, _P.red,    'Ver listado →'),
  ('Control Hitos', Icons.flag_rounded,  _P.gold,   'Ver hitos →'),
  ('Acta Reuniones', Icons.groups_rounded, _P.neon, 'Ver actas →'),
  ('Analítica', Icons.analytics_rounded, _P.accentBright, 'Ver datos →'),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloP extends StatelessWidget {
  const HubModeloP({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg1,
      body: Stack(
        children: [
          const _MeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(),
                  const SizedBox(height: 24),
                  _HealthCard(),
                  const SizedBox(height: 16),
                  _KpiRow(),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Módulos'),
                  const SizedBox(height: 12),
                  _ModuleGrid(),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Actividad reciente'),
                  const SizedBox(height: 12),
                  _ActivityFeed(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mesh background ───────────────────────────────────────────
class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _MeshPainter()),
    );
  }
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = _P.mesh1.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    final p2 = Paint()
      ..color = _P.mesh2.withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    final p3 = Paint()
      ..color = _P.mesh3.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 110);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.1), 200, p1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 160, p2);
    canvas.drawCircle(Offset(size.width * 0.5,  size.height * 0.7), 180, p3);
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
        _GlassChip(label: 'PRISM', icon: Icons.lens_blur_rounded),
        const Spacer(),
        Text(
          _projectName,
          style: const TextStyle(
            color: _P.textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        _GlassIcon(icon: Icons.palette_rounded, onTap: () => showStylePicker(context)),
        const SizedBox(width: 8),
        _GlassIcon(icon: Icons.notifications_none_rounded),
        const SizedBox(width: 8),
        _GlassIcon(icon: Icons.person_outline_rounded),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _P.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _P.accentBright, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: _P.textLight, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _P.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.glassBorder),
          ),
          child: Icon(icon, color: _P.muted, size: 18),
        ),
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: child) : child;
  }
}

// ── Health card ───────────────────────────────────────────────
class _HealthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Salud del proyecto', style: TextStyle(color: _P.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _P.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _P.green.withAlpha(80)),
                ),
                child: const Text('SALUDABLE', style: TextStyle(color: _P.green, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(_health * 100).toInt()}',
                style: const TextStyle(color: _P.textLight, fontSize: 52, fontWeight: FontWeight.w800, height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('%', style: TextStyle(color: _P.muted, fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(painter: _ArcPainter(value: _health, color: _P.accent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MultiTrack(label: 'Avance', value: _advance, color: _P.green),
          const SizedBox(height: 8),
          _MultiTrack(label: 'Presupuesto', value: _budget, color: _P.gold),
          const SizedBox(height: 8),
          _MultiTrack(label: 'Cronograma', value: _schedule, color: _P.neon),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 6;
    final bg = Paint()
      ..color = _P.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    const start = -3.14159 / 2;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, 3.14159 * 2, false, bg);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, 3.14159 * 2 * value, false, fg);
    final glow = Paint()
      ..color = color.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, 3.14159 * 2 * value, false, glow);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MultiTrack extends StatelessWidget {
  const _MultiTrack({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: _P.muted, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: _P.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _kpis.map((kpi) {
        final (label, value, color, icon) = kpi;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: _kpis.indexOf(kpi) == 0 ? 0 : 6),
            child: _GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(color: _P.muted, fontSize: 9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                ],
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
      childAspectRatio: 1.4,
      children: _modules.map((m) {
        final (label, icon, color, cta) = m;
        return _GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(label, style: const TextStyle(color: _P.textLight, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(cta, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Activity feed ─────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Restricción R-041 cerrada', '2h', _P.green,  Icons.check_circle_outline_rounded),
      ('Hito H-07 con riesgo de retraso', '5h', _P.red, Icons.warning_amber_rounded),
      ('Reunión de seguimiento agendada', '1d', _P.neon, Icons.event_rounded),
      ('Presupuesto actualizado', '2d', _P.gold, Icons.paid_rounded),
    ];
    return _GlassCard(
      child: Column(
        children: items.map((item) {
          final (title, time, color, icon) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(color: _P.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                Text(time, style: const TextStyle(color: _P.muted, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Glass card ────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _P.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _P.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _P.muted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}
