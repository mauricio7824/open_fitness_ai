# Fase 4C.2: preparación de secuencias ilustradas originales

## Disponibilidad real

La interfaz y el contrato de integración están implementados. **No se han creado, proporcionado ni incorporado ilustraciones originales.** Las 18 fichas mantienen `resources: []`. No se han descargado imágenes de terceros, asignado autores o licencias a archivos inexistentes ni registrado revisiones profesionales.

El catálogo de contenido pasa a `catalogVersion: 3`, manteniendo `schemaVersion: 1`. Añade un campo opcional `illustrationPlan` únicamente a los ejercicios `squat`, `pushup` y `biceps-curl`. Las instrucciones originales, guías de técnica, referencias, requisitos, alternativas e IDs se conservan. El catálogo de 84 equipos, el perfil y el historial no cambian.

## Ubicación y estados de la interfaz

«Demostración visual» se muestra en todas las fichas inmediatamente después del resumen, músculos y requisitos del ejercicio, antes de «Posición inicial y preparación». «Recursos y licencias» se conserva al final como sección de atribución diferenciada.

- Sin recursos: «Este ejercicio todavía no tiene una demostración visual disponible.» y recordatorio de que los pasos siguen disponibles sin conexión.
- Con un plan y sin la secuencia registrada: «Ilustraciones pendientes», explicación de que todavía no hay archivos originales y los tres guiones propuestos. No se muestran imágenes provisionales ni controles para recorrer imágenes inexistentes.
- Con una secuencia real registrada: visor con descripciones y navegación manual por fase, sin autoplay. La existencia del registro JSON no demuestra que sus archivos estén presentes: si falta una fase o no se puede decodificar, se muestra el error, se conserva su descripción y se permite continuar a otra fase o leer las instrucciones.

## Planes vinculados por ID

Un plan es una **especificación**, separada de los recursos disponibles. Contiene `resourceId` y exactamente tres `phases` ordenadas con IDs `initial`, `intermediate`, `final`. Cada fase exige `title`, `description` y `expectedAssetPath`. Sus descripciones son guiones de lo que se propone ilustrar, no textos alternativos atribuidos a imágenes existentes.

| ID del ejercicio | ID previsto del recurso | Carpeta prevista |
| --- | --- | --- |
| `squat` | `squat-illustration-sequence` | `assets/exercise_media/squat/` |
| `pushup` | `pushup-illustration-sequence` | `assets/exercise_media/pushup/` |
| `biceps-curl` | `biceps-curl-illustration-sequence` | `assets/exercise_media/biceps-curl/` |

En cada carpeta faltan **`01-inicial.png`, `02-intermedia.png` y `03-final.png`**: nueve archivos en total. El [inventario de archivos pendientes](../assets/exercise_media/README.md) detalla las rutas. No están declarados en `pubspec.yaml`, porque aún no existen; los guiones del catálogo sí viajan dentro del asset de texto.

La vinculación se hace buscando la ficha por el ID estable del ejercicio, nunca por su posición en la lista. Para incorporar su demostración, se añade a `resources` un `imageSequence` cuyo `id` coincide con `illustrationPlan.resourceId`. Los frames deben tener los tres IDs y rutas locales del plan en el mismo orden, y metadatos completos de texto alternativo y derechos. Las rutas deben pertenecer a la carpeta del ID del ejercicio. Se rechazan planes con IDs repetidos y secuencias asociadas a la ficha equivocada.

Los guiones iniciales siguen los pasos existentes: Sentadilla representa preparación, descenso y punto inferior; Flexiones representa apoyo inicial, descenso y posición inferior; Curl representa brazos a los lados, flexión intermedia y extremo superior. La posición final corresponde al final de la fase principal representada, no a una afirmación de recorrido universal. El regreso se explica en las instrucciones escritas. Estos guiones siguen pendientes de revisión técnica.

## Metadatos y revisiones independientes

Los archivos reales deberán declarar `creator`, `sourceUrl`, `license`, `licenseUrl`, `permissionNote`, `attribution`, `altText` general y `altText` de cada frame. La atribución y los textos alternativos deben describir el material efectivamente aportado. No se completan con datos ficticios para que el visor parezca disponible.

Se añade `technicalReview`, independiente de `editorial`, con:

| Campo | Contenido |
| --- | --- |
| `status` | `pending` o `reviewed`. |
| `updatedOn` | Fecha del contenido que debe revisarse. |
| `reviewer`, `reviewedOn` | `null` mientras siga pendiente; responsable real y fecha cuando la revisión se haya realizado. |
| `notes` | Alcance, comprobaciones y limitaciones reales de la revisión. |

