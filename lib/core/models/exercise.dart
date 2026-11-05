import 'dart:convert';

import 'training_modality.dart';
import 'equipment.dart';
import 'equipment_requirements.dart';
export 'training_modality.dart';

part 'exercise_resource.dart';

enum MuscleGroup {
  quadriceps('Cuádriceps'),
  glutes('Glúteos'),
  hamstrings('Isquiotibiales'),
  calves('Gemelos'),
  chest('Pecho'),
  back('Espalda'),
  shoulders('Hombros'),
  biceps('Bíceps'),
  triceps('Tríceps'),
  core('Zona media');

  const MuscleGroup(this.label);
  final String label;
}

enum ExerciseEquipment {
  dumbbells('Mancuernas'),
  barbell('Barra con discos'),
  bench('Banco'),
  resistanceBand('Bandas de resistencia'),
  pullUpBar('Barra de dominadas'),
  cableMachine('Polea alta'),
  legPressMachine('Prensa de piernas'),
  wall('Pared'),
  mat('Esterilla');

  const ExerciseEquipment(this.label);
  final String label;
}

enum ExerciseDifficulty {
  beginner('Inicial'),
  intermediate('Intermedia'),
  advanced('Avanzada');

  const ExerciseDifficulty(this.label);
  final String label;
}

enum EditorialStatus {
  pending('Pendiente de revisión editorial'),
  reviewed('Revisado editorialmente');

  const EditorialStatus(this.label);
  final String label;
}

/// A reference is not a license to redistribute the referenced site's media.
class ExerciseSource {
  ExerciseSource._(
    this.title,
    this.publisher,
    this.url,
    this.checkedOn,
    this.scope,
  );
  final String title;
  final String publisher;
  final Uri url;
  final DateTime checkedOn;
  final String? scope;

  factory ExerciseSource.fromJson(Map<String, dynamic> json) =>
      ExerciseSource._(
        _text(json, 'title'),
        _text(json, 'publisher'),
        _url(json, 'url'),
        _date(json, 'checkedOn'),
        json.containsKey('scope') ? _text(json, 'scope') : null,
      );
}

class EditorialReview {
  EditorialReview._(
    this.status,
    this.updatedOn,
    this.reviewer,
    this.reviewedOn,
    this.notes,
  );
  final EditorialStatus status;
  final DateTime updatedOn;
  final String? reviewer;
  final DateTime? reviewedOn;
  final String notes;

  factory EditorialReview.fromJson(Map<String, dynamic> json) {
    final status = _enum(json['status'], EditorialStatus.values);
    final updated = _date(json, 'updatedOn');
    final reviewer = json['reviewer'] == null ? null : _text(json, 'reviewer');
    final reviewed = json['reviewedOn'] == null
        ? null
        : _date(json, 'reviewedOn');
    if (status == EditorialStatus.reviewed &&
        (reviewer == null || reviewed == null || reviewed.isBefore(updated))) {
      throw const FormatException(
        'La revisión necesita responsable y fecha vigente.',
      );
    }
    if (status == EditorialStatus.pending &&
        (reviewer != null || reviewed != null)) {
      throw const FormatException(
        'Una revisión pendiente no puede figurar firmada.',
      );
    }
    return EditorialReview._(
      status,
      updated,
      reviewer,
      reviewed,
      _text(json, 'notes'),
    );
  }
}

class ExerciseAlternative {
  ExerciseAlternative._(this.exerciseId, this.reason);
  final String exerciseId;
  final String reason;
  factory ExerciseAlternative.fromJson(Map<String, dynamic> json) =>
      ExerciseAlternative._(_text(json, 'exerciseId'), _text(json, 'reason'));
}

/// Observable teaching cues; these do not diagnose the cause of a movement.
class TechniqueError {
  TechniqueError._(this.title, this.recognition, this.correction);
  final String title;
  final String recognition;
  final String correction;

  factory TechniqueError.fromJson(Map<String, dynamic> json) =>
      TechniqueError._(
        _text(json, 'title'),
        _text(json, 'recognition'),
        _text(json, 'correction'),
      );
}

/// Adjustments of the same movement, separate from catalog alternatives.
class TechniqueVariation {
  TechniqueVariation._(this.title, this.description);
  final String title;
  final String description;

  factory TechniqueVariation.fromJson(Map<String, dynamic> json) =>
      TechniqueVariation._(_text(json, 'title'), _text(json, 'description'));
}

class ExerciseTechnique {
  ExerciseTechnique._({
    required this.preparation,
    required this.steps,
    required this.breathing,
    required this.control,
    required this.commonErrors,
    required this.tips,
    required this.regressions,
    required this.progressions,
    required this.precautions,
    required this.stopSignals,
  });

