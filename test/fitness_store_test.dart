import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/fitness_models.dart';

// In-memory plugin boundary; exercises the production repository's JSON codec.
class TestPreferences implements SharedPreferencesAsync {
  final Map<String, String> values = {};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Un almacenamiento vacío usa el tema del sistema y no inventa progreso',
    () async {
      final data = await PreferencesFitnessStore(preferences: TestPreferences())
          .load();
      expect(data.themeMode, ThemeMode.system);
      expect(data.records, isEmpty);
    },
  );

  test(
    'Restaura tema e historial serializados en una nueva instancia',
    () async {
      final preferences = TestPreferences();
      final store = PreferencesFitnessStore(preferences: preferences);
      final record = WorkoutRecord(
        id: '1',
        workoutName: 'Cuerpo completo',
        completedAt: DateTime.utc(2026, 11, 3, 14),
        durationSeconds: 123,
        exerciseCount: 4,
      );
      await store.saveRecords([record]);
      await store.saveTheme(ThemeMode.dark);
      final restored = await PreferencesFitnessStore(preferences: preferences)
          .load();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.records.single.toJson(), record.toJson());
    },
  );

  test('Rechaza registros corruptos sin sobrescribirlos', () async {
    final preferences = TestPreferences();
    final store = PreferencesFitnessStore(preferences: preferences);
    await store.saveRecords([]);
    final key = preferences.values.keys.single;
    for (final invalid in ['invalid json', '{}', '[null]', '[{"id":"1"}]']) {
      preferences.values[key] = invalid;
      await expectLater(store.load(), throwsFormatException);
      expect(preferences.values[key], invalid);
    }
  });
}
