import 'package:flutter/material.dart';

import '../../core/models/fitness_models.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';
import '../exercises/exercises_page.dart';

Future<void> openWorkout(
  BuildContext context,
  FitnessController controller,
  Workout workout,
) async {
  // When a session exists, always resume it rather than silently replacing it.
  final selected = controller.activeSession?.workout ?? workout;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) =>
          WorkoutSessionPage(controller: controller, workout: selected),
    ),
  );
}

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({
    super.key,
    required this.controller,
    required this.workout,
  });
  final FitnessController controller;
  final Workout workout;
  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  Future<void> _finish() async {
    try {
      final saved = await widget.controller.finishWorkout();
      if (!mounted || !saved) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Sesión guardada! Consulta tu progreso.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la sesión. Puedes volver a intentarlo.',
          ),
        ),
      );
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar esta sesión?'),
        content: const Text(
          'Los ejercicios marcados no se añadirán a tu historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir entrenando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    widget.controller.discardSession();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final session = widget.controller.activeSession;
      final saving = widget.controller.saving;
      return PopScope(
        canPop: !saving,
        child: Scaffold(
          appBar: AppBar(title: const Text('Tu entrenamiento')),
          body: SafeArea(
            top: false,
            child: PageContent(
              children: [
                PageHeading(
                  title: widget.workout.name,
                  subtitle: widget.workout.description,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 18),
                      label: Text('${widget.workout.minutes} min estimados'),
                    ),
                    Chip(
                      label: Text(
                        'Nivel ${widget.workout.level.toLowerCase()}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (session != null) ...[
                  Text(
                    '${session.completedMoves.length} de ${widget.workout.moves.length} ejercicios completados',
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        session.completedMoves.length /
                        widget.workout.moves.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  session == null
                      ? 'Revisa los movimientos y comienza cuando estés listo.'
                      : 'Marca cada ejercicio cuando hayas terminado todas sus series.',
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < widget.workout.moves.length; i++) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          if (session != null)
                            CheckboxListTile(
                              key: ValueKey('move-$i'),
                              contentPadding: EdgeInsets.zero,
                              value: session.completedMoves.contains(i),
                              onChanged: saving
                                  ? null
                                  : (_) => widget.controller.toggleMove(i),
                              title: Text(
                                widget.workout.moves[i].exercise.name,
                              ),
                              subtitle: Text(
                                widget.workout.moves[i].prescription,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            )
                          else
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: Text(
                                widget.workout.moves[i].exercise.name,
                              ),
                              subtitle: Text(
                                widget.workout.moves[i].prescription,
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => showExerciseDetails(
                                context,
                                widget.workout.moves[i].exercise,
                              ),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Ver técnica'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                if (session == null)
                  FilledButton.icon(
                    onPressed: () =>
                        widget.controller.startWorkout(widget.workout),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar sesión'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: session.isComplete && !saving ? _finish : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(saving ? 'Guardando…' : 'Finalizar y guardar'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Puedes volver a las pestañas y continuar durante esta apertura de la app. '
                    'El historial se guarda al finalizar la sesión.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: saving ? null : _discard,
                    child: const Text('Descartar sesión'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
