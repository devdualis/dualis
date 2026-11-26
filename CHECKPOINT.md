# Checkpoint: iconos propietarios del diario (2026-11-26)

## Qué se completó

El objetivo es que cada mark (icono propietario del diario) se entienda sin leer su etiqueta. Antes muchos eran formas abstractas, como arcos, cúpulas o puntos, y varios significados compartían el mismo dibujo.

Commits en `main`:

- `270797e`: 76 marks rediseñados en 6 tandas (ánimo y sueño, ramas "Não tão bem" y "Bem", persistencia, desencadenantes, afrontamiento, ayudas y sensaciones del cuerpo).
- `e48fb75`: "Em paz" (`paz`) y "Confiante" (`confiante`) con dibujo propio.
- `e0bbdc8`: 11 zonas del cuerpo como silueta con la zona en cian.
- `50ac880`: 14 opciones que repetían el icono de su zona ahora tienen uno propio:
  - Pelve: `xixi` (inodoro), `vontade_xixi` (gota con flecha circular), `fluxo_fraco` (grifo que gotea), `urina_cor` (gota oscura con ondas de olor), `baixo_ventre` (torso con la zona bajo el ombligo) e `intima` (ropa interior sola). `pelve` no cambió.
  - Pele: `pele_aparencia` (lupa sobre la piel), `vermelhidao` (mancha grande con halo) y `manchas` (varias manchas irregulares).
  - Respiração: `respiracao` (pulmones con aire), `respiracao_curta` (perfil con soplos cortos) y `tosse` (perfil con estallido).
  - Temperatura: `calorao` (persona con ondas de calor y sudor) y `frio` (persona tiritando con copo de nieve).
  - Las claves antiguas `pelve.urina*` y `pelve.intima` solo aparecen en el historial, pero también tienen dibujo propio.

- Tanda 8 (este commit siguiente a `2df7dfd`): `musculos` (brazo flexionado), `tensao` (hombros subidos con zigzags), `dolorido` (brazo con destello), `membros_pesados` (figura con flechas hacia abajo), `temporas` y `rosto` (cabeza de perfil con la zona en cian: frente y sien, o cara baja), `dor_mexer` (figura caminando con destello en la espalda) y `apetite` (bol con comida y vaso).

- Tanda 9 (`169dd4b`): `refluxo` (torso con llama y flecha a la garganta) para `barriga.queimacao.subindo`, `irradia` (figura con destello en la espalda y flecha por la pierna) para `costas.fisgada.irradia`, `cansaco_muscular` (brazo de `musculos` con gotas de sudor) para la rama `musculos.cansaco`, `fraqueza` redibujado (mismo brazo con flecha hacia abajo), `pele_ardencia` (piel con llama) para `pele.coceira.ardencia` y `hormonios` (persona con flechas de ciclo) para la zona `hormonios`. El brazo se hizo componiendo `musculos.png` sin su relleno cian más el acento en SVG.
- Tanda 10 (`b3c283a`): `pele_coceira` (piel con rasguños cian) para `pele.coceira.coceira`, `coceira_ardencia` (piel con rasguños y llama) para la rama `pele.coceira`, y el desencadenante `sono` ("Noite mal dormida") reusa `sono_mal`. Los rasguños sueltos `coceira` quedan para la pelve y las claves antiguas; `descansar` y `repouso` siguen con `cama`.
- Tanda 11 (`1c7e13b`): `refluxo` e `irradia` con acentos cian más gruesos (trazo 3.6–3.8, llama y destello más grandes) tras verlos en el simulador; `irradia` queda como figura quieta de frente para no confundirse con `dor_mexer`.

Tests: `flutter test test/features/journal/ test/features/journal_insights/` pasó (201) después de la tanda 11. El test "a screen never shows the same phrase twice in a row" era inestable (en ~0,5 % de las semillas no salían las 7 variantes); ahora usa semilla fija (`1f4513b`). Todos los archivos que nombra el mapa existen en `assets/marks/`.

## Estado actual