  final List<String> preparation;
  final List<String> steps;
  final List<String> breathing;
  final List<String> control;
  final List<TechniqueError> commonErrors;
  final List<String> tips;
  final List<TechniqueVariation> regressions;
  final List<TechniqueVariation> progressions;
  final List<String> precautions;
  final List<String> stopSignals;

  factory ExerciseTechnique.fromJson(Map<String, dynamic> json) {
    final technique = ExerciseTechnique._(
      preparation: _strings(json, 'preparation'),
      steps: _strings(json, 'steps'),
      breathing: _strings(json, 'breathing'),
      control: _strings(json, 'control'),
      commonErrors: _objects(json, 'commonErrors', TechniqueError.fromJson),
      tips: _strings(json, 'tips'),
      regressions: _objects(json, 'regressions', TechniqueVariation.fromJson),
      progressions: _objects(json, 'progressions', TechniqueVariation.fromJson),
      precautions: _strings(json, 'precautions'),
      stopSignals: _strings(json, 'stopSignals'),
    );
    if (technique.preparation.isEmpty ||
        technique.steps.length < 3 ||
        technique.breathing.isEmpty ||
        technique.control.isEmpty ||
        technique.commonErrors.isEmpty ||
        technique.tips.isEmpty ||
        technique.regressions.isEmpty ||
        technique.progressions.isEmpty ||
        technique.precautions.isEmpty ||
        technique.stopSignals.isEmpty) {
      throw const FormatException('Ficha técnica incompleta.');
    }
    return technique;
  }
}

class Exercise {
  Exercise._({
    required this.id,
    required this.name,
    required this.description,
    required this.modalities,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.requiredEquipment,
    required this.optionalEquipment,
    required this.difficulty,
    required this.instructions,
    required this.requirements,
    required this.alternatives,
    required this.sources,
    required this.resources,
    required this.editorial,
    required this.equipmentRequirements,
    required this.technique,
  });

  final String id;
  final String name;
  final String description;
  final List<ExerciseModality> modalities;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<ExerciseEquipment> requiredEquipment;
  final List<ExerciseEquipment> optionalEquipment;
  final ExerciseDifficulty difficulty;
  final List<String> instructions;
  final List<String> requirements;
  final List<ExerciseAlternative> alternatives;
  final List<ExerciseSource> sources;
  final List<ExerciseResource> resources;
  final EditorialReview editorial;
  final EquipmentRequirements equipmentRequirements;
  final ExerciseTechnique? technique;

  String get equipmentLabel => requiredEquipment.isEmpty
      ? 'Sin material'
      : requiredEquipment.map((item) => item.label).join(' · ');

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final id = _text(json, 'id');
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
      throw const FormatException('Identificador de ejercicio inválido.');
    }
    final primary = _enums(json, 'primaryMuscles', MuscleGroup.values);
    final secondary = _enums(json, 'secondaryMuscles', MuscleGroup.values);
    final requiredEquipment = _enums(
      json,
      'requiredEquipment',
      ExerciseEquipment.values,
    );
    final optional = _enums(
      json,
      'optionalEquipment',
      ExerciseEquipment.values,
    );
    final equipmentRequirements = json.containsKey('equipmentRequirements')
        ? EquipmentRequirements.fromJson(json['equipmentRequirements'])
        : EquipmentRequirements.legacy(
            requiredEquipment.map((item) => item.name),
            optional.map((item) => item.name),
          );
    final modalities = _enums(json, 'modalities', ExerciseModality.values);
    final instructions = _strings(json, 'instructions');
    final requirements = _strings(json, 'requirements');
    if (primary.isEmpty ||
        modalities.isEmpty ||
        instructions.length < 2 ||
        requirements.isEmpty ||
        primary.any(secondary.contains) ||
        requiredEquipment.any(optional.contains)) {
      throw FormatException(
        'Datos incompletos o categorías superpuestas: $id.',
      );
    }
    final sources = _objects(json, 'sources', ExerciseSource.fromJson);
    final editorial = EditorialReview.fromJson(_object(json['editorial']));
    if (editorial.status == EditorialStatus.reviewed && sources.isEmpty) {
      throw const FormatException('Un ejercicio revisado debe tener fuentes.');
    }
    return Exercise._(
      id: id,
      name: _text(json, 'name'),
      description: _text(json, 'description'),
      modalities: modalities,
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      requiredEquipment: requiredEquipment,
      optionalEquipment: optional,
      difficulty: _enum(json['difficulty'], ExerciseDifficulty.values),
      instructions: instructions,
      requirements: requirements,
      alternatives: _objects(
        json,
        'alternatives',
        ExerciseAlternative.fromJson,
      ),
      sources: sources,
      resources: _objects(json, 'resources', ExerciseResource.fromJson),
      editorial: editorial,
      equipmentRequirements: equipmentRequirements,
      technique: json.containsKey('technique')
          ? ExerciseTechnique.fromJson(_object(json['technique']))
          : null,
    );
  }
}

