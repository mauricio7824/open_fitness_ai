# Perfil deportivo y equipamiento — fase 3

Este documento describe la base de fase 3. La [fase 4A](equipment.md) amplía el inventario a IDs de catálogo y escribe versión 2, conservando la lectura de versión 1 y las preferencias anteriores. Consulta esa guía para el formato actual de equipamiento.

La personalización es local y editable. La barra superior abre «Perfil y equipamiento» y conserva las cuatro pestañas existentes. La biblioteca mantiene sus 18 ejercicios, sus filtros y sus fuentes. No se incorporaron dependencias, nuevas referencias científicas, rutinas automáticas ni servicios remotos.

## Modelos

Los modelos están en `lib/core/models/user_preferences.dart` y usan los identificadores de modalidad y equipo del catálogo de ejercicios.

| Modelo | Datos e invariantes |
| --- | --- |
| `SportsProfile` | Experiencia (`beginner`, `intermediate`, `advanced`), una o más modalidades, objetivos, días disponibles y duración habitual entera entre 5 y 180 minutos. Las colecciones son inmutables. |
| `EquipmentInventory` | Conjunto inmutable de piezas de equipo concretas. Un conjunto vacío significa una elección explícita de «Sin material». |
| `UserPreferences` | Perfil opcional, inventario opcional y estado de configuración. Se guardan juntos con `schemaVersion: 1`. |
| `SetupStatus` | `notStarted`, `skipped` o `completed`. Solo se completa cuando hay perfil e inventario configurados. |

Los objetivos disponibles son crear constancia, desarrollar fuerza, mejorar resistencia, trabajar movilidad y mantenerse activo. La duración es una preferencia declarada; sus límites son una validación del formulario, no una prescripción de actividad física.

Se distinguen **inventario desconocido** (`null`) y **sin material** (`equipment: []`). Omitir la configuración no inventa experiencia, objetivos ni equipo. Los valores desconocidos, repetidos, incompletos o de tipos incorrectos se rechazan al decodificar. Las versiones desconocidas también se rechazan.

El inventario permite declarar mancuernas, barra con discos, banco, bandas de resistencia, barra de dominadas, polea alta, prensa de piernas, pared y esterilla. Las opciones se corresponden con tipos concretos: tener una máquina no implica disponer de todas las demás. La barra con discos y las bandas quedan disponibles para ampliar el catálogo; los 18 ejercicios actuales no las requieren.

## Persistencia y migración

`FitnessStore` añade `savePreferences(UserPreferences)`. `PreferencesFitnessStore` usa la API asíncrona de `shared_preferences`, ya existente en el proyecto, y guarda un único JSON bajo:

```text
open_fitness.personalization.v1
```

El formato tiene esta estructura (los valores son un ejemplo de preferencias, no una recomendación):

```json
{
  "schemaVersion": 1,
  "profile": {
    "experience": "beginner",
    "modalities": ["home"],
    "goals": ["consistency"],
    "availableDays": ["friday", "monday"],
    "sessionMinutes": 30
  },
  "inventory": {"equipment": ["bench", "dumbbells"]},
  "setupStatus": "completed"
}
```

Las listas se serializan con un orden estable. La interfaz muestra los días de lunes a domingo. Las claves anteriores de historial y apariencia permanecen intactas. Si la nueva clave no existe —primera apertura o instalación de una fase anterior— se presenta la configuración inicial sin borrar los datos anteriores.

`FitnessController` espera a que cada escritura termine correctamente antes de actualizar sus preferencias. Una cola serializa las ediciones y calcula cada actualización sobre el estado más reciente, evitando perder un inventario al guardar el perfil o viceversa. Un fallo no bloquea la cola ni confirma un cambio que no se haya guardado. Los formularios conservan las selecciones para reintentar. Volver sin guardar cancela la edición.

Los errores de lectura o formato utilizan la pantalla de reintento existente; no se sobrescriben datos corruptos automáticamente. Las preferencias no se sincronizan con otros dispositivos. Las pruebas del repositorio verifican el JSON real mediante un límite del plugin en memoria; no son una prueba física del almacenamiento Android.

## Configuración inicial

1. La primera apertura muestra «Haz la app tuya», con acceso independiente al perfil y al inventario.
2. Cada sección puede guardarse por separado. La configuración parcial se conserva tras cerrar la app.
3. «Omitir por ahora» guarda `skipped` y abre Inicio. No vuelve a bloquear la navegación en aperturas posteriores.
4. Cuando ambas secciones están configuradas se guarda `completed` y se muestra la aplicación principal.
5. Se puede editar cualquier sección después desde el icono de perfil, conservando la pestaña y los filtros al regresar.

