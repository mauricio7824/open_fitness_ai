import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/app.dart';

import 'support/memory_fitness_store.dart';

Future<void> openApp(WidgetTester tester, MemoryFitnessStore store) async {
  await tester.pumpWidget(OpenFitnessApp(store: store));
  await tester.pumpAndSettle();
}

Future<void> selectTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  testWidgets('Navega por las cuatro pestañas y conserva la búsqueda', (
    tester,
  ) async {
    await openApp(tester, MemoryFitnessStore());
    expect(find.text('Tu próximo paso empieza hoy'), findsOneWidget);
    await selectTab(tester, 'nav-workouts');
    expect(find.text('Encuentra tu ritmo'), findsOneWidget);
    await selectTab(tester, 'nav-exercises');
    await tester.enterText(find.byType(TextField), 'gluteos');
    await tester.pumpAndSettle();
    expect(find.text('Puente de glúteos'), findsOneWidget);
    expect(find.text('Sentadilla'), findsNothing);
    await selectTab(tester, 'nav-progress');
    expect(find.text('Tu historia empieza aquí'), findsOneWidget);
    await selectTab(tester, 'nav-exercises');
    expect(find.text('gluteos'), findsOneWidget);
    await tapVisible(tester, find.text('Puente de glúteos'));
    expect(find.text('Cómo realizarlo'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await selectTab(tester, 'nav-home');
    expect(find.text('Tu próximo paso empieza hoy'), findsOneWidget);
  });

  testWidgets('Busca, filtra y muestra el estado sin resultados', (
    tester,
  ) async {
    await openApp(tester, MemoryFitnessStore());
    await selectTab(tester, 'nav-exercises');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Zona media'));
    await tester.pumpAndSettle();
    expect(find.text('2 ejercicios'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'sentadilla');
    await tester.pumpAndSettle();
    expect(find.text('Sin coincidencias'), findsOneWidget);
    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('2 ejercicios'), findsOneWidget);
  });

  testWidgets(
    'Completa una sesión, la retoma y restaura el historial al reabrir',
    (tester) async {
      final store = MemoryFitnessStore();
      await openApp(tester, store);
      await tapVisible(tester, find.text('Comenzar entrenamiento'));
      await tapVisible(tester, find.text('Iniciar sesión'));
      final finish = find.widgetWithText(FilledButton, 'Finalizar y guardar');
      expect(tester.widget<FilledButton>(finish).onPressed, isNull);
      await tapVisible(tester, find.byKey(const ValueKey('move-0')));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await selectTab(tester, 'nav-progress');
      expect(find.text('Tu historia empieza aquí'), findsOneWidget);
      await selectTab(tester, 'nav-home');
      await tapVisible(tester, find.text('Continuar sesión'));
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const ValueKey('move-0')))
            .value,
        isTrue,
      );
      for (var index = 1; index < 4; index++) {
        await tapVisible(tester, find.byKey(ValueKey('move-$index')));
      }
      await tapVisible(tester, finish);
      expect(store.recordWrites, 1);
      await selectTab(tester, 'nav-progress');
      expect(find.text('Cuerpo completo'), findsOneWidget);
      expect(find.text('Tu historia empieza aquí'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await openApp(tester, store);
      await selectTab(tester, 'nav-progress');
      expect(find.text('Cuerpo completo'), findsOneWidget);
      expect(store.data.records, hasLength(1));
    },
  );

  testWidgets('Permite descartar con confirmación sin registrar progreso', (
    tester,
  ) async {
    final store = MemoryFitnessStore();
    await openApp(tester, store);
    await tapVisible(tester, find.text('Comenzar entrenamiento'));
    await tapVisible(tester, find.text('Iniciar sesión'));
    await tapVisible(tester, find.text('Descartar sesión'));
    await tester.tap(find.text('Seguir entrenando'));
    await tester.pumpAndSettle();
    expect(find.text('Tu entrenamiento'), findsOneWidget);
    await tapVisible(tester, find.text('Descartar sesión'));
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar entrenamiento'), findsOneWidget);
    expect(store.data.records, isEmpty);
  });

  testWidgets(
    'Cambia entre tema oscuro, claro y sistema y restaura la preferencia',
    (tester) async {
      final store = MemoryFitnessStore();
      await openApp(tester, store);
      for (final entry in [
        ('Modo oscuro', ThemeMode.dark),
        ('Modo claro', ThemeMode.light),
        ('Usar tema del sistema', ThemeMode.system),
        ('Modo oscuro', ThemeMode.dark),
      ]) {
        await tester.tap(find.byTooltip('Cambiar apariencia'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is CheckedPopupMenuItem<ThemeMode> &&
                widget.value == entry.$2,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          entry.$2,
        );
        expect(store.data.themeMode, entry.$2);
      }
      await tester.pumpWidget(const SizedBox());
      await openApp(tester, store);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.dark,
      );
    },
  );

  testWidgets('Muestra error de lectura y permite reintentar', (tester) async {
    final store = MemoryFitnessStore()..failRead = true;
    await openApp(tester, store);
    expect(find.text('No pudimos abrir tus datos'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(412, 915),
    const Size(1024, 768),
  ]) {
    testWidgets('Navegación y sesión sin desbordamiento en $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await openApp(tester, MemoryFitnessStore());
      for (final tab in [
        'nav-workouts',
        'nav-exercises',
        'nav-progress',
        'nav-home',
      ]) {
        await selectTab(tester, tab);
        expect(tester.takeException(), isNull);
      }
      await tapVisible(tester, find.text('Comenzar entrenamiento'));
      await tapVisible(tester, find.text('Iniciar sesión'));
      for (var index = 0; index < 4; index++) {
        await tapVisible(tester, find.byKey(ValueKey('move-$index')));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Admite texto ampliado en un teléfono pequeño', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openApp(tester, MemoryFitnessStore());
    for (final tab in [
      'nav-workouts',
      'nav-exercises',
      'nav-progress',
      'nav-home',
    ]) {
      await selectTab(tester, tab);
      expect(tester.takeException(), isNull);
    }
  });
}
