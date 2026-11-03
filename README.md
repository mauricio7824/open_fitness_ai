# Open Fitness AI

Aplicación Flutter orientada a Android. Primera fase: entrenamiento físico y seguimiento personal en español, con Material Design 3.

## Funciones disponibles

- **Inicio:** acceso a la sesión de hoy, continuación de una sesión abierta y estadísticas calculadas a partir del historial real.
- **Entrenamientos:** tres rutinas con ejercicios, series, repeticiones y duración estimada. Se pueden iniciar, completar mediante una lista de ejercicios, retomar entre pestañas o descartar con confirmación.
- **Ejercicios:** seis movimientos con instrucciones, búsqueda que reconoce palabras sin tildes, filtros por grupo y estado sin resultados.
- **Progreso:** historial con fecha, ejercicios y tiempo transcurrido real, incluidas las pausas. No se muestran datos ficticios.
- Apariencia clara, oscura o según el sistema desde el icono de contraste de la barra superior.
- Historial y apariencia almacenados localmente con `shared_preferences`, usando su API asíncrona. No se requiere cuenta ni conexión para usar la aplicación.
- Tarjetas que se distribuyen según el ancho disponible, contenido desplazable, áreas seguras y navegación inferior en los cuatro apartados.

Una sesión pendiente se conserva **durante la apertura actual de la app**. Solo las sesiones finalizadas y la apariencia se restauran al reiniciar. Si falla el guardado, la sesión permanece disponible para reintentar. Los datos pertenecen a este dispositivo; no hay sincronización ni copias de seguridad propias de la app.

La fase no incluye inteligencia artificial, nutrición clínica, tratamientos médicos, cuentas ni servicios remotos.

## Organización

```text
lib/
  main.dart                 # Inicialización
  app.dart                  # Aplicación, localización y temas
  core/
    data/                   # Catálogo y contrato/repositorio de almacenamiento
    models/                 # Ejercicios, rutinas, sesiones y registros
    state/                  # FitnessController con ChangeNotifier
    theme/                  # Temas Material 3
  features/
    shell/                  # Navegación y selector de apariencia
    home/
    workouts/
    exercises/
    progress/
  shared/widgets/           # Componentes adaptables y formato de datos
test/                       # Pruebas de widgets, controlador y almacenamiento
tool/                       # Alternativa opcional para el SDK local modificado
```

El controlador recibe un `FitnessStore`, lo que permite verificar las reglas y errores de persistencia sin depender de Android. Se usa el estado de Flutter, sin paquetes adicionales de navegación o gestión de estado. `flutter_localizations` procede del SDK; la única dependencia externa de ejecución es `shared_preferences`.

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

Resultado de esta fase (3 de noviembre de 2026, con los paquetes originales preparados localmente):

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: **18 pruebas aprobadas**.
- Android 15 / API 35: APK de depuración compilado e instalado; revisión visual de las cuatro pestañas y cambio entre apariencia clara y oscura mediante `computer-use`.

En `flutter run --no-pub -d emulator-5554 --no-resident`, la compilación e instalación terminaron correctamente, pero la conexión de depuración se cerró durante la inicialización de DevFS (`Service disconnected`). La app permaneció ejecutándose y permitió la revisión manual. Esto no verifica hot reload ni estabilidad de la conexión del depurador.
