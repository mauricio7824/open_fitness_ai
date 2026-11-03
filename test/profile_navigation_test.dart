import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/exercise.dart';
import 'package:open_fitness_ai/core/models/user_preferences.dart';

import 'navigation_test.dart' show openApp, selectTab, selectFilter, tapVisible;
import 'support/memory_fitness_store.dart';
import 'user_preferences_test.dart' show exampleProfile;

Future<void> fillProfile(WidgetTester tester) async {
  await selectFilter(tester, 'profile-experience', 'Estoy empezando');
  await tapVisible(tester, find.byKey(const ValueKey('profile-modality-home')));
  await tapVisible(
    tester,
    find.byKey(const ValueKey('profile-goal-consistency')),
  );
  await tapVisible(tester, find.byKey(const ValueKey('profile-day-monday')));
  await tester.ensureVisible(find.byKey(const ValueKey('profile-minutes')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('profile-minutes')), '30');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'La configuración inicial puede omitirse y no reaparece al reabrir',
    (tester) async {
      final store = MemoryFitnessStore()..data = const StoredFitnessData();
      await openApp(tester, store);
      expect(find.text('Haz la app tuya'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('skip-setup')));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(store.data.preferences!.setupStatus, SetupStatus.skipped);
      await tester.pumpWidget(const SizedBox());
      await openApp(tester, store);
      expect(find.text('Haz la app tuya'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Perfil y equipamiento'), findsOneWidget);
    },
  );

  testWidgets(
    'Completa la configuración inicial y restaura perfil e inventario',
    (tester) async {
      final store = MemoryFitnessStore()..data = const StoredFitnessData();
      await openApp(tester, store);
      await tapVisible(tester, find.byKey(const ValueKey('edit-profile')));
      await fillProfile(tester);
      await tapVisible(tester, find.byKey(const ValueKey('save-profile')));
      expect(find.text('Duración habitual: 30 min'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('edit-inventory')));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-dumbbells')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('inventory-bench')));
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(store.data.preferences!.setupStatus, SetupStatus.completed);
      await tester.pumpWidget(const SizedBox());
      await openApp(tester, store);
      await tester.tap(find.byKey(const ValueKey('open-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Duración habitual: 30 min'), findsOneWidget);
      expect(find.text('Mancuernas, Banco'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('edit-profile')));
      expect(find.widgetWithText(FilterChip, 'Casa'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('profile-modality-home')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('profile-minutes')),
            )
            .controller!
            .text,
        '30',
      );
    },
  );

  testWidgets(
    'Valida el formulario y conserva cambios ante un fallo de escritura',
    (tester) async {
      final store = MemoryFitnessStore();
      await openApp(tester, store);
      await tester.tap(find.byKey(const ValueKey('open-profile')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('edit-profile')));
      await tapVisible(tester, find.byKey(const ValueKey('save-profile')));
      expect(find.text('Selecciona tu experiencia.'), findsOneWidget);
      expect(find.text('Selecciona al menos una opción.'), findsNWidgets(3));
      await fillProfile(tester);
      store.failWrite = true;
      await tapVisible(tester, find.byKey(const ValueKey('save-profile')));
      expect(
        find.text('No se pudo guardar el perfil. Tus cambios siguen aquí.'),
        findsOneWidget,
      );
      expect(store.data.preferences!.profile, isNull);
      expect(find.text('Editar perfil deportivo'), findsOneWidget);
      store.failWrite = false;
      // Allow the error snackbar to leave the bottom action before retrying.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('save-profile')));
      expect(store.data.preferences!.profile!.sessionMinutes, 30);
    },
  );

  testWidgets(
    'Inventario exige una elección explícita y cancelar no guarda cambios',
    (tester) async {
      final store = MemoryFitnessStore();
      await openApp(tester, store);
      await selectTab(tester, 'nav-exercises');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('library-edit-inventory')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(
        find.text('Selecciona material o marca «Sin material».'),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-dumbbells')),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(store.data.preferences!.inventory, isNull);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('library-edit-inventory')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('inventory-none')));
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(store.data.preferences!.inventory!.items, isEmpty);
    },
  );

  testWidgets(
    'La biblioteca conserva filtros y actualiza compatibilidad tras editar el equipo',
    (tester) async {
      final store = MemoryFitnessStore()
        ..data = StoredFitnessData(
          preferences: UserPreferences(
            profile: exampleProfile(),
            inventory: EquipmentInventory([ExerciseEquipment.dumbbells]),
            setupStatus: SetupStatus.completed,
          ),
        );
      await openApp(tester, store);
      await selectTab(tester, 'nav-exercises');
      await tester.enterText(find.byType(TextField), 'remo');
      await tester.pumpAndSettle();
      expect(find.text('Te falta: Banco'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('compatible-only')));
      expect(find.text('Sin coincidencias'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('library-edit-inventory')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('inventory-bench')));
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(find.text('1 ejercicio'), findsOneWidget);
      expect(find.text('Compatible con tu equipo'), findsOneWidget);
      expect(find.text('remo'), findsOneWidget);
    },
  );

  testWidgets(
    'Las alternativas se actualizan en el detalle sin perder la ruta',
    (tester) async {
      final store = MemoryFitnessStore()
        ..data = StoredFitnessData(
          preferences: UserPreferences(
            inventory: EquipmentInventory([]),
            setupStatus: SetupStatus.skipped,
          ),
        );
      await openApp(tester, store);
      await selectTab(tester, 'nav-exercises');
      await tester.enterText(find.byType(TextField), 'flexiones');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('exercise-pushup')));
      expect(
        find.byKey(const ValueKey('alternative-knee-pushup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('alternative-wall-pushup')),
        findsNothing,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('detail-edit-inventory')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('inventory-wall')));
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(find.text('Detalle del ejercicio'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('alternative-wall-pushup')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Filtra modalidades preferidas sin ocultar permanentemente el catálogo',
    (tester) async {
      final store = MemoryFitnessStore()
        ..data = StoredFitnessData(
          preferences: UserPreferences(
            profile: SportsProfile(
              experience: TrainingExperience.intermediate,
              modalities: [ExerciseModality.calisthenics],
              goals: [ActivityGoal.strength],
              availableDays: [AvailableDay.friday],
              sessionMinutes: 20,
            ),
            setupStatus: SetupStatus.skipped,
          ),
        );
      await openApp(tester, store);
      await selectTab(tester, 'nav-exercises');
      expect(find.text('18 ejercicios'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('preferred-modalities-only')),
      );
      expect(find.byKey(const ValueKey('exercise-biceps-curl')), findsNothing);
      await tapVisible(tester, find.byKey(const ValueKey('reset-filters')));
      expect(find.text('18 ejercicios'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('exercise-biceps-curl')),
        findsOneWidget,
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Perfil e inventario adaptables en $brightness y texto ampliado',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final store = MemoryFitnessStore()..data = const StoredFitnessData();
        await openApp(tester, store);
        await tapVisible(tester, find.byKey(const ValueKey('edit-profile')));
        await tester.ensureVisible(find.byKey(const ValueKey('save-profile')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('edit-inventory')));
        await tester.ensureVisible(
          find.byKey(const ValueKey('save-inventory')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
          brightness,
        );
      },
    );
  }
}
