import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/data/fitness_store.dart';
import 'core/data/exercise_repository.dart';
import 'core/state/fitness_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/fitness_shell.dart';
import 'shared/widgets/fitness_widgets.dart';

class OpenFitnessApp extends StatefulWidget {
  const OpenFitnessApp({
    super.key,
    required this.store,
    this.exerciseRepository,
  });
  final FitnessStore store;
  final ExerciseRepository? exerciseRepository;
  @override
  State<OpenFitnessApp> createState() => _OpenFitnessAppState();
}

class _OpenFitnessAppState extends State<OpenFitnessApp> {
  late final FitnessController _controller;
  @override
  void initState() {
    super.initState();
    _controller = FitnessController(
      widget.store,
      exerciseRepository: widget.exerciseRepository,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => MaterialApp(
      title: 'Open Fitness AI',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: _controller.themeMode,
      home: _controller.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _controller.loadFailed
          ? Scaffold(
              body: SafeArea(
                child: Center(
                  child: PageContent(
                    children: [
                      EmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'No pudimos abrir tus datos',
                        message: 'Tu historial no se ha sobrescrito. Intenta cargarlo de nuevo.',
                        action: FilledButton(
                          onPressed: _controller.initialize,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : FitnessShell(controller: _controller),
    ),
  );
}
