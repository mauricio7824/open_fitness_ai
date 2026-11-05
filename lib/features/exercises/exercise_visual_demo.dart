import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/data/exercise_media_repository.dart';
import '../../core/models/exercise.dart';
import '../../shared/widgets/fitness_widgets.dart';

class ExerciseVisualDemo extends StatefulWidget {
  const ExerciseVisualDemo({
    super.key,
    required this.resources,
    this.loader,
    this.illustrationPlan,
  });
  final List<ExerciseResource> resources;
  final ExerciseMediaLoader? loader;
  final ExerciseIllustrationPlan? illustrationPlan;

  @override
  State<ExerciseVisualDemo> createState() => _ExerciseVisualDemoState();
}

class _ExerciseVisualDemoState extends State<ExerciseVisualDemo> {
  late ExerciseMediaLoader _loader =
      widget.loader ?? AssetExerciseMediaLoader();

  @override
  void didUpdateWidget(ExerciseVisualDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) {
      _loader = widget.loader ?? AssetExerciseMediaLoader();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SemanticsHeading(title: 'Demostración visual'),
      if (widget.resources.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Este ejercicio todavía no tiene una demostración visual disponible.',
                ),
                SizedBox(height: 8),
                Text(
                  'Puedes consultar la preparación y los pasos de este ejercicio sin conexión.',
                ),
              ],
            ),
          ),
        )
      else ...[
        const Text(
          'Abre un recurso para consultarlo. Las secuencias se recorren a tu ritmo, sin reproducción automática.',
        ),
        for (final resource in widget.resources)
          _ResourceCard(
            key: ValueKey(resource.id),
            resource: resource,
            loader: _loader,
          ),
      ],
      if (widget.illustrationPlan case final plan?)
        if (!widget.resources.any((resource) => resource.id == plan.resourceId))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ilustraciones pendientes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Se han preparado tres fases para ilustrar. Los archivos originales todavía no están disponibles; este guion no es una demostración visual.',
                  ),
                  for (final phase in plan.phases) ...[
                    const SizedBox(height: 12),
                    Text('${phase.title}: ${phase.description}'),
                  ],
                ],
              ),
            ),
          ),
    ],
  );
}

