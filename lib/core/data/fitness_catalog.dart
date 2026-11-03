import '../models/fitness_models.dart';

const exercises = [
  Exercise(
    id: 'squat',
    name: 'Sentadilla',
    group: 'Piernas',
    equipment: 'Sin material',
    instructions:
        'Separa los pies al ancho de los hombros. Lleva la cadera hacia atrás, '
        'flexiona las rodillas y vuelve a subir con un movimiento controlado.',
  ),
  Exercise(
    id: 'pushup',
    name: 'Flexiones',
    group: 'Tren superior',
    equipment: 'Sin material',
    instructions:
        'Apoya las manos bajo los hombros y mantén el cuerpo alineado. '
        'Flexiona los codos para bajar y empuja para subir. '
        'Puedes apoyar las rodillas para reducir la dificultad.',
  ),
  Exercise(
    id: 'bridge',
    name: 'Puente de glúteos',
    group: 'Piernas',
    equipment: 'Esterilla opcional',
    instructions:
        'Túmbate boca arriba, flexiona las rodillas y apoya los pies. '
        'Eleva la cadera sin arquear la espalda y baja lentamente.',
  ),
  Exercise(
    id: 'plank',
    name: 'Plancha',
    group: 'Zona media',
    equipment: 'Esterilla opcional',
    instructions:
        'Apoya los antebrazos y las puntas de los pies. Mantén el cuerpo '
        'alineado y respira con normalidad durante la posición.',
  ),
  Exercise(
    id: 'lunge',
    name: 'Zancadas alternas',
    group: 'Piernas',
    equipment: 'Sin material',
    instructions:
        'Da un paso hacia atrás, flexiona ambas rodillas y mantén el tronco '
        'erguido. Vuelve al inicio y alterna las piernas.',
  ),
  Exercise(
    id: 'bird-dog',
    name: 'Bird dog',
    group: 'Zona media',
    equipment: 'Esterilla opcional',
    instructions:
        'A cuatro apoyos, estira un brazo y la pierna contraria sin girar '
        'el tronco. Regresa despacio y cambia de lado.',
  ),
];

final workouts = [
  Workout(
    id: 'full-body',
    name: 'Cuerpo completo',
    description: 'Una base sencilla para mover todo el cuerpo a tu ritmo.',
    minutes: 20,
    level: 'Inicial',
    moves: [
      WorkoutMove(exercises[0], '3 series · 10 repeticiones'),
      WorkoutMove(exercises[1], '3 series · 8 repeticiones'),
      WorkoutMove(exercises[2], '3 series · 12 repeticiones'),
      WorkoutMove(exercises[3], '3 series · 20 segundos'),
    ],
  ),
  Workout(
    id: 'lower-body',
    name: 'Piernas en movimiento',
    description: 'Trabaja piernas y glúteos con tu propio peso.',
    minutes: 15,
    level: 'Inicial',
    moves: [
      WorkoutMove(exercises[0], '3 series · 10 repeticiones'),
      WorkoutMove(exercises[4], '2 series · 8 por lado'),
      WorkoutMove(exercises[2], '3 series · 12 repeticiones'),
    ],
  ),
  Workout(
    id: 'core',
    name: 'Estabilidad y control',
    description: 'Una sesión breve para entrenar la zona media.',
    minutes: 10,
    level: 'Inicial',
    moves: [
      WorkoutMove(exercises[3], '3 series · 20 segundos'),
      WorkoutMove(exercises[5], '3 series · 8 por lado'),
      WorkoutMove(exercises[2], '2 series · 12 repeticiones'),
    ],
  ),
];
