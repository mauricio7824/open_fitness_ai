import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:open_fitness_ai/core/data/exercise_repository.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';

const fixtureImagePath = 'assets/exercise_media/test/start.png';
const fixtureEndPath = 'assets/exercise_media/test/end.png';

Map<String, dynamic> technicalReviewFixture() => {
  'status': 'pending',
  'updatedOn': '2026-11-04',
  'reviewer': null,
  'reviewedOn': null,
  'notes':
      'Registro técnico ficticio del test; no es una revisión profesional.',
};

Map<String, dynamic> plannedIllustrationFixture(String exerciseId) {
  final json = catalogWithMedia([]);
  final exercise = (json['exercises'] as List).firstWhere(
    (e) => e['id'] == exerciseId,
  );
  final plan = exercise['illustrationPlan'];
  return mediaFixture(id: plan['resourceId'], kind: 'imageSequence')
    ..remove('assetPath')
    ..['technicalReview'] = technicalReviewFixture()
    ..['frames'] = [
      for (final phase in plan['phases'])
        {
          'id': phase['id'],
          'title': phase['title'],
          'altText':
              'Patrón sintético de prueba para ${phase['title']}; no representa un ejercicio.',
          'assetPath': phase['expectedAssetPath'],
        },
    ];
}

ExerciseCatalog catalogWithPlannedResource(
  String exerciseId,
  Map<String, dynamic> resource,
) {
  final json = catalogWithMedia([]);
  (json['exercises'] as List).firstWhere(
    (e) => e['id'] == exerciseId,
  )['resources'] = [
    resource,
  ];
  return ExerciseCatalog.fromJson(json);
}

/// Deliberately fictitious metadata; never added to the application catalog.
Map<String, dynamic> mediaFixture({
  String id = 'fixture-image',
  String kind = 'illustration',
}) => {
  'id': id,
  'title': 'Figura sintética de prueba',
  'kind': kind,
  'assetPath': fixtureImagePath,
  'creator': 'Autor ficticio del fixture; no es una atribución real',
  'sourceUrl': 'https://example.invalid/fixture',
  'license': 'LicenseRef-Permission',
  'licenseUrl': 'https://example.invalid/fixture-permission',
  'permissionNote': 'Metadatos ficticios para pruebas, sin autorización real ni uso en el catálogo distribuido.',
  'attribution':
      'Fixture sintético. No representa un ejercicio ni una revisión real.',
  'altText': 'Cuadrado sintético de dos colores para comprobar la carga local.',
  'editorial': {
    'status': 'pending',
    'updatedOn': '2026-11-04',
    'reviewer': null,
    'reviewedOn': null,
    'notes': 'Fixture pendiente; no demuestra técnica de ejercicio.',
  },
};

Map<String, dynamic> sequenceFixture() =>
    mediaFixture(id: 'fixture-sequence', kind: 'imageSequence')
      ..remove('assetPath')
      ..['frames'] = [
        {
          'id': 'start',
          'title': 'Posición de prueba A',
          'altText': 'Primer patrón de prueba.',
          'assetPath': fixtureImagePath,
        },
        {
          'id': 'end',
          'title': 'Posición de prueba B',
          'altText': 'Segundo patrón de prueba.',
          'assetPath': fixtureEndPath,
        },
      ];

Map<String, dynamic> videoFixture() =>
    mediaFixture(id: 'fixture-video', kind: 'video')
      ..['assetPath'] = 'assets/exercise_media/test/clip.mp4'
      ..['durationSeconds'] = 12
      ..['transcript'] =
          'Transcripción sintética de prueba. No representa una ejecución.';

Map<String, dynamic> catalogWithMedia(List<Map<String, dynamic>> resources) {
  final json = jsonDecode(
    File(AssetExerciseRepository.assetPath).readAsStringSync(),
  ) as Map<String, dynamic>;
  json['exercises'][0]['resources'] = resources;
  return json;
}

ExerciseCatalog fixtureCatalog(List<Map<String, dynamic>> resources) =>
    ExerciseCatalog.fromJson(catalogWithMedia(resources));

class MediaFixtureBundle extends CachingAssetBundle {
  MediaFixtureBundle(this.files, {Set<String>? declared})
    : declared = declared ?? files.keys.toSet();
  final Map<String, Uint8List> files;
  final Set<String> declared;
  final List<String> reads = [];
  bool failReads = false;

  @override
  Future<ByteData> load(String key) async {
    reads.add(key);
    if (failReads) throw StateError('Fallo transitorio del bundle');
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final path in declared)
          path: [
            {'asset': path},
          ],
      })!;
    }
    final data = files[key];
    if (data == null) throw StateError('Archivo de prueba ausente');
    return ByteData.sublistView(data);
  }
}

/// Generates an original 8x8 static PNG in memory with standard PNG chunks.
/// It has no exercise content and is not included in the app bundle.
Uint8List syntheticPng() {
  final result = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String name, List<int> content) {
    final typeAndData = [...ascii.encode(name), ...content];
    var crc = 0xffffffff;
    for (final byte in typeAndData) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    final length = ByteData(4)..setUint32(0, content.length);
    final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff);
    result
      ..add(length.buffer.asUint8List())
      ..add(typeAndData)
      ..add(checksum.buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, 8)
    ..setUint32(4, 8)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  chunk('IHDR', header.buffer.asUint8List());
  chunk(
    'IDAT',
    ZLibEncoder().convert([
      for (var row = 0; row < 8; row++) ...[
        0,
        for (var col = 0; col < 8; col++) ...[
          row < 4 ? 220 : 30,
          col < 4 ? 80 : 180,
          100,
        ],
      ],
    ]),
  );
  chunk('IEND', []);
  return result.takeBytes();
}
