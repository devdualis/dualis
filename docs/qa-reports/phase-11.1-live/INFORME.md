# QA en vivo de la fase 11.1 — permiso legal (2.1.1) y permiso opcional (2.1.2)

Fecha: 2026-11-03. Rama: `room/phase-11-1-worktree-setup-9ps7`.

Prueba hecha como una persona usuaria: se tocó la interfaz real de la app en el simulador de iOS, contra el backend real con RLS activo. No se usaron fakes. Donde hacía falta, se comprobó además la API (curl) y la base de datos (como `dualis_app` con `app.current_user_id`, y como `postgres` solo para ver la verdad de la tabla o preparar datos).

## Entorno

- Simulador: iPhone 16e (iOS 26.1), app en pt-BR, lanzada con `flutter run -t test_driver/live_main.dart --dart-define=PREMIUM_FEATURES=true --dart-define=API_BASE_URL=http://127.0.0.1:3200` (Flutter 3.47.6). Control por DTD + `flutter_driver_command`, capturas con el driver.
- Backend: build limpio (`rm -rf dist && npm run build`), `node dist/src/main.js` en el puerto 3200 con Node 22.21.1, `NODE_ENV=development`, `ENCRYPTION_MASTER_KEY` y `JWT_SECRET` aleatorios desechables, `DISCLAIMER_VERSION=2026.2`, sin `RESEND_API_KEY` (correos en modo simulación, visibles en el log). No se leyó ningún `.env`.
- Base de datos: contenedor Docker `dualis-111-qa-pg`, base `dualis_live_qa` (PostgreSQL 17.11), 30 migraciones incluida la 0028, vacía al empezar. La app se conecta como `dualis_app` (NOSUPERUSER, NOBYPASSRLS): ver [evidence/pg_role_evidence.txt](evidence/pg_role_evidence.txt). No se tocó ninguna base de producción.
- Cuentas ficticias: Ana (titular y responsable), Bruno (familiar), Carla (joven que recibe el perfil, cuenta nueva sin datos), Diego (cuenta con datos). Para un caso extra de C2 se creó Elisa (cuenta nueva). Registro por API y verificación con el código que el backend escribe en el log.

## Resultado

23 casos: **23 PASS** tras las correcciones. 5 fallaban antes de corregir: B4, B5, B8, B9 y C1. Se encontraron y corrigieron 6 fallos, en 7 commits. Quedan 2 hallazgos abiertos de bajo impacto.

### A. Permiso legal (Ana)

| Caso | Resultado | Evidencia |
|------|-----------|-----------|
| A1 Menor (~10 años): solo "Poder familiar" y "Tutela", texto de consentimiento Art. 14, campo de notas visible; se crea con poder familiar + nota | PASS. BD: `dependent_minor`, `parent`, `lgpd_art_14`, nota guardada, consentimiento con fecha | [A1-minor-options-art14.png](A1-minor-options-art14.png), [A1-minor-created-active.png](A1-minor-created-active.png), [evidence/A-db.txt](evidence/A-db.txt) |
| A2 Menor con tutela | PASS. BD: `legal_guardian`, `lgpd_art_14` | [evidence/A-db.txt](evidence/A-db.txt) |
| A3 Adulto (~40 años) con curatela: solo "Curatela" y "Tomada de decisão apoiada", texto Art. 11, I; la etiqueta no dice "Maior sob tutela" ni "incapaz" | PASS. Etiqueta: "Maior com representação legal". BD: `dependent_adult`, `curator`, `lgpd_art_11_i` | [A5-after-adult-cleared-A3-art11.png](A5-after-adult-cleared-A3-art11.png), [A3-adult-curator-badge.png](A3-adult-curator-badge.png) |
| A4 Adulto con tomada de decisão apoiada | PASS. BD: `supported_decision`, `lgpd_art_11_i` | [A4-supported-decision-form.png](A4-supported-decision-form.png), [evidence/A-db.txt](evidence/A-db.txt) |
| A5 Cambiar la fecha de menor a adulto en el formulario borra relación y consentimiento | PASS | [A5-before-minor-parent-consent.png](A5-before-minor-parent-consent.png), [A5-after-adult-cleared-A3-art11.png](A5-after-adult-cleared-A3-art11.png) |
| A6 "Cadastrar" desactivado sin consentimiento; tocarlo no crea filas | PASS. 0 dependientes y 0 llamadas a `POST /profiles/dependents` | [A6-submit-disabled-no-consent.png](A6-submit-disabled-no-consent.png) |
| A7 API: `parent` para 40 años y `curator` para 10 años | PASS. Ambos 400 con mensaje legible en pt-BR; 0 filas creadas | [evidence/A7-curl.txt](evidence/A7-curl.txt) |

