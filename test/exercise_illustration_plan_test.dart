import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/exercise_media_repository.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';

import 'support/exercise_media_fixture.dart';
import 'support/test_exercise_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ids = ['squat', 'pushup', 'biceps-curl'];

  test('Tres planes vinculados por ID no son recursos disponibles ni archivos inventados', () {
    final planned = testExerciseCatalog.exercises
        .where((e) => e.illustrationPlan != null)
        .toList();
    expect(planned.map((e) => e.id), ids);
    expect(testExerciseCatalog.exercises, hasLength(18));
    expect(testEquipmentCatalog.equipment, hasLength(84));
    for (final exercise in testExerciseCatalog.exercises) {
      expect(exercise.resources, isEmpty);
      expect(exercise.instructions, isNotEmpty);
      expect(exercise.technique!.steps, isNotEmpty);
    }
    for (final exercise in planned) {
      final plan = exercise.illustrationPlan!;
      expect(plan.resourceId, '${exercise.id}-illustration-sequence');
      expect(plan.phases.map((p) => p.id), [
        'initial',
        'intermediate',
        'final',
      ]);
      expect(plan.phases.map((p) => p.title), [
        'Posición inicial',
        'Fase intermedia',
        'Posición final',
      ]);
      expect(() => plan.phases.clear(), throwsUnsupportedError);
      for (final phase in plan.phases) {
        expect(phase.description, startsWith('Guion previsto:'));
        expect(File(phase.expectedAssetPath).existsSync(), isFalse);
      }
    }
  });

  for (final id in ids) {
    test(
      'Acepta las tres fases locales de $id por su ID estable, con derechos y revisiones explícitos',
      () {
        final resource = plannedIllustrationFixture(id);
        final catalog = catalogWithPlannedResource(id, resource);
        final exercise = catalog.requireById(id);
        expect(
          exercise.resources.single.id,
          exercise.illustrationPlan!.resourceId,
        );
        expect(exercise.resources.single.frames, hasLength(3));
        expect(
          exercise.resources.single.technicalReview!.status,
          TechnicalReviewStatus.pending,
        );
        expect(exercise.resources.single.creator, contains('ficticio'));
        expect(exercise.resources.single.attribution, isNotEmpty);
        expect(exercise.resources.single.license, 'LicenseRef-Permission');
        expect(
          exercise.resources.single.frames.every(
            (frame) => frame.altText.isNotEmpty,
          ),
          isTrue,
        );
      },
    );
  }

  final invalidPlans = <String, void Function(Map<String, dynamic>)>{
    'sin resourceId': (j) => j.remove('resourceId'),
    'sin fases': (j) => j.remove('phases'),
    'dos fases': (j) => (j['phases'] as List).removeLast(),
    'fases desordenadas': (j) =>
        j['phases'] = (j['phases'] as List).reversed.toList(),
    'fase repetida': (j) => j['phases'][1]['id'] = 'initial',
    'archivo repetido': (j) => j['phases'][1]['expectedAssetPath'] =
        j['phases'][0]['expectedAssetPath'],
    'archivo ajeno al ejercicio': (j) =>
        j['phases'][0]['expectedAssetPath'] = fixtureImagePath,
    'ruta insegura': (j) =>
        j['phases'][0]['expectedAssetPath'] = '../image.png',
    'formato no permitido': (j) => j['phases'][0]['expectedAssetPath'] =
        'assets/exercise_media/squat/image.gif',
    'descripción vacía': (j) => j['phases'][0]['description'] = ' ',
  };
  for (final entry in invalidPlans.entries) {
    test('Rechaza plan ${entry.key}', () {
      final json = catalogWithMedia([]);
      entry.value(json['exercises'][0]['illustrationPlan']);
      expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
    });
  }

  test(
    'Rechaza planes con ID repetido o recurso vinculado a otro ejercicio',
    () {
      final repeated = catalogWithMedia([]);
      repeated['exercises'][1]['illustrationPlan']['resourceId'] =
          repeated['exercises'][0]['illustrationPlan']['resourceId'];
      expect(() => ExerciseCatalog.fromJson(repeated), throwsFormatException);
      expect(
        () => fixtureCatalog([plannedIllustrationFixture('pushup')]),
        throwsFormatException,
      );
    },
  );

  test('Un recurso que implementa el plan exige tres fases, orden, ruta y revisión técnica', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (r) => r.remove('technicalReview'),
      (r) => (r['frames'] as List).removeLast(),
      (r) => r['frames'] = (r['frames'] as List).reversed.toList(),
      (r) => r['frames'][0]['assetPath'] = fixtureImagePath,
      (r) => r['frames'][0]['altText'] = ' ',
      (r) => r.remove('creator'),
      (r) => r.remove('license'),
      (r) => r.remove('attribution'),
    ]) {
      final resource = plannedIllustrationFixture('squat');
      change(resource);
      expect(
        () => catalogWithPlannedResource('squat', resource),
        throwsFormatException,
      );
    }
  });

  test('La ausencia de revisión técnica en recursos anteriores no hereda aprobación editorial', () {
    final json = mediaFixture();
    json['editorial']
      ..['status'] = 'reviewed'
      ..['reviewer'] = 'Revisor ficticio'
      ..['reviewedOn'] = '2026-11-04';
    final resource = ExerciseResource.fromJson(json);
    expect(resource.editorial.status, EditorialStatus.reviewed);
    expect(resource.technicalReview, isNull);
  });

  test('Revisiones técnica y editorial se registran independientemente', () {
    final json = mediaFixture()..['technicalReview'] = technicalReviewFixture();
    json['technicalReview']
      ..['status'] = 'reviewed'
      ..['reviewer'] = 'Responsable técnico ficticio'
      ..['reviewedOn'] = '2026-11-04';
    final resource = ExerciseResource.fromJson(json);
    expect(resource.editorial.status, EditorialStatus.pending);
    expect(resource.technicalReview!.status, TechnicalReviewStatus.reviewed);
    expect(resource.editorial.reviewer, isNull);
    expect(resource.technicalReview!.reviewer, 'Responsable técnico ficticio');
  });

  test('Rechaza revisiones técnicas incompletas, firmas falsas de pendientes y fechas obsoletas', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (r) => r['technicalReview'] = null,
      (r) => r['technicalReview']['status'] = 'validated',
      (r) => r['technicalReview']['reviewer'] = 'Firma que no corresponde',
      (r) => r['technicalReview']['status'] = 'reviewed',
      (r) => r['technicalReview']['notes'] = ' ',
      (r) {
        r['technicalReview']
          ..['status'] = 'reviewed'
          ..['reviewer'] = 'Fixture'
          ..['reviewedOn'] = '2026-11-03';
      },
      (r) {
        r['editorial']['updatedOn'] = '2026-11-05';
        r['technicalReview']
          ..['status'] = 'reviewed'
          ..['reviewer'] = 'Fixture'
          ..['reviewedOn'] = '2026-11-04';
      },
    ]) {
      final json = mediaFixture()
        ..['technicalReview'] = technicalReviewFixture();
      change(json);
      expect(() => ExerciseResource.fromJson(json), throwsFormatException);
    }
  });

  test('Valida archivos sintéticos disponibles y detecta la fase intermedia ausente sin perder textos', () async {
    final resource = plannedIllustrationFixture('squat');
    final catalog = catalogWithPlannedResource('squat', resource);
    final paths = catalog
        .requireById('squat')
        .resources
        .single
        .localAssetPaths
        .toList();
    final png = syntheticPng();
    final bundle = MediaFixtureBundle({for (final path in paths) path: png});
    final loader = AssetExerciseMediaLoader(bundle: bundle);
    expect(await loader.validateCatalog(catalog), isEmpty);
    bundle.files.remove(paths[1]);
    final issues = await loader.validateCatalog(catalog);
    expect(issues, hasLength(1));
    expect(issues.single.path, paths[1]);
    expect(catalog.requireById('squat').technique!.steps, isNotEmpty);
  });

  test('Los planes pendientes no provocan intentos de cargar sus archivos inexistentes', () async {
    final bundle = MediaFixtureBundle({});
    expect(
      await AssetExerciseMediaLoader(bundle: bundle)
          .validateCatalog(testExerciseCatalog),
      isEmpty,
    );
    expect(bundle.reads, isEmpty);
  });
}
