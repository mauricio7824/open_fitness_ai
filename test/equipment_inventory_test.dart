import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fitness_ai/core/data/fitness_store.dart';
import 'package:open_fitness_ai/core/models/equipment.dart';
import 'package:open_fitness_ai/core/models/user_preferences.dart';

import 'navigation_test.dart'
    show openApp, selectTab, tapVisible, tapInventoryItem;
import 'support/memory_fitness_store.dart';

Future<void> openEditor(WidgetTester tester, MemoryFitnessStore store) async {
  await openApp(tester, store);
  await selectTab(tester, 'nav-exercises');
  await tapVisible(
    tester,
    find.byKey(const ValueKey('library-edit-inventory')),
  );
}

Future<void> search(WidgetTester tester, String text) async {
  final field = find.byKey(const ValueKey('inventory-search'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Busca por sinónimo e inglés, selecciona varios y persiste al reabrir',
    (tester) async {
      final store = MemoryFitnessStore();
      await openEditor(tester, store);
      await search(tester, 'multipower');
      expect(
        find.byKey(const ValueKey('inventory-smith-machine')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('inventory-barbell')), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-smith-machine')),
      );
      await search(tester, 'low pulley');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-low-pulley')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(store.data.preferences!.inventory!.availableIds, {
        'smith-machine',
        'low-pulley',
      });
      await tester.pumpWidget(const SizedBox());
      await openEditor(tester, store);
      await search(tester, 'multipower');
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('inventory-smith-machine')),
            )
            .value,
        isTrue,
      );
      expect(
        store.data.preferences!.inventory!.stateOf('barbell'),
        EquipmentAvailability.unknown,
      );
    },
  );

  testWidgets(
    'Distingue estados no disponible y sin declarar y permite filtrar',
    (tester) async {
      final store = MemoryFitnessStore();
      await openEditor(tester, store);
      await tapInventoryItem(tester, 'dumbbells');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-dumbbells')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-state-unavailable')),
      );
      expect(find.byKey(const ValueKey('inventory-dumbbells')), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(
        store.data.preferences!.inventory!.stateOf('dumbbells'),
        EquipmentAvailability.unavailable,
      );
      expect(store.data.preferences!.inventory!.availableIds, isEmpty);
    },
  );

  testWidgets(
    'Las propuestas requieren confirmación y no seleccionan todo un gimnasio',
    (tester) async {
      final store = MemoryFitnessStore();
      await openEditor(tester, store);
      await tapVisible(tester, find.byKey(const ValueKey('preset-gym')));
      expect(find.text('Propuesta: Gimnasio'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(store.data.preferences!.inventory, isNull);
      await tapVisible(tester, find.byKey(const ValueKey('preset-gym')));
      await tester.tap(find.text('Añadir propuesta'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(store.data.preferences!.inventory!.availableIds, {
        'dumbbells',
        'barbell',
        'bench',
      });
      expect(
        store.data.preferences!.inventory!.stateOf('cableMachine'),
        EquipmentAvailability.unknown,
      );
    },
  );

  testWidgets(
    'Crea un equipo personalizado y conserva su ID al editarlo y restaurarlo',
    (tester) async {
      final store = MemoryFitnessStore();
      await openEditor(tester, store);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('add-custom-equipment')),
      );
      for (final entry in {
        'custom-name': 'Agarre artesanal',
        'custom-english': 'Handmade handle',
        'custom-aliases': 'Asa personal',
        'custom-description': 'Asa de entrenamiento de uso personal.',
      }.entries) {
        await tester.ensureVisible(find.byKey(ValueKey(entry.key)));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      await tapVisible(
        tester,
        find.byKey(const ValueKey('custom-modality-home')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('save-custom-equipment')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      final original =
          store.data.preferences!.inventory!.customEquipment.single;
      expect(original.id, startsWith('custom-'));
      expect(
        store.data.preferences!.inventory!.availableIds,
        contains(original.id),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('library-edit-inventory')),
      );
      await search(tester, 'Asa personal');
      await tapVisible(tester, find.byKey(ValueKey('edit-${original.id}')));
      await tester.enterText(
        find.byKey(const ValueKey('custom-name')),
        'Agarre artesanal azul',
      );
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('save-custom-equipment')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(
        store.data.preferences!.inventory!.customEquipment.single.id,
        original.id,
      );
      await tester.pumpWidget(const SizedBox());
      await openEditor(tester, store);
      await search(tester, 'azul');
      expect(find.byKey(ValueKey('inventory-${original.id}')), findsOneWidget);
    },
  );

  testWidgets(
    'Plegar categorías no cambia selecciones y cancelar descarta el borrador',
    (tester) async {
      final store = MemoryFitnessStore()
        ..data = StoredFitnessData(
          preferences: UserPreferences(
            inventory: EquipmentInventory.fromAvailability({
              'dumbbells': EquipmentAvailability.available,
            }),
            setupStatus: SetupStatus.skipped,
          ),
        );
      await openEditor(tester, store);
      final title = find.text('Peso libre');
      await tapVisible(tester, title);
      expect(find.byKey(const ValueKey('inventory-dumbbells')), findsNothing);
      await tapVisible(tester, title);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('inventory-dumbbells')),
            )
            .value,
        isTrue,
      );
      await tapInventoryItem(tester, 'dumbbells');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(store.data.preferences!.inventory!.availableIds, {'dumbbells'});
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('Equipos legibles en $brightness con texto al 200 %', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await openEditor(tester, MemoryFitnessStore());
      await search(tester, 'dominadas asistidas');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('inventory-assisted-pullup-machine')),
      );
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        brightness,
      );
      await tapVisible(tester, find.byKey(const ValueKey('save-inventory')));
      expect(find.text('Explora los ejercicios'), findsOneWidget);
    });
  }
}