### B. Permiso opcional (Ana → Bruno)

| Caso | Resultado | Evidencia |
|------|-----------|-----------|
| B1 Invitar el perfil propio: relación obligatoria (8 opciones), solo "Hábitos" marcado, diario emocional desmarcado con explicación, aviso de que los pedidos de ayuda nunca se comparten | PASS. "Gerar" desactivado sin relación | [B1-invite-own-defaults-generate-disabled.png](B1-invite-own-defaults-generate-disabled.png), [B1-relationship-8-options.png](B1-relationship-8-options.png), [B1-categories-emotional-explanation-safety.png](B1-categories-emotional-explanation-safety.png), [B1-invite-code-dialog.png](B1-invite-code-dialog.png) |
| B2 Invitar un dependiente: confirmación del responsable obligatoria | PASS. "Gerar" desactivado hasta marcarla; BD guarda `dependent_share_confirmed_at` | [B2-dependent-confirm-required-disabled.png](B2-dependent-confirm-required-disabled.png) |
| B3 Bruno acepta el código escrito en minúsculas; ambos lados ven relación y categorías | PASS. El campo pasa a mayúsculas | [B3-accept-lowercase-uppercased.png](B3-accept-lowercase-uppercased.png), [B3-grantee-list-relationship-chips.png](B3-grantee-list-relationship-chips.png), [B3-owner-list-relationship-chips.png](B3-owner-list-relationship-chips.png) |
| B4 Bruno en el perfil de Ana solo con hábitos: ve agua y hábitos; diarios, condiciones y cuidados dicen "Não compartilhado com você"; historial correcto; API 403; BD 0 filas | PASS tras corregir fallos 1, 2 y 3. API: condiciones y cuidados 403, entradas del diario lista vacía (RLS). BD como `dualis_app`: 0 filas en journal_entries, user_conditions y care_records (como postgres hay 2, 1 y 1) | [B4-home-viewonly-journal-not-shared.png](B4-home-viewonly-journal-not-shared.png), [B4-care-not-shared.png](B4-care-not-shared.png), [B4-history-hint-physical-only.png](B4-history-hint-physical-only.png), [evidence/B4-api-db.txt](evidence/B4-api-db.txt) |
| B5 Ana añade `physical_journal` y luego `emotional_journal`: Bruno ve las nuevas áreas al actualizar; explicación del emocional visible | PASS tras corregir fallos 3 y 4 | [B5-physical-added-visible-no-start.png](B5-physical-added-visible-no-start.png), [B5-emotional-added-visible-after-refresh.png](B5-emotional-added-visible-after-refresh.png), [B5-edit-categories-dialog.png](B5-edit-categories-dialog.png) |
| B6 VIEW_ONLY sin botones de escritura; CO_MANAGE escribe en un área concedida y no en otra | PASS. VIEW_ONLY: sin "+200 ml", sin "Adicionar" en cuidados, los inicios de check-in no abren nada; API 403 "Acesso somente leitura". CO_MANAGE (Sofia, hábitos): +200 ml por la UI y por API 201; diario físico, condiciones y cuidados 403 | [B4-B6-hydration-viewonly-no-add.png](B4-B6-hydration-viewonly-no-add.png), [B6-viewonly-care-subscreen-no-add.png](B6-viewonly-care-subscreen-no-add.png), [B6-comanage-water-added.png](B6-comanage-water-added.png), [evidence/B6-api.txt](evidence/B6-api.txt) |
| B7 Grant antiguo con `relationship` NULL (insertado por SQL) | PASS. Se muestra "Não informado" | [B7-legacy-grant-nao-informado.png](B7-legacy-grant-nao-informado.png) |
| B8 Editar categorías de un grant revocado; código inválido; aceptar el código propio | PASS tras corregir fallo 4. Revocado: mensaje de `GRANT_SCOPE_LOCKED` en la app y 409 en la API. Inválido: "Código inválido ou expirado." Propio: ahora "Este código é seu…" | [B8-scope-locked-error.png](B8-scope-locked-error.png), [B8-invalid-code-error.png](B8-invalid-code-error.png), [BUG4-after-self-accept-specific-message.png](BUG4-after-self-accept-specific-message.png), [evidence/B8-api.txt](evidence/B8-api.txt) |
| B9 Revoca Ana (Lucas, Sofia) y revoca Bruno (grant de Diego): el acceso desaparece en la misma sesión | PASS tras corregir fallo 3. BD `REVOKED`; como `dualis_app` Bruno ve 0 filas de Diego | [B9-revoked-by-ana-gone-same-session.png](B9-revoked-by-ana-gone-same-session.png), [E3-revoke-dialog-help.png](E3-revoke-dialog-help.png) |

