import 'package:flutter/material.dart';

import '../../core/data/fitness_catalog.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';
import 'workout_session_page.dart';

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key, required this.controller});
  final FitnessController controller;
  @override
  Widget build(BuildContext context) => PageContent(
    children: [
      const PageHeading(
        title: 'Encuentra tu ritmo',
        subtitle: 'Rutinas con tu propio peso, listas para empezar.',
      ),
      if (controller.activeSession != null) ...[
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tienes una sesión en curso',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(controller.activeSession!.workout.name),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => openWorkout(
                    context,
                    controller,
                    controller.activeSession!.workout,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continuar sesión'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
      AdaptiveCards(
        children: [
          for (final workout in workouts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      workout.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(workout.description),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('${workout.minutes} min aprox.')),
                        Chip(label: Text(workout.level)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${workout.moves.length} ejercicios · Sin pesas'),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () =>
                          openWorkout(context, controller, workout),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ver rutina'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ],
  );
}
