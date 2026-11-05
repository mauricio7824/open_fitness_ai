part of 'exercise.dart';

/// A specification for files that have not yet been supplied. This is never an
/// available media resource and carries no fabricated author/license/review.
class ExerciseIllustrationPhase {
  ExerciseIllustrationPhase._(
    this.id,
    this.title,
    this.description,
    this.expectedAssetPath,
  );
  final String id;
  final String title;
  final String description;
  final String expectedAssetPath;

  factory ExerciseIllustrationPhase.fromJson(Map<String, dynamic> json) {
    final location = ExerciseMediaLocation.fromJson({
      'assetPath': _text(json, 'expectedAssetPath'),
    });
    return ExerciseIllustrationPhase._(
      _mediaId(json),
      _text(json, 'title'),
      _text(json, 'description'),
      location.assetPath!,
    );
  }
}

class ExerciseIllustrationPlan {
  ExerciseIllustrationPlan._(this.resourceId, this.phases);
  final String resourceId;
  final List<ExerciseIllustrationPhase> phases;

  factory ExerciseIllustrationPlan.fromJson(Map<String, dynamic> json) {
    final phases = _objects(json, 'phases', ExerciseIllustrationPhase.fromJson);
    const ids = ['initial', 'intermediate', 'final'];
    if (phases.length != ids.length ||
        Iterable<int>.generate(ids.length).any((i) => phases[i].id != ids[i]) ||
        phases.map((phase) => phase.expectedAssetPath).toSet().length !=
            ids.length) {
      throw const FormatException(
        'El plan necesita tres fases distintas: initial, intermediate y final, en ese orden.',
      );
    }
    return ExerciseIllustrationPlan._(
      _mediaId({'id': json['resourceId']}),
      phases,
    );
  }

  /// If a contributor supplies this sequence, it must implement the plan and
  /// explicitly declare its technical review. File existence is checked by the
  /// media loader/build checks, never inferred from a catalog entry.
  void validateResource(ExerciseResource resource) {
    if (resource.kind != ExerciseResourceKind.imageSequence ||
        resource.frames.length != phases.length ||
        resource.technicalReview == null) {
      throw const FormatException(
        'La secuencia ilustrada necesita tres fases y revisión técnica explícita.',
      );
    }
    for (var i = 0; i < phases.length; i++) {
      if (resource.frames[i].id != phases[i].id ||
          resource.frames[i].location.assetPath !=
              phases[i].expectedAssetPath) {
        throw const FormatException(
          'La secuencia no coincide con las fases y archivos locales del plan.',
        );
      }
    }
  }
}
