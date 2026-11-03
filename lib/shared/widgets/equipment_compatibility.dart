import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import '../../core/models/user_preferences.dart';
import '../../core/models/equipment.dart';

class EquipmentCompatibility extends StatelessWidget {
  const EquipmentCompatibility({
    super.key,
    required this.exercise,
    required this.inventory,
    this.catalog,
  });
  final Exercise exercise;
  final EquipmentInventory? inventory;
  final EquipmentCatalog? catalog;
  @override
  Widget build(BuildContext context) {
    final result = inventory?.check(exercise);
    final compatible = result?.compatible ?? false;
    String equipmentLabel(String id) =>
        catalog?.label(id) ??
        ExerciseEquipment.values
            .where((item) => item.name == id)
            .firstOrNull
            ?.label ??
        id;
    final label = result == null
        ? 'Inventario sin configurar'
        : result.explain(equipmentLabel);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          result == null
              ? Icons.help_outline
              : compatible
              ? Icons.check_circle_outline
              : Icons.inventory_2_outlined,
          size: 20,
          color: compatible
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}
