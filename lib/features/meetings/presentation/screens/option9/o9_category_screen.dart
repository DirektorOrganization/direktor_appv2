import 'package:flutter/material.dart';
import '../../../../../../app/state/app_scope.dart';
import 'o9_subcategory_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Gestión de Categorías y Subcategorías
// ─────────────────────────────────────────────

class _O9Subcategory {
  _O9Subcategory({required this.id, required this.name});
  final int id;
  String name;
}

class _O9Category {
  _O9Category({
    required this.id,
    required this.name,
    required this.color,
    required this.subcategories,
  });
  final int id;
  String name;
  Color color;
  List<_O9Subcategory> subcategories;
}

class O9CategoryScreen extends StatefulWidget {
  const O9CategoryScreen({super.key});
  @override
  State<O9CategoryScreen> createState() => _O9CategoryScreenState();
}

class _O9CategoryScreenState extends State<O9CategoryScreen> {
  final List<_O9Category> _categories = [];
  bool _loading = true;
  bool _loaded = false;

  final Set<int> _expanded = {1};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final controller = AppScope.of(context);
    final data = await controller.loadActreuCategoryTree();
    final palette = <Color>[
      const Color(0xFF0A66B7),
      const Color(0xFF1B8E5A),
      const Color(0xFF7C3AED),
      const Color(0xFFD64545),
      const Color(0xFFE4A620),
    ];
    var index = 0;
    final mapped = data
        .map(
          (item) => _O9Category(
            id: item.categoryId,
            name: item.categoryName,
            color: palette[index++ % palette.length],
            subcategories: item.subcategories
                .map(
                  (sub) => _O9Subcategory(
                    id: sub.subcategoryId,
                    name: sub.subcategoryName,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    if (!mounted) return;
    setState(() {
      _categories
        ..clear()
        ..addAll(mapped);
      if (_categories.isNotEmpty) {
        _expanded
          ..clear()
          ..add(_categories.first.id);
      }
      _loading = false;
    });
  }

  void _showUserMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB3261E) : null,
      ),
    );
  }

  void _addCategory() {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nueva categoría', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de categoría',
                prefixIcon: Icon(Icons.folder_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear categoría'),
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  final createdId = await AppScope.of(
                    context,
                  ).createActreuCategory(name: name, statusCode: 1);
                  if (!mounted) return;
                  if (createdId != null) {
                    setState(
                      () => _categories.insert(
                        0,
                        _O9Category(
                          id: createdId,
                          name: name,
                          color: const Color(0xFF0A66B7),
                          subcategories: [],
                        ),
                      ),
                    );
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSubcategory(_O9Category cat) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nueva subcategoría',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'en ${cat.name}',
              style: TextStyle(
                fontSize: 12,
                color: cat.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de subcategoría',
                prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar subcategoría'),
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  final createdId = await AppScope.of(
                    context,
                  ).createActreuSubcategory(
                    categoryId: cat.id,
                    name: name,
                    statusCode: 1,
                  );
                  if (!mounted) return;
                  if (createdId != null) {
                    setState(
                      () => cat.subcategories.insert(
                        0,
                        _O9Subcategory(id: createdId, name: name),
                      ),
                    );
                    _expanded.add(cat.id);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(_O9Category cat) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.name}" y todas sus subcategorías?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () async {
              final controller = AppScope.of(context);
              final deleted = await controller.deleteActreuCategory(cat.id);
              if (!mounted) return;
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (deleted) {
                await _loadFromDb();
                _showUserMessage('Categoría eliminada.');
              } else {
                final error = controller.error;
                _showUserMessage(
                  error ??
                      'No se pudo eliminar la categoría. Verifica que no tenga subcategorías activas.',
                  isError: true,
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteSubcategory(_O9Category cat, _O9Subcategory sub) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar subcategoría'),
        content: Text('¿Eliminar "${sub.name}" de "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () async {
              final controller = AppScope.of(context);
              final deleted = await controller.deleteActreuSubcategory(sub.id);
              if (!mounted) return;
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (deleted) {
                await _loadFromDb();
                _showUserMessage('Subcategoría eliminada.');
              } else {
                final error = controller.error;
                _showUserMessage(
                  error ??
                      'No se pudo eliminar la subcategoría. Verifica que no tenga acuerdos ni sesiones pendientes.',
                  isError: true,
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _editCategory(_O9Category cat) {
    final ctrl = TextEditingController(text: cat.name);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar categoría',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de categoría',
                prefixIcon: Icon(Icons.folder_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Guardar cambios'),
                onPressed: () async {
                  final nextName = ctrl.text.trim();
                  if (nextName.isEmpty) return;
                  final controller = AppScope.of(context);
                  final updated = await controller.updateActreuCategoryName(
                    categoryId: cat.id,
                    name: nextName,
                  );
                  if (!mounted) return;
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (updated) {
                    await _loadFromDb();
                    _showUserMessage('Categoría actualizada.');
                  } else {
                    _showUserMessage(
                      controller.error ?? 'No se pudo actualizar la categoría.',
                      isError: true,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSubcategory(_O9Category cat, _O9Subcategory sub) {
    final ctrl = TextEditingController(text: sub.name);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar subcategoría',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'en ${cat.name}',
              style: TextStyle(
                fontSize: 12,
                color: cat.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Guardar'),
                onPressed: () async {
                  final nextName = ctrl.text.trim();
                  if (nextName.isEmpty) return;
                  final controller = AppScope.of(context);
                  final updated = await controller.updateActreuSubcategoryName(
                    subcategoryId: sub.id,
                    name: nextName,
                  );
                  if (!mounted) return;
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (updated) {
                    await _loadFromDb();
                    _showUserMessage('Subcategoría actualizada.');
                  } else {
                    _showUserMessage(
                      controller.error ??
                          'No se pudo actualizar la subcategoría.',
                      isError: true,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToSubcategory(_O9Category cat, _O9Subcategory sub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => O9SubcategoryScreen(
          subcategoryId: sub.id,
          subcategoryName: sub.name,
          categoryName: cat.name,
          categoryColor: cat.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0EAF6)),
        ),
        title: const Text(
          'Categorías y Subcategorías',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('Nueva categoría'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sin categorías aún',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Toca el botón para crear una',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A66B7).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0A66B7).withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF0A66B7),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Organiza tus reuniones en categorías y agrupa subcategorías dentro de cada una. Toca una subcategoría para acceder a ella.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0A66B7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._categories.map(
                  (cat) => _CategoryTile(
                    cat: cat,
                    isExpanded: _expanded.contains(cat.id),
                    onToggle: () => setState(() {
                      if (_expanded.contains(cat.id)) {
                        _expanded.remove(cat.id);
                      } else {
                        _expanded.add(cat.id);
                      }
                    }),
                    onAddSub: () => _addSubcategory(cat),
                    onDeleteCat: () => _deleteCategory(cat),
                    onEditCat: () => _editCategory(cat),
                    onDeleteSub: (sub) => _deleteSubcategory(cat, sub),
                    onEditSub: (sub) => _editSubcategory(cat, sub),
                    onTapSub: (sub) => _goToSubcategory(cat, sub),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.isExpanded,
    required this.onToggle,
    required this.onAddSub,
    required this.onDeleteCat,
    required this.onEditCat,
    required this.onDeleteSub,
    required this.onEditSub,
    required this.onTapSub,
  });
  final _O9Category cat;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAddSub;
  final VoidCallback onDeleteCat;
  final VoidCallback onEditCat;
  final ValueChanged<_O9Subcategory> onDeleteSub;
  final ValueChanged<_O9Subcategory> onEditSub;
  final ValueChanged<_O9Subcategory> onTapSub;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cat.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cat.subcategories.length} sub',
                      style: TextStyle(
                        fontSize: 10,
                        color: cat.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    onSelected: (v) {
                      if (v == 'delete') onDeleteCat();
                      if (v == 'add') onAddSub();
                      if (v == 'edit') onEditCat();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Editar categoría'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Agregar subcategoría'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Color(0xFFD64545),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Color(0xFFD64545)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: cat.color.withValues(alpha: 0.15)),
            ...cat.subcategories.map(
              (sub) => InkWell(
                onTap: () => onTapSub(sub),
                borderRadius: BorderRadius.circular(0),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(24, 2, 8, 2),
                  leading: Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 18,
                    color: cat.color.withValues(alpha: 0.70),
                  ),
                  title: Text(
                    sub.name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => onEditSub(sub),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Color(0xFFD64545),
                        ),
                        onPressed: () => onDeleteSub(sub),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: OutlinedButton.icon(
                onPressed: onAddSub,
                icon: Icon(Icons.add_rounded, size: 16, color: cat.color),
                label: Text(
                  'Agregar subcategoría',
                  style: TextStyle(fontSize: 12, color: cat.color),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cat.color.withValues(alpha: 0.40)),
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
