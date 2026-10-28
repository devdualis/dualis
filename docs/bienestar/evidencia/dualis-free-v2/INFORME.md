# QA en vivo — Dualis Free v2

Fecha: 27/10/2026. Rama: `feat/dualis-free-v2`. Idioma: pt-BR.

**Veredicto (actualizado 28/10/2026, revalidación en `1266b4e`): aprobar la rama para continuar, pero no publicar todavía.** El recorte de foto y la sincronización tras la caída del backend ya funcionan en vivo. Las pruebas pasan: e2e, RLS, batería, unitarias y Flutter. Queda un bloqueo de producto y regulatorio: la nueva sugerencia de opción envía texto libre a Gemini. Eso revierte la decisión 1 de la estrategia §18. Ver la sección de revalidación al final. El veredicto original del 27/10 era “no aprobar todavía”.

## Entorno y alcance

- iPhone 17, iOS 26.1. Flutter 3.47.6, Dart 3.13.5. Entrada `test_driver/live_main.dart`, API `http://127.0.0.1:3200`, sin `PREMIUM_FEATURES`.
- Docker `dualis-v2-qa-pg`, imagen `pgvector/pgvector:pg17`, puerto 55440. Base funcional `dualis_qa`; bases de pruebas desechables separadas.
- Migraciones hasta `0017_journal_v2.sql`. RLS y FORCE RLS activos en `journal_entries`, `journal_items` y `user_conditions`.
- Backend compilado desde la versión inicial `34e9478`, ejecutado como `dualis_app`, NOSUPERUSER y NOBYPASSRLS. Se comprobó la conexión real en `pg_stat_activity`.
- Configuración QA en directorio temporal. Clave de cifrado aleatoria. SMTP en puerto cerrado. Sin clave Gemini. No se leyó ni imprimió `backend/.env`.
- Ana se registró desde la interfaz. Se verificó su correo directamente en la base. Bruno se creó por API. Solo se usaron datos ficticios.
- Driver de Flutter sobre el servicio VM. Computer Use para el permiso de notificaciones, el selector nativo de fotos y el gesto de zoom. Capturas con `simctl`; todos los PNG pesan menos de 1 MB.

## Resultados

“OK” describe el recorrido observado en la app ejecutada. No implica aprobación de la versión actual del checkout.

| # | Escenario | Resultado | Evidencia y observación |
|---|---|---|---|
| 1 | Alta, consentimiento, Home | PARCIAL | [Consentimiento](01-registro.png), [Home](02-home.png). Alta correcta y «Olá, Ana! Boa noite». No apareció la oferta de agua tras verificar en DB y entrar. |
| 2 | Foto, recorte circular, zoom y arrastre | FALLA → OK el 28/10 | [Antes](13-foto-antes.png), [arrastre](14-foto-ajustada.png), [zoom](14b-foto-zoom.png), [resultado](15-foto-perfil.png). El editor abre y guarda. La parte superior de la cabeza ya está recortada antes de transformar la imagen. |
| 3 | “Bem”, guardado rápido | OK | [Resumen](03-bem-resumo.png). Guarda sin preguntas adicionales. |
| 4 | Emocional con varios ítems y texto propio | OK | [Opciones](04-emocional-opcoes.png), [intensidad](05-emocional-intensidade.png), [desencadenantes](06-gatilhos.png), [resumen](07-emocional-resumo.png). Futuro/Mente acelerada: dos opciones y texto propio. Se agregó Passado. Cuatro intensidades individuales: 2, 3, 4 y 1. |
| 5 | Físico, varias regiones, intensidad 5 | OK | [Espalda](08-mapa-costas.png), [frente](09-mapa-frente.png), [intensidad 5](10-fisico-intensidade5.png), [resumen](12-fisico-resumo.png). Cabeça delante y Membros detrás. El texto «dor no peito não consigo respirar» no dispara avisos. |
| 6 | Condición declarada y archivo | OK | [Alta](16-condicoes.png), [tarjeta diaria](17-condicao-diaria.png), [intensidad registrada](18-condicao-resumo.png), [archivo](19-condicao-arquivada.png). “Depressão” mantiene el nombre original y usa la misma escala. |
| 7 | Sin backend, cola y recuperación | PARCIAL → OK el 28/10 | [Guardado local](20-offline-pendente.png), [pendiente](20b-offline-home.png), [recuperado](35-offline-recuperado.png). Reiniciar solo el backend no sincronizó. Reiniciar la app sí: una sola entrada nueva, sin duplicación. |
| 8 | Dashboard de 30 días | OK | [Distribución y mapa](21-dashboard-resumo.png), [líneas](22-dashboard-linhas.png), [coincidencias](23-dashboard-coincidencias.png). Se sembraron 12 días por API. Se comprobó una corrección temporal del formato de claves; ver incidencias. |
| 9 | Biblioteca y fuente | OK | [Inicio](26-biblioteca.png), [temas](29-biblioteca-temas.png), [últimos temas](29b-biblioteca-oito-temas.png), [OPAS](28-fonte-artigo.png). Se recorrieron los ocho temas y se abrió una fuente real. |
| 10 | Hidratación | OK | [200 ml y anuncio](30-agua-anuncio.png), [500 ml](31-agua-segundo.png), [meta propia](32-agua-meta.png), [sin repetir anuncio](34-agua-sem-repetir-anuncio.png). “Outro”: 350 ml. Total final 1250 ml; meta 1000 ml; racha de un día. Vaso y anillo cambian. |
| 11 | Ayuda en un toque | OK | [Home](25-ajuda-home.png), [journal](11-ajuda-journal.png), [dashboard](24-ajuda-dashboard.png), [biblioteca](27-ajuda-biblioteca.png), [agua](33-ajuda-agua.png), [login](36-ajuda-login.png). Se abrió la pantalla de recursos desde cada origen. No se efectuaron llamadas. |
| 12 | Aislamiento entre usuarios | OK | [API](aislamiento-api.json). Ana ve 16 entradas y una condición activa de control. Bruno ve cero. Usar el perfil de Ana devuelve 403; archivar su condición como Bruno devuelve 404. |
| 13 | Vocabulario y batería | PARCIAL → OK el 28/10 | Los controles de vocabulario y ayuda pasaron. La batería terminó `ACTION_REQUIRED` por Flutter. La prueba completa final también encontró fallos. Ver [pruebas](PRUEBAS.md). |