/// Shared educational precautions and their references, bundled offline.
class TeachingGuidance {
  TeachingGuidance._(
    this.scope,
    this.precautions,
    this.stopSignals,
    this.sources,
  );
  final String scope;
  final List<String> precautions;
  final List<String> stopSignals;
  final List<ExerciseSource> sources;

  factory TeachingGuidance.fromJson(Map<String, dynamic> json) {
    final precautions = _strings(json, 'precautions');
    final stopSignals = _strings(json, 'stopSignals');
    final sources = _objects(json, 'sources', ExerciseSource.fromJson);
    if (precautions.isEmpty || stopSignals.isEmpty || sources.isEmpty) {
      throw const FormatException('Orientaciones generales incompletas.');
    }
    return TeachingGuidance._(
      _text(json, 'scope'),
      precautions,
      stopSignals,
      sources,
    );
  }
}

/// Versioned, validated, immutable snapshot of the offline catalog.
class ExerciseCatalog {
  ExerciseCatalog._(
    this.version,
    this.exercises,
    this._byId,
    this.teachingGuidance,
  );
  final int version;
  final List<Exercise> exercises;
  final Map<String, Exercise> _byId;
  final TeachingGuidance? teachingGuidance;
  void validateEquipment(EquipmentCatalog catalog) {
    for (final exercise in exercises) {
      exercise.equipmentRequirements.validate(catalog);
    }
  }

  Exercise? findById(String id) => _byId[id];
  Exercise requireById(String id) =>
      _byId[id] ??
      (throw FormatException('No existe el ejercicio $id en el catálogo.'));

  factory ExerciseCatalog.decode(String source) =>
      ExerciseCatalog.fromJson(jsonDecode(source));

  factory ExerciseCatalog.fromJson(Object? value) {
    final json = _object(value);
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['catalogVersion'] is! int ||
        (json['catalogVersion'] as int) < 1) {
      throw const FormatException('Versión del catálogo no compatible.');
    }
    final exercises = _objects(json, 'exercises', Exercise.fromJson);
    final byId = {for (final exercise in exercises) exercise.id: exercise};
    if (exercises.isEmpty || byId.length != exercises.length) {
      throw const FormatException(
        'El catálogo está vacío o repite identificadores.',
      );
    }
    for (final exercise in exercises) {
      final ids = exercise.alternatives.map((item) => item.exerciseId).toList();
      if (ids.toSet().length != ids.length ||
          ids.contains(exercise.id) ||
          ids.any((id) => !byId.containsKey(id))) {
        throw FormatException('Alternativas inválidas para ${exercise.id}.');
      }
      if (exercise.sources.map((source) => source.url).toSet().length !=
          exercise.sources.length) {
        throw FormatException('Fuentes repetidas para ${exercise.id}.');
      }
    }
    final resourceIds = exercises
        .expand((exercise) => exercise.resources)
        .map((resource) => resource.id)
        .toList();
    if (resourceIds.toSet().length != resourceIds.length) {
      throw const FormatException('Identificadores de recursos repetidos.');
    }
    return ExerciseCatalog._(
      json['catalogVersion'] as int,
      exercises,
      Map.unmodifiable(byId),
      json.containsKey('teachingGuidance')
          ? TeachingGuidance.fromJson(_object(json['teachingGuidance']))
          : null,
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Se esperaba un objeto JSON.');
  }
  return value;
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Texto obligatorio: $key.');
  }
  return value.trim();
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Se esperaba una lista: $key.');
  return value;
}

List<T> _objects<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) => List.unmodifiable(_list(json, key).map((value) => decode(_object(value))));

List<String> _strings(Map<String, dynamic> json, String key) =>
    List.unmodifiable(
      _list(json, key).map((value) => _text({'value': value}, 'value')),
    );

T _enum<T extends Enum>(Object? value, List<T> options) => options.firstWhere(
  (option) => option.name == value,
  orElse: () => throw FormatException('Categoría desconocida: $value.'),
);

List<T> _enums<T extends Enum>(
  Map<String, dynamic> json,
  String key,
  List<T> options,
) {
  final result = _list(
    json,
    key,
  ).map((value) => _enum(value, options)).toList();
  if (result.toSet().length != result.length) {
    throw FormatException('Categorías repetidas: $key.');
  }
  return List.unmodifiable(result);
}

Uri _url(Map<String, dynamic> json, String key) {
  final uri = Uri.tryParse(_text(json, key));
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw FormatException('URL HTTPS inválida: $key.');
  }
  return uri;
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = _text(json, key);
  final date = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      date == null ||
      date.toIso8601String().substring(0, 10) != value) {
    throw FormatException('Fecha inválida: $key.');
  }
  return date;
}
