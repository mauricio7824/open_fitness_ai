part of 'exercise.dart';

enum ExerciseResourceKind {
  image('Imagen'),
  illustration('Ilustración'),
  imageSequence('Secuencia de imágenes'),
  video('Video corto');

  const ExerciseResourceKind(this.label);
  final String label;
}

enum TechnicalReviewStatus { pending, reviewed }

class TechnicalReview {
  TechnicalReview._(
    this.status,
    this.updatedOn,
    this.reviewer,
    this.reviewedOn,
    this.notes,
  );
  final TechnicalReviewStatus status;
  final DateTime updatedOn;
  final String? reviewer;
  final DateTime? reviewedOn;
  final String notes;

  factory TechnicalReview.fromJson(Map<String, dynamic> json) {
    // Date/signature integrity follows the same rules as editorial review;
    // the records and statuses remain independent.
    final review = EditorialReview.fromJson(json);
    return TechnicalReview._(
      review.status == EditorialStatus.reviewed
          ? TechnicalReviewStatus.reviewed
          : TechnicalReviewStatus.pending,
      review.updatedOn,
      review.reviewer,
      review.reviewedOn,
      review.notes,
    );
  }
}

/// Describes a location only. An HTTPS URL never authorizes a download.
class ExerciseMediaLocation {
  ExerciseMediaLocation._(this.assetPath, this.url);
  final String? assetPath;
  final Uri? url;
  bool get isLocal => assetPath != null;

  factory ExerciseMediaLocation.fromJson(
    Map<String, dynamic> json, {
    bool video = false,
  }) {
    if (json.containsKey('assetPath') == json.containsKey('url')) {
      throw const FormatException(
        'Declara una ruta local o una URL, no ambas.',
      );
    }
    if (json.containsKey('url')) {
      return ExerciseMediaLocation._(null, _url(json, 'url'));
    }
    final path = _mediaPath(_text(json, 'assetPath'));
    final extension = path.split('.').last;
    if (!(video ? ['mp4', 'webm'] : ['png', 'jpg', 'jpeg', 'webp']).contains(
      extension,
    )) {
      throw const FormatException('Formato de recurso no compatible.');
    }
    return ExerciseMediaLocation._(path, null);
  }
}

class ExerciseMediaFrame {
  ExerciseMediaFrame._(this.id, this.title, this.altText, this.location);
  final String id;
  final String title;
  final String altText;
  final ExerciseMediaLocation location;

  factory ExerciseMediaFrame.fromJson(Map<String, dynamic> json) =>
      ExerciseMediaFrame._(
        _mediaId(json),
        _text(json, 'title'),
        _text(json, 'altText'),
        ExerciseMediaLocation.fromJson(json),
      );
}

/// The media review is independent of the exercise text review.
/// Metadata validation does not certify ownership, licensing, or technique.
class ExerciseResource {
  ExerciseResource._({
    required this.id,
    required this.title,
    required this.kind,
    required this.location,
    required this.frames,
    required this.creator,
    required this.sourceUrl,
    required this.license,
    required this.licenseUrl,
    required this.permissionNote,
    required this.attribution,
    required this.altText,
    required this.editorial,
    required this.technicalReview,
    required this.durationSeconds,
    required this.transcript,
    required this.captionsAssetPath,
  });

  final String id;
  final String title;
  final ExerciseResourceKind kind;
  final ExerciseMediaLocation? location;
  final List<ExerciseMediaFrame> frames;
  final String creator;
  final Uri sourceUrl;
  final String license;
  final Uri licenseUrl;
  final String permissionNote;
  final String attribution;
  final String altText;
  final EditorialReview editorial;

  /// Missing in older resources means that no technical review is recorded.
  final TechnicalReview? technicalReview;
  final int? durationSeconds;
  final String? transcript;
  final String? captionsAssetPath;

  Iterable<String> get localAssetPaths sync* {
    if (location?.assetPath case final path?) yield path;
    for (final frame in frames) {
      if (frame.location.assetPath case final path?) yield path;
    }
    if (captionsAssetPath case final path?) yield path;
  }

