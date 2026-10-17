# DualisCheckUp como app de bienestar

**Propuesta de actualización** | 15 de octubre de 2026

---

## En una página

**Qué pasa hoy.** Por lo que hace y por lo que dice, DualisCheckUp funciona hoy como un **software médico**:
- evalúa los síntomas de cada persona;
- le dice qué tipo de atención buscar (autocuidado, consulta, pronto atención o emergencia);
- sus propios Términos de uso afirman que está clasificado bajo la norma de dispositivos médicos de ANVISA.

En Brasil, la Unión Europea y Estados Unidos, eso exige registro sanitario antes de lanzar. Es un proceso largo y costoso, y distinto en cada país. Eso choca con el plan de internacionalizar Dualis.

**Qué proponemos.** Reposicionar Dualis como **app de bienestar**: un diario diario de cómo te sientes en el cuerpo y en las emociones, con hábitos, historial y contenidos educativos. Mantiene la experiencia que ya existe, pero la app **deja de decidir** sobre la salud de cada persona. La ayuda de emergencia queda **siempre a un toque**, para todos.

**Cuánto lleva.** Unas **5 semanas** de trabajo de ingeniería por etapas, más la revisión de un consultor regulatorio externo.

**Qué necesitamos de ustedes.** Seis decisiones, listadas al final. La más importante: aceptar que la app **no indique urgencia**.

**Qué es urgente aunque no se haga nada más.** Dos cosas deberían corregirse esta misma semana:
- **Artículos con autores no verificados:** los artículos de la app citan médicos y psicólogos con números de registro profesional (CRM/CRP) que no pudimos verificar.
- **Términos de uso:** el texto declara que la app es un dispositivo médico.

---

## 1. Por qué importa

Los reguladores no miran la categoría que se elige en la tienda de apps. Miran **qué hace la app y qué promete**, en la app y fuera de ella: pantallas, términos, ficha de tienda, sitio web, presentaciones y documentos internos.

- **App de bienestar.** Ayuda a la persona a registrar y conocer sus hábitos y cómo se siente. No requiere registro sanitario. Ejemplos: diarios de ánimo, apps de hidratación, de sueño o de hábitos.
- **Software médico.** Evalúa la salud de una persona concreta y le dice qué hacer. Requiere registro: ANVISA en Brasil, marcado CE en Europa y autorización de la FDA en Estados Unidos. En Europa además se suman las obligaciones de la ley de inteligencia artificial para sistemas de alto riesgo.

La auditoría que hicimos concluye que, **tal como está hoy**, Dualis probablemente sería software médico en Brasil y en Europa, y tendría riesgo medio-alto en Estados Unidos. Las tiendas de Apple y Google también pedirían pruebas de autorización sanitaria.

> Esta conclusión es un análisis técnico, no asesoría legal. Recomendamos que un consultor regulatorio la confirme antes del lanzamiento.

---

## 2. Qué cambia para el usuario

| Hoy | Después |
|---|---|
| "Triagem preventiva" | **"Diário de bem-estar"**: el usuario registra cómo se siente. |
| Al terminar, la app recomienda "Consulta", "Pronto Atendimento" o "Emergência" según lo que respondió | Al terminar, ve un **resumen de lo que registró** y un mensaje igual para todos: *"Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192."* |
| Una pantalla roja de emergencia aparece **solo si el algoritmo decide**, y no se puede cerrar | Un botón **"Ajuda urgente" visible en todas las pantallas**, con los números de emergencia del país del usuario y una lista de señales de alarma oficial. Si el usuario anota algo muy fuerte, ve un aviso: *"Se isso for uma emergência, ligue 192 agora."* |
| La app nombra posibles problemas ("Suspeita de AVC", "Dor torácica crítica") | La app **no nombra condiciones**. Habla del cuerpo en lenguaje común: "Peito", "Cabeça", "Respiração". |
| "Intensidade calculada" en una "escala clínica" | **"Intensidade que você informou"**: es la nota que dio la propia persona. |
| "Foco de atenção: desconforto severo" | **"Padrões nos seus registros"**: *"Você registrou dor de cabeça com intensidade alta 3 vezes em 10 dias."* |
| La inteligencia artificial clasifica la urgencia del síntoma | La inteligencia artificial **organiza las anotaciones** del diario (qué parte del cuerpo, qué emoción). No evalúa nada. |
| "Artigos médicos recomendados para seus sintomas", firmados por médicos | **"Leituras sobre bem-estar"**, contenido general con su **fuente oficial real** (por ejemplo, Ministério da Saúde). |
| Números de emergencia solo de Brasil | Números según el país: 192 y 188 en Brasil, 911 y 988 en Estados Unidos, 112 en Europa, etc. |
| "Paciente", "prontuário", "histórico clínico" | "Olá", "seus registros", "histórico de registros". |

## 3. Qué se mantiene igual

- El check-in diario en dos ejes: **físico y emocional**.
- El **mapa del cuerpo** y el historial de 14 días.
- **Hidratación**, recordatorios y notificaciones.
- **Perfiles familiares**: dependientes con consentimiento legal y compartir con la familia. Se terminaron en la fase 11.
- Funcionamiento **sin conexión**.
- Privacidad y seguridad: cifrado, control de acceso por perfil, exportación y borrado de datos (LGPD).
- La red de seguridad ante mensajes de **riesgo de suicidio**, que sigue mostrando el CVV 188. Es una práctica estándar de seguridad de contenido.

## 4. Seguridad del usuario: mejora, no empeora

