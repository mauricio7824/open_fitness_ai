import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/equipment_compatibility.dart';
import '../profile/inventory_editor_page.dart';
import '../../shared/widgets/fitness_widgets.dart';
import 'exercise_detail_page.dart';
import 'exercise_filter.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key, required this.catalog, this.controller});
  final ExerciseCatalog catalog;
  final FitnessController? controller;
  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final _search = TextEditingController();
  MuscleGroup? _muscle;
  ExerciseModality? _modality;
  String _equipment = 'all';
  bool _compatibleOnly = false;
  bool _preferredOnly = false;

  bool get _hasFilters =>
      _search.text.isNotEmpty ||
      _muscle != null ||
      _modality != null ||
      _equipment != 'all' ||
      _compatibleOnly ||
      _preferredOnly;

  void _reset() => setState(() {
    _search.clear();
    _muscle = null;
    _modality = null;
    _equipment = 'all';
    _compatibleOnly = false;
    _preferredOnly = false;
  });

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = widget.controller?.preferences;
    final inventory = preferences?.inventory;
    final items = widget.catalog.exercises;
    final muscles = MuscleGroup.values
        .where(
          (muscle) => items.any(
            (item) =>
                item.primaryMuscles.contains(muscle) ||
                item.secondaryMuscles.contains(muscle),
          ),
        )
        .toList();
    final equipment = ExerciseEquipment.values
        .where(
          (equipment) =>
              items.any((item) => item.requiredEquipment.contains(equipment)),
        )
        .toList();
    final filter = ExerciseFilter(
      query: _search.text,
      muscle: _muscle,
      modality: _modality,
      withoutEquipment: _equipment == 'none',
      equipment: equipment.where((item) => item.name == _equipment).firstOrNull,
      inventory: inventory,
      compatibleOnly: _compatibleOnly,
      preferredModalities: _preferredOnly
          ? preferences?.profile?.modalities
          : null,
    );
    final filtered = filter.apply(items);
    return PageContent(
      children: [
        const PageHeading(
          title: 'Explora los ejercicios',
          subtitle: 'Conoce cada movimiento antes de empezar.',
        ),
        const Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.offline_pin_outlined, size: 18),
            Text('Biblioteca disponible sin conexión'),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Buscar ejercicios',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 720
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: _LibraryFilter<MuscleGroup?>(
                    key: const ValueKey('filter-muscle'),
                    label: 'Grupo muscular',
                    value: _muscle,
                    entries: {
                      null: 'Todos los músculos',
                      for (final muscle in muscles) muscle: muscle.label,
                    },
                    onChanged: (value) => setState(() => _muscle = value),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _LibraryFilter<ExerciseModality?>(
                    key: const ValueKey('filter-modality'),
                    label: 'Modalidad',
                    value: _modality,
                    entries: {
                      null: 'Todas las modalidades',
                      for (final modality in ExerciseModality.values)
                        modality: modality.label,
                    },
                    onChanged: (value) => setState(() => _modality = value),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _LibraryFilter<String>(
                    key: const ValueKey('filter-equipment'),
                    label: 'Equipo necesario',
                    value: _equipment,
                    entries: {
                      'all': 'Cualquier equipo',
                      'none': 'Sin material',
                      for (final item in equipment) item.name: item.label,
                    },
                    onChanged: (value) =>
                        setState(() => _equipment = value ?? 'all'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const ValueKey('compatible-only'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Solo compatibles con mi equipo'),
          value: _compatibleOnly,
          onChanged: inventory == null
              ? null
              : (value) => setState(() => _compatibleOnly = value),
        ),
        if (preferences?.profile != null)
          SwitchListTile(
            key: const ValueKey('preferred-modalities-only'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo mis modalidades preferidas'),
            value: _preferredOnly,
            onChanged: (value) => setState(() => _preferredOnly = value),
          ),
        if (widget.controller != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('library-edit-inventory'),
              onPressed: () => openInventory(context, widget.controller!),
              icon: const Icon(Icons.tune),
              label: Text(
                inventory == null ? 'Configurar mi equipo' : 'Editar mi equipo',
              ),
            ),
          ),
        const Text('La compatibilidad comprueba solo el material obligatorio.'),
        const SizedBox(height: 12),
        const Text(
          'El grupo incluye músculos principales y secundarios. El equipo opcional no limita los resultados.',
        ),
        if (_hasFilters)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('reset-filters'),
              onPressed: _reset,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpiar filtros'),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          '${filtered.length} ${filtered.length == 1 ? 'ejercicio' : 'ejercicios'}',
          key: const ValueKey('exercise-count'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: 'Sin coincidencias',
            message: 'Prueba con otro nombre o cambia los filtros.',
            action: OutlinedButton(
              onPressed: _reset,
              child: const Text('Mostrar todos'),
            ),
          )
        else
          AdaptiveCards(
            children: [
              for (final exercise in filtered)
                Card(
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      key: ValueKey('exercise-${exercise.id}'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => showExerciseDetails(
                        context,
                        exercise,
                        catalog: widget.catalog,
                        controller: widget.controller,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.accessibility_new_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              exercise.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exercise.primaryMuscles
                                  .map((muscle) => muscle.label)
                                  .join(' · '),
                            ),
                            const SizedBox(height: 4),
                            Text(exercise.equipmentLabel),
                            const SizedBox(height: 8),
                            EquipmentCompatibility(
                              exercise: exercise,
                              inventory: inventory,
                            ),
                            const SizedBox(height: 8),
                            Text(exercise.difficulty.label),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Expanded(child: Text('Ver técnica')),
                                Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _LibraryFilter<T> extends StatelessWidget {
  const _LibraryFilter({
    super.key,
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> entries;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    // Recreate the field when its controlled value changes (including reset).
    key: ValueKey('$label:$value'),
    initialValue: value,
    isExpanded: true,
    itemHeight: null,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final entry in entries.entries)
        DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: onChanged,
  );
}
