import '../../core/models/exercise.dart';

/// Categories combine with AND; muscle matching includes secondary muscles.
class ExerciseFilter {
  const ExerciseFilter({
    this.query = '',
    this.muscle,
    this.modality,
    this.equipment,
    this.withoutEquipment = false,
  });
  final String query;
  final MuscleGroup? muscle;
  final ExerciseModality? modality;
  final ExerciseEquipment? equipment;
  final bool withoutEquipment;

  List<Exercise> apply(Iterable<Exercise> exercises) {
    final words = normalizeExerciseSearch(query)
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    return exercises
        .where((exercise) {
          final name = normalizeExerciseSearch(exercise.name);
          return words.every(name.contains) &&
              (muscle == null ||
                  exercise.primaryMuscles.contains(muscle) ||
                  exercise.secondaryMuscles.contains(muscle)) &&
              (modality == null || exercise.modalities.contains(modality)) &&
              (!withoutEquipment || exercise.requiredEquipment.isEmpty) &&
              (equipment == null ||
                  exercise.requiredEquipment.contains(equipment));
        })
        .toList(growable: false);
  }
}

String normalizeExerciseSearch(String value) {
  var result = value.toLowerCase().trim();
  for (final entry in const {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  }.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  result = result.replaceAll(RegExp('[\u0300-\u0308]'), '');
  return result.replaceAll(RegExp(r'\s+'), ' ');
}