- `main` está sincronizado con `origin/main`.
- Los PNG viven en `mobile/assets/marks/` (160×160, RGBA) y el mapa clave→archivo está en `mobile/lib/features/journal/presentation/journal_marks.dart`, en `_byKey` y `_sleep`.
- Tamaños en la app: 64px en tarjetas grandes y entre 16 y 26px en filas e historial. Cada mark debe leerse a 22px.
- Verificado en el simulador iPhone 17 (build debug contra el backend de producción, `--dart-define=API_BASE_URL=https://dualis-backend-476640769147.southamerica-east1.run.app`): zonas "No corpo todo", pele, músculos, barriga, costas y desencadenantes muestran los marks nuevos. No se guardó ningún registro de prueba.
- Para revisar en la app: login con la cuenta del usuario (pedirla con una tarjeta privada), "Atualizar" en Físico, "Não tão bem" y elegir zonas. En el simulador, "Continuar" a veces pareció necesitar un segundo toque; en tests de widget un solo toque 16 ms después de marcar avanza (emocional y físico), así que probablemente es la automatización.
- Los SVG fuente y los scripts generadores quedaron en el scratchpad de la sesión. No son durables; usa la receta de abajo para regenerarlos.

## Sistema visual (respetarlo)

- Duotono: navy `#032B5F` para la estructura y cian `#20CAEB` para el acento o la idea clave.
- SVG con `viewBox="0 0 48 48"`, trazo 2.6 navy, `stroke-linecap/linejoin="round"` y salida PNG de 160px.
- Render: `pip install resvg-py pillow` en un venv y `resvg_py.svg_to_bytes(svg_string=...)`.
- Formas compartidas:
  - Persona: cabeza con `circle r=4.6` en (24,23) más hombros `M13.5 43 C13.5 35 18 31 24 31 C30 31 34.5 35 34.5 43`.
  - Cabeza de perfil (`HEAD`, mira a la derecha): `M15 43 V35.5 C10 32.5 8.5 26.5 9 21 C9.8 12 16.5 6 25 6 C33 6 38.5 11.5 38.5 19 L41.5 25.5 L38.5 26.5 V31.5 C38.5 33.5 37 34.5 35 34.5 H31.5 V43`. Para dejar sitio delante de la boca: `translate(-3 2) scale(0.92)`.
  - Torso: `M19 3 V6.5 C19 8.5 17 9.5 13 10 C8.5 10.5 6 13 6.5 17 C7 23 10 27 10 32 C10 36 8.5 40 8 44`, más su espejo en x.
  - Piel (cuadrado ondulado): `M13 7 C18 9 30 9 35 7 C39 6 42 9 41 13 C39 18 39 30 41 35 C42 39 39 42 35 41 C30 39 18 39 13 41 C9 42 6 39 7 35 C9 30 9 18 7 13 C6 9 9 6 13 7Z`.
  - Corazón: `M24 40 C10 31 6 24 6 17.5 C6 12 10 8 15 8 C19 8 22 10.5 24 14 C26 10.5 29 8 33 8 C38 8 42 12 42 17.5 C42 24 38 31 24 40Z`.
- Reglas que fijó el usuario:
  - Pictogramas literales, no abstractos.
  - Un dibujo por significado.
  - Nada que se vea descuidado o deforme: proporciones limpias y piezas geométricas en vez de contornos a mano alzada.
  - Mostrar un antes/después a 64px y a 22px y esperar aprobación antes de copiar al repo.
  - Evitar dibujos que se lean como otra cosa: un vaso con vapor parecía una taza de café.

## Próximos pasos (opcionales)

La revisión de marks está terminada. Solo quedan ideas si el usuario quiere seguir:

1. No quedan pictogramas compartidos entre significados distintos. Lo que se repite son claves antiguas y su equivalente nueva, o el mismo significado en zonas distintas.
2. Pendiente de aprobación (2026-11-26): reforzar a 22px `cabeca`, `nariz`, `ouvido`, `pulmoes`, `perna`, `joelho`, `tronco`, `algo`, `alguem`, `orgulho`, `confiante`, `fome`, `fluxo_fraco` y `escrever`.
3. Si algún mark se ve débil a 22px, engrosar el acento cian (trazo 3.6–3.8) como en la tanda 11.
4. Reglas aprendidas en la tanda 8: en cabezas de frente, cualquier punto o arco se lee como ojos o boca. Para marcar zonas de la cabeza usar `HEAD` de perfil con la zona en cian recortada por `clipPath` del mismo contorno.

Para sacar la lista completa, agrupa por archivo las líneas `'clave': 'archivo',` de `journal_marks.dart`.

Después de cada cambio de mapa: correr los tests del diario y del historial, verificar que cada archivo mapeado exista en `assets/marks/` y hacer commit y push a `main` (el usuario lo autoriza en cada tanda).