### C. Traspaso a los 18

| Caso | Resultado | Evidencia |
|------|-----------|-----------|
| C1 Dependiente con 18 años (fecha cambiada por SQL): aviso para Ana, código con caducidad y copiar, correo único en el log | PASS tras corregir fallo 5. El aviso sale una sola vez aunque la lista se pida varias veces | [C1-handover-notice.png](C1-handover-notice.png), [C1-handover-code-dialog.png](C1-handover-code-dialog.png), [evidence/C1-email-log.txt](evidence/C1-email-log.txt) |
| C2 Carla (cuenta nueva) introduce el código: el perfil pasa a ser suyo y principal; Ana ya no lo ve (selector, API y BD); guarda cerrada pero conservada; grants revocados | PASS. Ana: 403 con `X-Profile-Id` y 0 filas como `dualis_app`. Guarda `closed_reason = handed_over`. Para probar la revocación de un grant activo se repitió con Sofia y Elisa: `ACCEPTED` pasó a `REVOKED` y Bruno recibe 403 | [C2-claimed-profile-is-carlas.png](C2-claimed-profile-is-carlas.png), [C2-D-ana-switcher-lucas-gone-legal-basis-notice.png](C2-D-ana-switcher-lucas-gone-legal-basis-notice.png), [evidence/C2-checks.txt](evidence/C2-checks.txt), [evidence/C2-grants-revoked.txt](evidence/C2-grants-revoked.txt) |
| C3 Errores: código inválido, Ana con su propio código, Diego con datos, perfil menor de 18 | PASS. Cada uno con su mensaje: `CLAIM_INVALID_CODE`, `CLAIM_BY_GUARDIAN`, `CLAIM_ACCOUNT_HAS_DATA`, `CLAIM_NOT_ADULT` (UI) y `HANDOVER_NOT_DUE` (API, al pedir código para Sofia con 13 años) | [C3-invalid-claim-code.png](C3-invalid-claim-code.png), [C3-claim-by-guardian.png](C3-claim-by-guardian.png), [C3-claim-account-has-data.png](C3-claim-account-has-data.png), [C3-claim-not-adult.png](C3-claim-not-adult.png), [evidence/C3-api.txt](evidence/C3-api.txt) |

### D. Reconfirmación de la base legal

| Caso | Resultado | Evidencia |
|------|-----------|-----------|
| D Dependiente con curatela guardado como `lgpd_art_14` (por SQL): aviso, "Confirmar" desactivado hasta marcar la declaración Art. 11, I; después BD `lgpd_art_11_i` y el aviso desaparece | PASS. Tocar "Confirmar" sin marcar no cambia la BD | [C2-D-ana-switcher-lucas-gone-legal-basis-notice.png](C2-D-ana-switcher-lucas-gone-legal-basis-notice.png), [D-confirm-disabled-until-declaration.png](D-confirm-disabled-until-declaration.png), [D-confirmed-notice-gone-code-active.png](D-confirmed-notice-gone-code-active.png), [evidence/D-db.txt](evidence/D-db.txt) |

### E. Ayuda urgente a 1 toque

| Caso | Resultado | Evidencia |
|------|-----------|-----------|
| Botón de ayuda visible en todas las pantallas, hojas y diálogos nuevos: selector, alta de dependiente, invitación, edición de categorías, aceptar código, revocar, código de traspaso, reconfirmación, hoja de reclamación, también en la pantalla de bienvenida sin sesión | PASS | [E1-switcher-sheet-help.png](E1-switcher-sheet-help.png), [E3-revoke-dialog-help.png](E3-revoke-dialog-help.png), [E4-claim-sheet-help-C2.png](E4-claim-sheet-help-C2.png), resto de capturas |
| Tocarlo una vez desde la hoja de reclamación abre la ayuda (SAMU 192, CVV 188, 193, 190) | PASS | [E5-urgent-help-opened-from-claim-sheet.png](E5-urgent-help-opened-from-claim-sheet.png) |

### F. Salud en ejecución

| Caso | Resultado | Evidencia |
|------|-----------|-----------|
| `get_runtime_errors` vacío al final; log de `flutter run` sin excepciones ni overflows | PASS. Hubo una vez un error "Guarded function conflict" de `FlutterDriverExtension`, causado por dos órdenes del driver solapadas (herramienta de prueba, no la app); se limpió con un hot restart y no volvió | — |

## Fallos encontrados y corregidos

Cada corrección tiene su prueba (falla sin la corrección y pasa con ella) y se volvió a probar en vivo.

