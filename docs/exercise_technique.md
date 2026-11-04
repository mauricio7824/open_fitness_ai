# Fase 4B: técnica y enseñanza de ejercicios

Las 18 fichas del catálogo local incluyen preparación y posición inicial, ejecución por pasos, respiración, control del movimiento, errores observables con ajustes educativos, consejos de aprendizaje, variantes de menor dificultad, progresiones, precauciones y señales para detener la actividad. Todo se distribuye como texto en el asset y funciona sin conexión desde la primera apertura.

## Modelo y compatibilidad

`exercises.v1.json` mantiene `schemaVersion: 1` y pasa a `catalogVersion: 2`. La ampliación es aditiva: se conservan los 18 IDs, su orden, descripciones, instrucciones originales, categorías, requisitos, equipo y alternativas. No modifica preferencias, inventario, rutinas, historial ni claves de almacenamiento. El catálogo de 84 equipos y su motor de compatibilidad permanecen intactos. No hay dependencias nuevas, descargas ni recursos multimedia.

Cada ejercicio añade `technique`, decodificado como `ExerciseTechnique`:

| Campo | Contenido y validación |
| --- | --- |
| `preparation` | Lista no vacía de colocación y preparación. |
| `steps` | Lista ordenada de al menos tres pasos; las 18 fichas incluidas tienen al menos cuatro. |
| `breathing`, `control`, `tips` | Listas no vacías de orientaciones específicas del ejercicio. |
| `commonErrors` | Lista no vacía de objetos con `title`, `recognition` y `correction` obligatorios. Describe señales observables, sin diagnosticar causas. |
| `regressions`, `progressions` | Listas no vacías de objetos con `title` y `description`. Son ajustes educativos del movimiento, no cambios en la rutina. |
| `precautions`, `stopSignals` | Listas no vacías específicas del ejercicio. |

La raíz añade `teachingGuidance`: `scope`, `precautions`, `stopSignals` y `sources`. Centraliza las orientaciones comunes y sus fuentes, y se muestra en cada ficha junto con la información específica. Todas las listas se leen como colecciones inmutables. Se rechazan tipos incorrectos, campos incompletos y textos vacíos.

La lectura de catálogos anteriores sigue siendo posible: si no existen `technique` o `teachingGuidance`, se conservan como `null`. Una técnica presente debe estar completa. La pantalla utiliza las instrucciones originales cuando no hay técnica ampliada. Las pruebas exigen la ampliación en los 18 ejercicios del asset actual.

## Organización de la ficha

La posición inicial, los pasos y las señales para detenerse se muestran directamente. Respiración, control, errores, consejos, variantes, progresiones y precauciones se organizan en secciones desplegables. Las instrucciones originales siguen disponibles en «Resumen de instrucciones». Se usan colores y tipografía del tema Material, ajuste de línea, desplazamiento y encabezados semánticos; las señales de parada se expresan con texto y no dependen de un color.

Una variante de menor dificultad reduce la exigencia del movimiento descrito. Una progresión propone un cambio de exigencia cuando se conserva el control. Una alternativa es otro ejercicio con sus propios apoyos, equipo y dificultad. Ninguna opción modifica automáticamente el entrenamiento. Las alternativas navegables conservan el filtro de compatibilidad con el inventario; los ajustes educativos no añaden equipamiento obligatorio ni generan equivalencias entre ejercicios.

En dominadas, un recorrido reducido solo se propone si ya se puede entrar en la posición, sostenerse y bajar con seguridad. Si no es posible, se remite a comparar alternativas en lugar de indicar una suspensión o una repetición forzada. Las instrucciones de máquinas remiten al manual y a una demostración presencial para sus mecanismos de seguridad.

## Fuentes y revisión editorial

El 4 de noviembre de 2026 se abrieron las páginas originales y se comprobó que describían el movimiento correspondiente. Se incorporaron las doce referencias que faltaban y se reconsultaron las seis existentes. Las seis fuentes originales conservan sus títulos, URL, editor y fecha inicial del 3 de noviembre. El nuevo campo opcional `scope` explica el alcance y las diferencias relevantes entre la referencia y la ficha; aparece también en pantalla.