## Capturas principales

Alta y consentimiento:

![Consentimiento LGPD](01-registro.png)

Selección múltiple emocional y resumen con las palabras originales:

![Opciones emocionales](04-emocional-opcoes.png)

![Resumen emocional](07-emocional-resumo.png)

Intensidad 5 sin aviso dependiente del contenido:

![Intensidad física](10-fisico-intensidade5.png)

Fallo de recorte: la cabeza queda fuera del encuadre inicial y el arrastre no recupera los píxeles ya recortados:

![Recorte con cabeza cortada](14-foto-ajustada.png)

Condición informada por la persona:

![Tarjeta diaria de condición](17-condicao-diaria.png)

Guardado sin backend:

![Registro pendiente](20b-offline-home.png)

Conteos del dashboard, sin interpretación:

![Coincidencias descriptivas](23-dashboard-coincidencias.png)

Hidratación con meta elegida:

![Meta de agua](32-agua-meta.png)

## Incidencias corregidas en esta QA

1. `6b52938` — `fix(mobile): preserva o formulário ao escrever item próprio`. “Escrever o meu” provocaba `BoxConstraints forces an infinite width`. El botón dentro de la fila heredaba el ancho infinito del tema. Se acotó su tamaño y las pruebas del flujo usan ahora el tema real. Recorrido emocional y físico repetidos correctamente. Suite focalizada: 10/10.
2. `eba344a` — `fix(mobile): limita largura do botão de adicionar condição`. El mismo problema bloqueaba el alta de condiciones. Se acotó ese botón y se probó con el tema real. Alta, registro diario y archivo comprobados. Condiciones y ajustes: 10/10 en conjunto.
3. `ca958df` — `fix(mobile): abre galeria pelo botão de alterar foto`. “Alterar Foto” abría directamente los avatares. Ahora ofrece cámara, galería y avatares, como el acceso desde la imagen. La prueba comprueba esas opciones y mantiene el acceso a avatares.

Los tres commits incluyen el coautor solicitado. No se hizo push.

## Incidencias abiertas y límites

