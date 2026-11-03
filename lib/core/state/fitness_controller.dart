import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../models/fitness_models.dart';

class FitnessController extends ChangeNotifier {
  FitnessController(this._store);
  final FitnessStore _store;
  ThemeMode themeMode = ThemeMode.system;
  List<WorkoutRecord> _records = [];
  WorkoutSession? _activeSession;
  bool loading = true;
  bool loadFailed = false;
  bool _saving = false;
  bool _savingTheme = false;
  bool _disposed = false;

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
      themeMode = data.themeMode;
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
