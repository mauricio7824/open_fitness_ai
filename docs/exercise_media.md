# Fase 4C: recursos visuales de ejercicios

Esta fase prepara la infraestructura multimedia. Los 18 ejercicios mantienen toda su información, instrucciones originales y guías de técnica. El catálogo de 84 equipos, el motor de compatibilidad, el perfil y el historial no cambian. El catálogo distribuido sigue con `resources: []`: no se han incorporado demostraciones, imágenes ni videos de terceros. No hay dependencias nuevas.

## Comportamiento de la aplicación

Cada ficha incluye «Demostración visual». Si no hay recursos, se indica su ausencia y se remite a las instrucciones disponibles sin conexión. Cada recurso se abre por separado; las imágenes se cargan solo al abrirlo. Las secuencias tienen controles de fase anterior/siguiente, descripción de cada fase y contador anunciado por accesibilidad. No avanzan solas ni reproducen animaciones.

La sección se incluye siempre en `ExerciseDetailPage`, incluso con `resources: []`. Se sitúa inmediatamente después del resumen, músculos y requisitos, antes de «Posición inicial y preparación». El estado vacío muestra «Este ejercicio todavía no tiene una demostración visual disponible.», seguido del recordatorio de acceso a los pasos sin conexión. El repositorio multimedia no condiciona la presencia de esta sección. Las pruebas de integración comprueban la visibilidad al desplazarse en las 18 fichas sin recursos, en ambos temas con texto al 200 %, y la apertura de Sentadilla desde la biblioteca. «Recursos y licencias» permanece al final para la atribución, separada de la demostración educativa.

La [fase 4C.2](exercise_illustrations.md) añade planes de tres fases para Sentadilla, Flexiones y Curl de bíceps, sin registrar imágenes inexistentes como recursos, y una revisión técnica independiente de la editorial. El [inventario de archivos pendientes](../assets/exercise_media/README.md) enumera las nueve ilustraciones que faltan. El catálogo actual sigue sin demostraciones originales disponibles.

Las imágenes locales usan `Image.memory`, se muestran completas sin recortarse y tienen una descripción equivalente visible y accesible. Se usan colores del tema, botones estándar y contenido que ajusta sus líneas. Los estados de carga, error y reintento se expresan mediante texto. Una imagen ausente o dañada no impide consultar la descripción ni las instrucciones y no bloquea la inicialización de la aplicación.

Las URL se conservan como referencias seleccionables, sin descargarlas, abrirlas ni solicitar red automáticamente. No existe todavía un flujo de descarga, caché remota o consentimiento para recursos externos. Para disponer de una imagen sin conexión debe incorporarse al bundle local con autorización.

El tipo `video` reserva duración, ubicación, transcripción y subtítulos opcionales. La interfaz informa de que la reproducción todavía no está implementada y ofrece la transcripción; no presenta un botón de reproducción ficticio. Un futuro reproductor debe ser un adaptador separado del cargador de imágenes, con controles accesibles, pausa, subtítulos, ausencia de autoplay y gestión de su ciclo de vida. Esta fase no incorpora códecs ni paquetes de video.

## Contrato del recurso

El campo `resources` de cada ejercicio admite objetos con estos metadatos. Las listas vacías de las versiones previas siguen siendo válidas. Los antiguos campos reservados, nunca usados en el catálogo distribuido, ahora requieren ID, accesibilidad y revisión explícitos: no se infieren atribuciones ni revisiones al migrar aportaciones externas.