Una revisión técnica registrada exige responsable, fecha no anterior a su actualización ni al contenido editorial del recurso y notas no vacías. Un estado pendiente no puede figurar firmado. Son reglas de integridad del registro; no certifican credenciales o que una revisión haya ocurrido realmente.

La interfaz muestra los dos estados por separado. Una aprobación editorial nunca otorga aprobación técnica. Los recursos del formato anterior sin `technicalReview` se interpretan como **sin revisión técnica registrada**; la UI los mantiene como pendientes y no validados técnicamente. Las nuevas secuencias que implementen los tres planes exigen declarar `technicalReview` explícitamente, empezando en `pending`.

Al modificar la demostración hay que actualizar las fechas y volver a dejar las revisiones afectadas pendientes, retirando sus firmas anteriores. Registrar la revisión profesional solo después de que una persona cualificada e identificable haya comprobado el material, y documentar su alcance. Ningún estado afirma que la app evalúe la técnica personal del usuario.

## Incorporación de archivos reales

1. Proporcionar tres ilustraciones originales por ejercicio, con procedencia y derechos comprobados. No reutilizar medios de las referencias de 4B por el solo hecho de estar enlazadas.
2. Revisar que los tres dibujos representan la misma variante y secuencia, con un estilo y punto de vista consistentes. Ajustar los guiones si el material real lo requiere y solicitar revisión técnica.
3. Guardar los archivos en sus rutas previstas y declararlos explícitamente en `pubspec.yaml`.
4. Añadir el recurso a la ficha correcta por ID. Registrar autoría, fuente, licencia y atribución reales, descripciones alternativas y ambas revisiones pendientes. Aumentar la versión del contenido.
5. Ejecutar la validación de assets, el análisis y la suite completa; comprobar navegación, fallos de una fase, temas, texto ampliado y uso sin red. Compilar Android y comprobar la versión instalada antes de atribuir una ausencia de imágenes a la UI.

La [guía de medios](exercise_media.md) conserva el contrato de recursos y el procedimiento local. No se modifica el SDK ni se requieren dependencias nuevas. Los fixtures de las pruebas generan patrones geométricos en memoria y usan metadatos explícitamente ficticios; están fuera del catálogo de producción y no son ilustraciones de ejercicios.

## Verificación inicial de 4C.2

Esta verificación corresponde a la compilación inicial, que no se instaló. La [corrección de integración multimedia](multimedia_integration.md) documenta la verificación posterior con 256 pruebas, instalación del APK actual y comprobación del emulador.

Verificado el 2026-11-04 en `feature/exercise-illustrations`, conservando los cambios pendientes anteriores y sin hacer commits:

- `flutter analyze --no-pub`: sin incidencias, código 0.
- `flutter test --no-pub`: **254 pruebas aprobadas**, código 0. Incluye las pruebas anteriores de catálogo, técnica, perfil, compatibilidad, inventario, historial y navegación. La ejecución específica de multimedia aprobó **92 pruebas**.
- Las pruebas nuevas comprueban los tres planes por ID, secuencias disponibles con archivos sintéticos, fase ausente, metadatos inválidos, revisiones independientes, navegación manual y acceso a los pasos sin recursos visuales. Las pruebas de widgets existentes siguen comprobando los 18 ejercicios en ambos temas, a 320 px y con texto al 200 %.
- Android: `app:assembleDebug` con Gradle offline y objetivo Flutter `android-x64`, **BUILD SUCCESSFUL**, código 0. APK en `build/app/outputs/flutter-apk/app-debug.apk` y `build/app/outputs/apk/debug/app-debug.apk`.
- Se inspeccionaron ambos APK: incluyen el catálogo de contenido versión 3, los 18 ejercicios, los tres planes y los 84 equipos. No contienen ilustraciones ni registros multimedia ficticios.
- Comparación con Git: todos los campos anteriores de los 18 ejercicios se conservan. El catálogo de equipos, las dependencias y la configuración Android no cambian. `git diff --check` no informa errores.

Se aplicó `tool/use_pristine_framework.ps1` y el procedimiento local descrito en la guía de medios: lanzador temporal de `flutter_tools` dentro de `.dart_tool` para ejecutar los subcomandos sin actualizar la caché del SDK, y wrapper Gradle del proyecto dirigido al mismo lanzador. El análisis necesitó acceso a la configuración de Dart del usuario; Gradle utilizó las cachés locales del entorno. El build mostró avisos de deprecación de Gradle/AGP, sin impedir la compilación. No se modificó el SDK ni se añadieron dependencias.

No se instaló esta compilación ni se verificó manualmente con TalkBack o en dispositivo. Las pruebas con patrones sintéticos verifican la infraestructura, no la corrección técnica de ilustraciones reales. Siguen faltando los nueve archivos originales y sus metadatos comprobados; su revisión editorial y técnica deberá realizarse al aportarlos.
