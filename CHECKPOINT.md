# Checkpoint: iconos propietarios del diario (2026-11-26)

## Qué se completó

El objetivo es que cada mark (icono propietario del diario) se entienda sin leer su etiqueta. Antes muchos eran formas abstractas, como arcos, cúpulas o puntos, y varios significados compartían el mismo dibujo.

Commits ya en `main`:

- `270797e`: 76 marks rediseñados en 6 tandas:
  - ánimo y sueño (caras; las de sueño llevan luna)
  - rama "Não tão bem": tiempo, ramas y opciones
  - rama "Bem": ramas y opciones
  - persistencia, desencadenantes, afrontamiento y ayudas
  - sensaciones del cuerpo
- `e48fb75`: "Em paz" (`paz`) y "Confiante" (`confiante`) con dibujo propio.
- `e0bbdc8`: 11 zonas del cuerpo dibujadas como silueta con la zona en cian: nuca, mandíbula, garganta, presión, hombros, costillas, barriga, gases, pelvis, espalda y lumbar.

Archivos nuevos que se agregaron al mapa de `mobile/lib/features/journal/presentation/journal_marks.dart`:

- `dias`: antes era `passado`.
- `esperar`: antes era `hoje`.
- `emocional`: antes era `mente`.
- `pontada`, `batedeira`, `choque` y `caibra`: antes las cuatro usaban `latejando`.
- `paz` y `confiante`.

Tests: `flutter test test/features/journal/ test/features/journal_insights/` pasó (201) después del último cambio de mapa (`e48fb75`). El commit `e0bbdc8` solo reemplazó PNG, así que después de él no se volvieron a correr.

## Estado actual

- `main` está limpio y sincronizado con `origin/main` en `e0bbdc8`. Este archivo no está commiteado.
- Los PNG viven en `mobile/assets/marks/` (160×160, RGBA) y el mapa clave→archivo está en `journal_marks.dart`, en `_byKey` y `_sleep`.
- Tamaños en la app: 64px en tarjetas grandes y entre 16 y 26px en filas e historial. Cada mark debe leerse a 22px.
- Los SVG fuente y los scripts generadores quedaron en el scratchpad de la sesión. No son durables; usa la receta de abajo para regenerarlos.

## Sistema visual (respetarlo)

- Duotono: navy `#032B5F` para la estructura y cian `#20CAEB` para el acento o la idea clave.
- SVG con `viewBox="0 0 48 48"`, trazo 2.6 navy, `stroke-linecap/linejoin="round"` y salida PNG de 160px.
- Render: `pip install resvg-py pillow` en un venv y `resvg_py.svg_to_bytes(svg_string=...)`.
- Formas compartidas:
  - Persona: cabeza con `ring r=4.2` más hombros redondeados.
  - Cabeza de perfil (`HEAD`, mira a la derecha): `M15 43 V35.5 C10 32.5 8.5 26.5 9 21 C9.8 12 16.5 6 25 6 C33 6 38.5 11.5 38.5 19 L41.5 25.5 L38.5 26.5 V31.5 C38.5 33.5 37 34.5 35 34.5 H31.5 V43`.
  - Torso: `M19 3 V6.5 C19 8.5 17 9.5 13 10 C8.5 10.5 6 13 6.5 17 C7 23 10 27 10 32 C10 36 8.5 40 8 44`, más su espejo en x.
  - Corazón: `M24 40 C10 31 6 24 6 17.5 C6 12 10 8 15 8 C19 8 22 10.5 24 14 C26 10.5 29 8 33 8 C38 8 42 12 42 17.5 C42 24 38 31 24 40Z`.
- Reglas que fijó el usuario:
  - Pictogramas literales, no abstractos.
  - Un dibujo por significado.
  - Nada que se vea descuidado o deforme: proporciones limpias y piezas geométricas en vez de contornos a mano alzada.
  - Mostrar un antes/después a 64px y a 22px y esperar aprobación antes de copiar al repo.

## Próximos pasos

Dar icono propio a las opciones que hoy repiten el de su zona. Cada una necesita un PNG nuevo y una línea en `_byKey`:

1. **Pelve:** 9 claves usan `pelve`:
   - `pelve.baixo_ventre`
   - `pelve.intima`
   - `pelve.urina`
   - `pelve.urina.cor_odor`
   - `pelve.urina.dificuldade`
   - `pelve.urina.vontade`
   - `pelve.xixi_intima`
   - `pelve.xixi_intima.vontade`
   - (la propia `pelve`)

   Sacar las etiquetas de `jv2Branch*`/`jv2Opt*` en `mobile/lib/l10n/app_pt.arb`.
2. **Pele:** `pele.aparencia`, `pele.aparencia.manchas` y `pele.aparencia.vermelhidao` usan `pele`.
3. **Pulmões:** `peito.respiracao`, `peito.respiracao.curta` ("Respiração curta") y `peito.respiracao.tosse` ("Tosse ou peito carregado") usan `pulmoes`.
4. **Temperatura:** `hormonios.temperatura.calorao` ("Calorões") y `hormonios.temperatura.frio` ("Frio fora do comum") comparten `temperatura`.
5. Después de cambiar el mapa: correr los tests del diario y del historial, verificar que cada archivo mapeado exista en `assets/marks/` y hacer commit y push a `main` (el usuario lo autoriza en cada tanda).
