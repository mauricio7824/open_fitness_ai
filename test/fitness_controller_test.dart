import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/fitness_catalog.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/fitness_models.dart';
import 'package:open_fitness_ai/core/state/fitness_controller.dart';

import 'support/memory_fitness_store.dart';

void main() {
  late MemoryFitnessStore store;
  late FitnessController controller;
  setUp(() {
    store = MemoryFitnessStore();
    controller = FitnessController(store);
  });
  tearDown(() => controller.dispose());

  test('No guarda sesiones incompletas y evita duplicados', () async {
    await controller.initialize();
    controller.startWorkout(workouts.first);
    controller.toggleMove(0);
    expect(await controller.finishWorkout(), isFalse);
    controller.startWorkout(workouts.last);
    expect(controller.activeSession!.workout, workouts.first);
    for (var index = 1; index < workouts.first.moves.length; index++) {
      controller.toggleMove(index);
    }
    expect(await controller.finishWorkout(), isTrue);
    expect(await controller.finishWorkout(), isFalse);
    expect(store.recordWrites, 1);
    expect(controller.records, hasLength(1));
    expect(controller.activeSession, isNull);
  });

  test(
    'Conserva la sesión si falla el guardado y permite reintentar',
    () async {
      await controller.initialize();
      controller.startWorkout(workouts.last);
      for (var index = 0; index < workouts.last.moves.length; index++) {
        controller.toggleMove(index);
      }
      store.failWrite = true;
      await expectLater(controller.finishWorkout(), throwsStateError);
      expect(controller.activeSession!.isComplete, isTrue);
      expect(controller.records, isEmpty);
      expect(controller.saving, isFalse);
      store.failWrite = false;
      expect(await controller.finishWorkout(), isTrue);
    },
  );

  test('Descartar y desmarcar no producen historial', () async {
    await controller.initialize();
    controller.startWorkout(workouts.first);
    controller.toggleMove(0);
    controller.toggleMove(0);
    controller.toggleMove(-1);
    controller.toggleMove(100);
    expect(controller.activeSession!.completedMoves, isEmpty);
    controller.discardSession();
    expect(controller.activeSession, isNull);
    expect(store.data.records, isEmpty);
  });

  test('Cuenta la semana de lunes a domingo y ordena el historial', () async {
    WorkoutRecord record(int day) => WorkoutRecord(
      id: '$day',
      workoutName: 'Rutina',
      completedAt: DateTime(2026, 11, day, 12),
      durationSeconds: 60,
      exerciseCount: 3,
    );
    store.data = StoredFitnessData(
      records: [record(1), record(2), record(8), record(9)],
    );
    await controller.initialize();
    expect(controller.sessionsThisWeek(DateTime(2026, 11, 3)), 2);
    expect(controller.records.first.completedAt.day, 9);
  });

  test('Un fallo de escritura no cambia la apariencia guardada', () async {
    await controller.initialize();
    store.failWrite = true;
    await expectLater(
      controller.setThemeMode(ThemeMode.dark),
      throwsStateError,
    );
    expect(controller.themeMode, ThemeMode.system);
  });
}
