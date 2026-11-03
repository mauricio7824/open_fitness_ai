import 'package:flutter/material.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/fitness_models.dart';
import 'package:open_fitness_ai/core/models/user_preferences.dart';

class MemoryFitnessStore implements FitnessStore {
  // Existing navigation scenarios represent a user who skipped setup.
  StoredFitnessData data = StoredFitnessData(
    preferences: UserPreferences(setupStatus: SetupStatus.skipped),
  );
  bool failRead = false;
  bool failWrite = false;
  int recordWrites = 0;

  @override
  Future<StoredFitnessData> load() async {
    if (failRead) throw StateError('Read failed');
    return data;
  }

  @override
  Future<void> saveTheme(ThemeMode mode) async {
    if (failWrite) throw StateError('Write failed');
    data = StoredFitnessData(
      themeMode: mode,
      records: data.records,
      preferences: data.preferences,
    );
  }

  @override
  Future<void> saveRecords(List<WorkoutRecord> records) async {
    if (failWrite) throw StateError('Write failed');
    recordWrites++;
    data = StoredFitnessData(
      themeMode: data.themeMode,
      records: List.of(records),
      preferences: data.preferences,
    );
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    if (failWrite) throw StateError('Write failed');
    data = StoredFitnessData(
      themeMode: data.themeMode,
      records: data.records,
      preferences: preferences,
    );
  }
}
