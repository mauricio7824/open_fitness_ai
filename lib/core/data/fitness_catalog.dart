import '../models/exercise.dart';
import '../models/fitness_models.dart';

/// Stable exercise IDs keep routines independent of catalog ordering.
List<Workout> buildWorkouts(ExerciseCatalog catalog) => List.unmodifiable([
  Workout(
    id: 'full-body',
    name: 'Cuerpo completo',
    description: 'Una base sencilla para mover todo el cuerpo a tu ritmo.',
    minutes: 20,
    level: 'Inicial',
    moves: List.unmodifiable([
      WorkoutMove(catalog.requireById('squat'), '3 series · 10 repeticiones'),
      WorkoutMove(catalog.requireById('pushup'), '3 series · 8 repeticiones'),
      WorkoutMove(catalog.requireById('bridge'), '3 series · 12 repeticiones'),
      WorkoutMove(catalog.requireById('plank'), '3 series · 20 segundos'),
    ]),
  ),
  Workout(
    id: 'lower-body',
    name: 'Piernas en movimiento',
    description: 'Trabaja piernas y glúteos con tu propio peso.',
    minutes: 15,
    level: 'Inicial',
    moves: List.unmodifiable([
      WorkoutMove(catalog.requireById('squat'), '3 series · 10 repeticiones'),
      WorkoutMove(catalog.requireById('lunge'), '2 series · 8 por lado'),
      WorkoutMove(catalog.requireById('bridge'), '3 series · 12 repeticiones'),
    ]),
  ),
  Workout(
    id: 'core',
    name: 'Estabilidad y control',
    description: 'Una sesión breve para entrenar la zona media.',
    minutes: 10,
    level: 'Inicial',
    moves: List.unmodifiable([
      WorkoutMove(catalog.requireById('plank'), '3 series · 20 segundos'),
      WorkoutMove(catalog.requireById('bird-dog'), '3 series · 8 por lado'),
      WorkoutMove(catalog.requireById('bridge'), '2 series · 12 repeticiones'),
    ]),
  ),
]);