  factory ExerciseResource.fromJson(Map<String, dynamic> json) {
    final kind = _enum(json['kind'], ExerciseResourceKind.values);
    final sequence = kind == ExerciseResourceKind.imageSequence;
    final video = kind == ExerciseResourceKind.video;
    final frames = sequence
        ? _objects(json, 'frames', ExerciseMediaFrame.fromJson)
        : const <ExerciseMediaFrame>[];
    if (sequence &&
        (json.containsKey('assetPath') ||
            json.containsKey('url') ||
            frames.length < 2 ||
            frames.length > 12 ||
            frames.map((frame) => frame.id).toSet().length != frames.length)) {
      throw const FormatException(
        'Una secuencia necesita de 2 a 12 fases únicas.',
      );
    }
    if (!sequence && json.containsKey('frames')) {
      throw const FormatException('Solo las secuencias declaran fases.');
    }
    if (!video &&
        [
          'durationSeconds',
          'transcript',
          'captionsAssetPath',
        ].any(json.containsKey)) {
      throw const FormatException('Los campos de video requieren tipo video.');
    }
    final duration = video ? json['durationSeconds'] : null;
    if (video && (duration is! int || duration < 1 || duration > 180)) {
      throw const FormatException(
        'El video debe durar entre 1 y 180 segundos.',
      );
    }
    final captions = json.containsKey('captionsAssetPath')
        ? _mediaPath(_text(json, 'captionsAssetPath'))
        : null;
    if (captions != null && !captions.endsWith('.vtt')) {
      throw const FormatException('Los subtítulos locales deben ser WebVTT.');
    }
    final license = _text(json, 'license');
    final licenseUrl = _url(json, 'licenseUrl');
    const licenses = {
      'CC0-1.0': 'https://creativecommons.org/publicdomain/zero/1.0/',
      'CC-BY-4.0': 'https://creativecommons.org/licenses/by/4.0/',
      'CC-BY-SA-4.0': 'https://creativecommons.org/licenses/by-sa/4.0/',
    };
    if (license != 'LicenseRef-Permission' &&
        (!licenses.containsKey(license) ||
            licenses[license] != licenseUrl.toString())) {
      throw const FormatException(
        'Licencia o enlace de licencia no admitidos.',
      );
    }
    final editorial = EditorialReview.fromJson(_object(json['editorial']));
    final technicalReview = json.containsKey('technicalReview')
        ? TechnicalReview.fromJson(_object(json['technicalReview']))
        : null;
    if (technicalReview != null &&
        technicalReview.status == TechnicalReviewStatus.reviewed &&
        technicalReview.reviewedOn!.isBefore(editorial.updatedOn)) {
      throw const FormatException(
        'La revisión técnica es anterior al contenido del recurso.',
      );
    }
    return ExerciseResource._(
      id: _mediaId(json),
      title: _text(json, 'title'),
      kind: kind,
      location: sequence
          ? null
          : ExerciseMediaLocation.fromJson(json, video: video),
      frames: frames,
      creator: _text(json, 'creator'),
      sourceUrl: _url(json, 'sourceUrl'),
      license: license,
      licenseUrl: licenseUrl,
      permissionNote: _text(json, 'permissionNote'),
      attribution: _text(json, 'attribution'),
      altText: _text(json, 'altText'),
      editorial: editorial,
      technicalReview: technicalReview,
      durationSeconds: duration as int?,
      transcript: video ? _text(json, 'transcript') : null,
      captionsAssetPath: captions,
    );
  }
}

String _mediaId(Map<String, dynamic> json) {
  final id = _text(json, 'id');
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
    throw const FormatException('Identificador de recurso o fase inválido.');
  }
  return id;
}

String _mediaPath(String path) {
  if (!RegExp(
    r'^assets/exercise_media/(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+\.[a-z0-9]+$',
  ).hasMatch(path)) {
    throw const FormatException('Ruta multimedia local inválida.');
  }
  return path;
}
