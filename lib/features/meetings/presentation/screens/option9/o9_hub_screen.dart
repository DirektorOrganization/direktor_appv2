// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import '../../../../../../app/state/app_scope.dart';
import '../../../../../../data/models/app_models.dart';
import 'o9_subcategory_screen.dart';
import 'o9_category_screen.dart';
import 'o9_overdue_screen.dart';
import 'o9_session_screen.dart';
import 'o9_agreement_detail_screen.dart';

// ── Paleta Direktor ───────────────────────────────────────────
abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const white = Colors.white;
  static const stroke = Color(0xFFE0EAF6);
  static const primary = Color(0xFF0A66B7);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const yellow = Color(0xFFF59E0B);
}

// ── Modelos internos ──────────────────────────────────────────

class _SubRow {
  const _SubRow({
    this.id = 0,
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.overdue,
    required this.pending,
    this.nextDate,
    required this.hasActiveSession,
    this.activeSessionId,
  });

  final int id;
  final String name;
  final String category;
  final Color categoryColor;
  final int overdue;
  final int pending;
  final String? nextDate;
  final bool hasActiveSession;
  final int? activeSessionId;
}

// ── Pantalla principal ────────────────────────────────────────

class O9HubScreen extends StatefulWidget {
  const O9HubScreen({super.key});

  @override
  State<O9HubScreen> createState() => _O9HubScreenState();
}