| Campo | Requisito |
| --- | --- |
| `id` | Identificador estable, minúsculas ASCII, números y guiones; único en todo el catálogo. |
| `title` | Título breve en español para abrir el recurso. |
| `kind` | `image`, `illustration`, `imageSequence` o `video`. |
| `assetPath` o `url` | Exactamente una ubicación para imágenes, ilustraciones y videos. URL HTTPS sin credenciales; no implica descarga. |
| `creator` | Nombre real del autor o titular, comprobado por el colaborador. |
| `sourceUrl` | Página original o registro del recurso propio, con HTTPS. No sustituye la autorización para redistribuirlo. |
| `license`, `licenseUrl` | Declaración y enlace de licencia o permiso verificable. |
| `permissionNote` | Explicación de la evidencia de autoría/permiso, ubicación del comprobante y modificaciones realizadas. No incluir información privada en el catálogo público. |
| `attribution` | Crédito completo que se mostrará al usuario, incluidas modificaciones cuando corresponda. |
| `altText` | Descripción textual útil de lo que muestra el recurso. No basta «imagen del ejercicio». |
| `editorial` | Estado y fechas de revisión del recurso, independientes de los del texto del ejercicio. |
| `technicalReview` | Revisión técnica independiente; si falta en un recurso anterior, se considera no registrada. Es explícita en las nuevas secuencias que implementan los planes de 4C.2. |

Las rutas locales se limitan a `assets/exercise_media/`, con carpetas y nombres de letras ASCII, números, guion o guion bajo. No se permiten rutas absolutas, traversal, barras invertidas, espacios, parámetros ni segmentos codificados. Se admiten PNG, JPG/JPEG y WebP estáticos; las ilustraciones utilizan esos mismos formatos. SVG y GIF no tienen adaptador en esta fase.

Una `imageSequence` no declara ubicación en su raíz. En su lugar, exige `frames`: de 2 a 12 fases ordenadas, cada una con `id` único dentro del recurso, `title`, `altText` y exactamente un `assetPath` o `url`. Todas las fases deben pertenecer al mismo autor y declaración de derechos. Si tienen titulares o licencias distintos, deben registrarse como recursos separados. Cada imagen se consulta individualmente al cambiar de fase.

Un `video` exige `durationSeconds` entero entre 1 y 180 y una `transcript` no vacía. Puede declarar `captionsAssetPath` a un archivo `.vtt` local. Sus formatos reservados son MP4 y WebM. La comprobación actual reconoce la firma del contenedor, tamaño y cabecera WebVTT; no certifica los códecs, la duración real, la sincronización de subtítulos ni la reproducción. Esas verificaciones corresponden al futuro adaptador y a la revisión humana.

## Autoría, licencias y atribución

El modelo admite como política inicial `CC0-1.0`, `CC-BY-4.0` y `CC-BY-SA-4.0`, con sus enlaces canónicos, o `LicenseRef-Permission`, cuyo enlace y nota deben documentar un permiso específico. Esta lista es una política del proyecto y no certifica compatibilidad jurídica. Un recurso propio también requiere declarar las condiciones reales de distribución; no se le asigna una licencia automáticamente.

La comprobación de software rechaza campos vacíos, declaraciones desconocidas y enlaces CC que no correspondan a la licencia declarada. No comprueba que el autor haya concedido realmente esos derechos: debe revisarse la fuente y conservarse evidencia antes de distribuir el archivo. No usar «encontrado en internet» como permiso ni reutilizar fotos de las referencias bibliográficas de 4B por el solo hecho de estar enlazadas.

