import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/features/exercises/exercise_detail_page.dart';

import 'support/test_exercise_catalog.dart';

Map<String, dynamic> freshCatalog() =>
    jsonDecode(File(AssetExerciseRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final catalog = testExerciseCatalog;
  final techniqueFields = [
    'preparation',
    'steps',
    'breathing',
    'control',
    'commonErrors',
    'tips',
    'regressions',
    'progressions',
    'precautions',
    'stopSignals',
  ];

  test('Las 18 fichas incluyen enseñanza, fuentes y revisión pendiente', () {
    expect(catalog.exercises, hasLength(18));
    expect(catalog.teachingGuidance, isNotNull);
    for (final exercise in catalog.exercises) {
      final technique = exercise.technique!;
      expect(technique.preparation.length, greaterThanOrEqualTo(2));
      expect(technique.steps.length, greaterThanOrEqualTo(4));
      expect(technique.commonErrors.length, greaterThanOrEqualTo(2));
      expect(technique.regressions, isNotEmpty);
      expect(technique.progressions, isNotEmpty);
      expect(exercise.sources, isNotEmpty);
      expect(exercise.editorial.status, EditorialStatus.pending);
      expect(exercise.editorial.updatedOn, DateTime(2026, 11, 4));
      expect(exercise.editorial.reviewer, isNull);
      expect(exercise.editorial.reviewedOn, isNull);
      expect(exercise.resources, isEmpty);
    }
  });

  test('Todas las colecciones de enseñanza son inmutables', () {
    final technique = catalog.exercises.first.technique!;
    for (final collection in <List<dynamic>>[
      technique.preparation,
      technique.steps,
      technique.breathing,
      technique.control,
      technique.commonErrors,
      technique.tips,
      technique.regressions,
      technique.progressions,
      technique.precautions,
      technique.stopSignals,
      catalog.teachingGuidance!.sources,
      catalog.teachingGuidance!.precautions,
      catalog.teachingGuidance!.stopSignals,
    ]) {
      expect(collection.clear, throwsUnsupportedError);
    }
  });

  for (final field in techniqueFields) {
    for (final invalid in ['missing', 'empty', 'wrongType']) {
      test('Rechaza técnica con $field $invalid', () {
        final json = freshCatalog();
        final technique = json['exercises'][0]['technique'] as Map;
        switch (invalid) {
          case 'missing':
            technique.remove(field);
          case 'empty':
            technique[field] = [];
          case 'wrongType':
            technique[field] = 'texto';
        }
        expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
      });
    }
  }

  test('Rechaza pasos insuficientes y errores o variantes sin explicación', () {
    for (final mutate in <void Function(Map)>[
      (t) => t['steps'] = ['Uno', 'Dos'],
      (t) => t['preparation'] = [' '],
      (t) => t['commonErrors'][0]['recognition'] = '',
      (t) => t['commonErrors'][0].remove('correction'),
      (t) => t['regressions'][0]['description'] = '',
      (t) => t['progressions'][0].remove('title'),
    ]) {
      final json = freshCatalog();
      mutate(json['exercises'][0]['technique'] as Map);
      expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
    }
  });

  test('Rechaza orientaciones generales incompletas o fuentes sin alcance', () {
    for (final field in ['scope', 'precautions', 'stopSignals', 'sources']) {
      final json = freshCatalog();
      (json['teachingGuidance'] as Map).remove(field);
      expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
    }
    final json = freshCatalog();
    json['exercises'][0]['sources'][0]['scope'] = ' ';
    expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
  });

  test('Sigue leyendo el formato anterior sin técnica ni guía general', () {
    final json = freshCatalog()..remove('teachingGuidance');
    json['catalogVersion'] = 1;
    for (final exercise in json['exercises'] as List) {
      (exercise as Map).remove('technique');
      for (final source in exercise['sources'] as List) {
        (source as Map).remove('scope');
      }
    }
    final legacy = ExerciseCatalog.fromJson(json);
    expect(legacy.exercises, hasLength(18));
    expect(legacy.exercises.first.technique, isNull);
    expect(legacy.exercises.first.instructions, hasLength(3));
    expect(legacy.teachingGuidance, isNull);
  });

  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final brightness in Brightness.values) {
    testWidgets(
      'Las 18 técnicas se leen a 320 px y texto al 200 %: $brightness',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final exercise in catalog.exercises) {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey('${exercise.id}-$brightness'),
              theme: ThemeData(brightness: brightness, useMaterial3: true),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: ExerciseDetailPage(exercise: exercise, catalog: catalog),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Posición inicial y preparación'), findsOneWidget);
          expect(find.text('Ejecución paso a paso'), findsOneWidget);
          expect(
            find.text('Señales para detener la actividad'),
            findsOneWidget,
          );
          for (final id in [
            'breathing',
            'control',
            'errors',
            'tips',
            'regressions',
            'progressions',
            'precautions',
          ]) {
            final tile = find.byKey(PageStorageKey('technique-$id'));
            final title = find
                .descendant(of: tile, matching: find.byType(Text))
                .first;
            await tester.ensureVisible(title);
            await tester.pumpAndSettle();
            await tester.tap(title);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${exercise.id}: $id',
            );
            await tester.ensureVisible(title);
            await tester.pumpAndSettle();
            await tester.tap(title);
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(find.text('Recursos y licencias'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: exercise.id);
          expect(find.text('Pendiente de revisión editorial'), findsOneWidget);
        }
      },
    );
  }

  testWidgets('Muestra errores, variantes y fuentes sin cambiar la rutina', (
    tester,
  ) async {
    final exercise = catalog.requireById('pushup');
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseDetailPage(exercise: exercise, catalog: catalog),
      ),
    );
    await tester.pumpAndSettle();
    final errorsTitle = find.text('Errores frecuentes y cómo reconocerlos');
    await tester.ensureVisible(errorsTitle);
    await tester.pumpAndSettle();
    await tester.tap(errorsTitle);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Cómo reconocerlo: ${exercise.technique!.commonErrors.first.recognition}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Qué ajustar: ${exercise.technique!.commonErrors.first.correction}',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Progresiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progresiones'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'No es una progresión obligatoria ni modifica tu rutina.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('alternative-knee-pushup')),
      findsOneWidget,
    );
    expect(
      find.text(catalog.teachingGuidance!.sources.first.scope!),
      findsOneWidget,
    );
  });
}
