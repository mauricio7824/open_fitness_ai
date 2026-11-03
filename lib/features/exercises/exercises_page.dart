import 'package:flutter/material.dart';

import '../../core/data/fitness_catalog.dart';
import '../../core/models/fitness_models.dart';
import '../../shared/widgets/fitness_widgets.dart';

void showExerciseDetails(BuildContext context, Exercise exercise) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${exercise.group} · ${exercise.equipment}'),
          const SizedBox(height: 24),
          Text(
            'Cómo realizarlo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(exercise.instructions),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    ),
  );
}

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});
  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final _search = TextEditingController();
  String _group = 'Todos';

  String _normalize(String value) {
    var result = value.toLowerCase().trim();
    for (final entry in const {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
    }.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = exercises
        .where(
          (exercise) =>
              (_group == 'Todos' || exercise.group == _group) &&
              _normalize('${exercise.name} ${exercise.group}')
                  .contains(_normalize(_search.text)),
        )
        .toList();
    return PageContent(
      children: [
        const PageHeading(
          title: 'Explora los ejercicios',
          subtitle: 'Conoce cada movimiento antes de empezar.',
        ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final group in [
              'Todos',
              'Piernas',
              'Tren superior',
              'Zona media',
            ])
              ChoiceChip(
                label: Text(group),
                selected: _group == group,
                onSelected: (_) => setState(() => _group = group),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '${filtered.length} ejercicios',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.search_off,
            title: 'Sin coincidencias',
            message: 'Prueba con otro nombre o cambia el grupo muscular.',
          )
        else
          AdaptiveCards(
            children: [
              for (final exercise in filtered)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => showExerciseDetails(context, exercise),
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
                          Text(exercise.group),
                          const SizedBox(height: 4),
                          Text(exercise.equipment),
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
            ],
          ),
      ],
    );
  }
}
