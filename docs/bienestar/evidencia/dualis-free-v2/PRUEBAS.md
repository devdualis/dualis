# Pruebas ejecutadas

Fecha: 27/10/2026. Los conteos se tomaron de la salida real. El checkout cambió durante la sesión. No se suman ejecuciones repetidas como si fueran casos distintos.

| Ejecución | Resultado | Alcance |
|---|---|---|
| Unitarias backend, sesión inicial | 209/209 | 19 archivos. Versión inicial de la sesión. |
| E2E backend, sesión inicial | 102/102 | 14 archivos. |
| RLS, sesión inicial | 48/48 | 5 archivos; Postgres desechable. |
| E2E backend, cierre | 102/102 | 14 archivos; inició durante los cambios concurrentes. |
| RLS, cierre | 49/49 | 5 archivos; incluye una prueba agregada concurrentemente. |
| Flujo journal, después del arreglo de ancho | 10/10 | Tema real de la app. Incluye texto propio emocional y físico. |
| Condiciones y ajustes, después de los arreglos | 10/10 | Alta/archivo de condiciones y selector de fotos. |
| Modelo de coincidencias, ajuste temporal | 6/6 | Formato observado en API. Esa implementación fue reemplazada después por cambios concurrentes. |
| `npm run test:battery` | `ACTION_REQUIRED` | Backend 209 aprobadas; Flutter no aprobado. Vocabulario y ayuda aprobados. Etiquetado de diccionario 11/11, cero infracciones y cero campos fuera del contrato. |
| `flutter test --concurrency=2`, cierre | **494 aprobadas, 13 fallidas** | También hubo errores de finalización. No es un gate válido de aprobación. |
| `dart analyze`, seis archivos de las correcciones QA | Sin errores | Pantallas journal, condiciones y ajustes; sus tres archivos de pruebas. |

La batería ejecuta también Flutter. Su salida interna no permitió recuperar un conteo completo de frontend; no se inventa uno. La ejecución explícita final sí imprimió `+494 -13: Some tests failed`.

Los 13 fallos finales se detallan en [fallos-flutter.txt](fallos-flutter.txt). Diez corresponden al dashboard (`pumpAndSettle timed out`). También fallaron una expectativa de coincidencias, el banner de sincronización y la ayuda desde Home. Al finalizar aparecieron errores de proceso y `PathNotFoundException` de un directorio temporal del runner. No se investigaron ni corrigieron como parte de esta QA porque la fuente seguía cambiando por otro proceso. No se afirma que estos fallos provengan de los tres arreglos de QA.

Para e2e y RLS al cierre se usó el mismo runner/configuración de los scripts npm, con `--root` y `--config` absolutos y cwd temporal. Así los `dotenv.config()` de las pruebas no buscaron `backend/.env`. `TEST_DATABASE_URL` apuntó exclusivamente al Postgres local en 55440. La suite RLS crea sus bases aisladas; no reutilizó los datos del recorrido funcional.

No se midió latencia de Gemini. Los 0,3 ms medios de la batería pertenecen al diccionario local, sin clave de proveedor. Tampoco se verificó OTP por correo: SMTP estaba cerrado y la cuenta se verificó en la base, como permitía el encargo.

Al retomar no estaban expuestas las herramientas MCP de Dart. Se accedió a `ext.flutter.driver` y a las extensiones de diagnóstico del servicio VM. Se observaron errores reales de layout en los botones de texto propio y condiciones. Se repitieron los recorridos después de corregirlos. Hubo también timeouts del driver al buscar controles fuera de pantalla. No se obtuvo un informe final limpio de `get_runtime_errors`; no se declara “cero errores de runtime”.

Los datos de aislamiento y recuperación están en [aislamiento-api.json](aislamiento-api.json) y [offline-api.json](offline-api.json). Los conteos y métricas resumidos están en [resultados-pruebas.json](resultados-pruebas.json).

## Revalidación 28/10/2026

Los conteos sobre el HEAD `1266b4e` están en la sección «Revalidación del 28/10/2026» de [INFORME.md](INFORME.md): RLS 49/49, e2e 98/98, unitarias 196/196, Flutter 516/516 y batería `PASSED`.
