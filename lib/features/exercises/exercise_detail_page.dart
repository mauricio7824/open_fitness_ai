import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import '../../shared/widgets/fitness_widgets.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/equipment_compatibility.dart';
import '../profile/inventory_editor_page.dart';
import 'exercise_filter.dart';
import 'exercise_technique_sections.dart';

Future<void> showExerciseDetails(
  BuildContext context,
  Exercise exercise, {
  required ExerciseCatalog catalog,
  FitnessController? controller,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ExerciseDetailPage(
      exercise: exercise,
      catalog: catalog,
      controller: controller,
    ),
  ),
);

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    required this.catalog,
    this.controller,
  });
  final Exercise exercise;
  final ExerciseCatalog catalog;
  final FitnessController? controller;

  @override
  Widget build(BuildContext context) => controller == null
      ? _build(context)
      : ListenableBuilder(
          listenable: controller!,
          builder: (context, _) => _build(context),
        );

  Widget _build(BuildContext context) {
    final inventory = controller?.preferences.inventory;
    final alternatives = availableAlternatives(exercise, catalog, inventory);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del ejercicio')),
      body: SafeArea(
        top: false,
        child: PageContent(
          children: [
            PageHeading(title: exercise.name, subtitle: exercise.description),
            if (exercise.technique != null &&
                exercise.editorial.status == EditorialStatus.pending)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Guía educativa pendiente de revisión editorial.'),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    'Dificultad: ${exercise.difficulty.label.toLowerCase()}',
                  ),
                ),
                for (final modality in exercise.modalities)
                  Chip(label: Text(modality.label)),
              ],
            ),
            const SectionHeading(title: 'Músculos'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Principales: ${exercise.primaryMuscles.map((muscle) => muscle.label).join(', ')}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secundarios: ${exercise.secondaryMuscles.isEmpty ? 'No especificados' : exercise.secondaryMuscles.map((muscle) => muscle.label).join(', ')}',
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeading(title: 'Requisitos'),
            EquipmentCompatibility(
              exercise: exercise,
              inventory: inventory,
              catalog: controller?.equipmentCatalog,
            ),
            if (controller != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('detail-edit-inventory'),
                  onPressed: () => openInventory(context, controller!),
                  child: const Text('Editar mi equipo'),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Equipo necesario: ${exercise.equipmentRequirements.describe((id) => controller?.equipmentCatalog.label(id) ?? ExerciseEquipment.values.where((item) => item.name == id).firstOrNull?.label ?? id)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Equipo opcional: ${exercise.equipmentRequirements.optional.isEmpty ? 'Ninguno' : exercise.equipmentRequirements.optional.map((id) => controller?.equipmentCatalog.label(id) ?? ExerciseEquipment.values.where((item) => item.name == id).firstOrNull?.label ?? id).join(', ')}',
            ),
            const SizedBox(height: 12),
            for (final requirement in exercise.requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $requirement'),
              ),
            if (exercise.technique case final technique?) ...[
              ExerciseTechniqueSections(
                key: ValueKey('technique-${exercise.id}'),
                technique: technique,
                guidance: catalog.teachingGuidance,
              ),
              ExpansionTile(
                key: const PageStorageKey('original-instructions'),
                title: const Text('Resumen de instrucciones'),
                children: [
                  for (
                    var index = 0;
                    index < exercise.instructions.length;
                    index++
                  )
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        '${index + 1}. ${exercise.instructions[index]}',
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SectionHeading(title: 'Cómo realizarlo'),
              for (var index = 0; index < exercise.instructions.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(exercise.instructions[index])),
                    ],
                  ),
                ),
            ],
            const SectionHeading(title: 'Alternativas'),
            if (exercise.technique != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Las variantes ajustan este movimiento; las progresiones aumentan su exigencia. Las alternativas son otros ejercicios con requisitos propios y no sustituyen automáticamente tu rutina.',
                ),
              ),
            if (alternatives.isEmpty)
              Text(
                exercise.alternatives.isEmpty
                    ? 'Todavía no hay alternativas registradas para este ejercicio.'
                    : 'No hay alternativas compatibles con tu inventario. Puedes revisar el material disponible.',
              )
            else ...[
              const Text(
                'Compara el material y la dificultad de cada opción. Los movimientos no son equivalentes en todos sus requisitos.',
              ),
              const SizedBox(height: 12),
              if (inventory == null)
                const Text(
                  'Configura tu inventario para comprobar el equipo de las alternativas.',
                )
              else
                const Text(
                  'Se muestran alternativas compatibles con tu equipo.',
                ),
              for (final alternative in alternatives) ...[
                Card(
                  child: ListTile(
                    key: ValueKey('alternative-${alternative.exerciseId}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    title: Text(
                      catalog.requireById(alternative.exerciseId).name,
                    ),
                    subtitle: Text(alternative.reason),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => showExerciseDetails(
                      context,
                      catalog.requireById(alternative.exerciseId),
                      catalog: catalog,
                      controller: controller,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
            const SectionHeading(title: 'Fuentes y revisión'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.editorial.status.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(exercise.editorial.notes),
                    const SizedBox(height: 8),
                    Text(
                      'Actualizado: ${formatDate(context, exercise.editorial.updatedOn)}',
                    ),
                    if (exercise.editorial.reviewer != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Revisión: ${exercise.editorial.reviewer} · ${formatDate(context, exercise.editorial.reviewedOn!)}',
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (exercise.sources.isEmpty)
                      const Text('Sin fuentes verificadas registradas.'),
                    for (final source in [
                      ...exercise.sources,
                      ...?catalog.teachingGuidance?.sources,
                    ]) ...[
                      Text(
                        source.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(source.publisher),
                      if (source.scope != null) Text(source.scope!),
                      SelectableText(source.url.toString()),
                      Text(
                        'Referencia comprobada: ${formatDate(context, source.checkedOn)}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Las instrucciones están guardadas en la app. Las referencias externas requieren conexión para consultarse.',
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeading(title: 'Recursos y licencias'),
            if (exercise.resources.isEmpty)
              const Text(
                'No hay imágenes ni videos asociados a este ejercicio.',
              )
            else
              for (final resource in exercise.resources) ...[
                Text(
                  'Autoría: ${resource.creator} · Licencia: ${resource.license}',
                ),
                SelectableText(resource.licenseUrl.toString()),
                SelectableText(resource.sourceUrl.toString()),
              ],
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
}
