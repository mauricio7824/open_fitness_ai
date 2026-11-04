# Catálogo local de ejercicios

El catálogo universal de equipamiento está en `equipment.v1.json`; su esquema, normalización, migración y motor de compatibilidad se documentan en [la guía de fase 4A](../../docs/equipment.md). Las 18 fichas de `exercises.v1.json` conservan su información actual. Pueden declarar requisitos estructurados explícitos mediante `equipmentRequirements`; si el campo falta, se interpretan sus listas de equipo anteriores.

`exercises.v1.json` se incluye como asset en `pubspec.yaml`. No depende de red, de una cuenta ni de una caché descargada previamente. `AssetExerciseRepository` lo lee; `ExerciseCatalog` valida el esquema y produce objetos inmutables. El repositorio conserva solo lecturas correctas y permite reintentar tras un error.

## Esquema 1

La raíz exige `schemaVersion: 1`, `catalogVersion` entero positivo y `exercises`, una lista no vacía. Cambia `catalogVersion` al actualizar el contenido. Un cambio incompatible de estructura necesita un nuevo esquema y adaptación del decodificador.

Cada ejercicio requiere:

| Campo | Contenido |
| --- | --- |
| `id` | ID estable con letras minúsculas ASCII, números y guiones. No reutilizar un ID para otro movimiento. |
| `name`, `description` | Textos en español. |
| `modalities` | Lista no vacía: `gym`, `home`, `calisthenics`. Puede incluir varias ubicaciones compatibles con los requisitos. |
| `primaryMuscles`, `secondaryMuscles` | Grupos tipados; al menos uno principal, sin duplicados ni solapamientos. |
| `requiredEquipment`, `optionalEquipment` | Listas separadas. Una lista obligatoria vacía representa «Sin material». |
| `difficulty` | `beginner`, `intermediate` o `advanced`; una clasificación editorial general. |
| `instructions` | Lista ordenada de al menos dos pasos no vacíos. |
| `requirements` | Condiciones de espacio, apoyos o uso del equipo. |
| `alternatives` | Objetos con `exerciseId` existente y `reason` en español. No admitir autorreferencias ni duplicados. |
| `sources` | Referencias efectivamente comprobadas; usar `[]` mientras falten. |
| `resources` | Metadatos de recursos locales; actualmente `[]` en todos los ejercicios. |
| `editorial` | Estado de revisión, fechas, responsable y notas. |

Los valores estables de músculos y equipo están en `lib/core/models/exercise.dart`; sus etiquetas visibles están en español. Añade una categoría al enum antes de utilizarla en el JSON: una categoría desconocida provoca un error de validación.

Los filtros combinan búsqueda por nombre, músculos principales/secundarios, modalidad y equipo obligatorio. Filtrar por una pieza de equipo no significa que sea la única necesaria; el detalle enumera todos los requisitos. El material opcional no interviene en el filtro.

## Fuentes, recursos y revisión

Una fuente contiene `title`, `publisher`, `url` HTTPS y `checkedOn` en formato `AAAA-MM-DD`. Conserva el título real de la publicación. Registrar una URL significa que se comprobó la referencia, no que el editor del sitio aprobó el contenido de esta app. La validación automática comprueba formato y duplicados; no certifica la veracidad ni los derechos de una fuente.

Antes de añadir una referencia, abre la página original, comprueba que describe el movimiento concreto y registra la fecha real. No deduzcas URLs ni inventes fechas, autores o publicaciones. Si falta verificación, deja la lista vacía y mantén la revisión pendiente. Las seis fuentes del catálogo inicial se consultaron el 3 de noviembre de 2026; las otras doce fichas no declaran fuentes comprobadas.

Un recurso necesita `kind` (`image` o `video`), `assetPath` dentro de `assets/`, `creator`, `sourceUrl`, `license` y `licenseUrl`. Además hay que incluir el archivo en el bundle, comprobar sus derechos de redistribución y añadir su renderizado: esta fase solo prepara los metadatos, no un visor multimedia. Una referencia bibliográfica no autoriza a descargar ni redistribuir sus fotos o videos.

`editorial` incluye:

- `status`: `pending` o `reviewed`.
- `updatedOn`: fecha del contenido.
- `reviewer`, `reviewedOn`: `null` mientras esté pendiente. No atribuir una revisión a una persona que no la realizó.
- `notes`: qué se comprobó y qué falta.

Marcar como revisado exige responsable, fecha de revisión no anterior a la actualización y al menos una fuente. Es una comprobación de integridad; la revisión debe realizarse realmente antes de cambiar el estado. Si se cambia el contenido después de revisarlo, vuelve a `pending` y elimina la firma anterior. **Las 18 fichas iniciales están pendientes.**

## Ampliar el catálogo

1. Añade una ficha completa con ID nuevo y conserva los seis IDs que utilizan las rutinas existentes: `squat`, `pushup`, `bridge`, `plank`, `lunge`, `bird-dog`.
2. Comprueba referencias y alternativas. Escribe instrucciones generales; no conviertas contenido clínico en recomendaciones o tratamientos personalizados.
3. Actualiza la versión del contenido y las expectativas del catálogo inicial en las pruebas cuando corresponda.
4. Ejecuta `flutter analyze` y `flutter test`; usa el procedimiento `--no-pub` del README principal si tu instalación local requiere las copias de paquetes originales.

Las pruebas rechazan versiones desconocidas, IDs duplicados, referencias rotas, campos vacíos, categorías inválidas, solapamientos de equipo/músculos, fechas inexistentes y revisiones o recursos sin metadatos necesarios. También verifican que las rutinas se resuelvan por ID aunque cambie el orden del catálogo.
