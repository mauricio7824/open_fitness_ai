import 'equipment.dart';

/// AND of groups. Each group is OR choices of simultaneous equipment (AND).
/// No equivalence is inferred from names, categories, machines or variants.
class EquipmentRequirements {
  EquipmentRequirements({
    required Iterable<Iterable<Iterable<String>>> allOf,
    Iterable<String> optional = const [],
  }) : allOf = List.unmodifiable(
         allOf.map(
           (group) => List<Set<String>>.unmodifiable(
             group.map((option) => Set<String>.unmodifiable(option)),
           ),
         ),
       ),
       optional = Set.unmodifiable(optional) {
    for (final group in this.allOf) {
      if (group.isEmpty || group.any((option) => option.isEmpty)) {
        throw const FormatException('Grupo de requisitos vacío.');
      }
      final keys = group
          .map((option) => (option.toList()..sort()).join('|'))
          .toSet();
      if (keys.length != group.length) {
        throw const FormatException('Alternativas de equipo repetidas.');
      }
    }
    if (referencedIds.any((id) => !validEquipmentId(id))) {
      throw const FormatException('ID inválido en requisitos de equipo.');
    }
    if (this.allOf
        .expand((group) => group.expand((option) => option))
        .any(this.optional.contains)) {
      throw const FormatException(
        'Equipo obligatorio y opcional superpuestos.',
      );
    }
  }
  final List<List<Set<String>>> allOf;
  final Set<String> optional;
  Set<String> get referencedIds => {
    ...optional,
    ...allOf.expand((group) => group.expand((option) => option)),
  };
  bool get needsEquipment => allOf.isNotEmpty;
  factory EquipmentRequirements.legacy(
    Iterable<String> required,
    Iterable<String> optional,
  ) => EquipmentRequirements(
    allOf: required.map(
      (id) => [
        [id],
      ],
    ),
    optional: optional,
  );
  factory EquipmentRequirements.fromJson(Object? value) {
    final json = equipmentObject(value);
    if (json['allOf'] is! List) {
      throw const FormatException('Se esperaba allOf en requisitos.');
    }
    final groups = <List<List<String>>>[];
    for (final value in json['allOf'] as List) {
      final group = equipmentObject(value);
      if (group['anyOf'] is! List) {
        throw const FormatException('Se esperaba anyOf en requisitos.');
      }
      groups.add((group['anyOf'] as List).map(equipmentStrings).toList());
    }
    return EquipmentRequirements(
      allOf: groups,
      optional: equipmentStrings(json['optional']),
    );
  }
  void validate(EquipmentCatalog catalog) {
    for (final id in referencedIds) {
      catalog.require(id);
    }
  }

  EquipmentCheck evaluate(Set<String> available) => EquipmentCheck([
    for (final group in allOf)
      if (!group.any((option) => option.every(available.contains)))
        [
          for (final option in group)
            option.where((id) => !available.contains(id)).toSet(),
        ],
  ]);
  String describe(String Function(String) label) => allOf.isEmpty
      ? 'Sin material'
      : allOf
            .map(
              (group) => group
                  .map((option) => option.map(label).join(' + '))
                  .join(' o '),
            )
            .join(' · ');
}

class EquipmentCheck {
  EquipmentCheck(Iterable<Iterable<Set<String>>> missing)
    : missing = List.unmodifiable(
        missing.map(
          (group) => List<Set<String>>.unmodifiable(
            group.map((option) => Set<String>.unmodifiable(option)),
          ),
        ),
      );
  final List<List<Set<String>>> missing;
  bool get compatible => missing.isEmpty;
  String explain(String Function(String) label) {
    if (compatible) return 'Compatible con tu equipo';
    if (missing.every((group) => group.length == 1)) {
      return 'Te falta: ${missing.expand((group) => group.single).map(label).join(', ')}';
    }
    return 'Te falta: ${missing.map((group) => group.map((option) => option.map(label).join(' + ')).join(' o ')).join('; además, ')}';
  }
}
