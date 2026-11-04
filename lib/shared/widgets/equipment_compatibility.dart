import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import '../../core/models/user_preferences.dart';

class EquipmentCompatibility extends StatelessWidget {
  const EquipmentCompatibility({
    super.key,
    required this.exercise,
    required this.inventory,
  });
  final Exercise exercise;
  final EquipmentInventory? inventory;
  @override
  Widget build(BuildContext context) {
    final missing = inventory?.missingFor(exercise);
    final compatible = missing?.isEmpty ?? false;
    final label = missing == null
        ? 'Inventario sin configurar'
        : compatible
        ? 'Compatible con tu equipo'
        : 'Te falta: ${missing.map((item) => item.label).join(', ')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          missing == null
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
