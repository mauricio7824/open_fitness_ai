import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../data/exercise_repository.dart';
import '../data/fitness_catalog.dart';
import '../models/exercise.dart';
import '../models/fitness_models.dart';
import '../models/user_preferences.dart';
import '../models/equipment.dart';
import '../data/equipment_repository.dart';

class FitnessController extends ChangeNotifier {
  FitnessController(
    this._store, {
    ExerciseRepository? exerciseRepository,
    EquipmentRepository? equipmentRepository,
  }) : _exerciseRepository = exerciseRepository ?? AssetExerciseRepository(),
       _equipmentRepository = equipmentRepository ?? AssetEquipmentRepository();
  final EquipmentRepository _equipmentRepository;
  EquipmentCatalog? _baseEquipmentCatalog;
  EquipmentCatalog get builtInEquipmentCatalog => _baseEquipmentCatalog!;
  EquipmentCatalog get equipmentCatalog => _baseEquipmentCatalog!.withCustom(
    _preferences.inventory?.customEquipment ?? const [],
  );
  final FitnessStore _store;
  final ExerciseRepository _exerciseRepository;
  ExerciseCatalog? _catalog;
  List<Workout> _workouts = const [];
  ExerciseCatalog get catalog => _catalog!;
  List<Workout> get workouts => _workouts;
  ThemeMode themeMode = ThemeMode.system;
  List<WorkoutRecord> _records = [];
  WorkoutSession? _activeSession;
  bool loading = true;
  bool loadFailed = false;
  bool _saving = false;
  bool _savingTheme = false;
  bool _disposed = false;
  UserPreferences _preferences = UserPreferences();
  UserPreferences get preferences => _preferences;
  Future<void> _preferenceQueue = Future.value();
  int _pendingPreferences = 0;
  bool get savingPreferences => _pendingPreferences > 0;

  List<WorkoutRecord> get records => List.unmodifiable(_records);
  WorkoutSession? get activeSession => _activeSession;
  bool get saving => _saving;

  int sessionsThisWeek([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    return _records.where((record) {
      final day = DateUtils.dateOnly(record.completedAt.toLocal());
      return !day.isBefore(monday) && day.isBefore(nextMonday);
    }).length;
  }

  Future<void> initialize() async {
    loading = true;
    loadFailed = false;
    _notify();
    try {
      final data = await _store.load();
      final catalog = await _exerciseRepository.load();
      final equipmentCatalog = await _equipmentRepository.load();
      catalog.validateEquipment(equipmentCatalog);
      data.preferences?.inventory?.validateAgainst(equipmentCatalog);
      _baseEquipmentCatalog = equipmentCatalog;
      final workouts = buildWorkouts(catalog);
      _catalog = catalog;
      _workouts = workouts;
      themeMode = data.themeMode;
      _preferences = data.preferences ?? UserPreferences();
      _records = List.of(data.records)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_savingTheme || themeMode == mode) return;
    _savingTheme = true;
    try {
      await _store.saveTheme(mode);
      themeMode = mode;
      _notify();
    } finally {
      _savingTheme = false;
    }
  }

  Future<void> saveProfile(SportsProfile profile) =>
      _updatePreferences((current) => current.withProfile(profile));
  Future<void> saveInventory(EquipmentInventory inventory) =>
      _updatePreferences((current) {
        inventory.validateAgainst(_baseEquipmentCatalog!);
        return current.withInventory(inventory);
      });
  Future<void> skipSetup() =>
      _updatePreferences((current) => current.skipSetup());

  Future<void> _updatePreferences(
    UserPreferences Function(UserPreferences) update,
  ) {
    _pendingPreferences++;
    _notify();
    final operation = _preferenceQueue.then((_) async {
      try {
        final updated = update(_preferences);
        await _store.savePreferences(updated);
        _preferences = updated;
      } finally {
        _pendingPreferences--;
        _notify();
      }
    });
    // A failed write must not prevent a later retry or another queued edit.
    _preferenceQueue = operation.catchError((Object _) {});
    return operation;
  }

  void startWorkout(Workout workout) {
    // Resume or discard a pending session before starting another.
    if (_activeSession != null) return;
    _activeSession = WorkoutSession(workout);
    _notify();
  }

  void toggleMove(int index) {
    final session = _activeSession;
    if (session == null || _saving) return;
    if (index < 0 || index >= session.workout.moves.length) return;
    if (!session.completedMoves.remove(index)) {
      session.completedMoves.add(index);
    }
    _notify();
  }

  void discardSession() {
    if (_saving) return;
    _activeSession = null;
    _notify();
  }

  Future<bool> finishWorkout({DateTime? now}) async {
    final session = _activeSession;
    if (session == null || !session.isComplete || _saving) return false;
    _saving = true;
    _notify();
    final completedAt = now ?? DateTime.now();
    final seconds = completedAt.difference(session.startedAt).inSeconds;
    final record = WorkoutRecord(
      id: completedAt.microsecondsSinceEpoch.toString(),
      workoutName: session.workout.name,
      completedAt: completedAt,
      durationSeconds: seconds < 0 ? 0 : seconds,
      exerciseCount: session.workout.moves.length,
    );
    try {
      final updated = [record, ..._records];
      await _store.saveRecords(updated);
      _records = updated;
      _activeSession = null;
      return true;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
