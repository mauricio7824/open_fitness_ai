import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/exercise.dart';

class ExerciseMediaException implements Exception {
  const ExerciseMediaException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ExerciseMediaIssue {
  const ExerciseMediaIssue(this.resourceId, this.path, this.message);
  final String resourceId;
  final String path;
  final String message;
  @override
  String toString() => '$resourceId · $path: $message';
}

/// Images only. A future video player can use the typed video metadata without
/// changing the image loader or adding a player to application initialization.
abstract interface class ExerciseMediaLoader {
  Future<Uint8List> loadImage(ExerciseMediaLocation location);
}

class AssetExerciseMediaLoader implements ExerciseMediaLoader {
  AssetExerciseMediaLoader({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<Set<String>>? _manifest;
  static const maxImageBytes = 8 * 1024 * 1024;
  static const maxVideoBytes = 30 * 1024 * 1024;
  static const maxImagePixels = 16 * 1024 * 1024;

  Future<Uint8List> _read(String path, int maxBytes) async {
    final assets = await (_manifest ??= AssetManifest.loadFromAssetBundle(
      _bundle,
    ).then((manifest) => manifest.listAssets().toSet()));
    if (!assets.contains(path)) {
      throw const ExerciseMediaException(
        'El archivo no está declarado en el bundle.',
      );
    }
    final data = await _bundle.load(path);
    if (data.lengthInBytes == 0 || data.lengthInBytes > maxBytes) {
      throw const ExerciseMediaException('Archivo vacío o demasiado grande.');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Future<Uint8List> loadImage(ExerciseMediaLocation location) async {
    final path = location.assetPath;
    if (path == null) {
      throw const ExerciseMediaException(
        'Los recursos externos no se descargan automáticamente.',
      );
    }
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      final bytes = await _read(path, maxImageBytes);
      final extension = path.split('.').last;
      final validHeader = switch (extension) {
        'png' => _starts(bytes, [137, 80, 78, 71, 13, 10, 26, 10]),
        'jpg' || 'jpeg' => _starts(bytes, [255, 216, 255]),
        'webp' =>
          _starts(bytes, [82, 73, 70, 70]) &&
              _starts(bytes, [87, 69, 66, 80], offset: 8),
        _ => false,
      };
      if (!validHeader) {
        throw const ExerciseMediaException(
          'La imagen no coincide con su formato declarado.',
        );
      }
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > 8192 ||
          descriptor.height > 8192 ||
          descriptor.width * descriptor.height > maxImagePixels) {
        throw const ExerciseMediaException(
          'Las dimensiones de la imagen superan el límite.',
        );
      }
      codec = await descriptor.instantiateCodec(
        targetWidth: descriptor.width > 1280 ? 1280 : descriptor.width,
      );
      if (codec.frameCount != 1) {
        throw const ExerciseMediaException(
          'Usa imágenes estáticas y fases manuales, sin animación automática.',
        );
      }
      image = (await codec.getNextFrame()).image;
      return bytes;
    } on ExerciseMediaException {
      rethrow;
    } catch (_) {
      _manifest = null; // A transient bundle failure can be retried.
      throw const ExerciseMediaException(
        'No se pudo leer o decodificar la imagen local.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// Contributor/build check. Media failures never block the exercise repository.
  /// Remote locations are metadata-only and are not requested or downloaded.
  Future<List<ExerciseMediaIssue>> validateCatalog(
    ExerciseCatalog catalog,
  ) async {
    final issues = <ExerciseMediaIssue>[];
    for (final resource in catalog.exercises.expand(
      (exercise) => exercise.resources,
    )) {
      for (final path in resource.localAssetPaths) {
        try {
          if (path.endsWith('.vtt')) {
            final text = utf8.decode(await _read(path, 256 * 1024));
            if (!text.replaceFirst('\uFEFF', '').startsWith('WEBVTT\n') &&
                !text.replaceFirst('\uFEFF', '').startsWith('WEBVTT\r\n')) {
              throw const ExerciseMediaException(
                'Subtítulos WebVTT inválidos.',
              );
            }
          } else if (resource.kind == ExerciseResourceKind.video) {
            final bytes = await _read(path, maxVideoBytes);
            final valid = path.endsWith('.mp4')
                ? _starts(bytes, [102, 116, 121, 112], offset: 4)
                : _starts(bytes, [26, 69, 223, 163]);
            if (!valid) {
              throw const ExerciseMediaException(
                'Contenedor de video no reconocido.',
              );
            }
          } else {
            final location = resource.kind == ExerciseResourceKind.imageSequence
                ? resource.frames
                      .firstWhere((frame) => frame.location.assetPath == path)
                      .location
                : resource.location!;
            await loadImage(location);
          }
        } catch (error) {
          issues.add(ExerciseMediaIssue(resource.id, path, error.toString()));
        }
      }
    }
    return List.unmodifiable(issues);
  }
}

bool _starts(Uint8List bytes, List<int> prefix, {int offset = 0}) =>
    bytes.length >= offset + prefix.length &&
    Iterable<int>.generate(prefix.length)
        .every((index) => bytes[offset + index] == prefix[index]);
