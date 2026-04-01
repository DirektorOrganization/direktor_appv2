// ============================================================
// VISTA POR DEFECTO — DIREKTOR
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ───────────────────────────────────────────────────
abstract final class _D {
  static const bg           = Color(0xFFF5FAFE);
  static const surface      = Colors.white;
  static const stroke       = Color(0xFFE0EAF6);
  static const primary      = Color(0xFF0A66B7); // Direktor brand blue
  static const primaryDark  = Color(0xFF0852A3);
  static const accent       = Color(0xFF1167C8);
  static const accentLight  = Color(0xFFCCDFF7);
  static const text         = Color(0xFF0F172A);
  static const muted        = Color(0xFF64748B);
  static const mutedLight   = Color(0xFF94A3B8);
  static const red          = Color(0xFFEF4444);
  static const green        = Color(0xFF10B981);
  static const yellow       = Color(0xFFF59E0B);
  static const white        = Colors.white;
}

// ── Screen ────────────────────────────────────────────────────
class HubDefaultScreen extends StatelessWidget {
  const HubDefaultScreen({super.key});

  static String _rel(DateTime dt) {
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user    = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return const Scaffold(
            backgroundColor: _D.bg,
            body: Center(child: CircularProgressIndicator(color: _D.primary)),
          );
        }

        final summary      = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones   = controller.milestoneSummary;
        final sync         = controller.syncOverview;
        final projects     = controller.projects;

        final overdueCount    = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pct             = (summary.compliancePercent * 100).round();
        final completed3      = controller.completedRestrictions.take(3).toList();
        final isOnline        = sync.hasNetwork && !sync.isOfflineEffective;

        final canSync = !controller.isBusy &&
            !sync.isOfflineEffective &&
            sync.remoteSyncEnabled &&
            sync.apiConfigured;

        final syncText = sync.isOfflineEffective
            ? 'Sin conexion — modo offline'
            : sync.isSyncing
                ? 'Sincronizando…'
                : sync.lastSyncAt != null
                    ? 'Ultima sync ${_rel(sync.lastSyncAt!)}'
                    : sync.pendingCount > 0
                        ? '${sync.pendingCount} cambios pendientes'
                        : 'Todo sincronizado';

