// ============================================================
// MODELO Q — "QUANTUM"
// Terminal / hacker aesthetic para PMs técnicos. Dark carbon
// con neon verde lima. Monospace, datos crudos, densidad máxima.
// Inspirado en Warp terminal + Linear + GitHub dark.
// ============================================================

import 'package:flutter/material.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _Q {
  static const bg        = Color(0xFF0D1117);
  static const surface   = Color(0xFF161B22);
  static const surface2  = Color(0xFF21262D);
  static const stroke    = Color(0xFF30363D);
  static const neon      = Color(0xFF39FF14);
  static const cyan      = Color(0xFF58A6FF);
  static const yellow    = Color(0xFFE3B341);
  static const red       = Color(0xFFF85149);
  static const purple    = Color(0xFFBC8CFF);
  static const textLight = Color(0xFFE6EDF3);
  static const muted     = Color(0xFF8B949E);
  static const mutedDim  = Color(0xFF484F58);
}

// ── Mock data ─────────────────────────────────────────────────
const _rows = [
  ('R-039', 'Permisos municipales bloqueados',  'CRÍTICO', _Q.red),
  ('R-041', 'Entrega hormigón postergada',       'ALTO',    _Q.yellow),
  ('R-044', 'Falta personal especializado',      'MEDIO',   _Q.cyan),
  ('R-045', 'Planos sin aprobación',             'ALTO',    _Q.yellow),
  ('R-047', 'Equipo grúa en revisión',           'BAJO',    _Q.neon),
];

const _stats = [
  ('AVANCE',       '61.4%',  _Q.neon),
  ('PRESUP.',      '48.2%',  _Q.cyan),
  ('HITOS',        '3 / 8',  _Q.purple),
  ('SPI',          '0.94',   _Q.yellow),
  ('CPI',          '1.02',   _Q.neon),
  ('RESTRICCIONES','12 open',_Q.red),
];

// ── Screen ────────────────────────────────────────────────────
class HubModeloQ extends StatelessWidget {
  const HubModeloQ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Q.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TerminalTopBar(),
            const _Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PromptLine(cmd: 'project status --project="Torre Mirador Norte"'),
                    const SizedBox(height: 12),
                    _StatsGrid(),
                    const SizedBox(height: 16),
                    _PromptLine(cmd: 'restrictions list --status=open --sort=priority'),
                    const SizedBox(height: 12),
                    _RestrictionsTable(),
                    const SizedBox(height: 16),
                    _PromptLine(cmd: 'milestones progress --format=bar'),
                    const SizedBox(height: 12),
                    _MilestonesBlock(),
                    const SizedBox(height: 16),
                    _PromptLine(cmd: 'sync status'),
                    const SizedBox(height: 8),
                    _SyncBlock(),
                    const SizedBox(height: 20),
                    _CursorLine(),
                  ],
                ),
              ),
            ),
            _BottomBar(),
          ],
        ),
      ),
    );
  }
}

