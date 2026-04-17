// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE0EAF6);
  static const primary = Color(0xFF0A66B7);
  static const accent = Color(0xFF1167C8);
  static const accentLight = Color(0xFFCCDFF7);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const yellow = Color(0xFFF59E0B);
  static const white = Colors.white;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Color _statusColor(MilestoneRecord m) {
  if (m.isCompleted) return _D.green;
  if (m.isDelayed) return _D.red;
  return _D.accent;
}

IconData _statusIcon(MilestoneRecord m) {
  if (m.isCompleted) return Icons.check_circle_rounded;
  if (m.isDelayed) return Icons.warning_amber_rounded;
  return Icons.timelapse_rounded;
}

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Hv2DetailScreen extends StatelessWidget {
  const Hv2DetailScreen({super.key, required this.milestoneId});
  final int milestoneId;

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final m = ctrl.findMilestoneById(milestoneId);
        final generalApplies = ctrl.milestoneGeneral?.appliesToGeneral ?? false;
        final showPenaltySection = generalApplies && m?.classificationCode == 2;
        if (m == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _D.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: const Text('Hito'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _D.stroke),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final color = _statusColor(m);

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, m),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Status Hero ───────────────────────────────────────────────
              _StatusHero(milestone: m),
              const SizedBox(height: 14),
              // ── Date Journey ──────────────────────────────────────────────
              _DateJourney(milestone: m),
              const SizedBox(height: 14),
              // ── Penalty section ───────────────────────────────────────────
              if (showPenaltySection) ...[
                _PenaltySection(milestone: m),
                const SizedBox(height: 14),
              ],
              // ── Extensions summary ────────────────────────────────────────
              _ExtensionsSection(
                milestone: m,
                onViewAll: () => Navigator.of(ctx).pushNamed(
                  RouteNames.controlHitosExtensions,
                  arguments: MilestoneExtensionsArgs(milestoneId: m.id),
                ),
                onNewExtension: () => Navigator.of(ctx).pushNamed(
                  RouteNames.controlHitosExtensionCreate,
                  arguments: MilestoneExtensionFormArgs(milestoneId: m.id),
                ),
              ),
              const SizedBox(height: 14),
              // ── Documents section ─────────────────────────────────────────
              _DocumentsSection(
                milestone: m,
                onView: () => Navigator.of(ctx).pushNamed(
                  RouteNames.controlHitosDocuments,
                  arguments: MilestoneDocumentsArgs(milestoneId: m.id),
                ),
              ),
              const SizedBox(height: 14),
              // ── Sync badge ────────────────────────────────────────────────
              _SyncBadge(isSynced: m.isSynced),
            ],
          ),
          // ── Bottom actions ────────────────────────────────────────────────
          bottomNavigationBar: _BottomActions(
            milestone: m,
            statusColor: color,
            onEdit: () => Navigator.of(ctx).pushNamed(
              RouteNames.controlHitosEdit,
              arguments: MilestoneFormArgs(milestoneId: m.id),
            ),
            onNewExtension: () => Navigator.of(ctx).pushNamed(
              RouteNames.controlHitosExtensionCreate,
              arguments: MilestoneExtensionFormArgs(milestoneId: m.id),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext ctx, MilestoneRecord m) {
    return AppBar(
      backgroundColor: _D.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle de Hito',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _D.text,
            ),
          ),
          if (m.code.isNotEmpty)
            Text(m.code, style: const TextStyle(fontSize: 11, color: _D.muted)),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

// ─── Status Hero ─────────────────────────────────────────────────────────────
class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.milestone});
  final MilestoneRecord milestone;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final color = _statusColor(m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + badges row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(m), size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m.contractualStatusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (m.isDelayed && m.delayDays > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            size: 12,
                            color: _D.red,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${m.delayDays} días de retraso',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _D.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Description
          Text(
            m.description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _D.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Type + classification chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (m.typeLabel.isNotEmpty)
                _Chip(label: m.typeLabel, color: _D.primary),
              if (m.classificationLabel.isNotEmpty)
                _Chip(label: m.classificationLabel, color: _D.muted),
              _Chip(
                label: 'Estado interno: ${m.internalStatusLabel}',
                color: _D.muted,
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Date Journey ─────────────────────────────────────────────────────────────
class _DateJourney extends StatelessWidget {
  const _DateJourney({required this.milestone});
  final MilestoneRecord milestone;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final hasExtension = m.extensionCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 15, color: _D.primary),
              const SizedBox(width: 6),
              const Text(
                'CRONOGRAMA DE FECHAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _D.muted,
                  letterSpacing: 0.6,
                ),
              ),
              if (hasExtension) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _D.yellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.update_rounded,
                        size: 11,
                        color: _D.yellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${m.extensionCount} ampliación${m.extensionCount > 1 ? 'es' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _D.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // 3-stage date flow
          _DateFlow(milestone: m),
          // If actual date set, show completion note
          if (m.actualDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _D.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _D.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: _D.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Realizado el ${_fmtDate(m.actualDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _D.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateFlow extends StatelessWidget {
  const _DateFlow({required this.milestone});
  final MilestoneRecord milestone;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final stages =
        <
          ({
            String title,
            DateTime? original,
            DateTime? extended,
            Color color,
            IconData icon,
          })
        >[
          (
            title: 'Contractual',
            original: m.contractualDate,
            extended: m.extendedContractualDate,
            color: _D.primary,
            icon: Icons.gavel_rounded,
          ),
          (
            title: 'Meta',
            original: m.targetDate,
            extended: m.extendedTargetDate,
            color: _D.accent,
            icon: Icons.flag_rounded,
          ),
          (
            title: 'Realización',
            original: m.actualDate,
            extended: null,
            color: m.actualDate != null ? _D.green : _D.mutedLight,
            icon: m.actualDate != null
                ? Icons.check_circle_rounded
                : Icons.hourglass_empty_rounded,
          ),
        ];

    return Row(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Expanded(child: _DateStage(stage: stages[i])),
          if (i < stages.length - 1)
            _StageArrow(
              done: i == 0
                  ? m.effectiveContractualDate.isBefore(DateTime.now())
                  : (m.actualDate != null),
            ),
        ],
      ],
    );
  }
}

class _DateStage extends StatelessWidget {
  const _DateStage({required this.stage});
  final ({
    String title,
    DateTime? original,
    DateTime? extended,
    Color color,
    IconData icon,
  })
  stage;

  @override
  Widget build(BuildContext context) {
    final hasExtension = stage.extended != null;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: stage.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: stage.color, width: 1.5),
          ),
          child: Icon(stage.icon, size: 15, color: stage.color),
        ),
        const SizedBox(height: 6),
        Text(
          stage.title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _D.muted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        if (hasExtension) ...[
          Text(
            _fmtDate(stage.original),
            style: const TextStyle(
              fontSize: 10,
              color: _D.mutedLight,
              decoration: TextDecoration.lineThrough,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _fmtDate(stage.extended),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: stage.color,
            ),
            textAlign: TextAlign.center,
          ),
        ] else
          Text(
            _fmtDate(stage.original),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: stage.original != null ? stage.color : _D.mutedLight,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _StageArrow extends StatelessWidget {
  const _StageArrow({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: SizedBox(
        width: 24,
        height: 2,
        child: CustomPaint(painter: _ArrowPainter(done: done)),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.done});
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final color = done ? _D.primary : _D.stroke;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    if (done) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      const w = 3.0, gap = 2.0;
      var x = 0.0;
      final y = size.height / 2;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + w).clamp(0, size.width), y),
          paint,
        );
        x += w + gap;
      }
    }
    // Arrowhead
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final tip = Offset(size.width, size.height / 2);
    canvas.drawLine(tip, tip + const Offset(-5, -4), arrowPaint);
    canvas.drawLine(tip, tip + const Offset(-5, 4), arrowPaint);
  }

  @override
  bool shouldRepaint(_ArrowPainter o) => o.done != done;
}