        return Scaffold(
          backgroundColor: _D.bg,
          body: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────
              Container(
                color: _D.surface,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _D.stroke)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const DirektorLogo(size: 26),
                        const SizedBox(width: 8),
                        const Text(
                          'DIREKTOR',
                          style: TextStyle(
                            color: _D.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        // Pill Online / Offline
                        _ConnPill(isOnline: isOnline),
                        const SizedBox(width: 10),
                        // Boton usuario rediseñado
                        _UserMenuButton(
                          user: user,
                          isOnline: isOnline,
                          onSelected: (v) async {
                            if (v == 'logout') {
                              await controller.logout();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                  context, RouteNames.login, (_) => false);
                            } else if (v == 'profile') {
                              if (!context.mounted) return;
                              Navigator.pushNamed(context, RouteNames.profile);
                            } else if (v == 'styles') {
                              if (!context.mounted) return;
                              await showStylePicker(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Scrollable Body ───────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Selector de Proyecto ───────────────
                      _ProjectSelectorRow(
                        currentProject: project,
                        projects: projects,
                        onChangeProject: (id) => controller.changeProject(id),
                      ),

                      // ── Sync Bar ───────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 16, 4),
                        child: Row(
                          children: [
                            Icon(
                              isOnline
                                  ? Icons.cloud_sync_rounded
                                  : Icons.cloud_off_rounded,
                              color: _D.mutedLight,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                syncText,
                                style: const TextStyle(color: _D.muted, fontSize: 11),
                              ),
                            ),
                            if (canSync)
                              TextButton(
                                onPressed: controller.syncNow,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Sincronizar',
                                  style: TextStyle(
                                    color: _D.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Metrics Grid ───────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          childAspectRatio: 1.5,
                          children: [
                            _DefaultMetric(
                              label: 'Cumplimiento',
                              value: '$pct%',
                              sublabel: 'restricciones',
                              color: _D.green,
                              icon: Icons.verified_rounded,
                            ),
                            _DefaultMetric(
                              label: 'Vencidas',
                              value: '$overdueCount',
                              sublabel: 'accion requerida',
                              color: overdueCount > 0 ? _D.red : _D.green,
                              icon: Icons.warning_rounded,
                            ),
                            _DefaultMetric(
                              label: 'En proceso',
                              value: '$inProgressCount',
                              sublabel: 'activas ahora',
                              color: _D.yellow,
                              icon: Icons.timelapse_rounded,
                            ),
                            _DefaultMetric(
                              label: 'Hitos activos',
                              value: '${milestones.inProgressCount}',
                              sublabel: 'seguimiento',
                              color: _D.primary,
                              icon: Icons.flag_circle_rounded,
                            ),
                          ],
                        ),
                      ),

                      // ── Module Navigation ──────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODULOS',
                              style: TextStyle(
                                color: _D.muted,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DefaultModuleRow(
                              icon: Icons.analytics_rounded,
                              accentColor: _D.primary,
                              title: 'Analisis de restricciones',
                              subtitle: 'Cumplimiento y vencidas',
                              bigValue: '$pct%',
                              bigLabel: 'cumplim.',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.restrictionsList),
                            ),
                            _DefaultModuleRow(
                              icon: Icons.flag_circle_rounded,
                              accentColor: const Color(0xFF0891B2),
                              title: 'Control de Hitos',
                              subtitle: 'Seguimiento contractual',
                              bigValue: '${milestones.delayedCount}',
                              bigLabel: 'vencidos',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.controlHitos),
                            ),
                            _DefaultModuleRow(
                              icon: Icons.groups_rounded,
                              accentColor: const Color(0xFF6366F1),
                              title: 'Acta de Reuniones',
                              subtitle: 'Option 9 panel',
                              bigValue: '—',
                              bigLabel: 'sesiones',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.actaReuniones),
                            ),
                          ],
                        ),
                      ),

                      // ── Recent Closures ────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Ultimas cerradas',
                                  style: TextStyle(
                                    color: _D.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, RouteNames.completedRestrictions),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Ver todo →',
                                    style: TextStyle(color: _D.primary, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _D.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _D.stroke),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: completed3.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Sin cierres recientes.',
                                        style: TextStyle(color: _D.muted, fontSize: 12),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (int i = 0; i < completed3.length; i++) ...[
                                          if (i > 0) const Divider(color: _D.stroke, height: 1),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: _D.green,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    completed3[i].activity,
                                                    style: const TextStyle(
                                                      color: _D.text,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _rel(completed3[i].updatedAt),
                                                  style: const TextStyle(
                                                    color: _D.muted,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),

                    ],
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

// ─────────────────────────────────────────────────────────────
// PILL ONLINE / OFFLINE
// ─────────────────────────────────────────────────────────────

class _ConnPill extends StatelessWidget {
  const _ConnPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color      = isOnline ? _D.green : _D.red;
    final bgColor    = color.withValues(alpha: 0.08);
    final borderColor = color.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECTOR DE PROYECTO (fila con icono, nombre, empresa y flechas)
// ─────────────────────────────────────────────────────────────

class _ProjectSelectorRow extends StatelessWidget {
  const _ProjectSelectorRow({
    required this.currentProject,
    required this.projects,
    required this.onChangeProject,
  });

  final ProjectRecord currentProject;
  final List<ProjectRecord> projects;
  final ValueChanged<int> onChangeProject;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: _D.surface,
          border: Border(bottom: BorderSide(color: _D.stroke)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _D.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_open_rounded, color: _D.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentProject.name,
                    style: const TextStyle(
                      color: _D.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 12, color: _D.mutedLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          currentProject.company,
                          style: const TextStyle(
                            color: _D.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.unfold_more_rounded, color: _D.mutedLight, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectPickerSheet(
        projects: projects,
        currentProjectId: currentProject.id,
        onSelect: (id) {
          onChangeProject(id);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PICKER DE PROYECTOS (bottom sheet con buscador)
// ─────────────────────────────────────────────────────────────

class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({
    required this.projects,
    required this.currentProjectId,
    required this.onSelect,
  });

  final List<ProjectRecord> projects;
  final int currentProjectId;
  final ValueChanged<int> onSelect;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.projects
        .where((p) =>
            _query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.company.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 18),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _D.stroke,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              'Cambiar proyecto',
              style: TextStyle(
                color: _D.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar proyecto...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _D.muted),
                filled: true,
                fillColor: _D.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _D.stroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _D.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _D.primary, width: 1.4),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: _D.muted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final project = filtered[i];
                      final isCurrent = project.id == widget.currentProjectId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _D.primary.withValues(alpha: 0.06)
                              : _D.surface,
                          border: Border.all(
                            color: isCurrent
                                ? _D.primary.withValues(alpha: 0.28)
                                : _D.stroke,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _D.primary
                                  .withValues(alpha: isCurrent ? 0.14 : 0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.folder_outlined,
                              size: 18,
                              color: _D.primary,
                            ),
                          ),
                          title: Text(
                            project.name,
                            style: const TextStyle(
                              color: _D.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            project.company,
                            style: const TextStyle(color: _D.muted, fontSize: 11),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle_rounded,
                                  color: _D.primary)
                              : null,
                          onTap: () => widget.onSelect(project.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTON DE USUARIO
// ─────────────────────────────────────────────────────────────

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({
    required this.user,
    required this.isOnline,
    required this.onSelected,
  });

  final UserProfile user;
  final bool isOnline;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _D.accentLight,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: _D.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserMenuSheet(
        user: user,
        isOnline: isOnline,
        onSelected: onSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MENU DE USUARIO (bottom sheet rediseñado)
// ─────────────────────────────────────────────────────────────

class _UserMenuSheet extends StatefulWidget {
  const _UserMenuSheet({
    required this.user,
    required this.isOnline,
    required this.onSelected,
  });

  final UserProfile user;
  final bool isOnline;
  final ValueChanged<String> onSelected;

  @override
  State<_UserMenuSheet> createState() => _UserMenuSheetState();
}

class _UserMenuSheetState extends State<_UserMenuSheet> {
  String? _locationText;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    if (!widget.isOnline) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Ubicacion no disponible';
            _loadingLocation = false;
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      final result = await _reverseGeocode(position.latitude, position.longitude);
      if (mounted) setState(() { _locationText = result; _loadingLocation = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'No se pudo obtener ubicacion';
          _loadingLocation = false;
        });
      }
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=es',
      );
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'DirektorApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 8));
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final address = (data['address'] as Map<String, dynamic>?) ?? {};
      final city = (address['city'] ?? address['town'] ?? address['county'] ?? '') as String;
      final state = (address['state'] ?? '') as String;
      final parts = [city, state].where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(', ');
      return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        '${widget.user.name.isNotEmpty ? widget.user.name[0] : ''}'
        '${widget.user.lastName.isNotEmpty ? widget.user.lastName[0] : ''}'
            .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 22),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _D.stroke,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          // Avatar + info del usuario
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_D.primaryDark, _D.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: _D.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      style: const TextStyle(
                        color: _D.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.user.role,
                      style: const TextStyle(color: _D.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Ubicacion
                    if (!widget.isOnline)
                      Row(
                        children: const [
                          Icon(Icons.wifi_off_rounded, size: 12, color: _D.red),
                          SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(color: _D.red, fontSize: 11),
                          ),
                        ],
                      )
                    else if (_loadingLocation)
                      Row(
                        children: const [
                          SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: _D.primary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Detectando ubicacion...',
                            style: TextStyle(color: _D.muted, fontSize: 11),
                          ),
                        ],
                      )
                    else if (_locationText != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: _D.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationText!,
                              style: const TextStyle(
                                color: _D.muted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(color: _D.stroke, height: 1),
          const SizedBox(height: 10),
          // Opciones
          _MenuOption(
            icon: Icons.person_rounded,
            label: 'Mi perfil',
            color: _D.primary,
            onTap: () {
              Navigator.pop(context);
              widget.onSelected('profile');
            },
          ),
          _MenuOption(
            icon: Icons.palette_rounded,
            label: 'Cambiar estilo',
            color: const Color(0xFFE8941A),
            onTap: () {
              Navigator.pop(context);
              widget.onSelected('styles');
            },
          ),
          _MenuOption(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesion',
            color: _D.red,
            onTap: () {
              Navigator.pop(context);
              widget.onSelected('logout');
            },
          ),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: _D.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.40),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────
class _DefaultMetric extends StatelessWidget {
  const _DefaultMetric({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.stroke),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(color: _D.mutedLight, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sublabel, style: const TextStyle(color: _D.muted, fontSize: 10)),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Module Row ────────────────────────────────────────────────
class _DefaultModuleRow extends StatelessWidget {
  const _DefaultModuleRow({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.bigValue,
    required this.bigLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String bigValue;
  final String bigLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _D.stroke),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _D.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _D.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bigValue,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  bigLabel,
                  style: const TextStyle(color: _D.muted, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _D.mutedLight,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
