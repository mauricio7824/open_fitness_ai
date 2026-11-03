class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.equipment,
    required this.instructions,
  });
  final String id;
  final String name;
  final String group;
  final String equipment;
  final String instructions;
}

class WorkoutMove {
  const WorkoutMove(this.exercise, this.prescription);
  final Exercise exercise;
  final String prescription;
}

class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.minutes,
    required this.level,
    required this.moves,
  });
  final String id;
  final String name;
  final String description;
  final int minutes;
  final String level;
  final List<WorkoutMove> moves;
}

class WorkoutSession {
  WorkoutSession(this.workout, {DateTime? startedAt})
    : startedAt = startedAt ?? DateTime.now();
  final Workout workout;
  final DateTime startedAt;
  final Set<int> completedMoves = {};
  bool get isComplete => completedMoves.length == workout.moves.length;
}

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.workoutName,
    required this.completedAt,
    required this.durationSeconds,
    required this.exerciseCount,
  });
  final String id;
  final String workoutName;
  final DateTime completedAt;
  final int durationSeconds;
  final int exerciseCount;

  Map<String, Object> toJson() => {
    'id': id,
    'workoutName': workoutName,
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'exerciseCount': exerciseCount,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['workoutName'];
    final date = json['completedAt'];
    final seconds = json['durationSeconds'];
    final count = json['exerciseCount'];
    if (id is! String ||
        name is! String ||
        date is! String ||
        seconds is! int ||
        seconds < 0 ||
        count is! int ||
        count < 1) {
      throw const FormatException('Registro de entrenamiento inválido.');
    }
    return WorkoutRecord(
      id: id,
      workoutName: name,
      completedAt: DateTime.parse(date),
      durationSeconds: seconds,
      exerciseCount: count,
    );
  }
}
