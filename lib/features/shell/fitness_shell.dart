import 'package:flutter/material.dart';

import '../../core/state/fitness_controller.dart';
import '../home/home_page.dart';
import '../exercises/exercises_page.dart';
import '../progress/progress_page.dart';
import '../workouts/workouts_page.dart';

class FitnessShell extends StatefulWidget {
  const FitnessShell({super.key, required this.controller});
  final FitnessController controller;
  @override
  State<FitnessShell> createState() => _FitnessShellState();
}

class _FitnessShellState extends State<FitnessShell> {
  int _selectedIndex = 0;
  void _select(int index) => setState(() => _selectedIndex = index);

  Future<void> _setTheme(ThemeMode mode) async {
    try {
      await widget.controller.setThemeMode(mode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la apariencia. Inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Open Fitness AI',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<ThemeMode>(
          tooltip: 'Cambiar apariencia',
          icon: const Icon(Icons.contrast_rounded),
          initialValue: widget.controller.themeMode,
          onSelected: _setTheme,
          itemBuilder: (context) => [
            for (final entry in const {
              ThemeMode.system: 'Usar tema del sistema',
              ThemeMode.light: 'Modo claro',
              ThemeMode.dark: 'Modo oscuro',
            }.entries)
              CheckedPopupMenuItem(
                value: entry.key,
                checked: widget.controller.themeMode == entry.key,
                child: Text(entry.value),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      top: false,
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(controller: widget.controller, onWorkouts: () => _select(1)),
          WorkoutsPage(controller: widget.controller),
          ExercisesPage(catalog: widget.controller.catalog),
          ProgressPage(
            controller: widget.controller,
            onWorkouts: () => _select(1),
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _select,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          key: ValueKey('nav-home'),
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          key: ValueKey('nav-workouts'),
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: 'Entrenamientos',
        ),
        NavigationDestination(
          key: ValueKey('nav-exercises'),
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Ejercicios',
        ),
        NavigationDestination(
          key: ValueKey('nav-progress'),
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Progreso',
        ),
      ],
    ),
  );
}
