import 'dart:convert';

enum ExerciseModality {
  gym('Gimnasio'),
  home('Casa'),
  calisthenics('Calistenia');

  const ExerciseModality(this.label);
  final String label;
}

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
  bench('Banco'),
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
  ExerciseSource._(this.title, this.publisher, this.url, this.checkedOn);
  final String title;
  final String publisher;
  final Uri url;
  final DateTime checkedOn;

  factory ExerciseSource.fromJson(Map<String, dynamic> json) =>
      ExerciseSource._(
        _text(json, 'title'),
        _text(json, 'publisher'),
        _url(json, 'url'),
        _date(json, 'checkedOn'),
      );
}

class ExerciseResource {
  ExerciseResource._(
    this.kind,
    this.assetPath,
    this.creator,
    this.sourceUrl,
    this.license,
    this.licenseUrl,
  );
  final String kind;
  final String assetPath;
  final String creator;
  final Uri sourceUrl;
  final String license;
  final Uri licenseUrl;

  factory ExerciseResource.fromJson(Map<String, dynamic> json) {
    final kind = _text(json, 'kind');
    final path = _text(json, 'assetPath');
    if (!['image', 'video'].contains(kind) ||
        !path.startsWith('assets/') ||
        path.contains('..') ||
        path.contains('\\')) {
      throw const FormatException('Tipo o ruta de recurso inválidos.');
    }
    return ExerciseResource._(
      kind,
      path,
      _text(json, 'creator'),
      _url(json, 'sourceUrl'),
      _text(json, 'license'),
      _url(json, 'licenseUrl'),
    );
  }
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
    );
  }
}

/// Versioned, validated, immutable snapshot of the offline catalog.
class ExerciseCatalog {
  ExerciseCatalog._(this.version, this.exercises, this._byId);
  final int version;
  final List<Exercise> exercises;
  final Map<String, Exercise> _byId;

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
    return ExerciseCatalog._(
      json['catalogVersion'] as int,
      exercises,
      Map.unmodifiable(byId),
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
