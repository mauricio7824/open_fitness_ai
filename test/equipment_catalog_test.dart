import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/equipment_repository.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/equipment.dart';
import 'package:open_fitness_ai/core/models/equipment_requirements.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/core/models/fitness_models.dart';
import 'package:open_fitness_ai/core/models/user_preferences.dart';
import 'package:open_fitness_ai/core/state/fitness_controller.dart';
import 'package:open_fitness_ai/features/exercises/exercise_filter.dart';

import 'fitness_store_test.dart' show TestPreferences;
import 'user_preferences_test.dart' show exampleProfile;
import 'support/test_exercise_catalog.dart';

EquipmentDefinition customEquipment({
  String id = 'custom-test',
  String name = 'Agarre artesanal',
  List<String> synonyms = const ['Asa de fabricación propia'],
}) => EquipmentDefinition(
  id: id,
  nameEs: name,
  nameEn: 'Handmade training handle',
  synonyms: synonyms,
  category: EquipmentCategory.functional,
  kind: EquipmentKind.implement,
  modalities: [ExerciseModality.home],
  description: 'Implemento declarado por el usuario.',
  variants: ['Agarre fijo'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = testEquipmentCatalog;

  test(
    'El asset empaquetado ofrece al menos 60 tipos en las diez categorías',
    () async {
      final loaded = await AssetEquipmentRepository().load();
      expect(loaded.equipment, hasLength(84));
      expect(loaded.equipment.length, greaterThanOrEqualTo(60));
      expect(
        loaded.equipment.map((item) => item.category).toSet(),
        EquipmentCategory.values.toSet(),
      );
      expect(loaded.equipment.map((item) => item.id).toSet(), hasLength(84));
      expect(() => loaded.equipment.clear(), throwsUnsupportedError);
      expect(
        () => loaded.equipment.first.synonyms.clear(),
        throwsUnsupportedError,
      );
      for (final item in loaded.equipment) {
        expect(item.nameEs, isNotEmpty);
        expect(item.nameEn, isNotEmpty);
        expect(item.nameEs, isNot(contains('?')));
        expect(item.description, isNot(contains('?')));
        expect(item.defaultAvailability, EquipmentAvailability.unknown);
        expect(item.modalities, isNotEmpty);
        expect(item.variants, isNotEmpty);
      }
    },
  );

  test('Los nueve IDs anteriores y sus nombres se conservan exactamente', () {
    for (final legacy in ExerciseEquipment.values) {
      expect(catalog.require(legacy.name).nameEs, legacy.label);
    }
    testExerciseCatalog.validateEquipment(catalog);
    for (final preset in equipmentPresets) {
      expect(preset.ids.length, lessThan(6));
      for (final id in preset.ids) {
        expect(catalog.find(id), isNotNull);
      }
    }
  });

  test(
    'Busca nombres bilingües y sinónimos sin distinguir tildes o mayúsculas',
    () {
      List<String> ids(String query) =>
          catalog.search(query).map((item) => item.id).toList();
      expect(ids('  MULTIPOWER '), ['smith-machine']);
      expect(ids('low pulley'), ['low-pulley']);
      expect(ids('PESA RUSA'), ['kettlebell']);
      expect(ids('eliptica'), ['elliptical']);
      expect(ids('mancuernas'), ['dumbbells']);
      expect(ids('equipo inexistente'), isEmpty);
      expect(catalog.search(''), hasLength(84));
    },
  );

  test('Rechaza otro equipo que use un nombre o sinónimo ya registrado', () {
    expect(
      () => catalog.withCustom([customEquipment(name: 'Mancuernas')]),
      throwsFormatException,
    );
    expect(
      () => catalog.withCustom([
        customEquipment(synonyms: ['multipower']),
      ]),
      throwsFormatException,
    );
    expect(
      () =>
          EquipmentCatalog([catalog.equipment.first, catalog.equipment.first]),
      throwsFormatException,
    );
  });

  test('Persistencia conserva equipos disponibles, no disponibles y personalizados', () async {
    final plugin = TestPreferences();
    final store = PreferencesFitnessStore(preferences: plugin);
    final inventory = EquipmentInventory.fromAvailability(
      {
        'kettlebell': EquipmentAvailability.available,
        'low-pulley': EquipmentAvailability.unavailable,
        'custom-test': EquipmentAvailability.available,
      },
      customEquipment: [customEquipment()],
    );
    await store.savePreferences(
      UserPreferences(inventory: inventory, setupStatus: SetupStatus.skipped),
    );
    final restored = (await PreferencesFitnessStore(
      preferences: plugin,
    ).load()).preferences!;
    restored.inventory!.validateAgainst(catalog);
    expect(restored.inventory!.toJson(), inventory.toJson());
    expect(
      restored.inventory!.stateOf('low-pulley'),
      EquipmentAvailability.unavailable,
    );
    expect(
      restored.inventory!.stateOf('smith-machine'),
      EquipmentAvailability.unknown,
    );
    expect(restored.inventory!.availableIds, {'kettlebell', 'custom-test'});
    expect(
      catalog
          .withCustom(restored.inventory!.customEquipment)
          .label('custom-test'),
      'Agarre artesanal',
    );
    expect(
      () => restored.inventory!.availability.clear(),
      throwsUnsupportedError,
    );
  });

  test('Migra fase 3 sin perder ninguno de los nueve equipos, perfil, tema o historial', () async {
    final plugin = TestPreferences();
    final original = {
      'schemaVersion': 1,
      'profile': exampleProfile().toJson(),
      'inventory': {
        'equipment': ExerciseEquipment.values.map((item) => item.name).toList(),
      },
      'setupStatus': 'completed',
    };
    final originalText = jsonEncode(original);
    plugin.values['open_fitness.personalization.v1'] = originalText;
    final store = PreferencesFitnessStore(preferences: plugin);
    await store.saveTheme(ThemeMode.dark);
    final record = WorkoutRecord(
      id: 'old',
      workoutName: 'Cuerpo completo',
      completedAt: DateTime(2026, 11, 3),
      durationSeconds: 300,
      exerciseCount: 4,
    );
    await store.saveRecords([record]);
    final migrated = await store.load();
    expect(
      migrated.preferences!.inventory!.availableIds,
      ExerciseEquipment.values.map((item) => item.name).toSet(),
    );
    expect(migrated.preferences!.profile!.toJson(), exampleProfile().toJson());
    expect(migrated.preferences!.setupStatus, SetupStatus.completed);
    expect(migrated.themeMode, ThemeMode.dark);
    expect(migrated.records.single.toJson(), record.toJson());
    expect(plugin.values['open_fitness.personalization.v1'], originalText);
    await store.savePreferences(migrated.preferences!);
    final reloaded = await PreferencesFitnessStore(preferences: plugin).load();
    expect(reloaded.preferences!.toJson()['schemaVersion'], 2);
    expect(
      reloaded.preferences!.inventory!.availableIds,
      migrated.preferences!.inventory!.availableIds,
    );
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.records.single.toJson(), record.toJson());
  });

  test('Migra sin material y mantiene inventario desconocido sin inventar selección', () {
    final empty = UserPreferences.fromJson({
      'schemaVersion': 1,
      'profile': null,
      'inventory': {'equipment': []},
      'setupStatus': 'skipped',
    });
    expect(empty.inventory, isNotNull);
    expect(empty.inventory!.availableIds, isEmpty);
    final unknown = UserPreferences.fromJson({
      'schemaVersion': 1,
      'profile': null,
      'inventory': null,
      'setupStatus': 'skipped',
    });
    expect(unknown.inventory, isNull);
  });

  test(
    'La validación cruzada detecta IDs desconocidos al cargar preferencias',
    () async {
      final plugin = TestPreferences();
      final unknown = UserPreferences(
        inventory: EquipmentInventory.fromAvailability({
          'unregistered': EquipmentAvailability.available,
        }),
        setupStatus: SetupStatus.skipped,
      );
      plugin.values['open_fitness.personalization.v1'] = jsonEncode(
        unknown.toJson(),
      );
      final controller = FitnessController(
        PreferencesFitnessStore(preferences: plugin),
        exerciseRepository: TestExerciseRepository(),
        equipmentRepository: TestEquipmentRepository(),
      );
      await controller.initialize();
      expect(controller.loadFailed, isTrue);
      expect(
        plugin.values['open_fitness.personalization.v1'],
        jsonEncode(unknown.toJson()),
      );
      controller.dispose();
    },
  );

  test('El motor combina requisitos simultáneos y opciones alternativas explícitas', () {
    final requirements = EquipmentRequirements.fromJson({
      'allOf': [
        {
          'anyOf': [
            ['dumbbells', 'bench'],
            ['kettlebell', 'bench'],
          ],
        },
        {
          'anyOf': [
            ['mat'],
          ],
        },
      ],
      'optional': ['wall'],
    });
    requirements.validate(catalog);
    expect(
      requirements.evaluate({'dumbbells', 'bench', 'mat'}).compatible,
      isTrue,
    );
    expect(
      requirements.evaluate({'kettlebell', 'bench', 'mat'}).compatible,
      isTrue,
    );
    expect(requirements.evaluate({'dumbbells', 'mat'}).compatible, isFalse);
    expect(requirements.evaluate({'dumbbells', 'bench'}).compatible, isFalse);
    expect(
      requirements.evaluate({'dumbbells', 'bench', 'mat', 'wall'}).compatible,
      isTrue,
    );
    expect(
      requirements.evaluate({'mat'}).explain(catalog.label),
      contains('Mancuernas + Banco o Pesa rusa + Banco'),
    );
  });

  test(
    'No infiere Smith, polea baja o cruce de poleas por tener otro equipo',
    () {
      final bar = EquipmentRequirements.legacy(['barbell'], []);
      expect(bar.evaluate({'smith-machine'}).compatible, isFalse);
      expect(
        EquipmentRequirements.legacy([
          'smith-machine',
        ], []).evaluate({'barbell'}).compatible,
        isFalse,
      );
      expect(
        EquipmentRequirements.legacy([
          'low-pulley',
        ], []).evaluate({'cableMachine'}).compatible,
        isFalse,
      );
      expect(
        EquipmentRequirements.legacy([
          'cable-crossover',
        ], []).evaluate({'cableMachine', 'low-pulley'}).compatible,
        isFalse,
      );
      expect(
        EquipmentRequirements.legacy([
          'cableMachine',
        ], []).evaluate({'multi-station'}).compatible,
        isFalse,
      );
      expect(
        EquipmentRequirements.legacy([
          'dumbbells',
        ], []).evaluate({'custom-test'}).compatible,
        isFalse,
      );
    },
  );

  test('Las fichas existentes conservan sus requisitos y el equipo opcional no bloquea', () {
    final noMaterial = EquipmentInventory([]);
    final plank = testExerciseCatalog.requireById('plank');
    expect(noMaterial.supports(plank), isTrue);
    final row = testExerciseCatalog.requireById('dumbbell-row');
    expect(
      EquipmentInventory.fromAvailability({
        'dumbbells': EquipmentAvailability.available,
        'bench': EquipmentAvailability.unavailable,
      }).supports(row),
      isFalse,
    );
    expect(
      availableAlternatives(
        testExerciseCatalog.requireById('pushup'),
        testExerciseCatalog,
        noMaterial,
      ).map((item) => item.exerciseId),
      ['knee-pushup'],
    );
  });

  test('Integra requisitos nuevos en ejercicio y filtros manteniendo visible todo el catálogo', () {
    final json = jsonDecode(
      File('assets/catalog/exercises.v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final source = json['exercises'][0] as Map<String, dynamic>;
    source['equipmentRequirements'] = {
      'allOf': [
        {
          'anyOf': [
            ['dumbbells'],
            ['kettlebell'],
          ],
        },
      ],
      'optional': ['mat'],
    };
    final exercise = Exercise.fromJson(source);
    exercise.equipmentRequirements.validate(catalog);
    final inventory = EquipmentInventory.fromAvailability({
      'kettlebell': EquipmentAvailability.available,
    });
    expect(inventory.supports(exercise), isTrue);
    expect(
      ExerciseFilter(
        equipmentId: 'kettlebell',
        compatibleOnly: true,
        inventory: inventory,
      ).apply([exercise]),
      [exercise],
    );
    expect(const ExerciseFilter().apply([exercise]), [exercise]);
    expect(
      ExerciseFilter(
        compatibleOnly: true,
        inventory: EquipmentInventory([]),
      ).apply([exercise]),
      isEmpty,
    );
  });

  final malformedRequirements = <String, Object>{
    'grupo vacío': {
      'allOf': [
        {'anyOf': []},
      ],
      'optional': [],
    },
    'opción vacía': {
      'allOf': [
        {
          'anyOf': [[]],
        },
      ],
      'optional': [],
    },
    'alternativa repetida': {
      'allOf': [
        {
          'anyOf': [
            ['bench'],
            ['bench'],
          ],
        },
      ],
      'optional': [],
    },
    'ID repetido': {
      'allOf': [
        {
          'anyOf': [
            ['bench', 'bench'],
          ],
        },
      ],
      'optional': [],
    },
    'equipo superpuesto': {
      'allOf': [
        {
          'anyOf': [
            ['bench'],
          ],
        },
      ],
      'optional': ['bench'],
    },
    'ID malformado': {
      'allOf': [
        {
          'anyOf': [
            ['../bench'],
          ],
        },
      ],
      'optional': [],
    },
  };
  for (final entry in malformedRequirements.entries) {
    test(
      'Rechaza requisitos con ${entry.key}',
      () => expect(
        () => EquipmentRequirements.fromJson(entry.value),
        throwsFormatException,
      ),
    );
  }
  test('No admite un catálogo que presuponga equipo disponible', () {
    final json = catalog.equipment.first.toJson()
      ..['defaultAvailability'] = 'available';
    expect(() => EquipmentDefinition.fromJson(json), throwsFormatException);
  });
  test('Rechaza disponibilidad contradictoria y definición personalizada con ID oficial', () {
    expect(
      () => EquipmentInventory.fromJson({
        'equipment': ['bench'],
        'unavailableEquipment': ['bench'],
        'customEquipment': [],
      }),
      throwsFormatException,
    );
    expect(
      () => EquipmentInventory.fromAvailability(
        {},
        customEquipment: [customEquipment(id: 'bench')],
      ),
      throwsFormatException,
    );
  });
}