// ─── Penalty Section ──────────────────────────────────────────────────────────
class _PenaltySection extends StatelessWidget {
  const _PenaltySection({required this.milestone});
  final MilestoneRecord milestone;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: m.isDelayed ? _D.red.withValues(alpha: 0.3) : _D.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gpp_bad_outlined,
                size: 15,
                color: m.isDelayed ? _D.red : _D.muted,
              ),
              const SizedBox(width: 6),
              Text(
                'PENALIDAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: m.isDelayed ? _D.red : _D.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PenaltyBox(
                  label: 'Porcentaje',
                  value: '${(m.penaltyPercent * 100).toStringAsFixed(2)}%',
                  color: m.isDelayed ? _D.red : _D.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PenaltyBox(
                  label: 'Monto acumulado',
                  value: 'S/ ${m.penaltyAmount.toStringAsFixed(2)}',
                  color: m.isDelayed && m.penaltyAmount > 0 ? _D.red : _D.muted,
                ),
              ),
            ],
          ),
          if (m.isDelayed && m.delayDays > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _D.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: _D.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hito retrasado ${m.delayDays} días — penalidad en curso',
                    style: const TextStyle(fontSize: 11, color: _D.red),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PenaltyBox extends StatelessWidget {
  const _PenaltyBox({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _D.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Extensions Section ───────────────────────────────────────────────────────
class _ExtensionsSection extends StatelessWidget {
  const _ExtensionsSection({
    required this.milestone,
    required this.onViewAll,
    required this.onNewExtension,
  });
  final MilestoneRecord milestone;
  final VoidCallback onViewAll;
  final VoidCallback onNewExtension;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final last = m.extensions.isNotEmpty ? m.extensions.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update_rounded, size: 15, color: _D.muted),
              const SizedBox(width: 6),
              const Text(
                'AMPLIACIONES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _D.muted,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (m.extensionCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _D.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${m.extensionCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _D.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (last != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _D.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _D.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    last.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _D.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: _D.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Nueva meta: ${_fmtDate(last.newTargetDate)}',
                        style: const TextStyle(fontSize: 11, color: _D.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Sin ampliaciones registradas.',
                style: const TextStyle(fontSize: 12, color: _D.mutedLight),
              ),
            ),
          Row(
            children: [
              if (m.extensionCount > 0)
                Expanded(
                  child: _OutlineBtn(
                    label: 'Ver todas',
                    icon: Icons.list_alt_rounded,
                    onTap: onViewAll,
                  ),
                ),
              if (m.extensionCount > 0) const SizedBox(width: 8),
              Expanded(
                child: _OutlineBtn(
                  label: 'Nueva ampliación',
                  icon: Icons.add_rounded,
                  color: _D.primary,
                  onTap: onNewExtension,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Documents Section ────────────────────────────────────────────────────────
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.milestone, required this.onView});
  final MilestoneRecord milestone;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final count = milestone.documents.length;
    return GestureDetector(
      onTap: onView,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _D.stroke),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _D.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.attach_file_rounded,
                size: 20,
                color: _D.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evidencias',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _D.text,
                    ),
                  ),
                  Text(
                    count == 0
                        ? 'Sin documentos registrados'
                        : '$count documento${count > 1 ? 's' : ''} adjunto${count > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 11, color: _D.muted),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _D.mutedLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sync Badge ───────────────────────────────────────────────────────────────
class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.isSynced});
  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
          size: 13,
          color: isSynced ? _D.green : _D.mutedLight,
        ),
        const SizedBox(width: 5),
        Text(
          isSynced ? 'Sincronizado' : 'Pendiente de sincronización',
          style: TextStyle(
            fontSize: 11,
            color: isSynced ? _D.green : _D.mutedLight,
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.milestone,
    required this.statusColor,
    required this.onEdit,
    required this.onNewExtension,
  });
  final MilestoneRecord milestone;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onNewExtension;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: _D.white,
        border: Border(top: BorderSide(color: _D.stroke)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OutlineBtn(
              label: 'Ampliación',
              icon: Icons.update_rounded,
              onTap: onNewExtension,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _D.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: _D.white),
                    SizedBox(width: 6),
                    Text(
                      'Editar Hito',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _D.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.outlined = false,
  });
  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = _D.muted,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
