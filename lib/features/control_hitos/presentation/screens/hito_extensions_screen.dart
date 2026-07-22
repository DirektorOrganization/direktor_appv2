// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

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
  static const yellow = Color(0xFFF59E0B);
  static const white = Colors.white;
}

String _fmt(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class HitoExtensionsScreen extends StatelessWidget {
  const HitoExtensionsScreen({super.key, required this.milestoneId});
  final int milestoneId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final canWrite = controller.canWriteProjectModule('CONHIT');
        final record = controller.findMilestoneById(milestoneId);
        final extensions =
            record?.extensions ?? const <MilestoneExtensionRecord>[];

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ampliaciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _D.text,
                  ),
                ),
                if (record != null)
                  Text(
                    record.code,
                    style: const TextStyle(fontSize: 11, color: _D.muted),
                  ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _D.stroke),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Header card ────────────────────────────────────────────────
              _HeaderCard(record: record, extensionCount: extensions.length),
              const SizedBox(height: 16),

              // ── Timeline de ampliaciones ───────────────────────────────────
              if (extensions.isEmpty)
                _EmptyState()
              else ...[
                _SectionLabel(
                  'HISTORIAL DE AMPLIACIONES · ${extensions.length}',
                ),
                const SizedBox(height: 10),
                ...List.generate(extensions.length, (i) {
                  final isLast = i == extensions.length - 1;
                  return _ExtensionEntry(
                    extension: extensions[i],
                    index: i,
                    isLast: isLast,
                  );
                }),
              ],
              const SizedBox(height: 20),

              // ── Acción ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0852A3), Color(0xFF1580D8)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _D.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MaterialButton(
                    onPressed: canWrite
                        ? () => Navigator.pushNamed(
                            context,
                            RouteNames.controlHitosExtensionCreate,
                            arguments: MilestoneExtensionFormArgs(
                              milestoneId: milestoneId,
                            ),
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: _D.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          canWrite ? 'Nueva ampliación' : 'Solo lectura',
                          style: const TextStyle(
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
      },
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.record, required this.extensionCount});
  final MilestoneRecord? record;
  final int extensionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0852A3), Color(0xFF1580D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _D.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(
                icon: Icons.timeline_rounded,
                label:
                    '$extensionCount ampliación${extensionCount != 1 ? 'es' : ''}',
              ),
              if (record != null) ...[
                const SizedBox(width: 8),
                _Tag(icon: Icons.numbers_rounded, label: record!.code),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            record?.description ?? '—',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _D.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Historial de ampliaciones y fechas vigentes del hito.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (record != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _DateTag(
                  label: 'Contractual vigente',
                  date: record!.effectiveContractualDate,
                ),
                const SizedBox(width: 8),
                _DateTag(
                  label: 'Meta vigente',
                  date: record!.effectiveTargetDate,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _D.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _D.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTag extends StatelessWidget {
  const _DateTag({required this.label, required this.date});
  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _fmt(date),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _D.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Extension Entry (timeline style) ────────────────────────────────────────
class _ExtensionEntry extends StatelessWidget {
  const _ExtensionEntry({
    required this.extension,
    required this.index,
    required this.isLast,
  });
  final MilestoneExtensionRecord extension;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ext = extension;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline column ────────────────────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Numbered circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _D.yellow.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _D.yellow, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _D.yellow,
                      ),
                    ),
                  ),
                ),
                // Connector
                if (!isLast)
                  Expanded(
                    child: Center(child: Container(width: 2, color: _D.stroke)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Card ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _D.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: _D.yellow, width: 3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: title + date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _D.yellow.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Ampliación ${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _D.yellow,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (ext.requestedAt != null) ...[
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: _D.mutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmt(ext.requestedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: _D.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date flow: previous → new
                    _DateFlow(ext: ext),
                    const SizedBox(height: 12),

                    // Justification
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _D.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _D.stroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 12,
                                color: _D.muted,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'MOTIVO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _D.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            ext.justification.isNotEmpty
                                ? ext.justification
                                : '—',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _D.text,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Document link
                    if (ext.supportDocument.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _D.accentLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.attach_file_rounded,
                              size: 13,
                              color: _D.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ext.supportDocument,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _D.accent,
                                decoration: TextDecoration.underline,
                                decorationColor: _D.accent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ─── Date Flow ────────────────────────────────────────────────────────────────
class _DateFlow extends StatelessWidget {
  const _DateFlow({required this.ext});
  final MilestoneExtensionRecord ext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (ext.newContractualDate != null) ...[
          _FlowRow(
            label: 'Fecha contractual',
            icon: Icons.gavel_rounded,
            color: _D.primary,
            from: ext.previousTargetDate,
            to: ext.newContractualDate!,
          ),
          const SizedBox(height: 8),
        ],
        _FlowRow(
          label: 'Fecha meta',
          icon: Icons.flag_rounded,
          color: _D.accent,
          from: ext.previousTargetDate,
          to: ext.newTargetDate,
        ),
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.from,
    required this.to,
  });
  final String label;
  final IconData icon;
  final Color color;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const Spacer(),
        // From (strikethrough)
        Text(
          _fmt(from),
          style: const TextStyle(
            fontSize: 11,
            color: _D.mutedLight,
            decoration: TextDecoration.lineThrough,
            decorationColor: _D.mutedLight,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 12, color: _D.muted),
        ),
        // To (highlighted)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _fmt(to),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.stroke),
      ),
      child: const Column(
        children: [
          Icon(Icons.timeline_rounded, size: 36, color: _D.mutedLight),
          SizedBox(height: 10),
          Text(
            'Sin ampliaciones registradas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _D.muted,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Las ampliaciones extienden las fechas del hito.',
            style: TextStyle(fontSize: 12, color: _D.mutedLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _D.mutedLight,
        letterSpacing: 0.8,
      ),
    );
  }
}
