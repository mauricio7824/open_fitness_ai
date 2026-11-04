# Equipamiento universal — fase 4A

Esta fase incorpora catálogo, inventario y compatibilidad. Conserva las cuatro pestañas, temas, perfil, sesiones y los 18 ejercicios. Las fichas pedagógicas y los recursos audiovisuales de 4B/4C no forman parte de esta entrega.

## Catálogo local

`assets/catalog/equipment.v1.json` contiene **84 tipos** en diez categorías:

| Categoría | Tipos |
| --- | ---: |
| Peso corporal y entorno | 5 |
| Peso libre | 12 |
| Bancos, soportes y racks | 7 |
| Máquinas de tren superior | 10 |
| Máquinas de tren inferior | 9 |
| Poleas y estaciones | 5 |
| Calistenia | 7 |
| Funcional | 13 |
| Movilidad | 7 |
| Cardiovascular | 9 |

El asset se distribuye con la aplicación y no necesita una descarga inicial. `AssetEquipmentRepository` carga y conserva una instantánea validada; el contrato `EquipmentRepository` permite cambiar el origen en el futuro. Las pruebas inyectan un repositorio local determinista.

Cada `EquipmentDefinition` contiene ID, nombre español/inglés, sinónimos, categoría, tipo (`implement`, `accessory`, `machine`, `support`, `environment` o `bodyweight`), modalidades, descripción, variantes y `defaultAvailability`. El estado inicial del catálogo siempre es `unknown`: ninguna definición supone que una persona tiene acceso al equipo.

Los IDs existentes se mantienen literalmente: `dumbbells`, `barbell`, `bench`, `resistanceBand`, `pullUpBar`, `cableMachine`, `legPressMachine`, `wall`, `mat`. Los nuevos usan nombres estables, normalmente en minúsculas y con guiones. No deben renombrarse al traducir una etiqueta. Una barra libre con discos y sus discos por separado representan un conjunto y un componente distintos; no se deducen uno del otro.

Los sinónimos se guardan en la misma definición. Las variantes no se cuentan como equipos adicionales. El decodificador rechaza IDs repetidos y nombres o sinónimos normalizados compartidos por tipos diferentes. La búsqueda usa nombre español, inglés y sinónimos, con tolerancia a mayúsculas, espacios y tildes. Las descripciones y variantes son informativas: **no crean capacidades ni equivalencias automáticas**.

