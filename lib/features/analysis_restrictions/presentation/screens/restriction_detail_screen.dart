// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';

// ─── Palette (mirrors restriction_form_screen / rv2 tablero) ─────────────────
abstract final class _D {
  static const bg         = Color(0xFFF5FAFE);
  static const surface    = Colors.white;
  static const stroke     = Color(0xFFE0EAF6);
  static const primary    = Color(0xFF0A66B7);
  static const text       = Color(0xFF0F172A);
  static const muted      = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class RestrictionDetailScreen extends StatelessWidget {
  const RestrictionDetailScreen({super.key, required this.restrictionId});

  final int restrictionId;

  @override
  Widget build(BuildContext context) {
    final ctrl    = AppScope.of(context);
    final item    = ctrl.findRestrictionById(restrictionId);
    final project = ctrl.currentProject;

    if (item == null) {
      return Scaffold(
        backgroundColor: _D.bg,
        appBar: AppBar(
          backgroundColor: _D.primary,
          foregroundColor: Colors.white,
          title: const Text('Detalle de restricción'),
        ),
        body: const Center(
          child: Text('Restricción no encontrada', style: TextStyle(color: _D.muted)),
        ),
      );
    }

    final refDate      = item.conciliatedDate ?? item.requiredDate;
    final daysOverdue  = item.isOverdue ? DateTime.now().difference(refDate).inDays : 0;
    final headerColors = _headerGradient(item.statusCode, item.isOverdue);

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Detalle de restricción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Gradient header (mismo estilo que el formulario) ──────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.activity,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          project.name,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.80), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Estado + overdue badge
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _HeaderBadge(icon: _statusIcon(item.statusCode), label: item.statusLabel),
                          _HeaderBadge(
                            icon: item.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                            label: item.isSynced ? 'Sincronizado' : 'Pendiente sync',
                          ),
                          if (item.isOverdue)
                            _HeaderBadge(icon: Icons.arrow_upward_rounded, label: '$daysOverdue días vencido'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sección: Ubicación ──────────────────────────────────────
          _DetailSection(
            icon: Icons.place_rounded,
            title: 'Ubicación',
            children: [
              _DetailRow(icon: Icons.apartment_rounded, label: 'Frente', value: item.front),
              const _RowDivider(),
              _DetailRow(icon: Icons.layers_outlined, label: 'Fase', value: item.phase),
              if (item.area.isNotEmpty) ...[
                const _RowDivider(),
                _DetailRow(icon: Icons.domain_verification_outlined, label: 'Área', value: item.area),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Sección: Restricción ────────────────────────────────────
          _DetailSection(
            icon: Icons.report_problem_rounded,
            title: 'Detalle de la restricción',
            children: [
              _DetailRow(icon: Icons.work_outline_rounded, label: 'Actividad', value: item.activity),
              if (item.description.isNotEmpty) ...[
                const _RowDivider(),
                _DetailRow(icon: Icons.notes_rounded, label: 'Descripción', value: item.description),
              ],
              const _RowDivider(),
              _DetailRow(icon: Icons.category_outlined, label: 'Tipo', value: item.type),
            ],
          ),
          const SizedBox(height: 12),

          // ── Sección: Planificación ──────────────────────────────────
          _DetailSection(
            icon: Icons.schedule_rounded,
            title: 'Planificación',
            children: [
              _DetailRow(icon: Icons.event_rounded, label: 'Fecha requerida', value: _fmtDate(item.requiredDate)),
              if (item.conciliatedDate != null) ...[
                const _RowDivider(),
                _DetailRow(icon: Icons.event_available_outlined, label: 'Fecha conciliada', value: _fmtDate(item.conciliatedDate!)),
              ],
              const _RowDivider(),
              _DetailRow(icon: Icons.flag_rounded, label: 'Estado', value: item.statusLabel),
              const _RowDivider(),
              _DetailRow(icon: Icons.person_outline_rounded, label: 'Responsable', value: item.responsible),
              const _RowDivider(),
              _DetailRow(icon: Icons.manage_accounts_rounded, label: 'Solicitante', value: item.requester),
              const _RowDivider(),
              _DetailRow(icon: Icons.business_outlined, label: 'Proyecto', value: project?.name ?? '-'),
              const _RowDivider(),
              _DetailRow(icon: Icons.update_rounded, label: 'Última actualización', value: _fmtDateTime(item.updatedAt)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Editar ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                RouteNames.restrictionEdit,
                arguments: RestrictionFormArgs(restrictionId: item.id),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _D.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Editar restricción', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  static List<Color> _headerGradient(String code, bool isOverdue) {
    if (isOverdue)              return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
    if (code == 'completed')    return [const Color(0xFF059669), const Color(0xFF10B981)];
    if (code == 'in_progress')  return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
    return [const Color(0xFF0A66B7), const Color(0xFF1580D8)];
  }

  static IconData _statusIcon(String code) {
    switch (code) {
      case 'in_progress': return Icons.timelapse_rounded;
      case 'completed':   return Icons.check_circle_rounded;
      default:            return Icons.pending_outlined;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─── Header Badge ─────────────────────────────────────────────────────────────
class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Section ───────────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _D.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _D.stroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Icon(icon, size: 15, color: _D.primary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _D.primary, letterSpacing: 0.5)),
          ]),
        ),
        const Divider(height: 1, color: _D.stroke),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    ),
  );
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 12, color: _D.mutedLight),
      const SizedBox(width: 4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.muted, letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 13, color: _D.text, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ],
  );
}

// ─── Row Divider ──────────────────────────────────────────────────────────────
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 9),
    child: Divider(height: 1, color: _D.stroke),
  );
}
