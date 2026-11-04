import 'dart:convert';

import 'training_modality.dart';

enum EquipmentCategory {
  environment('Peso corporal y entorno'),
  freeWeights('Peso libre'),
  racks('Bancos, soportes y racks'),
  upperMachines('Máquinas de tren superior'),
  lowerMachines('Máquinas de tren inferior'),
  cableStations('Poleas y estaciones'),
  calisthenics('Calistenia'),
  functional('Funcional'),
  mobility('Movilidad'),
  cardio('Cardiovascular');

  const EquipmentCategory(this.label);
  final String label;
}

enum EquipmentKind {
  bodyweight,
  environment,
  implement,
  accessory,
  machine,
  support,
}

enum EquipmentAvailability {
  unknown('Sin declarar'),
  available('Disponible'),
  unavailable('No disponible');

  const EquipmentAvailability(this.label);
  final String label;
}

bool validEquipmentId(String id) =>
    RegExp(r'^[a-z][A-Za-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id);
String normalizeEquipmentText(String text) {
  var value = text.toLowerCase().trim();
  for (final entry in const {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  }.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }
  return value
      .replaceAll(RegExp('[\u0300-\u0302\u0308]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

class EquipmentDefinition {
  EquipmentDefinition({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required Iterable<String> synonyms,
    required this.category,
    required this.kind,
    required Iterable<ExerciseModality> modalities,
    required this.description,
    required Iterable<String> variants,
    this.defaultAvailability = EquipmentAvailability.unknown,
  }) : synonyms = List.unmodifiable(synonyms),
       modalities = Set.unmodifiable(modalities),
       variants = List.unmodifiable(variants) {
    if (!validEquipmentId(id) ||
        nameEs.trim().isEmpty ||
        nameEn.trim().isEmpty ||
        description.trim().isEmpty ||
        this.modalities.isEmpty ||
        this.synonyms.any((item) => item.trim().isEmpty) ||
        this.variants.any((item) => item.trim().isEmpty) ||
        this.synonyms.map(normalizeEquipmentText).toSet().length !=
            this.synonyms.length) {
      throw FormatException('Definición de equipamiento inválida: $id.');
    }
    if (defaultAvailability != EquipmentAvailability.unknown) {
      throw const FormatException(
        'El catálogo no puede presuponer material del usuario.',
      );
    }
  }
  final String id;
  final String nameEs;
  final String nameEn;
  final List<String> synonyms;
  final EquipmentCategory category;
  final EquipmentKind kind;
  final Set<ExerciseModality> modalities;
  final EquipmentAvailability defaultAvailability;
  final String description;
  final List<String> variants;
  bool matches(String query) {
    final terms = [
      nameEs,
      nameEn,
      ...synonyms,
    ].map(normalizeEquipmentText).join(' ');
    return normalizeEquipmentText(query)
        .split(' ')
        .where((word) => word.isNotEmpty)
        .every(terms.contains);
  }

  Map<String, Object> toJson() => {
    'id': id,
    'nameEs': nameEs,
    'nameEn': nameEn,
    'synonyms': synonyms,
    'category': category.name,
    'kind': kind.name,
    'modalities': modalities.map((item) => item.name).toList()..sort(),
    'defaultAvailability': defaultAvailability.name,
    'description': description,
    'variants': variants,
  };
  factory EquipmentDefinition.fromJson(Object? source) {
    final json = equipmentObject(source);
    return EquipmentDefinition(
      id: equipmentText(json['id']),
      nameEs: equipmentText(json['nameEs']),
      nameEn: equipmentText(json['nameEn']),
      synonyms: equipmentStrings(json['synonyms']),
      category: equipmentEnum(json['category'], EquipmentCategory.values),
      kind: equipmentEnum(json['kind'], EquipmentKind.values),
      modalities: equipmentStrings(json['modalities'])
          .map((item) => equipmentEnum(item, ExerciseModality.values)),
      defaultAvailability: equipmentEnum(
        json['defaultAvailability'],
        EquipmentAvailability.values,
      ),
      description: equipmentText(json['description']),
      variants: equipmentStrings(json['variants']),
    );
  }
}

class EquipmentCatalog {
  EquipmentCatalog(
    Iterable<EquipmentDefinition> definitions, {
    this.version = 1,
  }) : equipment = List.unmodifiable(definitions) {
    if (equipment.isEmpty || version < 1) {
      throw const FormatException('Catálogo de equipo vacío o inválido.');
    }
    final names = <String, String>{};
    for (final item in equipment) {
      if (_byId.containsKey(item.id)) {
        throw FormatException('ID de equipo repetido: ${item.id}.');
      }
      _byId[item.id] = item;
      for (final term in [item.nameEs, item.nameEn, ...item.synonyms]) {
        final normalized = normalizeEquipmentText(term);
        final owner = names[normalized];
        if (owner != null && owner != item.id) {
          throw FormatException('Nombre o sinónimo duplicado: $term.');
        }
        names[normalized] = item.id;
      }
    }
  }
  final int version;
  final List<EquipmentDefinition> equipment;
  final Map<String, EquipmentDefinition> _byId = {};
  EquipmentDefinition? find(String id) => _byId[id];
  EquipmentDefinition require(String id) =>
      _byId[id] ?? (throw FormatException('Equipo no registrado: $id.'));
  String label(String id) => require(id).nameEs;
  List<EquipmentDefinition> search(String query) =>
      equipment.where((item) => item.matches(query)).toList(growable: false);
  EquipmentCatalog withCustom(Iterable<EquipmentDefinition> custom) =>
      EquipmentCatalog([...equipment, ...custom], version: version);
  factory EquipmentCatalog.decode(String source) {
    final json = equipmentObject(jsonDecode(source));
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['catalogVersion'] is! int ||
        json['equipment'] is! List) {
      throw const FormatException('Esquema de equipamiento no compatible.');
    }
    return EquipmentCatalog(
      (json['equipment'] as List).map(EquipmentDefinition.fromJson),
      version: json['catalogVersion'] as int,
    );
  }
}

class EquipmentPreset {
  const EquipmentPreset(this.id, this.label, this.ids);
  final String id;
  final String label;
  final List<String> ids;
}

const equipmentPresets = [
  EquipmentPreset('home', 'Hogar', ['mat', 'resistanceBand']),
  EquipmentPreset('gym', 'Gimnasio', ['dumbbells', 'barbell', 'bench']),
  EquipmentPreset('mixed', 'Mixto', ['mat', 'dumbbells', 'pullUpBar']),
];

Map<String, dynamic> equipmentObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Se esperaba un objeto de equipamiento.');
  }
  return value;
}

String equipmentText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Texto de equipamiento obligatorio.');
  }
  return value.trim();
}

List<String> equipmentStrings(Object? value) {
  if (value is! List ||
      value.any((item) => item is! String || item.trim().isEmpty)) {
    throw const FormatException('Lista de equipamiento inválida.');
  }
  final result = value.cast<String>().map((item) => item.trim()).toList();
  if (result.toSet().length != result.length) {
    throw const FormatException('Valores repetidos en equipamiento.');
  }
  return result;
}

T equipmentEnum<T extends Enum>(Object? value, List<T> options) =>
    options.firstWhere(
      (item) => item.name == value,
      orElse: () =>
          throw FormatException('Valor de equipamiento desconocido: $value.'),
    );
