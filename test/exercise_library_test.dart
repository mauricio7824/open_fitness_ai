import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/app.dart';

import 'support/memory_fitness_store.dart';
import 'support/test_exercise_catalog.dart';
import 'navigation_test.dart' show openApp, selectTab, selectFilter, tapVisible;

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Combina filtros, conserva selección entre pestañas y limpia todos',
    (tester) async {
      await openApp(tester, MemoryFitnessStore());
      await selectTab(tester, 'nav-exercises');
      await selectFilter(tester, 'filter-muscle', 'Espalda');
      await selectFilter(tester, 'filter-modality', 'Gimnasio');
      await selectFilter(tester, 'filter-equipment', 'Mancuernas');
      expect(find.text('1 ejercicio'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('exercise-dumbbell-row')),
        findsOneWidget,
      );
      await selectTab(tester, 'nav-home');
      await selectTab(tester, 'nav-exercises');
      expect(find.text('1 ejercicio'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('reset-filters')));
      expect(find.text('18 ejercicios'), findsOneWidget);
      expect(find.text('Todos los músculos'), findsOneWidget);
      expect(find.text('Todas las modalidades'), findsOneWidget);
      expect(find.text('Cualquier equipo'), findsOneWidget);
    },
  );

  testWidgets('Abre detalles y alternativas y vuelve conservando la búsqueda', (
    tester,
  ) async {
    await openApp(tester, MemoryFitnessStore());
    await selectTab(tester, 'nav-exercises');
    await tester.enterText(find.byType(TextField), 'flexiones');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('exercise-pushup')));
    expect(find.text('Detalle del ejercicio'), findsOneWidget);
    expect(find.text('Requisitos'), findsOneWidget);
    expect(find.text('Cómo realizarlo'), findsOneWidget);
    expect(find.text('Pendiente de revisión editorial'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('alternative-knee-pushup')),
    );
    expect(find.text('Flexiones con rodillas apoyadas'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Flexiones'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('flexiones'), findsOneWidget);
    expect(find.text('3 ejercicios'), findsOneWidget);
  });

  testWidgets(
    'Los detalles siguen disponibles desde una sesión sin perder sus marcas',
    (tester) async {
      await openApp(tester, MemoryFitnessStore());
      await tapVisible(tester, find.text('Comenzar entrenamiento'));
      await tapVisible(tester, find.text('Iniciar sesión'));
      await tapVisible(tester, find.byKey(const ValueKey('move-0')));
      await tapVisible(tester, find.text('Ver técnica').first);
      expect(find.text('Sentadilla'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const ValueKey('move-0')))
            .value,
        isTrue,
      );
    },
  );

  testWidgets(
    'Un error de catálogo permite reintentar sin sobrescribir datos',
    (tester) async {
      final store = MemoryFitnessStore();
      final repository = TestExerciseRepository()..failRead = true;
      await tester.pumpWidget(
        OpenFitnessApp(store: store, exerciseRepository: repository),
      );
      await tester.pumpAndSettle();
      expect(find.text('No pudimos abrir tus datos'), findsOneWidget);
      repository.failRead = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await selectTab(tester, 'nav-exercises');
      expect(find.text('18 ejercicios'), findsOneWidget);
      expect(store.recordWrites, 0);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Detalle y filtros adaptables en tema $brightness con texto al 200 %',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await openApp(tester, MemoryFitnessStore());
        await selectTab(tester, 'nav-exercises');
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'puente');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('exercise-bridge')));
        await tester.ensureVisible(find.text('Recursos y licencias'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
          brightness,
        );
        await tapVisible(tester, find.text('Entendido'));
        expect(find.text('1 ejercicio'), findsOneWidget);
      },
    );
  }
}
