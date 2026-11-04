import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/exercise.dart';
import '../../core/models/user_preferences.dart';
import '../../core/state/fitness_controller.dart';
import '../../shared/widgets/fitness_widgets.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key, required this.controller});
  final FitnessController controller;
  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _minutes;
  TrainingExperience? _experience;
  final Set<ExerciseModality> _modalities = {};
  final Set<ActivityGoal> _goals = {};
  final Set<AvailableDay> _days = {};
  bool _saving = false;
  bool _validateSelections = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.preferences.profile;
    _experience = profile?.experience;
    _modalities.addAll(profile?.modalities ?? {});
    _goals.addAll(profile?.goals ?? {});
    _days.addAll(profile?.availableDays ?? {});
    _minutes = TextEditingController(
      text: profile?.sessionMinutes.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _validateSelections = true);
    if (!_form.currentState!.validate() ||
        _modalities.isEmpty ||
        _goals.isEmpty ||
        _days.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveProfile(
        SportsProfile(
          experience: _experience!,
          modalities: _modalities,
          goals: _goals,
          availableDays: _days,
          sessionMinutes: int.parse(_minutes.text),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el perfil. Tus cambios siguen aquí.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _error(bool empty) => _validateSelections && empty
      ? Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Selecciona al menos una opción.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        )
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar perfil deportivo')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: PageContent(
            children: [
              const PageHeading(
                title: 'Entrena a tu manera',
                subtitle:
                    'Cuéntanos cómo prefieres organizar tu actividad física.',
              ),
              DropdownButtonFormField<TrainingExperience>(
                key: const ValueKey('profile-experience'),
                initialValue: _experience,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Experiencia'),
                items: [
                  for (final item in TrainingExperience.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _experience = value),
                validator: (value) =>
                    value == null ? 'Selecciona tu experiencia.' : null,
              ),
              const SectionHeading(title: 'Modalidades preferidas'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in ExerciseModality.values)
                    FilterChip(
                      key: ValueKey('profile-modality-${item.name}'),
                      label: Text(item.label),
                      selected: _modalities.contains(item),
                      onSelected: _saving
                          ? null
                          : (selected) => setState(() {
                              selected
                                  ? _modalities.add(item)
                                  : _modalities.remove(item);
                            }),
                    ),
                ],
              ),
              _error(_modalities.isEmpty),
              const SectionHeading(title: 'Objetivos de actividad física'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in ActivityGoal.values)
                    FilterChip(
                      key: ValueKey('profile-goal-${item.name}'),
                      label: Text(item.label),
                      selected: _goals.contains(item),
                      onSelected: _saving
                          ? null
                          : (selected) => setState(() {
                              selected ? _goals.add(item) : _goals.remove(item);
                            }),
                    ),
                ],
              ),
              _error(_goals.isEmpty),
              const SectionHeading(title: 'Días disponibles'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in AvailableDay.values)
                    FilterChip(
                      key: ValueKey('profile-day-${item.name}'),
                      label: Text(item.label),
                      selected: _days.contains(item),
                      onSelected: _saving
                          ? null
                          : (selected) => setState(() {
                              selected ? _days.add(item) : _days.remove(item);
                            }),
                    ),
                ],
              ),
              _error(_days.isEmpty),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('profile-minutes'),
                controller: _minutes,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Duración habitual (minutos)',
                  helperText: 'Entre 5 y 180 minutos',
                ),
                validator: (value) {
                  final minutes = int.tryParse(value ?? '');
                  return minutes == null || minutes < 5 || minutes > 180
                      ? 'Introduce un valor entre 5 y 180.'
                      : null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('save-profile'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
