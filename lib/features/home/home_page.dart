import 'package:flutter/material.dart';

import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';
import '../workouts/workout_session_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onWorkouts,
  });
  final FitnessController controller;
  final VoidCallback onWorkouts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = controller.activeSession;
    final workouts = controller.workouts;
    return PageContent(
      children: [
        const PageHeading(
          title: 'Tu próximo paso empieza hoy',
          subtitle: 'Muévete a tu ritmo. Cada sesión cuenta.',
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.tertiaryContainer,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    active == null
                        ? Icons.explore_outlined
                        : Icons.play_circle_outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      active == null ? 'TU SESIÓN DE HOY' : 'SESIÓN EN CURSO',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                active?.workout.name ?? workouts.first.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                active == null
                    ? '20 min estimados · Nivel inicial · Sin pesas'
                    : '${active.completedMoves.length} de ${active.workout.moves.length} ejercicios completados',
              ),
              const SizedBox(height: 12),
              Text(
                active == null
                    ? 'Un poco de fuerza, un nuevo comienzo.'
                    : 'Continúa desde donde lo dejaste.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    openWorkout(context, controller, workouts.first),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  active == null
                      ? 'Comenzar entrenamiento'
                      : 'Continuar sesión',
                ),
              ),
            ],
          ),
        ),
        const SectionHeading(title: 'Tu actividad'),
        AdaptiveCards(
          minWidth: 220,
          children: [
            StatCard(
              icon: Icons.calendar_today_outlined,
              value: '${controller.sessionsThisWeek()}',
              label: 'Sesiones esta semana',
            ),
            StatCard(
              icon: Icons.check_circle_outline,
              value: '${controller.records.length}',
              label: 'Sesiones completadas',
            ),
          ],
        ),
        SectionHeading(
          title: 'Haz espacio para ti',
          action: TextButton(
            onPressed: onWorkouts,
            child: const Text('Ver rutinas'),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.self_improvement_outlined),
                SizedBox(height: 12),
                Text(
                  'La constancia se construye paso a paso',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Elige un momento de tu día para moverte, descansar y volver a empezar. '
                  'No necesitas hacerlo todo hoy.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
