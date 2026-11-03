import 'package:flutter/material.dart';

import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    required this.controller,
    required this.onWorkouts,
  });
  final FitnessController controller;
  final VoidCallback onWorkouts;
  @override
  Widget build(BuildContext context) {
    final records = controller.records;
    final totalSeconds = records.fold<int>(
      0,
      (sum, record) => sum + record.durationSeconds,
    );
    return PageContent(
      children: [
        const PageHeading(
          title: 'Cada sesión cuenta',
          subtitle: 'Tu recorrido, un entrenamiento a la vez.',
        ),
        AdaptiveCards(
          minWidth: 220,
          children: [
            StatCard(
              icon: Icons.fitness_center,
              value: '${records.length}',
              label: 'Sesiones completadas',
            ),
            StatCard(
              icon: Icons.timer_outlined,
              value: formatDuration(totalSeconds),
              label: 'Tiempo registrado',
            ),
            StatCard(
              icon: Icons.date_range_outlined,
              value: '${controller.sessionsThisWeek()}',
              label: 'Sesiones esta semana',
            ),
          ],
        ),
        const SectionHeading(title: 'Historial de entrenamientos'),
        if (records.isEmpty)
          EmptyState(
            icon: Icons.insights_rounded,
            title: 'Tu historia empieza aquí',
            message:
                'Completa tu primera sesión para ver tu actividad. '
                'Tus entrenamientos se guardan en este dispositivo.',
            action: FilledButton(
              onPressed: onWorkouts,
              child: const Text('Elegir entrenamiento'),
            ),
          )
        else ...[
          const Text(
            'Guardado en este dispositivo · El tiempo incluye las pausas de la sesión.',
          ),
          const SizedBox(height: 16),
          for (final record in records) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.workoutName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatDate(context, record.completedAt)} · '
                      '${TimeOfDay.fromDateTime(record.completedAt.toLocal()).format(context)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record.exerciseCount} ejercicios · ${formatDuration(record.durationSeconds)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
