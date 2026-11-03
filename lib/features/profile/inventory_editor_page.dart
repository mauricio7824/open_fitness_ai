import 'package:flutter/material.dart';

import '../../core/models/equipment.dart';
import '../../core/models/user_preferences.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';
import 'custom_equipment_page.dart';

Future<void> openInventory(
  BuildContext context,
  FitnessController controller,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => InventoryEditorPage(controller: controller),
  ),
);

class InventoryEditorPage extends StatefulWidget {
  const InventoryEditorPage({super.key, required this.controller});
  final FitnessController controller;
  @override
  State<InventoryEditorPage> createState() => _InventoryEditorPageState();
}

class _InventoryEditorPageState extends State<InventoryEditorPage> {
  final _search = TextEditingController();
  final Map<String, EquipmentAvailability> _availability = {};
  final List<EquipmentDefinition> _custom = [];
  bool _saving = false;
  bool _hasSelection = false;
  bool _showError = false;
  String _statusFilter = 'all';
  int _revision = 0;
  EquipmentCatalog get _catalog =>
      widget.controller.builtInEquipmentCatalog.withCustom(_custom);

  @override
  void initState() {
    super.initState();
    final inventory = widget.controller.preferences.inventory;
    _availability.addAll(inventory?.availability ?? {});
    _custom.addAll(inventory?.customEquipment ?? []);
    _hasSelection = inventory != null;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setAvailability(String id, EquipmentAvailability state) => setState(() {
    if (state == EquipmentAvailability.unknown) {
      _availability.remove(id);
    } else {
      _availability[id] = state;
    }
    _hasSelection = _availability.isNotEmpty;
  });

  Future<void> _preset(EquipmentPreset preset) async {
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Propuesta: ${preset.label}'),
        content: Text(
          '${preset.ids.map(_catalog.label).join(', ')}.\n\nSe añadirán solo estos equipos. Revisa y ajusta la selección según lo que realmente tienes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Añadir propuesta'),
          ),
        ],
      ),
    );
    if (!mounted || apply != true) return;
    setState(() {
      for (final id in preset.ids) {
        _availability[id] = EquipmentAvailability.available;
      }
      _hasSelection = true;
      _revision++;
    });
  }

  Future<void> _editCustom([EquipmentDefinition? previous]) async {
    final definition = await Navigator.of(context).push<EquipmentDefinition>(
      MaterialPageRoute(
        builder: (_) =>
            CustomEquipmentPage(catalog: _catalog, previous: previous),
      ),
    );
    if (!mounted || definition == null) return;
    setState(() {
      _custom.removeWhere((item) => item.id == definition.id);
      _custom.add(definition);
      if (previous == null) {
        _availability[definition.id] = EquipmentAvailability.available;
      }
      _hasSelection = true;
      _revision++;
    });
  }

  Future<void> _save() async {
    if (!_hasSelection) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveInventory(
        EquipmentInventory.fromAvailability(
          _availability,
          customEquipment: _custom,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el inventario. Tus cambios siguen aquí.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final availableCount = _availability.values
        .where((state) => state == EquipmentAvailability.available)
        .length;
    final filtered = catalog
        .search(_search.text)
        .where(
          (item) =>
              _statusFilter == 'all' ||
              (_availability[item.id] ?? EquipmentAvailability.unknown).name ==
                  _statusFilter,
        )
        .toList();
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar equipamiento')),
        body: SafeArea(
          top: false,
          child: PageContent(
            children: [
              const PageHeading(
                title: 'Tu material disponible',
                subtitle: 'Busca por nombre, nombre en inglés o sinónimo. Declara cada equipo por separado.',
              ),
              const Text('Propuestas ajustables'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in equipmentPresets)
                    OutlinedButton(
                      key: ValueKey('preset-${preset.id}'),
                      onPressed: _saving ? null : () => _preset(preset),
                      child: Text(preset.label),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('inventory-search'),
                controller: _search,
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Buscar equipamiento',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda de equipo',
                          onPressed: () => setState(_search.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in {
                    'all': 'Todos',
                    for (final state in EquipmentAvailability.values)
                      state.name: state.label,
                  }.entries)
                    ChoiceChip(
                      key: ValueKey('inventory-state-${entry.key}'),
                      label: Text(entry.value),
                      selected: _statusFilter == entry.key,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _statusFilter = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$availableCount disponibles · ${filtered.length} equipos en la lista',
                key: const ValueKey('inventory-count'),
              ),
              CheckboxListTile(
                key: const ValueKey('inventory-none'),
                title: const Text('Sin material'),
                subtitle: const Text(
                  'Esta opción borra las selecciones de disponibilidad, sin eliminar tus equipos personalizados.',
                ),
                value: _hasSelection && _availability.isEmpty,
                onChanged: _saving
                    ? null
                    : (selected) => setState(() {
                        if (selected == true) {
                          _availability.clear();
                          _hasSelection = true;
                        } else {
                          _hasSelection = false;
                        }
                      }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const ValueKey('add-custom-equipment'),
                  onPressed: _saving ? null : () => _editCustom(),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir equipo personalizado'),
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'No hay equipos con estos filtros',
                  message: 'Prueba otro nombre o cambia la disponibilidad.',
                )
              else
                for (final category in EquipmentCategory.values)
                  if (filtered.any((item) => item.category == category))
                    Card(
                      child: ExpansionTile(
                        key: ValueKey(
                          'inventory-category-${category.name}-${_search.text}-$_statusFilter-$_revision',
                        ),
                        initiallyExpanded:
                            _search.text.isNotEmpty ||
                            filtered.any(
                              (item) =>
                                  item.category == category &&
                                  _availability[item.id] ==
                                      EquipmentAvailability.available,
                            ),
                        maintainState: true,
                        title: Text(category.label),
                        subtitle: Text(
                          '${filtered.where((item) => item.category == category).length} equipos',
                        ),
                        children: [
                          for (final item in filtered.where(
                            (item) => item.category == category,
                          ))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CheckboxListTile(
                                  key: ValueKey('inventory-${item.id}'),
                                  title: Text(item.nameEs),
                                  subtitle: Text(
                                    '${item.nameEn}\n${(_availability[item.id] ?? EquipmentAvailability.unknown).label}',
                                  ),
                                  isThreeLine: true,
                                  value:
                                      _availability[item.id] ==
                                      EquipmentAvailability.available,
                                  onChanged: _saving
                                      ? null
                                      : (selected) => _setAvailability(
                                          item.id,
                                          selected == true
                                              ? EquipmentAvailability.available
                                              : EquipmentAvailability
                                                    .unavailable,
                                        ),
                                  secondary:
                                      PopupMenuButton<EquipmentAvailability>(
                                        key: ValueKey(
                                          'availability-${item.id}',
                                        ),
                                        tooltip:
                                            'Disponibilidad de ${item.nameEs}',
                                        enabled: !_saving,
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (state) =>
                                            _setAvailability(item.id, state),
                                        itemBuilder: (_) => [
                                          for (final state
                                              in EquipmentAvailability.values)
                                            PopupMenuItem(
                                              value: state,
                                              child: Text(state.label),
                                            ),
                                        ],
                                      ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Text(item.description),
                                ),
                                if (item.variants.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      12,
                                    ),
                                    child: Text(
                                      'Configuraciones: ${item.variants.join(', ')}',
                                    ),
                                  ),
                                if (item.id.startsWith('custom-'))
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      key: ValueKey('edit-${item.id}'),
                                      onPressed: _saving
                                          ? null
                                          : () => _editCustom(item),
                                      child: const Text(
                                        'Editar equipo personalizado',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
              if (_showError && !_hasSelection)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Selecciona material o marca «Sin material».',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Una barra libre no implica disponer de una Smith. Polea alta, polea baja y cruce de poleas se declaran por separado.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('save-inventory'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar equipamiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
