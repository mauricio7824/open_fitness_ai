import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';

import 'support/exercise_media_fixture.dart';

void main() {
  test('Decodifica imágenes, ilustraciones, secuencias y video con revisión independiente', () {
    final catalog = fixtureCatalog([
      mediaFixture(id: 'photo', kind: 'image'),
      mediaFixture(),
      sequenceFixture(),
      videoFixture(),
    ]);
    final resources = catalog.exercises.first.resources;
    expect(resources.map((r) => r.kind), ExerciseResourceKind.values);
    expect(resources.first.location!.isLocal, isTrue);
    expect(resources[2].frames.map((f) => f.id), ['start', 'end']);
    expect(resources.last.durationSeconds, 12);
    expect(resources.last.transcript, isNotEmpty);
    expect(resources.first.editorial.status, EditorialStatus.pending);
    expect(resources.first.attribution, isNotEmpty);
    expect(resources.first.altText, isNotEmpty);
    expect(resources[2].localAssetPaths, [fixtureImagePath, fixtureEndPath]);
    expect(() => resources[2].frames.clear(), throwsUnsupportedError);
    expect(() => resources.clear(), throwsUnsupportedError);
  });

  test('Admite URL HTTPS explícita sin exigir un archivo local', () {
    final json = mediaFixture()
      ..remove('assetPath')
      ..['url'] = 'https://example.invalid/image.png';
    final resource = ExerciseResource.fromJson(json);
    expect(resource.location!.isLocal, isFalse);
    expect(resource.localAssetPaths, isEmpty);
  });

  for (final entry in {
    'CC0-1.0': 'https://creativecommons.org/publicdomain/zero/1.0/',
    'CC-BY-4.0': 'https://creativecommons.org/licenses/by/4.0/',
    'CC-BY-SA-4.0': 'https://creativecommons.org/licenses/by-sa/4.0/',
  }.entries) {
    test('Admite declaración ${entry.key} con enlace canónico', () {
      final json = mediaFixture()
        ..['license'] = entry.key
        ..['licenseUrl'] = entry.value;
      expect(ExerciseResource.fromJson(json).license, entry.key);
    });
  }

  for (final field in [
    'id',
    'title',
    'creator',
    'sourceUrl',
    'license',
    'licenseUrl',
    'permissionNote',
    'attribution',
    'altText',
    'editorial',
  ]) {
    test('Rechaza recurso sin $field', () {
      expect(
        () => ExerciseResource.fromJson(mediaFixture()..remove(field)),
        throwsFormatException,
      );
    });
  }

  final invalidCases = <String, void Function(Map<String, dynamic>)>{
    'ID no estable': (j) => j['id'] = '../photo',
    'tipo desconocido': (j) => j['kind'] = 'gif',
    'autor vacío': (j) => j['creator'] = ' ',
    'atribución vacía': (j) => j['attribution'] = ' ',
    'texto alternativo vacío': (j) => j['altText'] = ' ',
    'licencia desconocida': (j) => j['license'] = 'licencia-libre',
    'licencia CC con enlace ajeno': (j) => j['license'] = 'CC-BY-4.0',
    'fuente HTTP': (j) => j['sourceUrl'] = 'http://example.invalid/source',
    'URL con credenciales': (j) =>
        j['sourceUrl'] = 'https://user:pass@example.invalid',
    'licencia sin HTTPS': (j) => j['licenseUrl'] = 'file:///license',
    'dos ubicaciones': (j) => j['url'] = 'https://example.invalid/image.png',
    'sin ubicación': (j) => j.remove('assetPath'),
    'ruta absoluta': (j) => j['assetPath'] = 'C:/image.png',
    'ruta fuera del directorio': (j) =>
        j['assetPath'] = 'assets/catalog/image.png',
    'traversal': (j) => j['assetPath'] = 'assets/exercise_media/../image.png',
    'traversal codificado': (j) =>
        j['assetPath'] = 'assets/exercise_media/%2e%2e/image.png',
    'barras invertidas': (j) =>
        j['assetPath'] = r'assets\exercise_media\image.png',
    'parámetros en archivo': (j) =>
        j['assetPath'] = 'assets/exercise_media/image.png?x=1',
    'animación GIF': (j) => j['assetPath'] = 'assets/exercise_media/image.gif',
    'SVG sin adaptador': (j) =>
        j['assetPath'] = 'assets/exercise_media/image.svg',
    'video declarado como imagen': (j) =>
        j['assetPath'] = 'assets/exercise_media/image.mp4',
    'fases en imagen': (j) => j['frames'] = [],
    'campos de video en imagen': (j) => j['transcript'] = 'Texto',
    'revisión pendiente firmada': (j) => j['editorial']['reviewer'] = 'Fixture',
    'revisión sin firma': (j) => j['editorial']['status'] = 'reviewed',
    'revisión con fecha anterior': (j) {
      j['editorial']
        ..['status'] = 'reviewed'
        ..['reviewer'] = 'Revisor ficticio'
        ..['reviewedOn'] = '2026-11-03';
    },
  };
  for (final entry in invalidCases.entries) {
    test('Rechaza ${entry.key}', () {
      final json = mediaFixture();
      entry.value(json);
      expect(() => ExerciseResource.fromJson(json), throwsFormatException);
    });
  }

  test('Las secuencias necesitan fases completas, únicas y de 2 a 12', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (j) => j['frames'] = [],
      (j) => j['frames'] = [j['frames'][0]],
      (j) => j['frames'] = List.filled(13, j['frames'][0]),
      (j) => j['frames'][1]['id'] = 'start',
      (j) => j['frames'][0].remove('altText'),
      (j) => j['frames'][0]['title'] = ' ',
      (j) => j['frames'][0]['assetPath'] = '../test.png',
      (j) => j['assetPath'] = fixtureImagePath,
    ]) {
      final json = sequenceFixture();
      change(json);
      expect(() => ExerciseResource.fromJson(json), throwsFormatException);
    }
  });

  test(
    'Video exige duración corta, transcripción y subtítulos VTT si se declaran',
    () {
      for (final change in <void Function(Map<String, dynamic>)>[
        (j) => j.remove('durationSeconds'),
        (j) => j['durationSeconds'] = 0,
        (j) => j['durationSeconds'] = 181,
        (j) => j['durationSeconds'] = 12.5,
        (j) => j.remove('transcript'),
        (j) => j['transcript'] = ' ',
        (j) => j['captionsAssetPath'] = 'assets/exercise_media/subtitles.txt',
        (j) => j['assetPath'] = fixtureImagePath,
      ]) {
        final json = videoFixture();
        change(json);
        expect(() => ExerciseResource.fromJson(json), throwsFormatException);
      }
    },
  );

  test('Rechaza IDs de recurso duplicados, también entre ejercicios', () {
    final json = catalogWithMedia([mediaFixture()]);
    json['exercises'][1]['resources'] = [mediaFixture()];
    expect(() => ExerciseCatalog.fromJson(json), throwsFormatException);
    expect(
      () => fixtureCatalog([mediaFixture(), mediaFixture()]),
      throwsFormatException,
    );
  });

  test('Revisión del recurso no cambia la revisión del ejercicio', () {
    final json = mediaFixture();
    json['editorial']
      ..['status'] = 'reviewed'
      ..['reviewer'] = 'Revisor ficticio del test'
      ..['reviewedOn'] = '2026-11-04';
    final exercise = fixtureCatalog([json]).exercises.first;
    expect(exercise.resources.first.editorial.status, EditorialStatus.reviewed);
    expect(exercise.editorial.status, EditorialStatus.pending);
  });
}