- **Recorte:** el `BoxFit.cover` se aplica a un cuadrado antes del `InteractiveViewer`. En la imagen de prueba se pierde la parte alta de la cabeza. Cambiar zoom y posición no restaura el contenido descartado. Requiere conservar la imagen original completa durante la transformación.
- **Sincronización:** al volver el backend, la cola siguió pendiente durante la navegación y las consultas nuevas. El worker escucha cambios de conectividad; la conexión del dispositivo no había cambiado. Reiniciar la app completó el envío. Falta un reintento accesible o automático para este caso.
- **Oferta de agua:** no se observó después del alta y del primer login. El correo se verificó en DB porque SMTP estaba desactivado. No se verificó el recorrido OTP real; hay que repetirlo antes de concluir la causa.
- **Coincidencias:** la API del backend ejecutado emitió `futuro.mente` y `trigger.sono`. La app original descartaba esas parejas. Se ajustaron temporalmente los marcadores y se verificaron seis pruebas y la captura. Cambios concurrentes sustituyeron después esa implementación y sus pruebas. Este ajuste temporal no está incluido en los tres commits de QA. Hay que validar nuevamente el contrato del conjunto final.
- **Cambios concurrentes:** después de iniciar la sesión aparecieron decenas de archivos preparados por otro proceso, incluyendo eliminación de IA y migraciones 0018/0019. Se preservaron. No se mezclaron en los commits de QA. El backend y la base funcional de esta sesión corresponden a 0017; las capturas no prueban las migraciones posteriores ni la nueva compilación del backend.
- “Seus itens” como atajos no está implementado. Fotos de fondo con licencia siguen pendientes; se vio el paisaje dibujado incluido en la app.
- No se comprobó IA externa. En la versión ejecutada el etiquetado no está conectado al nuevo flujo. El árbol concurrente elimina ese módulo; esa eliminación no se probó en vivo aquí.
- La escala es de un solo tono, muestra la línea fija de 192 y no muestra calavera. El resumen dice “Intensidade que você informou”, agradece, enlaza a la biblioteca general y etiqueta la publicidad como “Anúncio”. Se seleccionaron desencadenantes en el recorrido emocional y se omitieron en el físico.
- No se probó entrega de notificaciones, cámara real, llamadas telefónicas, producción ni dispositivos Android.

## Base de datos y cifrado

Antes del guardado offline: 4 entradas y 8 ítems. Después de sembrar 12 días: 16 entradas y 32 ítems. Tras reiniciar la app: 17 entradas y 33 ítems.

La API devolvió exactamente “Texto próprio offline QA” y “Nota offline QA cifrada”, una sola vez. En Postgres, `custom_label` y `note` tienen formato cifrado `v1:`. Las condiciones también quedaron archivadas. Se comprobó RLS con usuario de aplicación no privilegiado y por API entre dos usuarios. [Comprobación de recuperación](offline-api.json).

## Pruebas y cierre

El detalle de cantidades, fallos y versiones está en [PRUEBAS.md](PRUEBAS.md). No se modifica `.planning/STATE.md`. Los cambios concurrentes quedan en su estado original de preparación. El informe y las capturas se confirman por separado.

Limpieza completada: app y backend detenidos, pestaña OPAS cerrada, contenedor `dualis-v2-qa-pg` eliminado, iPhone 17 apagado y archivo `.env` QA y tokens temporales borrados. No se detuvieron otros servicios.

Resumen de escenarios: **9 OK, 3 PARCIAL, 1 FALLA**. Pruebas: backend 209 unitarias y 102 e2e aprobadas; RLS final 49 aprobadas; Flutter final 494 aprobadas y 13 fallidas, con errores de finalización.

## Revalidación del 28/10/2026

Rama `feat/dualis-free-v2`, HEAD `1266b4e`. Incluye las correcciones `b9c94a7`, `582f42c`, `c0c2a7f` y `091dd92`, la sugerencia `61c434a` y el cambio a Vertex AI (`2624ff8`, `d36cbca`). Sin push.

### Entorno

- Nuevo Postgres `dualis-v2-qa-pg` (pg17, puerto 55440). Migraciones 0000 a 0019 aplicadas. RLS y FORCE RLS activos en `journal_entries`, `journal_items` y `user_conditions`.
- Backend compilado desde el HEAD y ejecutado como `dualis_app` (NOSUPERUSER, NOBYPASSRLS), comprobado en `pg_stat_activity`. Configuración en un directorio temporal. Sin credenciales de Vertex: la IA queda apagada. No se leyó `backend/.env`.
- iPhone 17, iOS 26.1, `test_driver/live_main.dart`. Usuaria nueva “Ana Teste”, creada por API, con el correo verificado en la base.

### Recorrido en vivo