1. **El receptor veía "Titular" en el perfil de otra persona** (selector de perfiles). El perfil principal de Ana, compartido con Bruno, salía como "Titular" con el color de dueño, porque se miraba "principal" antes que "compartido". Ahora dice "Somente leitura" o "Co-gestão". Commit `513f154`. Antes/después: [BUG1-before-shared-primary-titular.png](BUG1-before-shared-primary-titular.png), [BUG1-after-shared-primary-viewonly.png](BUG1-after-shared-primary-viewonly.png).
2. **Lo mismo en la tarjeta de inicio** (`profileContextSubtitle`). Commit `316905d`. Antes: [BUG1b-before-home-card-titular.png](BUG1b-before-home-card-titular.png).
3. **El historial se leía como "no hay registros"** cuando el diario no estaba compartido. Con solo hábitos, las pestañas Emoções y Corpo decían "Você ainda não tem registros neste período", como si Ana no hubiera escrito nada. Ahora esas pestañas muestran "Não compartilhado com você" y la lista de entradas se oculta si no se comparte ningún diario. Commit `4dae0ec`. Antes/después: [BUG2-before-history-reads-as-empty.png](BUG2-before-history-reads-as-empty.png), [BUG2-after-history-emotions-not-shared.png](BUG2-after-history-emotions-not-shared.png).
4. **Los permisos del receptor no se actualizaban en la misma sesión.** Perfiles y grants solo se cargaban al entrar o al abrir Compartilhamento Familiar. Las categorías nuevas, los perfiles nuevos y las revocaciones no aparecían hasta salir y volver a entrar. Ahora se recargan al abrir el selector de perfiles (commit `5ef77d7`) y con el botón de actualizar del historial (commit `adb9436`). Antes del segundo cambio, el historial podía decir "não compartilhado" encima de entradas de esa misma categoría: [BUG3b-before-stale-categories-mixed.png](BUG3b-before-stale-categories-mixed.png). Después: [BUG3-after-switcher-refreshes-grants.png](BUG3-after-switcher-refreshes-grants.png), [B5-emotional-added-visible-after-refresh.png](B5-emotional-added-visible-after-refresh.png).
5. **Aceptar el propio código decía "Código inválido ou expirado".** La API devolvía un 400 genérico en inglés ("Cannot share access with yourself") y la app mostraba el error de código inválido. Ahora la API devuelve `code: INVITE_OWN_PROFILE` con un mensaje en pt-BR, y la app muestra "Este código é seu. Envie-o para a pessoa que vai acompanhar você." (pt, es, en, sin texto cortado). Commit `22a6c6c`. Antes/después: [BUG4-before-self-accept-generic-error.png](BUG4-before-self-accept-generic-error.png), [BUG4-after-self-accept-specific-message.png](BUG4-after-self-accept-specific-message.png).
6. **El aviso de los 18 años no aparecía en modo simulación.** Sin `RESEND_API_KEY` se descartaba sin dejar rastro, así que no se podía comprobar en local que se envía una sola vez. Ahora escribe una línea de simulación (sin código, nunca en producción), como los demás correos. Commit `d4b9548`.

Pruebas después de las correcciones: `flutter analyze` sin problemas; `flutter test test/features/profile test/features/dashboard test/features/home`: 218 pasan; `vitest` unit del backend: 481 pasan (31 archivos). El texto nuevo no tiene vocabulario vetado (`findBannedVocabulary`).

## Hallazgos abiertos

1. **El botón de ayuda flotante tapa en parte la "X" de la hoja de perfiles** cuando la hoja ocupa toda la altura (4 o más perfiles). La hoja se puede cerrar igual (la mitad de la X sigue libre y se puede deslizar hacia abajo), y la ayuda sigue a 1 toque. Es una decisión de diseño (mover la X o el botón), no un fallo de funcionamiento. Captura: [E2-tall-switcher-help-overlaps-close.png](E2-tall-switcher-help-overlaps-close.png).
2. **Las entradas del diario no compartido devuelven 200 con lista vacía, no 403** (`GET /v1/journal/entries` de Bruno sobre Ana solo con hábitos). La RLS filtra bien (0 filas) y la app muestra "Não compartilhado". Condiciones y cuidados sí devuelven 403. Es coherente con el diseño (en la lista del diario el filtro va por entrada, A1/A9), pero el caso B4 pedía 403 "para una categoría no concedida". Queda anotado para decidir si hace falta un 403 cuando no se comparte ninguno de los dos diarios.

## Notas

- En C2, la cuenta de Carla no tenía perfiles a cargo ni grants, así que el traspaso de Lucas no tenía grants activos que revocar (Ana ya lo había revocado en B9). Por eso se repitió el traspaso con Sofia (grant ACCEPTED para Bruno) y una cuenta nueva (Elisa), por API.
- El contenedor Docker sigue en marcha con los datos de la prueba.
