import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import '../../core/models/user_preferences.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';

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
  final Set<ExerciseEquipment> _items = {};
  bool _saving = false;
  bool _hasSelection = false;
  bool _showError = false;
  @override
  void initState() {
    super.initState();
    final inventory = widget.controller.preferences.inventory;
    _items.addAll(inventory?.items ?? {});
    _hasSelection = inventory != null;
  }

  Future<void> _save() async {
    if (!_hasSelection) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveInventory(EquipmentInventory(_items));
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
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar equipamiento')),
      body: SafeArea(
        top: false,
        child: PageContent(
          children: [
            const PageHeading(
              title: 'Tu material disponible',
              subtitle:
                  'Selecciona el equipo al que tienes acceso habitualmente.',
            ),
            CheckboxListTile(
              key: const ValueKey('inventory-none'),
              title: const Text('Sin material'),
              subtitle: const Text(
                'Esta opción elimina la selección de equipamiento.',
              ),
              value: _hasSelection && _items.isEmpty,
              onChanged: _saving
                  ? null
                  : (selected) => setState(() {
                      if (selected == true) {
                        _items.clear();
                        _hasSelection = true;
                      } else {
                        _hasSelection = false;
                      }
                    }),
            ),
            const SizedBox(height: 16),
            for (final group in <String, List<ExerciseEquipment>>{
              'Pesos, bancos y bandas': [
                ExerciseEquipment.dumbbells,
                ExerciseEquipment.barbell,
                ExerciseEquipment.bench,
                ExerciseEquipment.resistanceBand,
              ],
              'Barras y máquinas': [
                ExerciseEquipment.pullUpBar,
                ExerciseEquipment.cableMachine,
                ExerciseEquipment.legPressMachine,
              ],
              'Otros apoyos': [ExerciseEquipment.wall, ExerciseEquipment.mat],
            }.entries) ...[
              SectionHeading(title: group.key),
              Card(
                child: Column(
                  children: [
                    for (final item in group.value)
                      CheckboxListTile(
                        key: ValueKey('inventory-${item.name}'),
                        title: Text(item.label),
                        value: _items.contains(item),
                        onChanged: _saving
                            ? null
                            : (selected) => setState(() {
                                selected == true
                                    ? _items.add(item)
                                    : _items.remove(item);
                                _hasSelection = _items.isNotEmpty;
                              }),
                      ),
                  ],
                ),
              ),
            ],
            if (_showError && !_hasSelection)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Selecciona material o marca «Sin material».',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Una barra con discos no equivale a una barra de dominadas. Marca cada máquina disponible por separado.',
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