| Ejercicio | Referencia consultada |
| --- | --- |
| Sentadilla | [ACE: Bodyweight Squat](https://www.acefitness.org/resources/everyone/exercise-library/135/bodyweight-squat/) |
| Flexiones | [ACE: Push-up](https://www.acefitness.org/resources/everyone/exercise-library/41/push-up/) |
| Puente de glúteos | [ACE: Glute Bridge Exercise](https://www.acefitness.org/resources/everyone/exercise-library/49/glute-bridge/) |
| Plancha | [ACE: Front Plank](https://www.acefitness.org/resources/everyone/exercise-library/32/front-plank/) |
| Zancadas alternas hacia atrás | [Harvard Health: Try this: Take a step back](https://www.health.harvard.edu/exercise-and-fitness/try-this-take-a-step-back) |
| Bird dog | [ACE: Bird-dog](https://www.acefitness.org/resources/everyone/exercise-library/14/bird-dog/) |
| Flexiones con rodillas apoyadas | [ACE: Bent Knee Push-up](https://www.acefitness.org/resources/everyone/exercise-library/13/bent-knee-push-up/) |
| Flexiones en pared | [NHS: Strength exercises, Wall press-up](https://www.nhs.uk/live-well/exercise/strength-exercises/) |
| Plancha lateral | [NASM: Side Plank](https://www.nasm.org/resource-center/exercise-library/side-plank) |
| Elevación de talones | [ACE: Standing Calf Raises - Wall](https://www.acefitness.org/resources/everyone/exercise-library/73/standing-calf-raises-wall/) |
| Dominadas | [ACE: Pull-ups](https://www.acefitness.org/resources/everyone/exercise-library/191/pull-ups/) |
| Remo con mancuerna | [ACE: Single-arm Row](https://www.acefitness.org/resources/everyone/exercise-library/126/single-arm-row/) |
| Sentadilla con mancuerna | [ACE: Goblet Squat](https://www.acefitness.org/resources/everyone/exercise-library/362/goblet-squat/) |
| Press de pecho en suelo | [StrengthLog: Dumbbell Floor Press](https://www.strengthlog.com/dumbbell-floor-press/) |
| Press de hombros con mancuernas | [PureGym: Dumbbell Shoulder Press](https://www.puregym.com/exercises/arms-and-shoulders/shoulder-press/dumbbell-shoulder-press/) |
| Curl de bíceps | [PureGym: Dumbbell Bicep Curls](https://www.puregym.com/exercises/arms-and-shoulders/bicep-curl/dumbbell-bicep-curls/) |
| Jalón al pecho | [PureGym: Lat Pulldown](https://www.puregym.com/exercises/back/lat-exercises/lat-pulldown/) |
| Prensa de piernas | [PureGym: Seated Leg Press](https://www.puregym.com/exercises/legs/quad-exercises/leg-presses/seated-leg-press/) |

Las orientaciones generales remiten a [Mayo Clinic](https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/weight-training/art-20045842) para respiración, calentamiento, control y parada ante dolor, y a [Banner Health](https://www.bannerhealth.com/healthcareblog/teach-me/heart-health-warning-signs-active-seniors-should-not-ignore) para señales de alarma. El artículo de Banner se dirige a adultos mayores; se utilizan únicamente las señales generales, sin trasladar diagnósticos ni prescripciones por edad.

La redacción española y los ajustes educativos son una síntesis editorial propia. Las referencias no respaldan automáticamente cada consejo, clasificación o progresión. **Las 18 fichas siguen en `pending`, sin responsable ni firma de revisión.** `updatedOn` corresponde al 4 de noviembre de 2026. La interfaz informa de la revisión pendiente tanto al principio como en el apartado de fuentes. Una revisión profesional real sigue pendiente; las pruebas automáticas verifican estructura y comportamiento, no certifican la técnica ni la idoneidad individual.

No se han descargado ni incorporado fotos, videos o licencias multimedia. Las referencias son URL seleccionables para copiar; solo su consulta externa necesita conexión.

## Verificación

Las pruebas nuevas cubren la integridad de las 18 técnicas, inmutabilidad, rechazo de datos incompletos, lectura del formato anterior y despliegue de todas las secciones con texto al 200 % a 320 × 568 en ambos temas. La suite existente conserva las verificaciones de navegación, compatibilidad de equipo, perfil y persistencia del historial. Se compararon también los datos originales contra `HEAD` para comprobar que se conservaron IDs, orden, instrucciones, requisitos, categorías, alternativas y fuentes previas.

Los comandos de desarrollo siguen siendo `flutter analyze --no-pub` y `flutter test --no-pub` cuando se usa la configuración local de paquetes descrita en el README. Esta fase no modifica el SDK de Flutter. Una prueba de widgets no sustituye una comprobación manual con TalkBack ni una revisión de ejecución física.

Resultado del 4 de noviembre de 2026:

- **162 pruebas aprobadas**, 124 existentes y 38 nuevas, con código de salida 0. La ejecución específica de catálogo y técnica aprobó antes sus 75 pruebas.
- `dart analyze --fatal-infos`: sin incidencias, código 0.
- Comparación de conservación de datos contra `HEAD` y `git diff --check`: correctas.

Para compilar las pruebas se ejecutó el script existente `tool/use_pristine_framework.ps1`, que prepara paquetes originales únicamente dentro de `.dart_tool`. El arranque habitual de Flutter intentaba escribir en la caché del SDK, bloqueada por los permisos del entorno; se utilizó un lanzador temporal local que invoca `flutter_tools` con `Cache.disableLocking()` para omitir la actualización de esa caché y ejecutar `test --no-pub`. No se modificaron fuentes ni artefactos del SDK. El intento final de `flutter analyze` a través de ese lanzador falló al actualizar un archivo de telemetría fuera del proyecto; el análisis final se completó correctamente con el ejecutable Dart instalado. Estos ajustes son propios del entorno de verificación y no forman parte de la aplicación.

No se realizó una instalación de la fase 4B en emulador o dispositivo, una comprobación manual con TalkBack ni una revisión profesional de la técnica física.
