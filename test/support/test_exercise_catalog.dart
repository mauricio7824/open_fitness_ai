import 'dart:io';

import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/core/models/equipment.dart';
import 'package:open_fitness_ai/core/data/equipment_repository.dart';

final testEquipmentCatalog = EquipmentCatalog.decode(
  File(AssetEquipmentRepository.assetPath).readAsStringSync(),
);

class TestEquipmentRepository implements EquipmentRepository {
  @override
  Future<EquipmentCatalog> load() async => testEquipmentCatalog;
}

final testExerciseCatalog = ExerciseCatalog.decode(
  File(AssetExerciseRepository.assetPath).readAsStringSync(),
);

class TestExerciseRepository implements ExerciseRepository {
  bool failRead = false;
  @override
  Future<ExerciseCatalog> load() async {
    if (failRead) throw const FormatException('Catálogo no disponible');
    return testExerciseCatalog;
  }
}