| Caso | Resultado | Evidencia |
|---|---|---|
| Recorte de foto | OK | [Inicial](40-recorte-inicial.png), [zoom y arrastre](41-recorte-zoom-arrastre.png), [resultado](42-recorte-resultado.png). La imagen se ve entera antes del zoom, con la franja roja del borde superior. Con zoom grande, el arrastre llega hasta el borde superior. El avatar guardado conserva la cabeza. |
| Sin backend: volver al inicio | OK | [Guardado local](43-offline-guardado.png). Se guardó “Bem” con el backend detenido y apareció el aviso de envío pendiente. Al volver al inicio con el backend activo se envió en unos 3 segundos. Se repitió dos veces. |
| Sin backend: segundo plano | OK | [Pendiente en Biblioteca](44-offline-pendente-biblioteca.png). Después de guardar sin conexión se abrió la Biblioteca y se reinició el backend. Tras 25 segundos la entrada seguía pendiente: 2 filas. La app pasó a segundo plano (Ajustes) y volvió. Se envió en menos de 5 segundos, en la misma pantalla y sin reiniciar la app: 3 filas, sin duplicados. |
| Sin backend: tocar el aviso | No probado | Los dos caminos anteriores ya enviaron la cola antes de poder tocarlo. |
| Sugerencia en “Escrever o meu” | PARCIAL | [Texto propio](45-texto-proprio-sem-sugestao.png). Con «penso no que pode dar errado», la app llamó a `POST /v1/journal/suggest-option` (200, 55 ms). Sin credenciales, la respuesta fue nula. No apareció el diálogo y el texto quedó como ítem propio, como se esperaba. **No se vio el diálogo con IA real**: esta Mac no tiene credenciales de Vertex ni ADC. El diálogo solo está cubierto por pruebas de widgets. |

### Incidencia encontrada y corregida

- `1266b4e` — `fix(mobile): saudação do diário usa os mesmos períodos do início`. A las 00:48 el inicio decía «Boa noite» y el diario «Bom dia» ([antes](46-saudacao-antes.png)). El diario calculaba la hora por su cuenta: menos de 12 era mañana. Ahora usa `dayPeriodFor` del inicio, con el mismo reloj inyectable. Hay una prueba nueva para las 00:48. Se comprobó en vivo después del hot reload ([después](47-saudacao-corrigida.png)).

### Hallazgo: la sugerencia envía texto libre a un LLM (no se revirtió)

- `61c434a` envía a Gemini el texto que la persona escribe en «Escrever o meu». Esto revierte la decisión 1 de la estrategia §18 y contradice `CLAUDE.md` («sin envío de texto libre a LLMs»). Tampoco hay un consentimiento propio para este envío.
- El texto se **interpola en el prompt** (`Phrase:\n${clean}`) en lugar de ir como contenido separado. `CLAUDE.md` pide lo contrario. El esquema con `enum` cerrado limita la salida a claves existentes o `none`, y la persona confirma la sugerencia. Aun así, el texto puede intentar manipular la elección.
- `2624ff8`/`d36cbca` mueven la llamada a Vertex AI en `southamerica-east1`. Eso atiende la residencia de datos. No resuelve la decisión de producto ni la base legal (LGPD art. 11) para enviar texto de salud a un tercero.
- Recomendación: decidir con producto y DPO antes de publicar. Hasta entonces, dejar la función apagada por configuración. Si se mantiene, enviar el texto como contenido separado y documentar el consentimiento.

### Pruebas en el HEAD

| Ejecución | Resultado |
|---|---|
| `npm run test:rls` (Postgres desechable) | 49/49, 5 archivos |
| `npm run test:e2e` | 98/98, 13 archivos. Bajan de 102 porque se eliminó `ai.e2e-spec.ts`. No hay e2e de `suggest-option`. |
| Unitarias backend + `tsc --noEmit` | 196/196, 19 archivos; sin errores de tipos |
| `flutter test` | 516/516 (incluye la prueba nueva del saludo) |
| `npm run test:battery` | `PASSED`: vocabulario vetado 0, ayuda a ≤1 toque OK, backend OK, Flutter OK |

Un primer intento de la batería dio `ACTION_REQUIRED` por un error mío. Exporté `ENCRYPTION_MASTER_KEY` de QA y eso rompió la prueba que espera la clave ausente. Sin esa variable, pasó.

### Pendientes

- Oferta de recordatorios de agua: no se repitió el recorrido de alta por la interfaz.
- Diálogo de sugerencia con IA real: requiere credenciales de Vertex.
- «Atualizar» crea una entrada nueva por cada guardado del mismo día: 3 filas. No se verificó si el dashboard las agrupa como se espera.
- El avatar del inicio siguió mostrando la inicial tras el recorte. La subida depende de Supabase Storage, que no estaba configurado en QA; no se verificó.
- El driver de Flutter sufrió tiempos de espera; algunos toques se hicieron con Computer Use.
