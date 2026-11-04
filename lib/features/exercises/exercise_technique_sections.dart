import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import '../../shared/widgets/fitness_widgets.dart';

class ExerciseTechniqueSections extends StatelessWidget {
  const ExerciseTechniqueSections({
    super.key,
    required this.technique,
    this.guidance,
  });

  final ExerciseTechnique technique;
  final TeachingGuidance? guidance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (guidance != null) ...[
        const SizedBox(height: 16),
        Text(guidance!.scope),
      ],
      _heading('Posición inicial y preparación'),
      _points(technique.preparation),
      _heading('Cómo realizarlo'),
      Text(
        'Ejecución paso a paso',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 12),
      for (var index = 0; index < technique.steps.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text('${index + 1}. ${technique.steps[index]}'),
        ),
      _heading('Señales para detener la actividad'),
      _points([...?guidance?.stopSignals, ...technique.stopSignals]),
      _section('breathing', 'Respiración', [_points(technique.breathing)]),
      _section('control', 'Control del movimiento', [
        _points(technique.control),
      ]),
      _section('errors', 'Errores frecuentes y cómo reconocerlos', [
        for (final error in technique.commonErrors)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  error.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text('Cómo reconocerlo: ${error.recognition}'),
                const SizedBox(height: 8),
                Text('Qué ajustar: ${error.correction}'),
              ],
            ),
          ),
      ]),
      _section('tips', 'Consejos para aprender', [_points(technique.tips)]),
      _section('regressions', 'Variantes de menor dificultad', [
        _variations(technique.regressions),
      ]),
      _section('progressions', 'Progresiones', [
        const Text(
          'Considera un cambio cada vez, cuando puedas mantener el control y respirar con comodidad. No es una progresión obligatoria ni modifica tu rutina.',
        ),
        const SizedBox(height: 12),
        _variations(technique.progressions),
      ]),
      _section('precautions', 'Precauciones generales', [
        _points([...?guidance?.precautions, ...technique.precautions]),
      ]),
    ],
  );

  Widget _heading(String title) =>
      Semantics(header: true, child: SectionHeading(title: title));

  Widget _points(List<String> values) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final value in values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('• $value'),
        ),
    ],
  );

  Widget _variations(List<TechniqueVariation> values) => _points([
    for (final value in values) '${value.title}: ${value.description}',
  ]);

  Widget _section(String id, String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Card(
      child: ExpansionTile(
        key: PageStorageKey('technique-$id'),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}