Para contrastar nomenclatura general se consultaron los listados públicos de [Rogue Fitness](https://www.roguefitness.com/conditioning) y [Life Fitness](https://www.lifefitness.com/en-us/catalog/strength-training). No se copiaron fotos, videos ni indicaciones científicas de esas páginas. El catálogo no atribuye una revisión técnica o científica a los fabricantes.

## Inventario editable

`EquipmentInventory` mantiene un mapa de ID a disponibilidad: `available`, `unavailable` o, por ausencia, `unknown`. Solo `available` satisface un requisito. Un inventario `null` sigue significando «sin configurar»; una selección explícita sin equipos sigue siendo válida.

La pantalla incorpora:

- Búsqueda bilingüe y por sinónimos.
- Diez categorías plegables. Buscar abre las categorías coincidentes; plegar no altera selecciones.
- Casillas de selección múltiple: marcar declara disponible; desmarcar declara no disponible.
- Un menú por equipo para declarar cualquiera de los tres estados y filtros para consultarlos.
- Propuestas de hogar, gimnasio y mixto que se presentan antes de aplicarse. Solo añaden dos o tres equipos concretos y no deducen las máquinas de un gimnasio.
- «Sin material», que limpia las declaraciones de disponibilidad pero conserva las definiciones personalizadas.
- Formularios para añadir o editar equipo personalizado, con nombre bilingüe, sinónimos, categoría, tipo, modalidades, descripción y variantes.

Los equipos personalizados usan IDs `custom-…` que se conservan al renombrar o volver a abrir la app. La validación impide que usen un ID oficial o un nombre/sinónimo que duplique otro equipo. Nombrar un objeto como una máquina parecida no le concede los requisitos de esa máquina. La creación modifica el borrador del inventario: hay que guardar el inventario para persistirlo. Salir sin guardar descarta el borrador.

Las 18 fichas actuales no requieren todos los tipos nuevos. Añadir una banda, una máquina o un equipo personalizado no genera ejercicios nuevos ni rutinas.

## Persistencia y migración

La clave de almacenamiento sigue siendo `open_fitness.personalization.v1`. Se conserva para encontrar las preferencias de fase 3; el JSON ahora se escribe con `schemaVersion: 2` y el lector acepta las versiones 1 y 2. No se cambian las claves de historial ni tema.

Formato del inventario en versión 2:

```json
{
  "equipment": ["bench", "dumbbells"],
  "unavailableEquipment": ["low-pulley"],
  "customEquipment": []
}
```

`equipment` enumera IDs disponibles y `unavailableEquipment` los no disponibles. Los demás permanecen sin declarar. Las definiciones personalizadas completas se almacenan en `customEquipment` junto con los estados; no se necesitan archivos o conexiones adicionales.

Al leer versión 1, los nueve valores anteriores se convierten en IDs disponibles conservando exactamente su significado y el resto de preferencias. No se añaden máquinas ni apoyos implícitos. Leer no reescribe el almacenamiento; el siguiente guardado explícito escribe versión 2. La selección vacía y el inventario desconocido siguen diferenciándose.

El codec valida tipos, duplicados, IDs malformados, estados contradictorios y prefijos personalizados. `FitnessController.initialize` valida además que cada ID exista en el catálogo oficial o en las definiciones personalizadas y que no haya nombres duplicados. El guardado hace la misma validación antes de confirmar. Un dato corrupto produce el mecanismo de error/reintento existente, sin sobrescribir preferencias. La cola de escrituras de fase 3 se mantiene.

`EquipmentInventory.items`, `missingFor` y `label` conservan adaptadores para los nueve tipos de fase 3. El código nuevo debe usar `availableIds`, `availability`, `check` y `displayLabel(catalog)` para incluir todos los equipos; no debe reconstruir un inventario universal a partir de la proyección antigua.

## Motor determinista

`EquipmentRequirements` es independiente de Flutter y de inteligencia artificial. Representa **AND de grupos**, cada grupo con **OR de opciones**, y cada opción con un conjunto simultáneo **AND**. El equipo opcional se informa pero no bloquea.

Ejemplo técnico de sintaxis, no una sustitución añadida a las 18 fichas:

```json
{
  "allOf": [
    {"anyOf": [["dumbbells", "bench"], ["kettlebell", "bench"]]},
    {"anyOf": [["mat"]]}
  ],
  "optional": ["wall"]
}
```

Este ejemplo exige mancuernas **y** banco, o pesa rusa **y** banco; además exige esterilla. La pared es opcional. Las opciones deben declararse de forma explícita para cada ejercicio; pertenecer a la misma categoría, tener un nombre similar o figurar como variante no basta.

Las fichas pueden incluir `equipmentRequirements`. Si falta, sus listas anteriores `requiredEquipment` y `optionalEquipment` se convierten en el mismo requisito AND que tenían. Así se mantienen las 18 fichas sin cambiar sus datos, sus instrucciones o sus fuentes. `ExerciseCatalog.validateEquipment` verifica las referencias antes de mostrar la aplicación.

El resultado `EquipmentCheck` indica compatibilidad y los conjuntos faltantes por opción. Las tarjetas y el detalle presentan esos motivos con los nombres del catálogo. Los filtros mantienen la posibilidad de ver todos los ejercicios y combinan la compatibilidad con búsqueda, músculo, modalidad y equipo. Las alternativas de ejercicio siguen siendo las relaciones editoriales existentes y solo se muestran como compatibles si cumplen sus propios requisitos completos.

Casos que no se infieren: barra libre → Smith; polea alta → polea baja; polea alta + baja → cruce de poleas; estación multifunción → cualquier módulo; equipo personalizado → otro tipo oficial. Las configuraciones de una máquina deben comprobarse en el propio equipo y no se evalúan automáticamente en esta versión.

## Ampliación y verificación

Para añadir un tipo, edita el JSON, asigna un ID nuevo y comprueba nombres/sinónimos, categoría y descripción. No hace falta ampliar el enum legado de nueve valores. Incrementa `catalogVersion` cuando cambie el contenido. No uses los sinónimos para crear entradas adicionales.

Se conservan los 97 casos anteriores. Las pruebas de interfaz se adaptaron para buscar equipo antes de seleccionarlo en las categorías plegables, manteniendo sus aserciones. Las nuevas pruebas cubren el asset empaquetado, duplicados, IDs históricos, búsqueda, estado de disponibilidad, propuestas revisables, equipos personalizados e IDs conservados al editar, migración real de versión 1, persistencia y reglas AND/OR. También comprueban inventario expandido a 320×568 con texto al 200 % en claro y oscuro.

Procedimiento local:

```powershell
# Solo si se ha regenerado la configuración de paquetes:
.\tool\use_pristine_framework.ps1
flutter analyze --no-pub
flutter test --no-pub
flutter run --no-pub -d emulator-5554 --no-resident
```

El script solo prepara copias dentro de `.dart_tool`; no se cambia el SDK. No se añaden dependencias. Los datos y formatos de técnica/multimedia de 4B y 4C permanecen fuera del alcance.

Resultado final de esta entrega: `flutter analyze --no-pub` sin incidencias, código 0; `flutter test --no-pub` con **124 pruebas aprobadas**, código 0 (97 anteriores y 27 nuevas). `git diff --check` terminó sin errores. La rama se mantuvo en `feature/equipment-technique`.

`flutter run --no-pub -d emulator-5554 --no-resident` compiló, instaló e inició la app en Android 15 / API 35, con código 0. La inspección visual manual quedó pendiente: el servicio local de `computer-use` no pudo conectarse (`native pipe unavailable`, error del sistema 2), incluso tras reintentar. Los estados, navegación e interfaces sí se comprobaron mediante pruebas de widgets, incluido texto al 200 % en ambos temas.
