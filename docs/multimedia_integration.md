# Corrección de integración multimedia en Android

## Causa comprobada

El 2026-11-04 se comprobó la rama `feature/exercise-illustrations` y se conservaron todos los cambios pendientes de 4C.2. La biblioteca, las sesiones y las alternativas abren la misma función `showExerciseDetails`, que construye `ExerciseDetailPage`. No hay una implementación duplicada de la pantalla en `lib`.

La pantalla actual ya incluía `ExerciseVisualDemo` sin condición basada en `resources`. El componente siempre construye su encabezado y, con la lista vacía, su mensaje de ausencia de recursos. El repositorio multimedia no controla la presencia de la sección.

**El emulador tenía un APK anterior al código multimedia actual.** Se copió el APK instalado mediante `adb pull` antes de actualizarlo y se comparó con el artefacto local:

| Evidencia | APK instalado antes de la corrección | APK local de la entrega anterior |
| --- | --- | --- |
| SHA-256 | `1FB977B389282679393E876467A04B3D4CBBD2F964CC7AD91E13A83CBA5AEC91` | `52C1A2AB77C09707AD720949AE072B35DC1CAF470EFD31064E29F2A051098377` |
| Catálogo de ejercicios | Versión 2, sin planes ilustrados | Versión 3, con los tres planes |
| Código Dart compilado (`kernel_blob.bin`) | No contiene `ExerciseVisualDemo`, «Demostración visual» ni el mensaje vacío actual | Contiene los tres |
| Texto antiguo de «Recursos y licencias» | Presente | Presente, como atribución diferenciada |

Ambos APK declaraban `versionName=1.0.0` y `versionCode=1`: esos campos por sí solos no identificaban la compilación ejecutada. La entrega anterior compiló el APK, pero no lo instaló; su documentación y resumen lo indicaban. No se encontró evidencia de un fallo del SDK que explicara la ausencia de la sección. La inspección visual de la versión antigua mostró que «Requisitos» pasaba directamente al contenido técnico.

## Cambios de esta corrección

- `exercise_detail_page.dart`: sitúa «Demostración visual» después del resumen, músculos y requisitos, antes de «Posición inicial y preparación», conservando su inclusión incondicional en las 18 fichas y la vinculación por ID estable.
- `exercise_visual_demo.dart`: ajusta la puntuación del mensaje exacto a «Este ejercicio todavía no tiene una demostración visual disponible.». Mantiene la navegación de las secuencias cuando hay recursos, el estado vacío y las descripciones accesibles, sin imágenes ficticias.
- `exercise_media_widget_test.dart`: amplía las comprobaciones de orden, desplazamiento y regreso al encabezado en las 18 pantallas completas. Añade dos recorridos desde `OpenFitnessApp` por biblioteca → cada ficha → atribución → demostración → biblioteca, con los repositorios de assets de producción, controlador y rutas reales, en modo claro y oscuro. Solo la persistencia de esas pruebas es en memoria; los catálogos se leen del bundle fuera del reloj simulado del test.
- La documentación se actualiza para reflejar la ubicación solicitada, el diagnóstico y la comprobación de instalación. Se conservan las instrucciones, los 18 ejercicios, los 84 equipos, el perfil, la compatibilidad, el historial y las pruebas anteriores.

No se crearon ilustraciones. Siguen faltando [nueve archivos originales](../assets/exercise_media/README.md); los tres planes no equivalen a recursos disponibles.

## Verificación automatizada y compilación