class _O9HubScreenState extends State<O9HubScreen> {
  Future<ActreuHubViewData>? _hubFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hubFuture ??= AppScope.of(context).loadActreuHubView();
  }

  Future<void> _reloadHub() async {
    if (!mounted) return;
    setState(() {
      _hubFuture = AppScope.of(context).loadActreuHubView();
    });
  }

  Future<void> _openAndReload(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _reloadHub();
  }

  Future<void> _openActiveSession(ActreuSessionBannerItem activeSession) async {
    final controller = AppScope.of(context);
    final hasParticipants = await controller.hasActreuParticipantsConfigured(
      activeSession.subcategoryId,
    );
    if (!mounted) return;
    if (!hasParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero agrega participantes en la subcategoría para ingresar a la sesión.',
          ),
        ),
      );
      return;
    }
    await _openAndReload(
      O9SessionScreen(
        subcategoryId: activeSession.subcategoryId,
        sessionId: activeSession.sessionId,
        canManageAttendance: controller.canWriteProjectModule('ACTAREU'),
        canManageAgreements: controller.canWriteProjectModule('ACTAREU'),
        canCloseSession: controller.canAdminProjectModule('ACTAREU'),
        canUseReporteria: controller.hasSubscriptionService('SERV_REPORTERIA'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final canAdmin = controller.canAdminProjectModule('ACTAREU');

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _D.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Acta de Reuniones',
          style: TextStyle(
            color: _D.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded, color: _D.muted),
            tooltip: canAdmin ? 'Gestionar categorías' : 'Ver categorías',
            onPressed: () => _openAndReload(const O9CategoryScreen()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _D.stroke),
        ),
      ),
      body: FutureBuilder<ActreuHubViewData>(
        future: _hubFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _D.primary),
            );
          }

          final data = snapshot.data!;
          final subRows = data.subcategories
              .map(
                (item) => _SubRow(
                  id: item.subcategoryId,
                  name: item.subcategoryName,
                  category: item.categoryName,
                  categoryColor: _D.primary,
                  overdue: item.overdueCount,
                  pending: item.pendingCount,
                  nextDate: _fmtShort(item.nextSessionDate),
                  hasActiveSession: item.hasActiveSession,
                  activeSessionId: item.activeSessionId,
                ),
              )
              .toList();

          final overdueItems = data.overdueAgreements;
          final activeSession = data.activeSession;

          return CustomScrollView(
            slivers: [
              // ── Cabecera proyecto ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.currentProject?.name ?? 'Proyecto',
                        style: const TextStyle(
                          color: _D.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Panorama general del módulo',
                        style: TextStyle(color: _D.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Banner sesión activa ────────────────────────
              if (activeSession != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _ActiveSessionBanner(
                      title: activeSession.title,
                      scheduleText:
                          '${_fmtShort(activeSession.sessionDate)} · ${activeSession.startTime}',
                      attendanceText:
                          '${activeSession.attendancePresent}/${activeSession.attendanceTotal}',
                      onEnter: () => _openActiveSession(activeSession),
                    ),
                  ),
                ),

              // ── Acuerdos vencidos ──────────────────────────
              if (overdueItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        const Text(
                          'ACUERDOS VENCIDOS',
                          style: TextStyle(
                            color: _D.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openAndReload(const O9OverdueScreen()),
                          child: const Text(
                            'Ver todos →',
                            style: TextStyle(
                              color: _D.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final a = overdueItems[i];
                    final gc = _colorFromHex(a.groupColorHex) ?? _D.primary;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _OverdueCard(
                        description: a.description,
                        responsible: a.responsible,
                        daysOverdue: a.daysOverdue,
                        group: a.group,
                        groupColor: gc,
                        onTap: () => _openAndReload(
                          O9AgreementDetailScreen(
                            id: a.agreementId,
                            description: a.description,
                            responsible: a.responsible,
                            dueDate: _fmtDate(a.dueDate),
                            status: 'overdue',
                            group: a.group,
                            groupColor: gc,
                            meetingDate: a.sessionLabel,
                            comments: a.commentsCount,
                            deferrals: a.deferralsCount,
                            readOnly: !controller.canWriteProjectModule(
                              'ACTAREU',
                            ),
                            onStatusChange: (_, _) {},
                          ),
                        ),
                      ),
                    );
                  }, childCount: overdueItems.length),
                ),
              ],

              // ── Subcategorías ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Text(
                        'SUBCATEGORÍAS',
                        style: TextStyle(
                          color: _D.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openAndReload(const O9CategoryScreen()),
                        child: const Text(
                          'Ver →',
                          style: TextStyle(
                            color: _D.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!data.hasSubcategories)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _EmptyState(
                      onTap: () => _openAndReload(const O9CategoryScreen()),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _SubCard(
                        sub: subRows[i],
                        canManageAttendance: controller.canWriteProjectModule(
                          'ACTAREU',
                        ),
                        canManageAgreements: controller.canWriteProjectModule(
                          'ACTAREU',
                        ),
                        canCloseSession: controller.canAdminProjectModule(
                          'ACTAREU',
                        ),
                        canUseReporteria: controller.hasSubscriptionService(
                          'SERV_REPORTERIA',
                        ),
                        onTap: () => _openAndReload(
                          O9SubcategoryScreen(subcategoryId: subRows[i].id),
                        ),
                      ),
                    ),
                    childCount: subRows.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  // ── Utilidades de fecha ──────────────────────────────────────
  static Color? _colorFromHex(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final hex = value.trim().replaceAll('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
  }

  static String _fmtDate(DateTime v) =>
      '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String _fmtShort(DateTime? v) {
    if (v == null) return '-';
    return '${v.day.toString().padLeft(2, '0')} ${_months[v.month - 1]}';
  }
}

// ── Banner sesión activa ──────────────────────────────────────

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({
    required this.title,
    required this.scheduleText,
    required this.attendanceText,
    required this.onEnter,
  });

  final String title;
  final String scheduleText;
  final String attendanceText;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0852A3), Color(0xFF0A66B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.radio_button_checked_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SESIÓN EN CURSO',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      scheduleText,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 11,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      attendanceText,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEnter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta acuerdo vencido ───────────────────────────────────

class _OverdueCard extends StatelessWidget {
  const _OverdueCard({
    required this.description,
    required this.responsible,
    required this.daysOverdue,
    required this.group,
    required this.groupColor,
    required this.onTap,
  });

  final String description;
  final String responsible;
  final int daysOverdue;
  final String group;
  final Color groupColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _D.red.withValues(alpha: 0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra lateral roja
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: _D.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grupo + días vencido
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: groupColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 10,
                            color: groupColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: _D.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Hace $daysOverdue días',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _D.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Descripcion
                  Text(
                    description,
                    style: const TextStyle(
                      color: _D.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Responsable
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: _D.mutedLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          responsible,
                          style: const TextStyle(color: _D.muted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: _D.mutedLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta subcategoría ──────────────────────────────────────

class _SubCard extends StatelessWidget {
  const _SubCard({
    required this.sub,
    required this.canManageAttendance,
    required this.canManageAgreements,
    required this.canCloseSession,
    required this.canUseReporteria,
    required this.onTap,
  });

  final _SubRow sub;
  final bool canManageAttendance;
  final bool canManageAgreements;
  final bool canCloseSession;
  final bool canUseReporteria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAlert = sub.overdue > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasAlert ? _D.red.withValues(alpha: 0.25) : _D.stroke,
          ),
        ),
        child: Row(
          children: [
            // Barra de color de categoría
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: sub.categoryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    sub.name,
                    style: const TextStyle(
                      color: _D.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Categoría + pills vencidos/pendientes
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sub.categoryColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          sub.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: sub.categoryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (sub.overdue > 0) ...[
                        const SizedBox(width: 6),
                        _StatPill(label: '${sub.overdue} venc.', color: _D.red),
                      ],
                      if (sub.pending > 0) ...[
                        const SizedBox(width: 6),
                        _StatPill(
                          label: '${sub.pending} pend.',
                          color: _D.yellow,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Estado sesión / próxima
                  if (sub.hasActiveSession)
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _D.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'Sesión en curso',
                            style: TextStyle(
                              fontSize: 11,
                              color: _D.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                               builder: (_) => sub.activeSessionId != null
                                   ? O9SessionScreen(
                                       subcategoryId: sub.id,
                                       sessionId: sub.activeSessionId,
                                       canManageAttendance:
                                           canManageAttendance,
                                       canManageAgreements:
                                           canManageAgreements,
                                       canCloseSession: canCloseSession,
                                       canUseReporteria: canUseReporteria,
                                     )
                                  : O9SubcategoryScreen(
                                      subcategoryId: sub.id,
                                      subcategoryName: sub.name,
                                      categoryName: sub.category,
                                      categoryColor: sub.categoryColor,
                                    ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _D.green.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 11,
                                color: _D.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (sub.nextDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 12,
                          color: _D.mutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Próxima: ${sub.nextDate}',
                          style: const TextStyle(fontSize: 11, color: _D.muted),
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 12,
                          color: _D.mutedLight,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sin sesiones agendadas',
                          style: TextStyle(fontSize: 11, color: _D.mutedLight),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: _D.mutedLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _D.stroke),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.settings_suggest_rounded,
              color: _D.mutedLight,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aún no hay subcategorías. Gestiona categorías primero.',
                style: TextStyle(color: _D.muted, fontSize: 13),
              ),
            ),
            const Text(
              'Gestionar →',
              style: TextStyle(
                color: _D.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pill de estadística ───────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
