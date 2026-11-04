import 'package:flutter/material.dart';

import '../../core/state/fitness_controller.dart';
import '../../core/models/user_preferences.dart';
import '../../shared/widgets/fitness_widgets.dart';
import 'profile_editor_page.dart';
import 'inventory_editor_page.dart';

Future<void> openProfile(BuildContext context, FitnessController controller) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(controller: controller),
      ),
    );

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    this.initialSetup = false,
  });
  final FitnessController controller;
  final bool initialSetup;

  Future<void> _skip(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.skipSetup();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la configuración. Inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final profile = controller.preferences.profile;
      final inventory = controller.preferences.inventory;
      final busy = controller.savingPreferences;
      return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              initialSetup ? 'Open Fitness AI' : 'Perfil y equipamiento',
            ),
            automaticallyImplyLeading: !initialSetup,
          ),
          body: SafeArea(
            top: false,
            child: PageContent(
              children: [
                PageHeading(
                  title: initialSetup
                      ? 'Haz la app tuya'
                      : 'Tu espacio de entrenamiento',
                  subtitle: initialSetup
                      ? 'Configura tus preferencias o empieza ahora y complétalas después.'
                      : 'Edita tus preferencias y el material que tienes disponible.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(title: 'Perfil deportivo'),
                        if (profile == null)
                          const Text('Todavía no has configurado tu perfil.')
                        else ...[
                          Text('Experiencia: ${profile.experience.label}'),
                          const SizedBox(height: 8),
                          Text(
                            'Modalidades: ${profile.modalities.map((item) => item.label).join(', ')}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Objetivos: ${profile.goals.map((item) => item.label).join(', ')}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Días: ${AvailableDay.values.where(profile.availableDays.contains).map((item) => item.label).join(', ')}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Duración habitual: ${profile.sessionMinutes} min',
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          key: const ValueKey('edit-profile'),
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProfileEditorPage(
                                      controller: controller,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.person_outline),
                          label: Text(
                            profile == null
                                ? 'Configurar perfil'
                                : 'Editar perfil',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(title: 'Tu equipamiento'),
                        Text(
                          inventory?.displayLabel(
                                controller.equipmentCatalog,
                              ) ??
                              'Inventario sin configurar',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'La biblioteca comprobará el material obligatorio de cada ejercicio.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          key: const ValueKey('edit-inventory'),
                          onPressed: busy
                              ? null
                              : () => openInventory(context, controller),
                          icon: const Icon(Icons.fitness_center),
                          label: Text(
                            inventory == null
                                ? 'Configurar equipamiento'
                                : 'Editar equipamiento',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Estas preferencias se guardan en este dispositivo. No generan rutinas automáticas.',
                ),
                if (initialSetup) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    key: const ValueKey('skip-setup'),
                    onPressed: busy ? null : () => _skip(context),
                    child: Text(busy ? 'Guardando…' : 'Omitir por ahora'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