// ── Terminal top bar ──────────────────────────────────────────
class _TerminalTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Q.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Row(children: [
            _Dot(color: const Color(0xFFFF5F57)),
            const SizedBox(width: 6),
            _Dot(color: const Color(0xFFFFBD2E)),
            const SizedBox(width: 6),
            _Dot(color: const Color(0xFF28C840)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Center(
              child: Text(
                'direktor-cli — quantum-hub v1.0.0',
                style: TextStyle(
                  color: _Q.muted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => showStylePicker(context),
            child: const Icon(Icons.palette_rounded, color: _Q.mutedDim, size: 18),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_horiz_rounded, color: _Q.mutedDim, size: 18),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _Q.stroke);
  }
}

// ── Prompt line ───────────────────────────────────────────────
class _PromptLine extends StatelessWidget {
  const _PromptLine({required this.cmd});
  final String cmd;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        children: [
          TextSpan(text: '❯ ', style: TextStyle(color: _Q.neon, fontWeight: FontWeight.w900)),
          TextSpan(text: cmd, style: const TextStyle(color: _Q.textLight)),
        ],
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Q.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Q.stroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (int i = 0; i < _stats.length; i += 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: List.generate(3, (j) {
                  final idx = i + j;
                  if (idx >= _stats.length) return const Expanded(child: SizedBox());
                  final (label, val, color) = _stats[idx];
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(color: _Q.mutedDim, fontSize: 9, fontFamily: 'monospace', letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Restrictions table ────────────────────────────────────────
class _RestrictionsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Q.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Q.stroke),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _Q.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 56, child: Text('ID', style: TextStyle(color: _Q.muted, fontSize: 10, fontFamily: 'monospace'))),
                Expanded(child: Text('DESCRIPCIÓN', style: TextStyle(color: _Q.muted, fontSize: 10, fontFamily: 'monospace'))),
                SizedBox(width: 60, child: Text('NIVEL', style: TextStyle(color: _Q.muted, fontSize: 10, fontFamily: 'monospace'), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ..._rows.map((r) {
            final (id, desc, level, color) = r;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: _Q.stroke))),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(id, style: TextStyle(color: _Q.cyan, fontSize: 11, fontFamily: 'monospace')),
                  ),
                  Expanded(
                    child: Text(desc, style: const TextStyle(color: _Q.textLight, fontSize: 11, fontFamily: 'monospace')),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(level, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'), textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Milestones block ──────────────────────────────────────────
class _MilestonesBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const milestones = [
      ('H-01 Cimentación',        1.0,   'DONE'),
      ('H-02 Estructura N1',      1.0,   'DONE'),
      ('H-03 Estructura N2',      1.0,   'DONE'),
      ('H-04 Instalaciones E.',   0.62,  'IN PROGRESS'),
      ('H-05 Tabiquería',         0.18,  'IN PROGRESS'),
      ('H-06 Terminaciones',      0.0,   'PENDING'),
      ('H-07 Inspección final',   0.0,   'PENDING'),
      ('H-08 Entrega',            0.0,   'PENDING'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _Q.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Q.stroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: milestones.map((m) {
          final (name, pct, status) = m;
          final barColor = pct == 1.0 ? _Q.neon : pct > 0 ? _Q.cyan : _Q.mutedDim;
          final bar = '█' * (pct * 20).round() + '░' * (20 - (pct * 20).round());
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(name, style: const TextStyle(color: _Q.textLight, fontSize: 10, fontFamily: 'monospace')),
                ),
                Expanded(
                  child: Text(bar, style: TextStyle(color: barColor, fontSize: 9, fontFamily: 'monospace')),
                ),
                const SizedBox(width: 8),
                Text('${(pct * 100).toInt()}%', style: TextStyle(color: barColor, fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Sync block ────────────────────────────────────────────────
class _SyncBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Q.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Q.stroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SyncRow('status',      '● connected',   _Q.neon),
          _SyncRow('last_sync',   '2025-03-27 09:41:12', _Q.muted),
          _SyncRow('pending',     '3 items',       _Q.yellow),
          _SyncRow('mode',        'online + remote', _Q.cyan),
        ],
      ),
    );
  }
}

class _SyncRow extends StatelessWidget {
  const _SyncRow(this.key2, this.value, this.color);
  final String key2;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          children: [
            TextSpan(text: '  $key2', style: const TextStyle(color: _Q.muted)),
            const TextSpan(text: ':  ', style: TextStyle(color: _Q.mutedDim)),
            TextSpan(text: value, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Cursor line ───────────────────────────────────────────────
class _CursorLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('❯ ', style: TextStyle(color: _Q.neon, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w900)),
        Container(width: 8, height: 16, color: _Q.neon),
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Q.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatusChip('QUANTUM', _Q.neon),
          const SizedBox(width: 10),
          _StatusChip('Torre Mirador', _Q.muted),
          const Spacer(),
          _StatusChip('UTF-8', _Q.mutedDim),
          const SizedBox(width: 10),
          _StatusChip('Dart 3.4', _Q.mutedDim),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace'));
  }
}
