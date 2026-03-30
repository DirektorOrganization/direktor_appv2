// ============================================================
// MODELO S — "SOLAR"
// Paleta sunset: naranja vivo → ámbar → amarillo cálido.
// Energía, urgencia, motivación. Para equipos de obra que
// necesitan un dashboard que transmita movimiento y acción.
// Inspirado en Notion + Superhuman + Linear (warm mode).
// ============================================================

import 'package:flutter/material.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _S {
  static const bg        = Color(0xFFFFFBF5);
  static const surface   = Color(0xFFFFFFFF);
  static const sunrise   = Color(0xFFFF6B2B);
  static const amber     = Color(0xFFF59E0B);
  static const gold      = Color(0xFFEAB308);
  static const sky       = Color(0xFF0EA5E9);
  static const green     = Color(0xFF10B981);
  static const red       = Color(0xFFEF4444);
  static const ink       = Color(0xFF1C1917);
  static const muted     = Color(0xFFA8A29E);
  static const rule      = Color(0xFFF5F0E8);
  static const ruleDark  = Color(0xFFE7DDD0);
}

// ── Mock data ─────────────────────────────────────────────────
const _kpis = [
  ('Avance',         '61%',   Icons.rocket_launch_rounded,   _S.sunrise),
  ('Presupuesto',    '48%',   Icons.paid_rounded,             _S.amber),
  ('Restricciones',  '12',    Icons.block_rounded,            _S.red),
  ('Hitos OK',       '3/8',   Icons.emoji_events_rounded,     _S.gold),
];

const _tasks = [
  ('Cerrar R-039 permisos',      'Urgente',  _S.red,     false),
  ('Revisar presupuesto N3',     'Hoy',      _S.amber,   false),
  ('Actualizar cronograma',      'Mañana',   _S.sunrise, false),
  ('Reunión de seguimiento',     'Viernes',  _S.sky,     true),
  ('Aprobar planos tabiquería',  'Pendiente',_S.muted,   false),
];

const _hitos = [
  ('Cimentación',      1.0),
  ('Estructura N1-N2', 1.0),
  ('Instalaciones E.', 0.62),
  ('Tabiquería',       0.18),
  ('Terminaciones',    0.0),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloS extends StatelessWidget {
  const HubModeloS({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: 20),
              _SunriseCard(),
              const SizedBox(height: 16),
              _KpiRow(),
              const SizedBox(height: 20),
              _Label('TAREAS PRIORITARIAS'),
              const SizedBox(height: 10),
              _TaskList(),
              const SizedBox(height: 20),
              _Label('PROGRESO DE HITOS'),
              const SizedBox(height: 10),
              _HitosBlock(),
              const SizedBox(height: 20),
              _Label('MÓDULOS'),
              const SizedBox(height: 10),
              _ModuleChips(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: _S.sunrise, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('SOLAR', style: TextStyle(color: _S.sunrise, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ]),
            const SizedBox(height: 4),
            const Text('Torre Mirador Norte', style: TextStyle(color: _S.ink, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Marzo 27, 2026', style: const TextStyle(color: _S.muted, fontSize: 11)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => showStylePicker(context),
          child: _IconBtn(icon: Icons.palette_rounded),
        ),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.notifications_none_rounded),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: _S.sunrise.withAlpha(20),
          child: const Text('DG', style: TextStyle(color: _S.sunrise, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _S.ruleDark),
      ),
      child: Icon(icon, color: _S.muted, size: 18),
    );
  }
}

// ── Sunrise card ──────────────────────────────────────────────
class _SunriseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B2B), Color(0xFFF59E0B), Color(0xFFEAB308)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Salud general', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('SATISFACTORIO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
          ]),
          const SizedBox(height: 10),
          const Text('74%', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.74,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          const Text('12 restricciones abiertas · 5 hitos en curso', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _kpis.asMap().entries.map((e) {
        final i = e.key;
        final (label, val, icon, color) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: _S.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _S.ruleDark),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 5),
                Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(color: _S.muted, fontSize: 8, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Label ─────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _S.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5));
  }
}

// ── Task list ─────────────────────────────────────────────────
class _TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _S.ruleDark),
      ),
      child: Column(
        children: _tasks.asMap().entries.map((e) {
          final i = e.key;
          final (title, due, color, done) = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: BorderSide(color: _S.rule)),
            ),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: done ? _S.green.withAlpha(20) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: done ? _S.green : _S.ruleDark, width: 1.5),
                  ),
                  child: done ? const Icon(Icons.check_rounded, color: _S.green, size: 12) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: done ? _S.muted : _S.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(due, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Hitos block ───────────────────────────────────────────────
class _HitosBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _S.ruleDark),
      ),
      child: Column(
        children: _hitos.map((h) {
          final (name, pct) = h;
          final color = pct == 1.0 ? _S.green : pct > 0 ? _S.sunrise : _S.ruleDark;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  child: Text(name, style: TextStyle(color: pct == 1.0 ? _S.muted : _S.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: _S.rule,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Module chips ──────────────────────────────────────────────
class _ModuleChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const chips = [
      ('Restricciones', Icons.block_rounded,     _S.red),
      ('Hitos',         Icons.flag_rounded,       _S.amber),
      ('Reuniones',     Icons.groups_rounded,     _S.sky),
      ('Analítica',     Icons.analytics_rounded,  _S.sunrise),
      ('Perfil',        Icons.person_rounded,     _S.muted),
      ('Ajustes',       Icons.tune_rounded,       _S.muted),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips.map((c) {
        final (label, icon, color) = c;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _S.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _S.ruleDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: _S.ink, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
