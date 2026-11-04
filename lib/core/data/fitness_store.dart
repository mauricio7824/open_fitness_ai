import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fitness_models.dart';
import '../models/user_preferences.dart';

class StoredFitnessData {
  const StoredFitnessData({
    this.themeMode = ThemeMode.system,
    this.records = const [],
    this.preferences,
  });
  final ThemeMode themeMode;
  final List<WorkoutRecord> records;
  final UserPreferences? preferences;
}

abstract interface class FitnessStore {
  Future<StoredFitnessData> load();
  Future<void> saveTheme(ThemeMode mode);
  Future<void> saveRecords(List<WorkoutRecord> records);
  Future<void> savePreferences(UserPreferences preferences);
}

class PreferencesFitnessStore implements FitnessStore {
  PreferencesFitnessStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const _themeKey = 'open_fitness.theme.v1';
  static const _recordsKey = 'open_fitness.records.v1';
  static const _preferencesKey = 'open_fitness.personalization.v1';

  @override
  Future<StoredFitnessData> load() async {
    final theme = await _preferences.getString(_themeKey);
    final records = await _preferences.getString(_recordsKey);
    final preferences = await _preferences.getString(_preferencesKey);
    final decoded = records == null ? <dynamic>[] : jsonDecode(records);
    if (decoded is! List) {
      throw const FormatException('El historial no tiene un formato válido.');
    }
    return StoredFitnessData(
      preferences: preferences == null
          ? null
          : UserPreferences.fromJson(jsonDecode(preferences)),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == theme,
        orElse: () => ThemeMode.system,
      ),
      records: decoded.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Registro inválido en el historial.');
        }
        return WorkoutRecord.fromJson(entry);
      }).toList(),
    );
  }

  @override
  Future<void> saveTheme(ThemeMode mode) =>
      _preferences.setString(_themeKey, mode.name);

  @override
  Future<void> saveRecords(List<WorkoutRecord> records) =>
      _preferences.setString(
        _recordsKey,
        jsonEncode(records.map((record) => record.toJson()).toList()),
      );

  @override
  Future<void> savePreferences(UserPreferences preferences) =>
      _preferences.setString(_preferencesKey, jsonEncode(preferences.toJson()));
}
