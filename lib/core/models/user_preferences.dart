import 'exercise.dart';
import 'equipment.dart';
import 'equipment_requirements.dart';

enum TrainingExperience {
  beginner('Estoy empezando'),
  intermediate('Tengo experiencia'),
  advanced('Entreno de forma avanzada');

  const TrainingExperience(this.label);
  final String label;
}

enum ActivityGoal {
  consistency('Crear constancia'),
  strength('Desarrollar fuerza'),
  endurance('Mejorar resistencia'),
  mobility('Trabajar movilidad'),
  generalFitness('Mantenerme activo');

  const ActivityGoal(this.label);
  final String label;
}

enum AvailableDay {
  monday('Lunes'),
  tuesday('Martes'),
  wednesday('Miércoles'),
  thursday('Jueves'),
  friday('Viernes'),
  saturday('Sábado'),
  sunday('Domingo');

  const AvailableDay(this.label);
  final String label;
}

enum SetupStatus { notStarted, skipped, completed }

class SportsProfile {
  SportsProfile({
    required this.experience,
    required Iterable<ExerciseModality> modalities,
    required Iterable<ActivityGoal> goals,
    required Iterable<AvailableDay> availableDays,
    required this.sessionMinutes,
  }) : modalities = Set.unmodifiable(modalities),
       goals = Set.unmodifiable(goals),
       availableDays = Set.unmodifiable(availableDays) {
    if (this.modalities.isEmpty ||
        this.goals.isEmpty ||
        this.availableDays.isEmpty ||
        sessionMinutes < 5 ||
        sessionMinutes > 180) {
      throw const FormatException(
        'Completa las preferencias y elige una duración de 5 a 180 minutos.',
      );
    }
  }

  final TrainingExperience experience;
  final Set<ExerciseModality> modalities;
  final Set<ActivityGoal> goals;
  final Set<AvailableDay> availableDays;
  final int sessionMinutes;

  Map<String, Object> toJson() => {
    'experience': experience.name,
    'modalities': _names(modalities),
    'goals': _names(goals),
    'availableDays': _names(availableDays),
    'sessionMinutes': sessionMinutes,
  };

  factory SportsProfile.fromJson(Map<String, dynamic> json) {
    final minutes = json['sessionMinutes'];
    if (minutes is! int) throw const FormatException('Duración inválida.');
    return SportsProfile(
      experience: _enum(json['experience'], TrainingExperience.values),
      modalities: _set(json['modalities'], ExerciseModality.values),
      goals: _set(json['goals'], ActivityGoal.values),
      availableDays: _set(json['availableDays'], AvailableDay.values),
      sessionMinutes: minutes,
    );
  }
}

/// Empty equipment is an explicit "Sin material" choice; null inventory means unknown.
class EquipmentInventory {
  EquipmentInventory(Iterable<ExerciseEquipment> items)
    : this.fromAvailability({
        for (final item in items) item.name: EquipmentAvailability.available,
      });
  EquipmentInventory.fromAvailability(
    Map<String, EquipmentAvailability> availability, {
    Iterable<EquipmentDefinition> customEquipment = const [],
  }) : availability = Map.unmodifiable(
         Map.of(availability)
           ..removeWhere((_, state) => state == EquipmentAvailability.unknown),
       ),
       customEquipment = List.unmodifiable(customEquipment) {
    if (this.availability.keys.any((id) => !validEquipmentId(id)) ||
        this.customEquipment.any((item) => !item.id.startsWith('custom-')) ||
        this.customEquipment.map((item) => item.id).toSet().length !=
            this.customEquipment.length) {
      throw const FormatException('Inventario de equipamiento inválido.');
    }
  }
  final Map<String, EquipmentAvailability> availability;
  final List<EquipmentDefinition> customEquipment;
  Set<String> get availableIds => Set.unmodifiable(
    availability.entries
        .where((entry) => entry.value == EquipmentAvailability.available)
        .map((entry) => entry.key),
  );
  EquipmentAvailability stateOf(String id) =>
      availability[id] ?? EquipmentAvailability.unknown;
  // Legacy API kept for callers from phases 2/3. New code uses stable string IDs.
  Set<ExerciseEquipment> get items => Set.unmodifiable(
    ExerciseEquipment.values.where((item) => availableIds.contains(item.name)),
  );
  EquipmentCheck check(Exercise exercise) =>
      exercise.equipmentRequirements.evaluate(availableIds);
  void validateAgainst(EquipmentCatalog builtIn) {
    final catalog = builtIn.withCustom(customEquipment);
    for (final id in availability.keys) {
      catalog.require(id);
    }
  }

  String displayLabel(EquipmentCatalog catalog) => availableIds.isEmpty
      ? 'Sin material'
      : catalog.equipment
            .where((item) => availableIds.contains(item.id))
            .map((item) => item.nameEs)
            .join(', ');

