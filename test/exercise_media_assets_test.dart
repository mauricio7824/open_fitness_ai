import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/exercise_media_repository.dart';
import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';

import 'support/exercise_media_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Todos los recursos del catálogo distribuido están empaquetados y son legibles', () async {
    final catalog = await AssetExerciseRepository().load();
    expect(catalog.exercises, hasLength(18));
    final issues = await AssetExerciseMediaLoader().validateCatalog(catalog);
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test(
    'Carga y decodifica una ilustración local y las dos fases sin red',
    () async {
      final png = syntheticPng();
      final bundle = MediaFixtureBundle({
        fixtureImagePath: png,
        fixtureEndPath: png,
      });
      final loader = AssetExerciseMediaLoader(bundle: bundle);
      final resource = ExerciseResource.fromJson(mediaFixture());
      expect(await loader.loadImage(resource.location!), png);
      expect(
        await loader.validateCatalog(fixtureCatalog([sequenceFixture()])),
        isEmpty,
      );
      expect(
        bundle.reads.where((path) => path == 'AssetManifest.bin'),
        hasLength(1),
      );
    },
  );

  test(
    'La presencia en el disco simulado no sustituye la declaración del asset',
    () async {
      final bundle = MediaFixtureBundle({
        fixtureImagePath: syntheticPng(),
      }, declared: {});
      final issues = await AssetExerciseMediaLoader(bundle: bundle)
          .validateCatalog(fixtureCatalog([mediaFixture()]));
      expect(issues, hasLength(1));
      expect(issues.single.message, contains('bundle'));
      expect(bundle.reads, ['AssetManifest.bin']);
    },
  );

  test(
    'Reporta archivo ausente, vacío o corrupto sin invalidar las instrucciones',
    () async {
      for (final files in <Map<String, Uint8List>>[
        {},
        {fixtureImagePath: Uint8List(0)},
        {
          fixtureImagePath: Uint8List.fromList([1, 2, 3]),
        },
        {
          fixtureImagePath: Uint8List.fromList([
            137,
            80,
            78,
            71,
            13,
            10,
            26,
            10,
            0,
          ]),
        },
      ]) {
        final catalog = fixtureCatalog([mediaFixture()]);
        final bundle = MediaFixtureBundle(files, declared: {fixtureImagePath});
        final issues = await AssetExerciseMediaLoader(bundle: bundle)
            .validateCatalog(catalog);
        expect(issues, hasLength(1));
        expect(catalog.exercises.first.instructions, isNotEmpty);
        expect(catalog.exercises.first.technique!.steps, isNotEmpty);
        expect(issues.single.resourceId, 'fixture-image');
      }
    },
  );

  test('Rechaza imagen que supera el límite de bytes', () async {
    final bundle = MediaFixtureBundle({
      fixtureImagePath: Uint8List(AssetExerciseMediaLoader.maxImageBytes + 1),
    });
    expect(
      await AssetExerciseMediaLoader(bundle: bundle)
          .validateCatalog(fixtureCatalog([mediaFixture()])),
      hasLength(1),
    );
  });

  test('Puede reintentar tras un fallo transitorio del bundle', () async {
    final bundle = MediaFixtureBundle({fixtureImagePath: syntheticPng()})
      ..failReads = true;
    final loader = AssetExerciseMediaLoader(bundle: bundle);
    final location = ExerciseResource.fromJson(mediaFixture()).location!;
    await expectLater(
      loader.loadImage(location),
      throwsA(isA<ExerciseMediaException>()),
    );
    bundle.failReads = false;
    expect(await loader.loadImage(location), isNotEmpty);
  });

  test('Las URL externas no hacen lecturas ni peticiones de red', () async {
    final json = mediaFixture()
      ..remove('assetPath')
      ..['url'] = 'https://example.invalid/image.png';
    final bundle = MediaFixtureBundle({});
    final loader = AssetExerciseMediaLoader(bundle: bundle);
    final catalog = fixtureCatalog([json]);
    expect(await loader.validateCatalog(catalog), isEmpty);
    await expectLater(
      loader.loadImage(catalog.exercises.first.resources.first.location!),
      throwsA(isA<ExerciseMediaException>()),
    );
    expect(bundle.reads, isEmpty);
  });

  test(
    'Valida contenedor de video y archivo de subtítulos sin reproductor',
    () async {
      final json = videoFixture()
        ..['captionsAssetPath'] = 'assets/exercise_media/test/captions.vtt';
      final bundle = MediaFixtureBundle({
        'assets/exercise_media/test/clip.mp4': Uint8List.fromList([
          0,
          0,
          0,
          12,
          102,
          116,
          121,
          112,
          105,
          115,
          111,
          109,
        ]),
        'assets/exercise_media/test/captions.vtt': Uint8List.fromList(
          'WEBVTT\n\n00:00.000 --> 00:01.000\nFixture\n'.codeUnits,
        ),
      });
      final loader = AssetExerciseMediaLoader(bundle: bundle);
      expect(await loader.validateCatalog(fixtureCatalog([json])), isEmpty);
      bundle.files['assets/exercise_media/test/clip.mp4'] = Uint8List.fromList([
        1,
        2,
        3,
      ]);
      bundle.files['assets/exercise_media/test/captions.vtt'] =
          Uint8List.fromList('Texto sin cabecera'.codeUnits);
      expect(
        await loader.validateCatalog(fixtureCatalog([json])),
        hasLength(2),
      );
    },
  );
}
