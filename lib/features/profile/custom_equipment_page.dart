import 'package:flutter/material.dart';

import '../../core/models/equipment.dart';
import '../../core/models/training_modality.dart';
import '../../shared/widgets/fitness_widgets.dart';

class CustomEquipmentPage extends StatefulWidget {
  const CustomEquipmentPage({super.key, required this.catalog, this.previous});
  final EquipmentCatalog catalog;
  final EquipmentDefinition? previous;
  @override
  State<CustomEquipmentPage> createState() => _CustomEquipmentPageState();
}

class _CustomEquipmentPageState extends State<CustomEquipmentPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name,
      _english,
      _aliases,
      _description,
      _variants;
  EquipmentCategory _category = EquipmentCategory.functional;
  EquipmentKind _kind = EquipmentKind.implement;
  final Set<ExerciseModality> _modalities = {};
  String? _error;
  @override
  void initState() {
    super.initState();
    final item = widget.previous;
    _name = TextEditingController(text: item?.nameEs ?? '');
    _english = TextEditingController(text: item?.nameEn ?? '');
    _aliases = TextEditingController(text: item?.synonyms.join('; ') ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _variants = TextEditingController(text: item?.variants.join('; ') ?? '');
    _category = item?.category ?? _category;
    _kind = item?.kind ?? _kind;
    _modalities.addAll(item?.modalities ?? []);
  }

  @override
  void dispose() {
    for (final field in [_name, _english, _aliases, _description, _variants]) {
      field.dispose();
    }
    super.dispose();
  }

  List<String> _split(String text) => text
      .split(';')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  void _save() {
    if (!_form.currentState!.validate()) return;
    if (_modalities.isEmpty) {
      setState(() => _error = 'Selecciona al menos una modalidad.');
      return;
    }
    try {
      final definition = EquipmentDefinition(
        id:
            widget.previous?.id ??
            'custom-${DateTime.now().microsecondsSinceEpoch}',
        nameEs: _name.text.trim(),
        nameEn: _english.text.trim(),
        synonyms: _split(_aliases.text),
        category: _category,
        kind: _kind,
        modalities: _modalities,
        description: _description.text.trim(),
        variants: _split(_variants.text),
      );
      EquipmentCatalog([
        ...widget.catalog.equipment.where(
          (item) => item.id != widget.previous?.id,
        ),
        definition,
      ]);
      Navigator.pop(context, definition);
    } on FormatException catch (error) {
      setState(() => _error = error.message.toString());
    }
  }

  String? _required(String? text) =>
      text == null || text.trim().isEmpty ? 'Completa este campo.' : null;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Equipo personalizado')),
    body: SafeArea(
      top: false,
      child: Form(
        key: _form,
        child: PageContent(
          children: [
            const PageHeading(
              title: 'Describe tu equipo',
              subtitle: 'El nombre no crea equivalencias automáticas con otro material.',
            ),
            TextFormField(
              key: const ValueKey('custom-name'),
              controller: _name,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Nombre en español'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('custom-english'),
              controller: _english,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Nombre en inglés'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('custom-aliases'),
              controller: _aliases,
              decoration: const InputDecoration(
                labelText: 'Sinónimos separados por punto y coma',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EquipmentCategory>(
              key: const ValueKey('custom-category'),
              initialValue: _category,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final item in EquipmentCategory.values)
                  DropdownMenuItem(value: item, child: Text(item.label)),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EquipmentKind>(
              initialValue: _kind,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final entry in {
                  EquipmentKind.implement: 'Implemento',
                  EquipmentKind.machine: 'Máquina',
                  EquipmentKind.accessory: 'Accesorio',
                  EquipmentKind.support: 'Soporte',
                  EquipmentKind.environment: 'Entorno',
                  EquipmentKind.bodyweight: 'Peso corporal',
                }.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _kind = value!),
            ),
            const SectionHeading(title: 'Modalidades compatibles'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in ExerciseModality.values)
                  FilterChip(
                    key: ValueKey('custom-modality-${item.name}'),
                    label: Text(item.label),
                    selected: _modalities.contains(item),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _modalities.add(item)
                          : _modalities.remove(item);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('custom-description'),
              controller: _description,
              validator: _required,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('custom-variants'),
              controller: _variants,
              decoration: const InputDecoration(
                labelText: 'Configuraciones separadas por punto y coma',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('save-custom-equipment'),
              onPressed: _save,
              child: const Text('Usar este equipo'),
            ),
          ],
        ),
      ),
    ),
  );
}
