import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/app.dart';
import 'package:open_fitness_ai/core/data/exercise_media_repository.dart';
import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/features/exercises/exercise_detail_page.dart';
import 'package:open_fitness_ai/features/exercises/exercise_visual_demo.dart';

import 'navigation_test.dart' show selectTab, tapVisible;
import 'support/exercise_media_fixture.dart';
import 'support/memory_fitness_store.dart';
import 'support/test_exercise_catalog.dart';

class RecordingMediaLoader implements ExerciseMediaLoader {
  final List<String?> reads = [];
  bool fail = false;
  Completer<Uint8List>? pending;
  @override
  Future<Uint8List> loadImage(ExerciseMediaLocation location) async {
    reads.add(location.assetPath);
    if (fail) throw const ExerciseMediaException('Fixture ausente');
    return pending?.future ?? syntheticPng();
  }
}

class FixedMediaCatalog implements ExerciseRepository {
  FixedMediaCatalog(this.catalog);
  final ExerciseCatalog catalog;
  @override
  Future<ExerciseCatalog> load() async => catalog;
}

Future<void> openResource(
  WidgetTester tester,
  ExerciseResource resource,
) async {
  await tapVisible(
    tester,
    find.descendant(
      of: find.byKey(ValueKey('media-${resource.id}')),
      matching: find.text(resource.title),
    ),
  );
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('El estado vacío conserva instrucciones y no promete recursos', (
    tester,
  ) async {
    final catalog = testExerciseCatalog;
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseDetailPage(
          exercise: catalog.exercises.first,
          catalog: catalog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Demostración visual'), findsOneWidget);
    expect(
      find.textContaining('Todavía no hay una demostración visual disponible.'),
      findsOneWidget,
    );
    expect(find.text('Cómo realizarlo'), findsOneWidget);
    expect(find.text('Ejecución paso a paso'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Carga diferida, descripción accesible y atribución completa', (
    tester,
  ) async {
    final loader = RecordingMediaLoader();
    final resource = ExerciseResource.fromJson(mediaFixture());
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExerciseVisualDemo(resources: [resource], loader: loader),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loader.reads, isEmpty);
    await openResource(tester, resource);
    expect(loader.reads, [fixtureImagePath]);
    expect(find.text(resource.altText), findsOneWidget);
    expect(find.bySemanticsLabel(resource.altText), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('No validado técnicamente.'), findsOneWidget);
    expect(find.text(resource.attribution), findsOneWidget);
    expect(find.text('Autoría: ${resource.creator}'), findsOneWidget);
    expect(find.text('Licencia: ${resource.license}'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'Secuencia manual con extremos deshabilitados y sin avance automático',
    (tester) async {
      final resource = ExerciseResource.fromJson(sequenceFixture());
      final loader = RecordingMediaLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseVisualDemo(resources: [resource], loader: loader),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openResource(tester, resource);
      final previous = find.byKey(ValueKey('media-previous-${resource.id}'));
      final next = find.byKey(ValueKey('media-next-${resource.id}'));
      expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
      expect(find.text('Fase 1 de 2: Posición de prueba A'), findsOneWidget);
      await tester.pump(const Duration(seconds: 20));
      expect(loader.reads, [fixtureImagePath]);
      await tapVisible(tester, next);
      expect(find.text('Fase 2 de 2: Posición de prueba B'), findsOneWidget);
      expect(find.text('Segundo patrón de prueba.'), findsOneWidget);
      expect(loader.reads, [fixtureImagePath, fixtureEndPath]);
      expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
      await tapVisible(tester, previous);
      expect(find.text('Fase 1 de 2: Posición de prueba A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Carga pendiente y error permiten reintentar conservando el texto',
    (tester) async {
      final resource = ExerciseResource.fromJson(mediaFixture());
      final loader = RecordingMediaLoader()..pending = Completer<Uint8List>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseVisualDemo(resources: [resource], loader: loader),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openResource(tester, resource);
      expect(find.text('Cargando imagen local…'), findsOneWidget);
      loader.pending!.completeError(const ExerciseMediaException('Ausente'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se pudo mostrar la imagen local.'),
        findsOneWidget,
      );
      expect(find.text(resource.altText), findsOneWidget);
      loader.pending = null;
      await tapVisible(tester, find.text('Reintentar imagen'));
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'URL externa se muestra como referencia y nunca llama al cargador',
    (tester) async {
      final json = mediaFixture()
        ..remove('assetPath')
        ..['url'] = 'https://example.invalid/remote.png';
      final resource = ExerciseResource.fromJson(json);
      final loader = RecordingMediaLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseVisualDemo(resources: [resource], loader: loader),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openResource(tester, resource);
      expect(find.textContaining('Imagen externa:'), findsOneWidget);
      expect(find.text(resource.location!.url.toString()), findsOneWidget);
      expect(loader.reads, isEmpty);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets(
    'Video conserva transcripción y evita controles de reproducción ficticios',
    (tester) async {
      final resource = ExerciseResource.fromJson(videoFixture());
      final loader = RecordingMediaLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseVisualDemo(resources: [resource], loader: loader),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openResource(tester, resource);
      expect(
        find.textContaining(
          'La reproducción de video todavía no está disponible.',
        ),
        findsOneWidget,
      );
      expect(find.text(resource.transcript!), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(loader.reads, isEmpty);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Imagen, secuencia, video y error a 320 px y texto al 200 %: $brightness',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final catalog = fixtureCatalog([
          mediaFixture(),
          sequenceFixture(),
          videoFixture(),
        ]);
        final loader = RecordingMediaLoader()..fail = true;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness, useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ExerciseDetailPage(
              exercise: catalog.exercises.first,
              catalog: catalog,
              mediaLoader: loader,
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final resource in catalog.exercises.first.resources) {
          await openResource(tester, resource);
          if (resource.kind == ExerciseResourceKind.imageSequence) {
            await tapVisible(
              tester,
              find.byKey(ValueKey('media-next-${resource.id}')),
            );
            await tapVisible(
              tester,
              find.byKey(ValueKey('media-previous-${resource.id}')),
            );
          }
          await tester.ensureVisible(find.text(resource.attribution));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await openResource(tester, resource);
        }
        await tester.ensureVisible(find.text('Cómo realizarlo'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Navega biblioteca, ficha y alternativa y conserva búsqueda y datos',
    (tester) async {
      final catalog = fixtureCatalog([sequenceFixture()]);
      final store = MemoryFitnessStore();
      await tester.pumpWidget(
        OpenFitnessApp(
          store: store,
          exerciseRepository: FixedMediaCatalog(catalog),
          equipmentRepository: TestEquipmentRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await selectTab(tester, 'nav-exercises');
      await tester.enterText(find.byType(TextField), 'sentadilla');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('exercise-squat')));
      expect(find.text('Demostración visual'), findsOneWidget);
      expect(find.text('Figura sintética de prueba'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('alternative-goblet-squat')),
      );
      expect(
        find.textContaining(
          'Todavía no hay una demostración visual disponible.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Figura sintética de prueba'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('sentadilla'), findsOneWidget);
      expect(store.recordWrites, 0);
    },
  );
}
