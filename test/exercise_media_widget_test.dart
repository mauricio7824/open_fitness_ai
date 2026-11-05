import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/app.dart';
import 'package:open_fitness_ai/core/data/exercise_media_repository.dart';
import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/data/equipment_repository.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/features/exercises/exercise_detail_page.dart';
import 'package:open_fitness_ai/features/exercises/exercise_visual_demo.dart';

import 'navigation_test.dart' show selectTab, tapVisible;
import 'support/exercise_media_fixture.dart';
import 'support/memory_fitness_store.dart';
import 'support/test_exercise_catalog.dart';

const emptyVisualMessage =
    'Este ejercicio todavía no tiene una demostración visual disponible.';

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
    expect(find.text(emptyVisualMessage), findsOneWidget);
    expect(find.text('Cómo realizarlo'), findsOneWidget);
    expect(find.text('Ejecución paso a paso'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Las 18 fichas sin recursos muestran sección, mensaje y técnica offline en $brightness',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final catalog = testExerciseCatalog;
        expect(catalog.exercises, hasLength(18));
        final loader = RecordingMediaLoader()..fail = true;
        for (final exercise in catalog.exercises) {
          expect(exercise.resources, isEmpty);
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey('${exercise.id}-$brightness'),
              theme: ThemeData(brightness: brightness, useMaterial3: true),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: ExerciseDetailPage(
                exercise: exercise,
                catalog: catalog,
                mediaLoader: loader,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final section = find.byKey(ValueKey('visual-demo-${exercise.id}'));
          expect(section, findsOneWidget);
          final heading = find.descendant(
            of: section,
            matching: find.text('Demostración visual'),
          );
          await tester.ensureVisible(heading);
          await tester.pumpAndSettle();
          expect(heading.hitTestable(), findsOneWidget);
          final message = find.descendant(
            of: section,
            matching: find.text(emptyVisualMessage),
          );
          await tester.ensureVisible(message);
          await tester.pumpAndSettle();
          expect(message.hitTestable(), findsOneWidget);
          final requirements = find.text('Requisitos');
          final preparation = find.text('Posición inicial y preparación');
          expect(
            tester.getTopLeft(requirements).dy,
            lessThan(tester.getTopLeft(heading).dy),
            reason: exercise.id,
          );
          expect(
            tester.getTopLeft(heading).dy,
            lessThan(tester.getTopLeft(preparation).dy),
            reason: exercise.id,
          );
          final instruction = find.text(
            '1. ${exercise.technique!.steps.first}',
          );
          await tester.ensureVisible(instruction);
          await tester.pumpAndSettle();
          expect(instruction.hitTestable(), findsOneWidget);
          await tester.ensureVisible(heading);
          await tester.pumpAndSettle();
          expect(heading.hitTestable(), findsOneWidget);
          expect(find.byType(Image), findsNothing);
          expect(tester.takeException(), isNull, reason: exercise.id);
        }
        expect(loader.reads, isEmpty);
      },
    );
  }

  testWidgets(
    'Sentadilla desde la biblioteca muestra el estado vacío y conserva la navegación',
    (tester) async {
      final store = MemoryFitnessStore();
      await tester.pumpWidget(
        OpenFitnessApp(
          store: store,
          exerciseRepository: TestExerciseRepository(),
          equipmentRepository: TestEquipmentRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await selectTab(tester, 'nav-exercises');
      await tester.enterText(find.byType(TextField), 'sentadilla');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('exercise-squat')));
      expect(find.text('Sentadilla'), findsOneWidget);
      final heading = find.text('Demostración visual');
      await tester.ensureVisible(heading);
      await tester.pumpAndSettle();
      expect(heading.hitTestable(), findsOneWidget);
      final message = find.text(emptyVisualMessage);
      await tester.ensureVisible(message);
      await tester.pumpAndSettle();
      expect(message.hitTestable(), findsOneWidget);
      expect(find.text('Cómo realizarlo'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('sentadilla'), findsOneWidget);
      expect(store.recordWrites, 0);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'App completa con catálogos del bundle: biblioteca, 18 fichas y regreso en $mode',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 640);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final store = MemoryFitnessStore();
        store.data = StoredFitnessData(
          themeMode: mode,
          preferences: store.data.preferences,
        );
        final exercises = AssetExerciseRepository();
        final equipment = AssetEquipmentRepository();
        // Read actual bundled files outside the widget test's fake async clock.
        // The app then uses these production repositories, controller and routes.
        // Only persistence is in memory so this test never alters user data.
        final catalog = (await tester.runAsync(exercises.load))!;
        await tester.runAsync(equipment.load);
        await tester.pumpWidget(
          OpenFitnessApp(
            store: store,
            exerciseRepository: exercises,
            equipmentRepository: equipment,
          ),
        );
        await tester.pumpAndSettle();
        await selectTab(tester, 'nav-exercises');
        expect(catalog.exercises, hasLength(18));
        for (final exercise in catalog.exercises) {
          final search = find.byType(TextField);
          await tester.ensureVisible(search);
          await tester.pumpAndSettle();
          await tester.enterText(search, exercise.name);
          await tester.pumpAndSettle();
          await tapVisible(
            tester,
            find.byKey(ValueKey('exercise-${exercise.id}')),
          );
          expect(find.byType(ExerciseDetailPage), findsOneWidget);
          expect(
            Theme.of(tester.element(find.byType(ExerciseDetailPage)))
                .brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          );
          final heading = find.text('Demostración visual');
          final message = find.text(emptyVisualMessage);
          final preparation = find.text('Posición inicial y preparación');
          await tester.ensureVisible(message);
          await tester.pumpAndSettle();
          expect(message.hitTestable(), findsOneWidget, reason: exercise.id);
          expect(
            tester.getTopLeft(find.text('Requisitos')).dy,
            lessThan(tester.getTopLeft(heading).dy),
            reason: exercise.id,
          );
          expect(
            tester.getTopLeft(heading).dy,
            lessThan(tester.getTopLeft(preparation).dy),
            reason: exercise.id,
          );
          final credits = find.text('Recursos y licencias');
          await tester.ensureVisible(credits);
          await tester.pumpAndSettle();
          expect(credits.hitTestable(), findsOneWidget);
          expect(
            find.text('No hay imágenes ni videos asociados a este ejercicio.'),
            findsOneWidget,
          );
          await tester.ensureVisible(heading);
          await tester.pumpAndSettle();
          expect(heading.hitTestable(), findsOneWidget, reason: exercise.id);
          expect(find.byType(Image), findsNothing);
          expect(tester.takeException(), isNull, reason: exercise.id);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(find.byType(ExerciseDetailPage), findsNothing);
          expect(find.widgetWithText(TextField, exercise.name), findsOneWidget);
        }
        expect(store.recordWrites, 0);
      },
    );
  }

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
    'La ficha sitúa la demostración después de requisitos y antes de preparación',
    (tester) async {
      final catalog = testExerciseCatalog;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailPage(
            exercise: catalog.requireById('squat'),
            catalog: catalog,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = find.text('Demostración visual');
      final requirements = find.text('Requisitos');
      final technique = find.text('Posición inicial y preparación');
      expect(
        tester.getTopLeft(requirements).dy,
        lessThan(tester.getTopLeft(heading).dy),
      );
      expect(
        tester.getTopLeft(heading).dy,
        lessThan(tester.getTopLeft(technique).dy),
      );
      await tester.ensureVisible(heading);
      await tester.pumpAndSettle();
      expect(heading.hitTestable(), findsOneWidget);
      expect(find.text('Ilustraciones pendientes'), findsOneWidget);
      expect(
        find.textContaining(
          'Los archivos originales todavía no están disponibles',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(Image), findsNothing);
    },
  );

  for (final id in ['squat', 'pushup', 'biceps-curl']) {
    testWidgets(
      'Navega las tres fases de $id con descripción y revisión pendiente',
      (tester) async {
        final catalog = catalogWithPlannedResource(
          id,
          plannedIllustrationFixture(id),
        );
        final exercise = catalog.requireById(id);
        final resource = exercise.resources.single;
        final loader = RecordingMediaLoader();
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseDetailPage(
              exercise: exercise,
              catalog: catalog,
              mediaLoader: loader,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(loader.reads, isEmpty);
        expect(find.text('Ilustraciones pendientes'), findsNothing);
        await openResource(tester, resource);
        for (var i = 0; i < 3; i++) {
          expect(
            find.text('Fase ${i + 1} de 3: ${resource.frames[i].title}'),
            findsOneWidget,
          );
          expect(find.text(resource.frames[i].altText), findsOneWidget);
          if (i < 2) {
            await tapVisible(
              tester,
              find.byKey(ValueKey('media-next-${resource.id}')),
            );
          }
        }
        expect(loader.reads, resource.localAssetPaths.toList());
        expect(
          find.text('Revisión técnica pendiente. No validado técnicamente.'),
          findsOneWidget,
        );
        final next = find.byKey(ValueKey('media-next-${resource.id}'));
        expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
        await tapVisible(
          tester,
          find.byKey(ValueKey('media-previous-${resource.id}')),
        );
        expect(find.text('Fase 2 de 3: Fase intermedia'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Una fase ausente mantiene descripción, navegación y pasos escritos',
    (tester) async {
      final catalog = catalogWithPlannedResource(
        'squat',
        plannedIllustrationFixture('squat'),
      );
      final exercise = catalog.requireById('squat');
      final resource = exercise.resources.single;
      final loader = RecordingMediaLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailPage(
            exercise: exercise,
            catalog: catalog,
            mediaLoader: loader,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openResource(tester, resource);
      loader.fail = true;
      await tapVisible(
        tester,
        find.byKey(ValueKey('media-next-${resource.id}')),
      );
      expect(
        find.textContaining('No se pudo mostrar la imagen local.'),
        findsOneWidget,
      );
      expect(find.text(resource.frames[1].altText), findsOneWidget);
      loader.fail = false;
      await tapVisible(
        tester,
        find.byKey(ValueKey('media-next-${resource.id}')),
      );
      expect(find.text('Fase 3 de 3: Posición final'), findsOneWidget);
      expect(
        find.textContaining('No se pudo mostrar la imagen local.'),
        findsNothing,
      );
      final step = find.text('1. ${exercise.technique!.steps.first}');
      await tester.ensureVisible(step);
      await tester.pumpAndSettle();
      expect(step.hitTestable(), findsOneWidget);
    },
  );

  testWidgets('La interfaz distingue aprobación editorial y revisión técnica', (
    tester,
  ) async {
    final json = mediaFixture();
    json['editorial']
      ..['status'] = 'reviewed'
      ..['reviewer'] = 'Revisor ficticio editorial'
      ..['reviewedOn'] = '2026-11-04';
    final resource = ExerciseResource.fromJson(json);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExerciseVisualDemo(
              resources: [resource],
              loader: RecordingMediaLoader(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openResource(tester, resource);
    expect(find.text('Recurso revisado editorialmente.'), findsOneWidget);
    expect(
      find.text('Revisión técnica pendiente. No validado técnicamente.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Revisión técnica registrada. Este recurso no evalúa tu técnica personal.',
      ),
      findsNothing,
    );
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
      expect(find.text(emptyVisualMessage), findsOneWidget);
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