## Compatibilidad y personalización de la biblioteca

La compatibilidad se calcula con una sola regla:

```text
compatible = todos los elementos de exercise.requiredEquipment están en inventory.items
```

El equipo opcional no limita la compatibilidad. Un remo que necesita mancuernas y banco no es compatible si solo hay mancuernas. Una barra con discos no sustituye una barra de dominadas. Una pared tampoco se presupone disponible si no se declara. Sin material, siguen siendo compatibles los ejercicios que no necesitan equipo obligatorio.

La lista y el detalle muestran «Compatible con tu equipo», «Te falta: …» o «Inventario sin configurar». Se conserva la lista de requisitos original de cada ejercicio.

Los controles «Solo compatibles con mi equipo» y «Solo mis modalidades preferidas» son opcionales y se combinan con los filtros anteriores mediante **AND**. El primero requiere un inventario configurado; el segundo aparece cuando hay perfil. Con el control de modalidades activo, basta que el ejercicio admita una de las modalidades preferidas. Limpiar filtros restaura el catálogo completo; las preferencias guardadas no se eliminan.

Las alternativas proceden exclusivamente de las relaciones editoriales del catálogo. Con inventario configurado, se muestran solo las que cumplen todos sus requisitos de equipo; si ninguna cumple, se indica expresamente. Con inventario desconocido, se conserva la navegación original y se pide configurarlo antes de comprobar compatibilidad. Cambiar el inventario desde el detalle actualiza las alternativas sin perder la ruta ni las marcas de una sesión.

La experiencia, los objetivos, los días y la duración se almacenan y presentan como preferencias. No generan rutinas ni evalúan si un ejercicio es apropiado para una persona. La compatibilidad verifica únicamente disponibilidad de material.

## Verificación y archivos

Se mantienen las 61 pruebas anteriores. Su fixture de almacenamiento en memoria representa ahora a alguien que omitió la configuración; no se eliminaron escenarios ni aserciones. Las nuevas pruebas parten también de almacenamiento vacío para cubrir la configuración inicial real.

Las comprobaciones de la fase 3 abarcan restauración y migración, configuración parcial/omitida, validación, escritura fallida y reintento, ediciones simultáneas, cancelación, compatibilidad con todos los requisitos, filtros combinados, alternativas actualizadas y formularios a 320×568 con texto al 200 % en ambos temas.

Resultado final: `flutter analyze --no-pub` terminó con `No issues found!` y código 0; `flutter test --no-pub` terminó con **97 pruebas aprobadas**, sin fallos y código 0. Se incluyen las 61 anteriores, 27 pruebas nuevas de modelos/almacenamiento/filtros y 9 nuevas de interfaz. `git diff --check` no informó errores. No se realizó una comprobación manual en el emulador durante esta fase.

Se usa la configuración local de paquetes ya preparada con `tool/use_pristine_framework.ps1`. Si `.dart_tool/package_config.json` vuelve a apuntar al SDK modificado después de un `pub get`, aplica el procedimiento del README. No hay cambios en el SDK.

Archivos de esta fase:

| Área | Archivos |
| --- | --- |
| Modelos | `lib/core/models/user_preferences.dart` (nuevo), `lib/core/models/exercise.dart` |
| Almacenamiento y estado | `lib/core/data/fitness_store.dart`, `lib/core/state/fitness_controller.dart` |
| Entrada y navegación | `lib/app.dart`, `lib/features/shell/fitness_shell.dart` |
| Perfil e inventario | `lib/features/profile/profile_page.dart`, `profile_editor_page.dart`, `inventory_editor_page.dart` (nuevos) |
| Biblioteca y entrenamiento | `lib/features/exercises/exercise_filter.dart`, `exercises_page.dart`, `exercise_detail_page.dart`; `lib/features/workouts/workout_session_page.dart` |
| Componente compartido | `lib/shared/widgets/equipment_compatibility.dart` (nuevo) |
| Pruebas | `test/user_preferences_test.dart`, `test/profile_navigation_test.dart` (nuevos), `test/support/memory_fitness_store.dart` |
| Documentación | `README.md`, `docs/personalization.md` (nuevo) |
