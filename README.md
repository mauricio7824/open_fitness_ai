# Open Fitness AI

Aplicación Flutter orientada a Android: entrenamiento físico y seguimiento personal en español, con Material Design 3. La fase 2 añade una biblioteca local de ejercicios.

## Funciones disponibles

- **Inicio:** acceso a la sesión de hoy, continuación de una sesión abierta y estadísticas calculadas a partir del historial real.
- **Entrenamientos:** tres rutinas con ejercicios, series, repeticiones y duración estimada. Se pueden iniciar, completar mediante una lista de ejercicios, retomar entre pestañas o descartar con confirmación.
- **Ejercicios:** 18 movimientos para gimnasio, casa y calistenia, con búsqueda por nombre y filtros combinables por músculo, modalidad y equipo necesario. Detalles con instrucciones ordenadas, músculos principales/secundarios, requisitos, dificultad, alternativas navegables, fuentes y estado editorial.
- **Progreso:** historial con fecha, ejercicios y tiempo transcurrido real, incluidas las pausas. No se muestran datos ficticios.
- Apariencia clara, oscura o según el sistema desde el icono de contraste de la barra superior.
- Historial y apariencia almacenados localmente con `shared_preferences`, usando su API asíncrona. No se requiere cuenta ni conexión para usar la aplicación.
- Catálogo JSON versionado incluido en la app: disponible sin conexión desde la primera apertura, sin descargas. Se valida antes de usarlo y se mantiene una instantánea inmutable en memoria.
- Tarjetas que se distribuyen según el ancho disponible, contenido desplazable, áreas seguras y navegación inferior en los cuatro apartados.

Una sesión pendiente se conserva **durante la apertura actual de la app**. Solo las sesiones finalizadas y la apariencia se restauran al reiniciar. Si falla el guardado, la sesión permanece disponible para reintentar. Los datos pertenecen a este dispositivo; no hay sincronización ni copias de seguridad propias de la app.

La fase no incluye inteligencia artificial, nutrición clínica, tratamientos médicos, cuentas ni servicios remotos.

## Organización

```text
lib/
  main.dart                 # Inicialización
  app.dart                  # Aplicación, localización y temas
  core/
    data/                   # Repositorios locales y rutinas referenciadas por ID
    models/                 # Catálogo tipado, ejercicios, sesiones y registros
    state/                  # FitnessController con ChangeNotifier
    theme/                  # Temas Material 3
  features/
    shell/                  # Navegación y selector de apariencia
    home/
    workouts/
    exercises/              # Búsqueda/filtros, biblioteca y detalle navegable
    progress/
  shared/widgets/           # Componentes adaptables y formato de datos
assets/catalog/             # Catálogo JSON y guía de ampliación/editorial
test/                       # Integridad, filtros, widgets, controlador y almacenamiento
tool/                       # Alternativa opcional para el SDK local modificado
```

El controlador recibe un `FitnessStore`, lo que permite verificar las reglas y errores de persistencia sin depender de Android. Se usa el estado de Flutter, sin paquetes adicionales de navegación o gestión de estado. `flutter_localizations` procede del SDK; la única dependencia externa de ejecución es `shared_preferences`.

También recibe un `ExerciseRepository`: `AssetExerciseRepository` lee el catálogo local y permite sustituir el origen en el futuro. Las rutinas resuelven ejercicios por ID, de modo que ordenar o ampliar el JSON no cambia sus movimientos. El historial anterior y sus claves de almacenamiento se mantienen. No se añadieron dependencias en la fase 2.

## Biblioteca sin conexión y contenido editorial

El archivo `assets/catalog/exercises.v1.json` es el almacenamiento local del catálogo y se distribuye dentro de la aplicación. No se duplica en preferencias ni se necesita una descarga inicial. Actualmente es de solo lectura: para añadir contenido se modifica el archivo y se publica una nueva versión de la app. Consulta la [guía del catálogo](assets/catalog/README.md) para conocer el esquema y el proceso de ampliación.

La búsqueda usa solo el nombre y tolera mayúsculas, tildes y espacios. Todos los filtros se combinan; el grupo muscular abarca músculos principales y secundarios. «Sin material» significa que no hay equipo obligatorio. Una esterilla opcional no excluye el ejercicio de ese filtro. La modalidad indica dónde se puede practicar **si se dispone de sus requisitos**: un ejercicio puede aparecer en varias modalidades.