Hoy, la ayuda de emergencia **solo aparece** si la persona hace un check-in y el algoritmo detecta un caso grave. Fuera de ese flujo, la app no ofrece ayuda.

Con el cambio:
- La ayuda está **a un toque desde cualquier pantalla**, para todos y sin condiciones.
- Funciona **sin internet**.
- Usa los **números correctos de cada país**.
- **Nunca** queda detrás de un plan pago.

La promesa deja de ser "detectamos tu emergencia", que es una afirmación médica. Pasa a ser **"la ayuda siempre está a un toque"**.

## 5. Cambios en los planes futuros

| Función planeada | Recomendación |
|---|---|
| Cartera de vacunas | Se mantiene. |
| Registro de alergias | Se mantiene el registro. Se **quita** la alerta automática que cruza alergias con medicamentos (es una función médica). |
| Condiciones de salud | Se mantiene, como "condições informadas por você". |
| Recordatorios de medicamentos | Se mantienen. |
| PDF para llevar al médico | Se mantiene como **"Resumo dos meus registros"**, sin evaluación ni recomendación. |
| Lectura de exámenes de laboratorio | Solo **guardar y transcribir** los valores que la persona confirma, con el rango que trae el propio informe. Si se quiere **interpretar** resultados, hacerlo con un socio que ya tenga registro sanitario. |
| Lectura de recetas | Posponer hasta tener la opinión del consultor: un error puede generar una dosis equivocada. |
| Resumen de prospectos (bulas) con IA | Se **quita**. Se reemplaza por un enlace al prospecto oficial de ANVISA o por contenido licenciado. |
| Interacción por voz | Se mantiene como "registro por voz". |
| Suscripciones | Se mantienen, sin promesas médicas en la oferta. |

## 6. Privacidad: lo que sigue siendo obligatorio

Ser una app de bienestar **no** cambia la naturaleza de los datos. Lo que la persona registra sigue siendo información sensible de salud. Por eso, en paralelo:

- **Inteligencia artificial y residencia de datos:** hoy los textos de los usuarios se procesan en Google con una configuración que **no garantiza que los datos queden en Brasil**. Eso contradice lo que promete la política de privacidad. Proponemos migrar a la versión empresarial de Google con región en Brasil o Europa, con contrato de procesamiento de datos y sin uso de los datos para entrenar modelos.
- **Informe de impacto de privacidad** (LGPD y GDPR) y un **encargado de datos (DPO)** publicado.
- **Publicidad:** ningún dato de salud puede usarse para anuncios.
- **Menores de edad:** reglas específicas por país para los perfiles de dependientes.

## 7. Calendario

| Etapa | Cuándo | Qué se entrega |
|---|---|---|
| 1. Riesgos inmediatos | Semana 1 | Artículos sin autores no verificados, Términos y Privacidad reescritos, textos principales de la app y documentación interna. |
| 2. Cambio de comportamiento | Semanas 2-3 | La app deja de recomendar tipo de atención; botón "Ajuda urgente"; nueva inteligencia artificial de organización. |
| 3. Ajustes internos | Semana 4 | Base de datos y servidor alineados; compatibilidad con versiones anteriores de la app. |
| 4. Validación | Semana 5 | Pruebas completas en el teléfono; versión lista para el consultor regulatorio. |
| En paralelo | Semanas 1-5 | Privacidad, fichas de las tiendas y nombre comercial. |

La revisión del consultor regulatorio es externa y no está incluida en estas 5 semanas.

## 8. Riesgos y cómo los manejamos

- **Si el valor principal de Dualis es "decir qué tan urgente es lo que siento",** eso no puede ser bienestar en ningún país. En ese caso proponemos lanzar ahora el diario de bienestar y desarrollar la evaluación de urgencia como **producto separado con registro sanitario**, o con un socio que ya lo tenga.
- **Usuarios actuales** que ya conocen la recomendación: avisarles dentro de la app y darles a cambio los nuevos resúmenes de patrones.
- **Versiones antiguas de la app:** agregar un aviso de "actualizar" antes de retirar funciones del servidor.

## 9. Decisiones que necesitamos de ustedes

1. **¿Aceptan que la app no indique urgencia ni tipo de atención?** Es la base de todo el plan.
2. **Autores de los artículos:** ¿existen contratos con los profesionales citados? Si no, se quitan de inmediato.
3. **Inteligencia artificial:** ¿migramos a la versión empresarial de Google con datos en Brasil o Europa?
4. **Exámenes de laboratorio:** ¿solo guardar y transcribir, o buscar un socio regulado para interpretar?
5. **Nombre en las tiendas:** "CheckUp" sugiere chequeo médico. ¿Lo mantenemos o usamos "Dualis: Diário de bem-estar"?
6. **Consultor regulatorio:** ¿quién y cuándo? Recomendamos contratarlo en paralelo a la etapa 1.

## 10. Después de la conversión: cómo crecer dentro de bienestar

Una vez reposicionada, la app puede ganar valor con funciones que encajan en bienestar:
- integración con Apple Health y Google Health Connect (pasos, sueño, frecuencia cardíaca);
- seguimiento del sueño;
- ejercicios de respiración y diario emocional guiado;
- hábitos y metas;
- carpeta personal de salud (vacunas, documentos, contactos de emergencia);
- seguimiento del ciclo menstrual (solo registro);
- derivación a teleconsulta con socios que ya tengan registro sanitario.

---

*Documentos que acompañan esta propuesta:*
- *"Plan Técnico de Reposicionamiento a Bienestar", con el detalle de cada cambio para el equipo técnico.*
- *"Auditoría de Uso Previsto", con la lista completa de hallazgos.*
