import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/data/fitness_catalog.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/features/exercises/exercise_filter.dart';

import 'support/test_exercise_catalog.dart';

class TestCatalogBundle extends CachingAssetBundle {
  int reads = 0;
  bool fail = false;
  @override
  Future<ByteData> load(String key) async {
    reads++;
    expect(key, AssetExerciseRepository.assetPath);
    if (fail) throw StateError('Asset unavailable');
    return ByteData.sublistView(File(key).readAsBytesSync());
  }
}

Map<String, dynamic> freshJson() =>
    jsonDecode(File(AssetExerciseRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
Map<String, dynamic> firstExercise(Map<String, dynamic> json) =>
    (json['exercises'] as List).first as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = testExerciseCatalog;
  List<String> ids(ExerciseFilter filter) =>
      filter.apply(catalog.exercises).map((item) => item.id).toList();

  test('El catálogo local está empaquetado y se puede cargar sin servicios remotos', () async {
    final loaded = await AssetExerciseRepository().load();
    expect(loaded.exercises.length, 18);
    expect(loaded.version, 2);
  });

  test('El repositorio conserva la instantánea en memoria', () async {
    final bundle = TestCatalogBundle();
    final repository = AssetExerciseRepository(bundle: bundle);
    final first = await repository.load();
    expect(await repository.load(), same(first));
    expect(bundle.reads, 1);
  });

  test('Permite volver a leer después de un fallo de almacenamiento', () async {
    final bundle = TestCatalogBundle()..fail = true;
    final repository = AssetExerciseRepository(bundle: bundle);
    await expectLater(repository.load(), throwsStateError);
    bundle.fail = false;
    expect((await repository.load()).exercises, hasLength(18));
  });

  test(
    'Conserva los ejercicios de las rutinas y resuelve por ID, no por posición',
    () {
      final reordered = freshJson();
      reordered['exercises'] = (reordered['exercises'] as List).reversed
          .toList();
      final workouts = buildWorkouts(ExerciseCatalog.fromJson(reordered));
      expect(workouts.first.moves.map((move) => move.exercise.id), [
        'squat',
        'pushup',
        'bridge',
        'plank',
      ]);
      expect(workouts.last.moves.map((move) => move.exercise.id), [
        'plank',
        'bird-dog',
        'bridge',
      ]);
    },
  );

  test('Cubre las tres modalidades y todos los registros tienen requisitos e instrucciones', () {
    for (final modality in ExerciseModality.values) {
      expect(ids(ExerciseFilter(modality: modality)), isNotEmpty);
    }
    for (final exercise in catalog.exercises) {
      expect(exercise.name, isNotEmpty);
      expect(exercise.description, isNotEmpty);
      expect(exercise.primaryMuscles, isNotEmpty);
      expect(exercise.instructions.length, greaterThanOrEqualTo(2));
      expect(exercise.requirements, isNotEmpty);
      for (final alternative in exercise.alternatives) {
        expect(catalog.findById(alternative.exerciseId), isNotNull);
      }
    }
  });

  test('La instantánea y las colecciones de sus ejercicios son inmutables', () {
    expect(() => catalog.exercises.clear(), throwsUnsupportedError);
    final exercise = catalog.requireById('pushup');
    expect(() => exercise.primaryMuscles.clear(), throwsUnsupportedError);
    expect(
      () => exercise.instructions.add('Otra instrucción'),
      throwsUnsupportedError,
    );
    expect(() => exercise.sources.clear(), throwsUnsupportedError);
    expect(catalog.findById('unknown'), isNull);
  });

  test('No atribuye revisión ni licencia multimedia inexistentes', () {
    expect(
      catalog.exercises.where((item) => item.sources.isNotEmpty),
      hasLength(18),
    );
    for (final exercise in catalog.exercises) {
      expect(exercise.editorial.status, EditorialStatus.pending);
      expect(exercise.editorial.reviewer, isNull);
      expect(exercise.editorial.reviewedOn, isNull);
      expect(exercise.resources, isEmpty);
      for (final source in exercise.sources) {
        expect(source.url.scheme, 'https');
        expect(source.scope, isNotEmpty);
        expect(
          source.checkedOn,
          isIn([DateTime(2026, 11, 3), DateTime(2026, 11, 4)]),
        );
      }
    }
  });

  test(
    'Busca solo por nombre sin distinguir mayúsculas, espacios o tildes',
    () {
      expect(ids(const ExerciseFilter(query: '  BÍCEPS   mancuernas ')), [
        'biceps-curl',
      ]);
      expect(ids(const ExerciseFilter(query: 'glu\u0301teos')), ['bridge']);
      expect(ids(const ExerciseFilter(query: 'cuádriceps')), isEmpty);
      expect(ids(const ExerciseFilter(query: '')), hasLength(18));
    },
  );

  test('Los filtros de nombre, músculo, modalidad y equipo se combinan', () {
    expect(
      ids(
        const ExerciseFilter(
          query: 'remo',
          muscle: MuscleGroup.back,
          modality: ExerciseModality.gym,
          equipment: ExerciseEquipment.dumbbells,
        ),
      ),
      ['dumbbell-row'],
    );
    expect(
      ids(
        const ExerciseFilter(
          muscle: MuscleGroup.chest,
          modality: ExerciseModality.home,
          withoutEquipment: true,
        ),
      ),
      ['pushup', 'knee-pushup'],
    );
    expect(
      ids(
        const ExerciseFilter(
          muscle: MuscleGroup.back,
          equipment: ExerciseEquipment.legPressMachine,
        ),
      ),
      isEmpty,
    );
  });

  test(
    'Filtra músculos secundarios y distingue equipo necesario de opcional',
    () {
      expect(
        ids(const ExerciseFilter(muscle: MuscleGroup.hamstrings)),
        contains('bridge'),
      );
      expect(
        ids(const ExerciseFilter(withoutEquipment: true)),
        contains('plank'),
      );
      expect(
        ids(const ExerciseFilter(equipment: ExerciseEquipment.mat)),
        isEmpty,
      );
      expect(ids(const ExerciseFilter(equipment: ExerciseEquipment.bench)), [
        'dumbbell-row',
      ]);
      expect(ids(const ExerciseFilter(equipment: ExerciseEquipment.wall)), [
        'wall-pushup',
      ]);
    },
  );

  final invalidCases = <String, void Function(Map<String, dynamic>)>{
    'esquema desconocido': (json) => json['schemaVersion'] = 2,
    'versión inválida': (json) => json['catalogVersion'] = 0,
    'catálogo vacío': (json) => json['exercises'] = [],
    'ID repetido': (json) =>
        (json['exercises'] as List).add(firstExercise(json)),
    'ID inválido': (json) => firstExercise(json)['id'] = '../squat',
    'nombre vacío': (json) => firstExercise(json)['name'] = ' ',
    'descripción ausente': (json) => firstExercise(json).remove('description'),
    'modalidad desconocida': (json) =>
        firstExercise(json)['modalities'] = ['unknown'],
    'modalidad vacía': (json) => firstExercise(json)['modalities'] = [],
    'músculo desconocido': (json) =>
        firstExercise(json)['primaryMuscles'] = ['unknown'],
    'músculo principal ausente': (json) =>
        firstExercise(json)['primaryMuscles'] = [],
    'músculos repetidos': (json) =>
        firstExercise(json)['primaryMuscles'] = ['core', 'core'],
    'músculos superpuestos': (json) =>
        firstExercise(json)['secondaryMuscles'] = ['quadriceps'],
    'equipo desconocido': (json) =>
        firstExercise(json)['requiredEquipment'] = ['unknown'],
    'equipo superpuesto': (json) {
      firstExercise(json)['requiredEquipment'] = ['mat'];
      firstExercise(json)['optionalEquipment'] = ['mat'];
    },
    'dificultad desconocida': (json) =>
        firstExercise(json)['difficulty'] = 'unknown',
    'instrucciones vacías': (json) => firstExercise(json)['instructions'] = [],
    'requisitos ausentes': (json) => firstExercise(json)['requirements'] = [],
    'alternativa inexistente': (json) => firstExercise(json)['alternatives'] = [
      {'exerciseId': 'unknown', 'reason': 'Prueba'},
    ],
    'alternativa propia': (json) => firstExercise(json)['alternatives'] = [
      {'exerciseId': 'squat', 'reason': 'Prueba'},
    ],
    'alternativa repetida': (json) =>
        (firstExercise(json)['alternatives'] as List).add(
          (firstExercise(json)['alternatives'] as List).first,
        ),
    'URL insegura': (json) =>
        (firstExercise(json)['sources'] as List).first['url'] =
            'http://example.com',
    'fuente repetida': (json) => (firstExercise(json)['sources'] as List).add(
      (firstExercise(json)['sources'] as List).first,
    ),
    'fecha inexistente': (json) =>
        firstExercise(json)['editorial']['updatedOn'] = '2026-02-31',
    'revisión sin responsable': (json) =>
        firstExercise(json)['editorial']['status'] = 'reviewed',
    'revisión sin fuentes': (json) {
      final exercise = firstExercise(json);
      exercise['sources'] = [];
      exercise['editorial']['status'] = 'reviewed';
      exercise['editorial']['reviewer'] = 'Revisor de prueba';
      exercise['editorial']['reviewedOn'] = '2026-11-04';
    },
    'recurso sin licencia': (json) => firstExercise(json)['resources'] = [
      {
        'kind': 'image',
        'assetPath': 'assets/test.png',
        'creator': 'Prueba',
        'sourceUrl': 'https://example.com/source',
        'licenseUrl': 'https://example.com/license',
      },
    ],
  };
  for (final entry in invalidCases.entries) {
    test('Rechaza ${entry.key}', () {
      final json = freshJson();
      entry.value(json);
      expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
    });
  }
}
