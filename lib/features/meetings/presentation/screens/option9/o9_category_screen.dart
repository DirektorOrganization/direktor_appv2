import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
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
  _O9Category({required this.id, required this.name, required this.color, required this.subcategories});
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
  final List<_O9Category> _categories = [
    _O9Category(id: 1, name: 'Obra', color: const Color(0xFF0A66B7), subcategories: [
      _O9Subcategory(id: 1, name: 'Comité Semanal de Obra'),
      _O9Subcategory(id: 2, name: 'Reunión de Subcontratistas'),
    ]),
    _O9Category(id: 2, name: 'SST y Sostenibilidad', color: const Color(0xFF1B8E5A), subcategories: [
      _O9Subcategory(id: 3, name: 'Comité SST Mensual'),
      _O9Subcategory(id: 4, name: 'Inspección de Seguridad'),
    ]),
    _O9Category(id: 3, name: 'Gerencia y Finanzas', color: const Color(0xFF7C3AED), subcategories: [
      _O9Subcategory(id: 5, name: 'Reunión Quincenal Financiera'),
    ]),
    _O9Category(id: 4, name: 'Procura y Logística', color: const Color(0xFFD64545), subcategories: [
      _O9Subcategory(id: 6, name: 'Coordinación de Materiales'),
      _O9Subcategory(id: 7, name: 'Revisión de Proveedores'),
    ]),
  ];

  final Set<int> _expanded = {1};

  void _addCategory() {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nueva categoría', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre de categoría', prefixIcon: Icon(Icons.folder_rounded))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear categoría'),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _categories.add(_O9Category(id: DateTime.now().millisecondsSinceEpoch, name: ctrl.text.trim(), color: AppTheme.brandBlue, subcategories: [])));
              }
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }

  void _addSubcategory(_O9Category cat) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nueva subcategoría', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('en ${cat.name}', style: TextStyle(fontSize: 12, color: cat.color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre de subcategoría', prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar subcategoría'),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => cat.subcategories.add(_O9Subcategory(id: DateTime.now().millisecondsSinceEpoch, name: ctrl.text.trim())));
                _expanded.add(cat.id);
              }
              Navigator.pop(ctx);
            },
          )),
        ]),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD64545)),
            onPressed: () { setState(() => _categories.remove(cat)); Navigator.pop(ctx); },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteSubcategory(_O9Category cat, _O9Subcategory sub) {
    setState(() => cat.subcategories.remove(sub));
  }

  void _editCategory(_O9Category cat) {
    final ctrl = TextEditingController(text: cat.name);
    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Editar categoría', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre de categoría', prefixIcon: Icon(Icons.folder_rounded))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar cambios'),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) setState(() => cat.name = ctrl.text.trim());
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }

  void _editSubcategory(_O9Category cat, _O9Subcategory sub) {
    final ctrl = TextEditingController(text: sub.name);
    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Editar subcategoría', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('en ${cat.name}', style: TextStyle(fontSize: 12, color: cat.color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar'),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) setState(() => sub.name = ctrl.text.trim());
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }

  void _goToSubcategory(_O9Category cat, _O9Subcategory sub) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => O9SubcategoryScreen(subcategoryName: sub.name, categoryName: cat.name, categoryColor: cat.color),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías y Subcategorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('Nueva categoría'),
      ),
      body: _categories.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.muted.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text('Sin categorías aún', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.muted)),
              const SizedBox(height: 6),
              Text('Toca el botón para crear una', style: theme.textTheme.bodySmall),
            ]))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.brandBlue),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Organiza tus reuniones en categorías y agrupa subcategorías dentro de cada una. Toca una subcategoría para acceder a ella.', style: TextStyle(fontSize: 12, color: AppTheme.brandBlue))),
                  ]),
                ),
                ..._categories.map((cat) => _CategoryTile(
                  cat: cat,
                  surface: surface,
                  isExpanded: _expanded.contains(cat.id),
                  onToggle: () => setState(() { if (_expanded.contains(cat.id)) { _expanded.remove(cat.id); } else { _expanded.add(cat.id); } }),
                  onAddSub: () => _addSubcategory(cat),
                  onDeleteCat: () => _deleteCategory(cat),
                  onEditCat: () => _editCategory(cat),
                  onDeleteSub: (sub) => _deleteSubcategory(cat, sub),
                  onEditSub: (sub) => _editSubcategory(cat, sub),
                  onTapSub: (sub) => _goToSubcategory(cat, sub),
                )),
              ],
            ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.cat, required this.surface, required this.isExpanded, required this.onToggle, required this.onAddSub, required this.onDeleteCat, required this.onEditCat, required this.onDeleteSub, required this.onEditSub, required this.onTapSub});
  final _O9Category cat;
  final Color surface;
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cat.color.withOpacity(0.25)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
      child: Column(children: [
        InkWell(
          onTap: onToggle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(cat.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: cat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text('${cat.subcategories.length} sub', style: TextStyle(fontSize: 10, color: cat.color, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppTheme.muted),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppTheme.muted, size: 20),
                onSelected: (v) { if (v == 'delete') onDeleteCat(); if (v == 'add') onAddSub(); if (v == 'edit') onEditCat(); },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Editar categoría')])),
                  const PopupMenuItem(value: 'add', child: Row(children: [Icon(Icons.add_rounded, size: 16), SizedBox(width: 8), Text('Agregar subcategoría')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFD64545)), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Color(0xFFD64545)))])),
                ],
              ),
            ]),
          ),
        ),
        if (isExpanded) ...[
          Divider(height: 1, color: cat.color.withOpacity(0.15)),
          ...cat.subcategories.map((sub) => InkWell(
            onTap: () => onTapSub(sub),
            borderRadius: BorderRadius.circular(0),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(24, 2, 8, 2),
              leading: Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: cat.color.withOpacity(0.70)),
              title: Text(sub.name, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 18),
                IconButton(
                  icon: Icon(Icons.edit_rounded, size: 16, color: AppTheme.muted),
                  onPressed: () => onEditSub(sub),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFD64545)),
                  onPressed: () => onDeleteSub(sub),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: OutlinedButton.icon(
              onPressed: onAddSub,
              icon: Icon(Icons.add_rounded, size: 16, color: cat.color),
              label: Text('Agregar subcategoría', style: TextStyle(fontSize: 12, color: cat.color)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: cat.color.withOpacity(0.40)), minimumSize: const Size(double.infinity, 36)),
            ),
          ),
        ],
      ]),
    );
  }
}