class SemanticsHeading extends StatelessWidget {
  const SemanticsHeading({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: SectionHeading(title: title));
}

class _ResourceCard extends StatefulWidget {
  const _ResourceCard({
    super.key,
    required this.resource,
    required this.loader,
  });
  final ExerciseResource resource;
  final ExerciseMediaLoader loader;
  @override
  State<_ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<_ResourceCard> {
  bool _expanded = false;
  int _index = 0;

  @override
  void didUpdateWidget(_ResourceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    final sequence = resource.kind == ExerciseResourceKind.imageSequence;
    final frame = sequence ? resource.frames[_index] : null;
    final pending = resource.editorial.status == EditorialStatus.pending;
    final technical = resource.technicalReview;
    final technicallyReviewed =
        technical?.status == TechnicalReviewStatus.reviewed;
    return Card(
      child: ExpansionTile(
        key: ValueKey('media-${resource.id}'),
        title: Text(resource.title),
        subtitle: Text(
          '${resource.kind.label} · ${pending ? 'Revisión editorial pendiente' : 'Revisado editorialmente'} · ${technicallyReviewed ? 'Revisión técnica registrada' : 'Revisión técnica pendiente'}',
        ),
        onExpansionChanged: (value) => setState(() => _expanded = value),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: _expanded
            ? [
                Text(
                  pending
                      ? 'Recurso pendiente de revisión editorial.'
                      : 'Recurso revisado editorialmente.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  technicallyReviewed
                      ? 'Revisión técnica registrada. Este recurso no evalúa tu técnica personal.'
                      : 'Revisión técnica pendiente. No validado técnicamente.',
                ),
                const SizedBox(height: 12),
                Text(resource.altText),
                const SizedBox(height: 12),
                if (sequence) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Fase ${_index + 1} de ${resource.frames.length}: ${frame!.title}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(frame.altText),
                  const SizedBox(height: 12),
                ],
                if (resource.kind == ExerciseResourceKind.video) ...[
                  const Text(
                    'La reproducción de video todavía no está disponible. Puedes leer su descripción y transcripción.',
                  ),
                  Text('Duración declarada: ${resource.durationSeconds} s'),
                  const SizedBox(height: 8),
                  const SemanticsHeading(title: 'Transcripción del video'),
                  Text(resource.transcript!),
                  if (resource.location!.url case final url?) ...[
                    const Text(
                      'Referencia externa; no se descarga automáticamente.',
                    ),
                    SelectableText(url.toString()),
                  ],
                ] else
                  _LocalImage(
                    key: ValueKey('${resource.id}-${frame?.id ?? 'image'}'),
                    location: frame?.location ?? resource.location!,
                    loader: widget.loader,
                  ),
                if (sequence) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        key: ValueKey('media-previous-${resource.id}'),
                        onPressed: _index == 0
                            ? null
                            : () => setState(() => _index--),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Fase anterior'),
                      ),
                      OutlinedButton.icon(
                        key: ValueKey('media-next-${resource.id}'),
                        onPressed: _index == resource.frames.length - 1
                            ? null
                            : () => setState(() => _index++),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Fase siguiente'),
                      ),
                    ],
                  ),
                ],
                const SemanticsHeading(
                  title: 'Atribución y revisión del recurso',
                ),
                Text(resource.attribution),
                Text('Autoría: ${resource.creator}'),
                Text('Licencia: ${resource.license}'),
                SelectableText(resource.sourceUrl.toString()),
                SelectableText(resource.licenseUrl.toString()),
                Text(resource.editorial.notes),
                Text(
                  'Actualizado: ${formatDate(context, resource.editorial.updatedOn)}',
                ),
                if (resource.editorial.reviewer case final reviewer?)
                  Text(
                    'Revisión: $reviewer · ${formatDate(context, resource.editorial.reviewedOn!)}',
                  ),
                if (technical != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Revisión técnica: ${technical.status == TechnicalReviewStatus.reviewed ? 'registrada' : 'pendiente'}',
                  ),
                  Text(technical.notes),
                  Text(
                    'Contenido técnico actualizado: ${formatDate(context, technical.updatedOn)}',
                  ),
                  if (technical.reviewer case final reviewer?)
                    Text(
                      'Responsable técnico: $reviewer · ${formatDate(context, technical.reviewedOn!)}',
                    ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Las instrucciones escritas siguen disponibles aunque el recurso visual no pueda mostrarse.',
                ),
              ]
            : const [],
      ),
    );
  }
}

class _LocalImage extends StatefulWidget {
  const _LocalImage({super.key, required this.location, required this.loader});
  final ExerciseMediaLocation location;
  final ExerciseMediaLoader loader;
  @override
  State<_LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<_LocalImage> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bytes = widget.location.isLocal
        ? widget.loader.loadImage(widget.location)
        : null;
  }

  @override
  void didUpdateWidget(_LocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.loader != widget.loader) {
      _load();
    }
  }

  Widget _unavailable() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'No se pudo mostrar la imagen local. La descripción y las instrucciones siguen disponibles.',
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar imagen'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.location.isLocal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Imagen externa: no está guardada para usarla sin conexión y no se descarga automáticamente.',
          ),
          SelectableText(widget.location.url.toString()),
        ],
      );
    }
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _unavailable();
        if (!snapshot.hasData) return const Text('Cargando imagen local…');
        return Image.memory(
          snapshot.data!,
          height: 240,
          width: double.infinity,
          cacheWidth: 1280,
          fit: BoxFit.contain,
          excludeFromSemantics:
              true, // The equivalent description is visible above.
          errorBuilder: (_, _, _) => _unavailable(),
        );
      },
    );
  }
}