CC BY requiere atribución; CC BY-SA también impone condiciones a las adaptaciones. Consultar las condiciones originales y las [explicaciones oficiales de Creative Commons](https://creativecommons.org/cc-licenses/). Las licencias con restricciones adicionales y las licencias no contempladas necesitan evaluación explícita y, si se aprueba su uso, una ampliación revisada de esta política o un permiso específico documentado.

El crédito debe identificar título, autor, fuente, licencia y cambios reales. Ejemplo de formato, **no de atribución real**: «[Título real], por [Autor real]. Fuente: [URL original]. Licencia: [licencia y URL]. Cambios: [recorte, traducción de rótulos u otros cambios efectivamente realizados]».

## Incorporar un recurso

1. Preparar un archivo propio o comprobar una autorización de redistribución compatible. Registrar titular, fuente, licencia, condiciones y evidencia; obtener también los permisos necesarios de las personas representadas.
2. Revisar que la imagen corresponde al ejercicio y a su variante concreta. Escribir una descripción que explique posición, apoyos y fase, sin declarar que evalúa la técnica personal del usuario.
3. Guardar el archivo en `assets/exercise_media/<exercise-id>/`. Optimizar tamaño y dimensiones sin eliminar información necesaria para comprenderlo.
4. Declarar el archivo en `pubspec.yaml`. Es preferible enumerar archivos concretos. Si se declara un directorio, recordar que los subdirectorios también necesitan declaración. La existencia en el disco no garantiza su inclusión en el bundle.
5. Añadir el objeto a `resources` de la ficha, conservando ID e instrucciones del ejercicio, y aumentar `catalogVersion` al cambiar el contenido del catálogo.
6. Dejar `editorial.status: pending`, `reviewer: null` y `reviewedOn: null`. Escribir qué se comprobó y qué falta. La interfaz mostrará «No validado técnicamente» mientras esté pendiente.
7. Solicitar revisión en la PR o proceso editorial del equipo, adjuntando evidencia de derechos, variante representada, texto alternativo, atribución y comprobaciones visuales. No se envían solicitudes automáticamente desde la app.
8. Ejecutar análisis, pruebas y compilación Android. Comprobar el recurso con conexión desactivada, ambos temas, texto ampliado y lector de pantalla. Pedir revisión de contenido técnico a una persona cualificada antes de afirmar que el movimiento está correctamente demostrado.

Ejemplo estructural para completar con **datos reales** antes de incorporarlo; los marcadores no son registros de autoría, autorización ni fechas:

```json
{
  "id": "squat-start-illustration",
  "title": "Preparación de la sentadilla",
  "kind": "illustration",
  "assetPath": "assets/exercise_media/squat/start.png",
  "creator": "<autor real>",
  "sourceUrl": "https://<dominio-real>/<registro-del-recurso>",
  "license": "CC-BY-4.0",
  "licenseUrl": "https://creativecommons.org/licenses/by/4.0/",
  "permissionNote": "<evidencia real de derechos y modificaciones>",
  "attribution": "<crédito completo comprobado>",
  "altText": "<descripción útil del archivo real>",
  "editorial": {
    "status": "pending",
    "updatedOn": "<AAAA-MM-DD de la aportación>",
    "reviewer": null,
    "reviewedOn": null,
    "notes": "<comprobaciones realizadas y revisión pendiente>"
  }
}
```

Para una secuencia, sustituir `kind` por `imageSequence`, eliminar `assetPath` de la raíz y añadir:

```json
"frames": [
  {
    "id": "start",
    "title": "Preparación",
    "altText": "<descripción de la primera fase real>",
    "assetPath": "assets/exercise_media/squat/start.png"
  },
  {
    "id": "end",
    "title": "Segunda fase",
    "altText": "<descripción de la segunda fase real>",
    "assetPath": "assets/exercise_media/squat/end.png"
  }
]
```

Una revisión `reviewed` exige responsable real y fecha no anterior a `updatedOn`. Debe describir su alcance en `notes`; la interfaz dice «revisado editorialmente», sin convertirlo en evaluación personalizada ni certificar automáticamente la técnica. Si cambia el archivo, la secuencia, sus descripciones o sus derechos, actualizar la fecha, volver a `pending` y retirar la firma anterior. La revisión del recurso no modifica la de la ficha y viceversa.

## Validación y comprobaciones

`AssetExerciseMediaLoader.validateCatalog` recorre las rutas locales: exige inclusión en `AssetManifest`, archivo no vacío, tamaño permitido y firma de formato. Para imágenes comprueba dimensiones, decodificación y que haya un único fotograma. Los límites actuales son 8 MiB por imagen, 8192 píxeles por lado, 16 × 1024 × 1024 píxeles totales, 30 MiB por video y 256 KiB por archivo VTT. Las imágenes se decodifican para validación con un ancho máximo de 1280 píxeles y los objetos nativos se liberan al terminar.

El test `exercise_media_assets_test.dart` valida todo recurso futuro del catálogo realmente empaquetado. Debe permanecer activo aunque hoy el catálogo no contenga recursos. Las pruebas de carga usan PNG sintéticos originales de 8 × 8 generados en memoria y bundles controlados. Sus metadatos son explícitamente ficticios, no se incluyen en el asset de la app y no representan demostraciones de ejercicios ni autorizaciones reales. Hay pruebas adicionales de errores, reintento, referencias externas sin lecturas, fases manuales, accesibilidad, navegación y diseño a 320 píxeles con texto al 200 % en ambos temas.

La validación de medios no se ejecuta como requisito del arranque: el repositorio de ejercicios sigue cargando el texto independientemente de los archivos visuales. Los metadatos JSON se validan estrictamente al leer el catálogo; un catálogo mal formado sigue siendo un error de integridad que debe corregirse antes de distribuirlo.

Procedimiento local, sin modificar el SDK:

```powershell
.\tool\use_pristine_framework.ps1
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub --target-platform android-x64
```

Consultar también la [particularidad del entorno de Flutter](../README.md#particularidad-del-sdk-de-esta-máquina). No ejecutar `flutter pub get` después de preparar las copias salvo que sea necesario; si se regenera la configuración, volver a ejecutar el script. La documentación de Flutter explica [cómo declarar assets](https://docs.flutter.dev/ui/assets/assets-and-images) y el [manifiesto de assets](https://api.flutter.dev/flutter/services/AssetManifest-class.html).

### Resultado original de 4C

La verificación posterior de 4C.2 está registrada en [la guía de secuencias ilustradas](exercise_illustrations.md#verificación-inicial-de-4c2). El diagnóstico del APK antiguo y la instalación actual se documentan en [la corrección de integración multimedia](multimedia_integration.md).

- `flutter analyze --no-pub`: sin incidencias, código de salida 0.
- `flutter test --no-pub`: **224 pruebas aprobadas**, código 0: 162 existentes y 62 nuevas de multimedia. Las 62 nuevas también pasaron en la ejecución específica previa.
- Android: `app:assembleDebug` con Gradle offline y `target-platform=android-x64`, **BUILD SUCCESSFUL**, código 0. APK generado en `build/app/outputs/flutter-apk/app-debug.apk` y `build/app/outputs/apk/debug/app-debug.apk`.
- Ambos catálogos, `pubspec.yaml` y `pubspec.lock` coinciden con `HEAD`. No se modificó ni eliminó ninguna prueba anterior. `git diff --check` no detecta errores de whitespace.

Se ejecutó `tool/use_pristine_framework.ps1` para preparar copias originales dentro del proyecto. Los subcomandos de análisis y pruebas se invocaron mediante un lanzador temporal de `flutter_tools` en `.dart_tool`, con actualización de caché desactivada mediante `Cache.disableLocking()` y sin comprobación de versiones. El primer análisis restringido falló por acceso al archivo de telemetría del usuario; la ejecución final completó el mismo análisis con el acceso necesario y sin incidencias.

Para Android se usó el wrapper Gradle del proyecto con un script de inicialización temporal que dirigía la tarea Flutter al mismo lanzador local. No se cambiaron fuentes del SDK ni los archivos de configuración Android del repositorio. El build mostró avisos de deprecación de Gradle/AGP y de versiones XML de las herramientas Android, sin impedir la compilación. Los scripts y registros temporales permanecen bajo `.dart_tool`, excluidos de Git.

No se instaló esta compilación en emulador o dispositivo ni se realizó una prueba manual con TalkBack. Las pruebas de accesibilidad, temas y texto ampliado son pruebas de widgets; la revisión física de demostraciones reales y sus permisos deberá realizarse cuando se aporten esos archivos. Los cambios quedan sin commit para revisión en `feature/exercise-media`.
