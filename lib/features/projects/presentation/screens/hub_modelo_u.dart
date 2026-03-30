// ============================================================
// MODELO U — "ULTRA"
// Tipografía dominante. Números enormes como protagonistas.
// Minimalismo radical: blanco + negro + UN solo acento naranja.
// Inspirado en Robinhood + Monzo + Pitch.com.
// ============================================================

import 'package:flutter/material.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _U {
  static const bg      = Color(0xFFFFFFFF);
  static const ink     = Color(0xFF0A0A0A);
  static const inkMid  = Color(0xFF3D3D3D);
  static const muted   = Color(0xFF9CA3AF);
  static const rule    = Color(0xFFF3F4F6);
  static const ruleDk  = Color(0xFFE5E7EB);
  static const accent  = Color(0xFFFF4D00);
  static const green   = Color(0xFF00C48C);
  static const red     = Color(0xFFFF3B30);
  static const yellow  = Color(0xFFFFC300);
}

// ── Mock data ─────────────────────────────────────────────────
const _hero = ('61', '%', 'avance físico', _U.ink);

const _numbers = [
  ('48%',  'presupuesto\nejecutado',  _U.accent),
  ('12',   'restricciones\nabiertas', _U.red),
  ('3/8',  'hitos\ncompletados',      _U.green),
  ('147',  'días\nrestantes',         _U.muted),
];

const _restrictions = [
  ('R-039', 'Permisos municipales', _U.red,    'CRÍTICO'),
  ('R-041', 'Entrega de hormigón',  _U.yellow, 'ALTO'),
  ('R-044', 'Personal especializ.', _U.accent, 'MEDIO'),
  ('R-047', 'Grúa en revisión',     _U.muted,  'BAJO'),
];

const _hitos = [
  ('H-01 Cimentación',      true,  1.0),
  ('H-02 Estructura',       true,  1.0),
  ('H-03 Instalaciones E.', false, 0.62),
  ('H-04 Tabiquería',       false, 0.18),
  ('H-05 Terminaciones',    false, 0.0),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloU extends StatelessWidget {
  const HubModeloU({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _U.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(),
              const SizedBox(height: 32),
              _HeroNumber(),
              const SizedBox(height: 8),
              _Divider(),
              const SizedBox(height: 24),
              _NumbersGrid(),
              const SizedBox(height: 32),
              _Divider(),
              const SizedBox(height: 24),
              _Cap('RESTRICCIONES ABIERTAS'),
              const SizedBox(height: 16),
              _RestrictionsList(),
              const SizedBox(height: 32),
              _Divider(),
              const SizedBox(height: 24),
              _Cap('HITOS DEL PROYECTO'),
              const SizedBox(height: 16),
              _HitosList(),
              const SizedBox(height: 32),
              _Divider(),
              const SizedBox(height: 24),
              _ModuleRow(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ULTRA', style: TextStyle(color: _U.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 2),
            const Text('Torre Mirador Norte', style: TextStyle(color: _U.ink, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => showStylePicker(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: _U.ruleDk),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.palette_rounded, color: _U.muted, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: _U.ruleDk),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: _U.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('En línea', style: TextStyle(color: _U.inkMid, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 1, color: _U.rule);
}

class _Cap extends StatelessWidget {
  const _Cap(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _U.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2));
  }
}

// ── Hero number ───────────────────────────────────────────────
class _HeroNumber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (num, unit, label, color) = _hero;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(num, style: TextStyle(color: color, fontSize: 96, fontWeight: FontWeight.w900, height: 1, letterSpacing: -6)),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(unit, style: const TextStyle(color: _U.accent, fontSize: 36, fontWeight: FontWeight.w900)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: _U.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.trending_up_rounded, color: _U.green, size: 14),
                const SizedBox(width: 4),
                const Text('+2.3% esta semana', style: TextStyle(color: _U.green, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Numbers grid ──────────────────────────────────────────────
class _NumbersGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _numbers.asMap().entries.map((e) {
        final i = e.key;
        final (num, label, color) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(num, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: _U.muted, fontSize: 10, height: 1.3)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Restrictions list ─────────────────────────────────────────
class _RestrictionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: _restrictions.asMap().entries.map((e) {
        final i = e.key;
        final (id, title, color, level) = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: i == 0 ? Colors.transparent : _U.rule)),
          ),
          child: Row(
            children: [
              Text(id, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(color: _U.ink, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(level, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Hitos list ────────────────────────────────────────────────
class _HitosList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: _hitos.asMap().entries.map((e) {
        final i = e.key;
        final (name, done, pct) = e.value;
        final color = done ? _U.green : pct > 0 ? _U.accent : _U.muted;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: i == 0 ? Colors.transparent : _U.rule)),
          ),
          child: Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: done ? _U.green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(color: done ? _U.muted : _U.ink, fontSize: 14, fontWeight: FontWeight.w600, decoration: done ? TextDecoration.lineThrough : null)),
                    if (!done && pct > 0) ...[
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 3,
                          backgroundColor: _U.rule,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                done ? '100%' : '${(pct * 100).toInt()}%',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Module row ────────────────────────────────────────────────
class _ModuleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const modules = [
      ('Actas',     Icons.description_rounded,  _U.inkMid),
      ('Analítica', Icons.bar_chart_rounded,     _U.accent),
      ('Perfil',    Icons.person_outline_rounded, _U.inkMid),
      ('Ajustes',   Icons.tune_rounded,           _U.inkMid),
    ];
    return Row(
      children: modules.asMap().entries.map((e) {
        final i = e.key;
        final (label, icon, color) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: i == 1 ? _U.ink : _U.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: i == 1 ? _U.ink : _U.ruleDk),
            ),
            child: Column(
              children: [
                Icon(icon, color: i == 1 ? Colors.white : color, size: 20),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(color: i == 1 ? Colors.white : _U.inkMid, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