Las seis referencias registradas se consultaron el 3 de noviembre de 2026 en la biblioteca de [ACE](https://www.acefitness.org/resources/everyone/exercise-library/): [sentadilla](https://www.acefitness.org/resources/everyone/exercise-library/135/bodyweight-squat/), [flexiones](https://www.acefitness.org/resources/everyone/exercise-library/41/push-up/), [puente de glúteos](https://www.acefitness.org/resources/everyone/exercise-library/49/glute-bridge/), [plancha](https://www.acefitness.org/resources/everyone/exercise-library/32/front-plank/), [bird dog](https://www.acefitness.org/resources/everyone/exercise-library/14/bird-dog/) y [flexiones con rodillas apoyadas](https://www.acefitness.org/resources/everyone/exercise-library/13/bent-knee-push-up/). Son referencias de consulta, no licencias de reproducción de sus recursos.

La redacción en español, las categorías y las alternativas están pendientes de revisión editorial en los **18 ejercicios**; ninguno figura firmado ni aprobado. Los **12 ejercicios restantes** todavía no tienen referencia verificada registrada. La interfaz muestra ambos estados de forma explícita. Las alternativas son opciones para comparar, no sustituciones personalizadas ni tratamientos.

No se incorporaron fotos ni videos. El modelo reserva metadatos de autoría, origen y licencia para futuros recursos locales. No se asigna ninguna licencia ficticia. Las URL de las fuentes son seleccionables para copiarlas; su consulta externa necesita conexión, pero el contenido del ejercicio permanece disponible sin ella.

Pendiente de futuras fases: revisión editorial, completar las referencias que faltan y, si se decide incorporarlos, recursos multimedia con autorización y su visualización. La edición/importación de catálogos desde la interfaz y las actualizaciones remotas no están implementadas.

## Desarrollo

Con una instalación de Flutter sin modificaciones locales:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

El proyecto mantiene el requisito Dart `^3.13.7` que ya tenía. El identificador de Android sigue siendo `org.openfitnessai.open_fitness_ai`; el nombre visible es **Open Fitness AI**.

### Particularidad del SDK de esta máquina

Durante esta fase se detectaron modificaciones preexistentes en las fuentes de `D:\GYM APP\flutter`: constructores incompatibles con sus metadatos y aserciones de nulidad eliminadas, entre otros cambios. Esas fuentes impiden compilar incluso las bibliotecas de pruebas. **No se modificó ni restauró el SDK.**

Para poder compilar y verificar aquí, el siguiente script extrae los paquetes originales `flutter`, `flutter_test` y `flutter_localizations` de la revisión Git `HEAD` instalada. Guarda las copias y ajusta únicamente la configuración generada **dentro de `.dart_tool` de este proyecto**. Requiere que la instalación conserve su repositorio Git. No descarga ni instala otro SDK.

```powershell
flutter pub get
.\tool\use_pristine_framework.ps1
flutter analyze --no-pub
flutter test --no-pub
flutter run --no-pub -d emulator-5554
```

`flutter pub get` y `flutter clean` regeneran o eliminan esa configuración: vuelve a ejecutar el script después de ellos. En una instalación normal no se necesita este ajuste. No edites las copias de `.dart_tool`; están excluidas del control de versiones.

En Android se desactivó la compilación incremental de Kotlin en `android/gradle.properties`: el proyecto está en D: y la caché de Pub en C:, y Kotlin fallaba al calcular rutas relativas entre unidades. Esto puede aumentar el tiempo de compilación. La propiedad es una [opción documentada de Kotlin](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).

## Verificación

Las pruebas cubren las cuatro pestañas, conservación de búsqueda, filtros y detalles, finalización y reanudación de una sesión, descarte con confirmación, restauración de historial y tema, errores de lectura/escritura y cálculo semanal. También comprueban ausencia de desbordamientos a 320×568, 412×915 y 1024×768, además de texto ampliado al 200 % en un teléfono pequeño.

Las pruebas del repositorio usan una implementación en memoria del límite del plugin para verificar la serialización real; no sustituyen una comprobación del almacenamiento nativo en un dispositivo.

Resultado de la fase 1 (3 de noviembre de 2026, con los paquetes originales preparados localmente):

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: **18 pruebas aprobadas**.
- Android 15 / API 35: APK de depuración compilado e instalado; revisión visual de las cuatro pestañas y cambio entre apariencia clara y oscura mediante `computer-use`.

En `flutter run --no-pub -d emulator-5554 --no-resident`, la compilación e instalación terminaron correctamente, pero la conexión de depuración se cerró durante la inicialización de DevFS (`Service disconnected`). La app permaneció ejecutándose y permitió la revisión manual. Esto no verifica hot reload ni estabilidad de la conexión del depurador.

Resultado de la fase 2 (rama `feature/exercise-library`, 3 de noviembre de 2026):

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: **61 pruebas aprobadas**: 37 de catálogo/repositorio/filtros, 6 de interfaz de biblioteca y 18 de regresión de la fase anterior.
- `flutter build apk --debug --no-pub --target-platform android-x64`: APK compilado correctamente en `build/app/outputs/flutter-apk/app-debug.apk`. Esta comprobación no instala la fase 2 ni sustituye una prueba manual en dispositivo.

La verificación usó el script local ya existente para leer las copias originales de los paquetes. No se cambiaron archivos del SDK, dependencias, temas ni colores. Las nuevas pruebas comprueban también carga del asset empaquetado, reintento ante errores, filtros simultáneos, regreso desde alternativas y detalles abiertos durante un entrenamiento, además de temas claro/oscuro con texto al 200 %.
