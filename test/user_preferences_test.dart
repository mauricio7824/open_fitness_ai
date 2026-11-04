import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/core/models/fitness_models.dart';
import 'package:open_fitness_ai/core/models/user_preferences.dart';
import 'package:open_fitness_ai/core/state/fitness_controller.dart';
import 'package:open_fitness_ai/features/exercises/exercise_filter.dart';

import 'fitness_store_test.dart' show TestPreferences;
import 'support/memory_fitness_store.dart';
import 'support/test_exercise_catalog.dart';

SportsProfile exampleProfile({int minutes = 30}) => SportsProfile(
  experience: TrainingExperience.beginner,
  modalities: [ExerciseModality.home],
  goals: [ActivityGoal.consistency],
  availableDays: [AvailableDay.monday, AvailableDay.friday],
  sessionMinutes: minutes,
);

UserPreferences completePreferences() => UserPreferences(
  profile: exampleProfile(),
  inventory: EquipmentInventory([
    ExerciseEquipment.dumbbells,
    ExerciseEquipment.bench,
  ]),
  setupStatus: SetupStatus.completed,
);

void main() {
  test('Serializa y restaura un perfil e inventario inmutables', () {
    final original = completePreferences();
    final restored = UserPreferences.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    expect(restored.toJson(), original.toJson());
    expect(() => restored.profile!.modalities.clear(), throwsUnsupportedError);
    expect(() => restored.profile!.goals.clear(), throwsUnsupportedError);
    expect(
      () => restored.profile!.availableDays.clear(),
      throwsUnsupportedError,
    );
    expect(() => restored.inventory!.items.clear(), throwsUnsupportedError);
  });

  test('Inventario desconocido y sin material son estados distintos', () {
    final initial = UserPreferences();
    expect(initial.inventory, isNull);
    expect(initial.needsSetup, isTrue);
    final skipped = initial.skipSetup();
    expect(skipped.inventory, isNull);
    expect(skipped.needsSetup, isFalse);
    final inventoryOnly = skipped.withInventory(EquipmentInventory([]));
    expect(inventoryOnly.inventory!.items, isEmpty);
    expect(inventoryOnly.setupStatus, SetupStatus.skipped);
    expect(
      inventoryOnly.withProfile(exampleProfile()).setupStatus,
      SetupStatus.completed,
    );
  });

  test('No considera completo un inventario que solo contiene parte del equipo necesario', () {
    final row = testExerciseCatalog.requireById('dumbbell-row');
    final dumbbells = EquipmentInventory([ExerciseEquipment.dumbbells]);
    expect(dumbbells.supports(row), isFalse);
    expect(dumbbells.missingFor(row), [ExerciseEquipment.bench]);
    expect(
      EquipmentInventory([ExerciseEquipment.dumbbells, ExerciseEquipment.bench])
          .supports(row),
      isTrue,
    );
    expect(
      EquipmentInventory([]).supports(testExerciseCatalog.requireById('plank')),
      isTrue,
    );
    expect(
      EquipmentInventory([ExerciseEquipment.barbell])
          .supports(testExerciseCatalog.requireById('pullup')),
      isFalse,
    );
    expect(
      EquipmentInventory([ExerciseEquipment.resistanceBand]).supports(row),
      isFalse,
    );
    expect(
      EquipmentInventory([ExerciseEquipment.cableMachine])
          .supports(testExerciseCatalog.requireById('leg-press')),
      isFalse,
    );
  });

  test('Combina compatibilidad, preferencias y los filtros existentes', () {
    final catalog = testExerciseCatalog;
    final filter = ExerciseFilter(
      query: 'pecho',
      modality: ExerciseModality.home,
      muscle: MuscleGroup.chest,
      equipment: ExerciseEquipment.dumbbells,
      compatibleOnly: true,
      inventory: EquipmentInventory([ExerciseEquipment.dumbbells]),
      preferredModalities: {ExerciseModality.home},
    );
    expect(filter.apply(catalog.exercises).map((item) => item.id), [
      'floor-press',
    ]);
    expect(
      const ExerciseFilter(compatibleOnly: true).apply(catalog.exercises),
      isEmpty,
    );
    expect(
      ExerciseFilter(
            preferredModalities: {ExerciseModality.calisthenics},
            inventory: EquipmentInventory([]),
            compatibleOnly: true,
          )
          .apply(catalog.exercises)
          .every(
            (item) =>
                item.requiredEquipment.isEmpty &&
                item.modalities.contains(ExerciseModality.calisthenics),
          ),
      isTrue,
    );
  });

  test(
    'Las alternativas solo incluyen ejercicios con todo el material disponible',
    () {
      final catalog = testExerciseCatalog;
      final pushup = catalog.requireById('pushup');
      expect(availableAlternatives(pushup, catalog, null), hasLength(2));
      expect(
        availableAlternatives(
          pushup,
          catalog,
          EquipmentInventory([]),
        ).map((item) => item.exerciseId),
        ['knee-pushup'],
      );
      expect(
        availableAlternatives(
          pushup,
          catalog,
          EquipmentInventory([ExerciseEquipment.wall]),
        ),
        hasLength(2),
      );
      expect(
        availableAlternatives(
          catalog.requireById('squat'),
          catalog,
          EquipmentInventory([]),
        ),
        isEmpty,
      );
    },
  );

  test('Restaura las preferencias reales del repositorio sin afectar historial ni tema', () async {
    final plugin = TestPreferences();
    final store = PreferencesFitnessStore(preferences: plugin);
    final record = WorkoutRecord(
      id: 'previous',
      workoutName: 'Rutina',
      completedAt: DateTime(2026, 11, 3),
      durationSeconds: 120,
      exerciseCount: 4,
    );
    await store.saveRecords([record]);
    await store.saveTheme(ThemeMode.dark);
    expect((await store.load()).preferences, isNull);
    await store.savePreferences(completePreferences());
    final restored = await PreferencesFitnessStore(preferences: plugin).load();
    expect(restored.preferences!.toJson(), completePreferences().toJson());
    expect(restored.records.single.toJson(), record.toJson());
    expect(restored.themeMode, ThemeMode.dark);
    final controller = FitnessController(
      PreferencesFitnessStore(preferences: plugin),
      exerciseRepository: TestExerciseRepository(),
      equipmentRepository: TestEquipmentRepository(),
    );
    await controller.initialize();
    expect(
      controller.preferences.inventory!.items,
      containsAll([ExerciseEquipment.dumbbells, ExerciseEquipment.bench]),
    );
    expect(controller.preferences.needsSetup, isFalse);
    controller.dispose();
  });

  test('Persiste omisión y configuración parcial entre instancias', () async {
    final plugin = TestPreferences();
    final store = PreferencesFitnessStore(preferences: plugin);
    final partial = UserPreferences().withProfile(exampleProfile());
    await store.savePreferences(partial);
    expect(
      (await PreferencesFitnessStore(
        preferences: plugin,
      ).load()).preferences!.needsSetup,
      isTrue,
    );
    await store.savePreferences(partial.skipSetup());
    final restored = (await PreferencesFitnessStore(
      preferences: plugin,
    ).load()).preferences!;
    expect(restored.setupStatus, SetupStatus.skipped);
    expect(restored.profile!.sessionMinutes, 30);
    expect(restored.inventory, isNull);
  });

  test('No sobrescribe preferencias corruptas al leerlas', () async {
    final plugin = TestPreferences();
    final store = PreferencesFitnessStore(preferences: plugin);
    await store.savePreferences(completePreferences());
    final key = plugin.values.keys.single;
    plugin.values[key] = '{"schemaVersion":99}';
    await expectLater(store.load(), throwsFormatException);
    expect(plugin.values[key], '{"schemaVersion":99}');
  });

  test(
    'Serializa ediciones simultáneas y permite reintentar tras un fallo',
    () async {
      final store = MemoryFitnessStore();
      final controller = FitnessController(
        store,
        exerciseRepository: TestExerciseRepository(),
        equipmentRepository: TestEquipmentRepository(),
      );
      await controller.initialize();
      await Future.wait([
        controller.saveProfile(exampleProfile()),
        controller.saveInventory(
          EquipmentInventory([ExerciseEquipment.dumbbells]),
        ),
      ]);
      expect(controller.preferences.setupStatus, SetupStatus.completed);
      expect(controller.preferences.profile, isNotNull);
      expect(
        controller.preferences.inventory!.items,
        contains(ExerciseEquipment.dumbbells),
      );
      final before = controller.preferences.toJson();
      store.failWrite = true;
      await expectLater(
        controller.saveInventory(EquipmentInventory([])),
        throwsStateError,
      );
      expect(controller.preferences.toJson(), before);
      expect(controller.savingPreferences, isFalse);
      store.failWrite = false;
      await controller.saveInventory(EquipmentInventory([]));
      expect(controller.preferences.inventory!.items, isEmpty);
      expect(controller.preferences.profile, isNotNull);
      controller.dispose();
    },
  );

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'versión desconocida': (json) => json['schemaVersion'] = 99,
    'perfil sin experiencia': (json) => json['profile']['experience'] = null,
    'experiencia desconocida': (json) =>
        json['profile']['experience'] = 'expert',
    'modalidad desconocida': (json) =>
        json['profile']['modalities'] = ['unknown'],
    'modalidades vacías': (json) => json['profile']['modalities'] = [],
    'objetivos vacíos': (json) => json['profile']['goals'] = [],
    'objetivo desconocido': (json) => json['profile']['goals'] = ['unknown'],
    'días vacíos': (json) => json['profile']['availableDays'] = [],
    'días repetidos': (json) =>
        json['profile']['availableDays'] = ['monday', 'monday'],
    'día desconocido': (json) => json['profile']['availableDays'] = ['unknown'],
    'duración negativa': (json) => json['profile']['sessionMinutes'] = -1,
    'duración demasiado larga': (json) =>
        json['profile']['sessionMinutes'] = 181,
    'duración no entera': (json) => json['profile']['sessionMinutes'] = 30.5,
    'equipo desconocido': (json) =>
        json['inventory']['equipment'] = ['unknown'],
    'equipo repetido': (json) =>
        json['inventory']['equipment'] = ['bench', 'bench'],
    'completado sin inventario': (json) => json['inventory'] = null,
    'omitido con ambos completos': (json) => json['setupStatus'] = 'skipped',
    'estado desconocido': (json) => json['setupStatus'] = 'unknown',
  };
  for (final entry in invalid.entries) {
    test('Rechaza ${entry.key}', () {
      final json = jsonDecode(
        jsonEncode(completePreferences().toJson()),
      ) as Map<String, dynamic>;
      entry.value(json);
      expect(
        () => UserPreferences.fromJson(
          json,
          equipmentCatalog: testEquipmentCatalog,
        ),
        throwsFormatException,
      );
    });
  }
}
