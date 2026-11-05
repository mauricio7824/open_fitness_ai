# Ilustraciones originales pendientes — fase 4C.2

Este directorio contiene documentación, no demostraciones disponibles. No hay imágenes originales aportadas ni generadas. Los planes del catálogo están separados de `resources`; no se incluyen autores, licencias ni firmas inventadas.

Faltan estos **nueve archivos**:

| ID estable del ejercicio | ID del recurso previsto | Archivos pendientes dentro de esta carpeta |
| --- | --- | --- |
| `squat` | `squat-illustration-sequence` | `squat/01-inicial.png`, `squat/02-intermedia.png`, `squat/03-final.png` |
| `pushup` | `pushup-illustration-sequence` | `pushup/01-inicial.png`, `pushup/02-intermedia.png`, `pushup/03-final.png` |
| `biceps-curl` | `biceps-curl-illustration-sequence` | `biceps-curl/01-inicial.png`, `biceps-curl/02-intermedia.png`, `biceps-curl/03-final.png` |

Cada `illustrationPlan` especifica las tres fases `initial`, `intermediate`, `final`, sus títulos y un guion textual. El guion expresa lo que se propone ilustrar: no es el texto alternativo de un archivo existente ni una validación de la ejecución. La posición final corresponde al final de la fase principal mostrada; el regreso se explica en las instrucciones conservadas.

Para incorporar una secuencia real:

1. Aportar los tres archivos originales y documentar su procedencia, autoría y condiciones reales de redistribución. No descargar contenido de terceros ni asignar una licencia por defecto.
2. Declarar cada archivo en `pubspec.yaml` después de que exista. No declarar ahora las rutas pendientes: impediría compilar el bundle.
3. Buscar la ficha por su ID estable y añadir un objeto `imageSequence` a su lista `resources`, con el `id` previsto. Sus tres frames deben usar los IDs y rutas del plan, en ese orden.
4. Escribir el `altText` general y el de cada frame a partir de lo que realmente muestran los archivos. Registrar `creator`, `sourceUrl`, `license`, `licenseUrl`, `permissionNote` y `attribution` con información comprobada.
5. Declarar `editorial` y `technicalReview` por separado, ambos pendientes, con responsable y fecha de revisión en `null`. No heredar la revisión del texto ni inventar una aprobación profesional.
6. Solicitar revisión editorial, de derechos y de técnica con personas identificables. Registrar responsable, fecha y alcance solo cuando esa revisión se haya realizado.
7. Ejecutar la validación de assets, análisis, suite completa y compilación Android; comprobar el uso sin red y la accesibilidad en dispositivo.

La guía completa del contrato y del procedimiento local está en [docs/exercise_media.md](../../docs/exercise_media.md). Ninguna ruta de esta tabla se considera un recurso disponible por el hecho de estar planificada.
