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

Tests: `flutter test test/features/journal/ test/features/journal_insights/` pasó (201) después de `50ac880`. Todos los archivos que nombra el mapa existen en `assets/marks/`.

## Estado actual

- `main` está sincronizado con `origin/main`.
- Los PNG viven en `mobile/assets/marks/` (160×160, RGBA) y el mapa clave→archivo está en `mobile/lib/features/journal/presentation/journal_marks.dart`, en `_byKey` y `_sleep`.
- Tamaños en la app: 64px en tarjetas grandes y entre 16 y 26px en filas e historial. Cada mark debe leerse a 22px.
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

La lista anterior está terminada. Todavía hay archivos que comparten varias claves. La mayoría está bien porque es el mismo significado: una clave antigua y su equivalente nueva, o una rama con una sola opción. Estos son los candidatos a revisar con el usuario:

1. `peso` lo usan `membros.cansaco.pesados`, `musculos.cansaco.dolorido` y `pelve.baixo_ventre.peso`. "Dolorido" podría necesitar dibujo propio.
2. `cabeca` lo usan la zona `cabeca`, `cabeca.pressao.temporas` y `cabeca.rosto`. Faltan dibujos para sienes y rostro.
3. `tronco` lo usan `musculos`, `musculos.tensao` y `physical`.
4. `caminhar` lo usan `mexer_corpo` y `costas.fisgada.ao_mexer` ("dolor al moverse").
5. `alimentacao` lo usan `alimentacao` y `hormonios.apetite`.
6. `temperatura` lo usan la zona `hormonios` y `hormonios.temperatura`.

Para sacar la lista completa, agrupa por archivo las líneas `'clave': 'archivo',` de `journal_marks.dart`.

Después de cada cambio de mapa: correr los tests del diario y del historial, verificar que cada archivo mapeado exista en `assets/marks/` y hacer commit y push a `main` (el usuario lo autoriza en cada tanda).