Se aplicó el [procedimiento local](exercise_media.md#validación-y-comprobaciones) con `tool/use_pristine_framework.ps1`, los lanzadores temporales dentro de `.dart_tool` y las herramientas instaladas, sin modificar el SDK:

- `flutter analyze --no-pub`: sin incidencias, código 0.
- `flutter test --no-pub`: **256 pruebas aprobadas**, código 0. Conserva las 254 de la entrega anterior y añade dos recorridos de aplicación con los catálogos reales.
- Ejecución específica de `test/exercise_media_widget_test.dart`: **20 pruebas aprobadas**, código 0.
- Android: `app:assembleDebug` offline, objetivo Flutter `android-x64`, **BUILD SUCCESSFUL** en 39 s, código 0. Permanecen avisos de deprecación de Gradle/AGP; no impidieron la compilación.

APK actualizado: `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256 `3660142C3EDFB5D17F49EA8EE232157A81D71E21219FB2A6DC473674BD8ADE14`.

## Instalación que conserva datos

Se actualizó únicamente `org.openfitnessai.open_fitness_ai` en `emulator-5554` con `adb install -r`, que terminó en `Success`. Se volvió a copiar el APK instalado y se comprobó que su SHA-256 coincide exactamente con el generado. Su bundle contiene los 18 ejercicios, tres planes, 84 equipos y cero recursos ficticios. El archivo de preferencias `files/datastore/FlutterSharedPreferences.preferences_pb`, que contiene la persistencia del perfil, tema e historial, conserva su huella SHA-256 anterior byte por byte tras la actualización.

Se inició explícitamente `org.openfitnessai.open_fitness_ai/.MainActivity` con arranque en frío (`am start -S -W`), resultado `Status: ok`. No se borraron datos, no se desinstaló la app y no se cambió de rama ni se hicieron commits.

Para próximas actualizaciones, después de analizar, probar y compilar mediante el procedimiento local:

```powershell
$adbTool = 'C:\Users\Mauricio\AppData\Local\Android\Sdk\platform-tools\adb.exe'
& $adbTool devices -l
& $adbTool -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
# Continuar solo si la instalación termina en Success.
$packagePath = (& $adbTool -s emulator-5554 shell pm path org.openfitnessai.open_fitness_ai).Trim().Replace('package:', '')
& $adbTool -s emulator-5554 pull $packagePath .dart_tool/installed-verification.apk
$builtHash = (Get-FileHash build/app/outputs/flutter-apk/app-debug.apk -Algorithm SHA256).Hash
$installedHash = (Get-FileHash .dart_tool/installed-verification.apk -Algorithm SHA256).Hash
if ($builtHash -ne $installedHash) { throw 'La instalación no corresponde al APK compilado.' }
& $adbTool -s emulator-5554 shell am start -S -W -n org.openfitnessai.open_fitness_ai/.MainActivity
```

Abrir la biblioteca, entrar en Sentadilla y desplazarse hasta la transición Requisitos → Demostración visual → Preparación. Comprobar también el estado vacío y la atribución al final. Una compilación correcta o una actividad visible no sustituyen esta revisión.

## Comprobación visual realizada

Se inspeccionó el emulador integrado en Android Studio mediante la habilidad de control de aplicaciones. Desde la biblioteca de la APK actualizada se abrió Sentadilla y se comprobó, en modo claro y oscuro:

- La sección «Demostración visual» aparece después de los requisitos.
- El mensaje de ausencia de demostración y el recordatorio de las instrucciones sin conexión se muestran sin imágenes ficticias.
- Los guiones de tres fases aparecen como «Ilustraciones pendientes».
- Al desplazarse se ve a continuación «Posición inicial y preparación»; se puede regresar a la biblioteca.

La comprobación manual se limita a Sentadilla en ambos temas. Las 18 fichas, el desplazamiento y «Recursos y licencias» se verifican además en los recorridos automatizados de la aplicación completa. No se realizó una evaluación con TalkBack ni una revisión técnica de ilustraciones reales, porque no se han aportado archivos.

Tras probar el modo oscuro se restauró la selección original «Usar tema del sistema». Se volvió a comparar la huella del archivo de preferencias con la capturada antes de instalar: coincidencia exacta, incluido el tema original. Los registros de inicio consultados no mostraron errores `E/flutter`, excepciones fatales ni assets ausentes. Android mantuvo `MainActivity` como actividad activa y ADB siguió conectado.