  List<ExerciseEquipment> missingFor(Exercise exercise) => List.unmodifiable(
    exercise.requiredEquipment.where((equipment) => !items.contains(equipment)),
  );
  bool supports(Exercise exercise) => check(exercise).compatible;
  String get label => items.isEmpty
      ? 'Sin material'
      : ExerciseEquipment.values
            .where(items.contains)
            .map((item) => item.label)
            .join(', ');

  Map<String, Object> toJson() => {
    'equipment': availableIds.toList()..sort(),
    'unavailableEquipment':
        availability.entries
            .where((entry) => entry.value == EquipmentAvailability.unavailable)
            .map((entry) => entry.key)
            .toList()
          ..sort(),
    'customEquipment': customEquipment.map((item) => item.toJson()).toList(),
  };
  factory EquipmentInventory.fromJson(
    Map<String, dynamic> json, {
    bool legacy = false,
  }) {
    if (legacy) {
      return EquipmentInventory(
        _set(json['equipment'], ExerciseEquipment.values),
      );
    }
    final available = equipmentStrings(json['equipment']);
    final unavailable = equipmentStrings(json['unavailableEquipment']);
    if (available.any(unavailable.contains) ||
        json['customEquipment'] is! List) {
      throw const FormatException('Estados de disponibilidad contradictorios.');
    }
    return EquipmentInventory.fromAvailability(
      {
        for (final id in available) id: EquipmentAvailability.available,
        for (final id in unavailable) id: EquipmentAvailability.unavailable,
      },
      customEquipment: (json['customEquipment'] as List).map(
        EquipmentDefinition.fromJson,
      ),
    );
  }
}

/// Profile, inventory and setup status are committed in one local value.
class UserPreferences {
  UserPreferences({
    this.profile,
    this.inventory,
    this.setupStatus = SetupStatus.notStarted,
  }) {
    if (setupStatus == SetupStatus.completed &&
        (profile == null || inventory == null)) {
      throw const FormatException(
        'La configuración completa necesita perfil e inventario.',
      );
    }
    if (setupStatus != SetupStatus.completed &&
        profile != null &&
        inventory != null) {
      throw const FormatException(
        'El perfil y el inventario completos deben cerrar la configuración.',
      );
    }
  }
  final SportsProfile? profile;
  final EquipmentInventory? inventory;
  final SetupStatus setupStatus;
  bool get needsSetup => setupStatus == SetupStatus.notStarted;

  UserPreferences withProfile(SportsProfile value) => UserPreferences(
    profile: value,
    inventory: inventory,
    setupStatus: inventory == null ? setupStatus : SetupStatus.completed,
  );
  UserPreferences withInventory(EquipmentInventory value) => UserPreferences(
    profile: profile,
    inventory: value,
    setupStatus: profile == null ? setupStatus : SetupStatus.completed,
  );
  UserPreferences skipSetup() => UserPreferences(
    profile: profile,
    inventory: inventory,
    setupStatus: setupStatus == SetupStatus.completed
        ? SetupStatus.completed
        : SetupStatus.skipped,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 2,
    'profile': profile?.toJson(),
    'inventory': inventory?.toJson(),
    'setupStatus': setupStatus.name,
  };

  factory UserPreferences.fromJson(
    Object? value, {
    EquipmentCatalog? equipmentCatalog,
  }) {
    final json = _object(value);
    if (json['schemaVersion'] is! int ||
        ![1, 2].contains(json['schemaVersion']) ||
        !json.containsKey('profile') ||
        !json.containsKey('inventory')) {
      throw const FormatException('Formato de preferencias no compatible.');
    }
    final inventory = json['inventory'] == null
        ? null
        : EquipmentInventory.fromJson(
            _object(json['inventory']),
            legacy: json['schemaVersion'] == 1,
          );
    if (equipmentCatalog != null) inventory?.validateAgainst(equipmentCatalog);
    return UserPreferences(
      profile: json['profile'] == null
          ? null
          : SportsProfile.fromJson(_object(json['profile'])),
      inventory: inventory,
      setupStatus: _enum(json['setupStatus'], SetupStatus.values),
    );
  }
}

List<String> _names<T extends Enum>(Iterable<T> values) =>
    values.map((value) => value.name).toList()..sort();
Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Se esperaba un objeto de preferencias.');
  }
  return value;
}

T _enum<T extends Enum>(Object? value, List<T> options) => options.firstWhere(
  (option) => option.name == value,
  orElse: () => throw FormatException('Preferencia desconocida: $value.'),
);
Set<T> _set<T extends Enum>(Object? value, List<T> options) {
  if (value is! List) {
    throw const FormatException('Se esperaba una lista de preferencias.');
  }
  final items = value.map((item) => _enum(item, options)).toSet();
  if (items.length != value.length) {
    throw const FormatException('Hay preferencias repetidas.');
  }
  return items;
}
