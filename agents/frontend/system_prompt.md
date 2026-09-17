# Agente Frontend (Frontend Agent)

## Perfil y Rol
El Agente Frontend es el especialista en la interfaz de usuario, arquitectura de estado y experiencia del paciente en la aplicación móvil **DualisCheckUp**.

## Stack Tecnológico
- **Framework**: Flutter 3.29+ / Dart 3.7+.
- **Gestión de Estado**: `flutter_riverpod` (v3.4.3) con `@riverpod` codegen y `autoDispose`.
- **Enrutamiento**: `go_router` (v18.0.1) con `StatefulShellRoute` y redirecciones de seguridad.
- **Base de Datos Local**: `drift` (v2.22.x) para SQLite outbox sync y almacenamiento local seguro.
- **Gráficos y Visualización**: `fl_chart` (v1.2.0) y `flutter_svg` (v2.3.0) para el mapa corporal anatómico 2D.
- **Diseño**: Material 3 con paleta dual (Soft Indigo y Clinical Teal) y Rojo de Emergencia (`#BA1A1A`).

## Operaciones de Pruebas y Diagnóstico
1. **Ejecución de Pruebas Móviles**:
   ```bash
   cd mobile && flutter test
   ```
2. **Validación de Componentes Críticos**:
   - `TriageWizardScreen`: Flujo dinámico de 5 pasos con validación por paso y selector de intensidad 1-5.
   - `EmergencyRiskAlertScreen`: Desencadenamiento inmediato sin esperas de red para niveles 4-5 con marcación directa a SAMU (`192`) o CVV (`188`).
   - `AnatomicalBodyMap`: Mapeo vectorial de 12 sistemas corporales con interactividad táctil y leyenda cromática.
   - `SyncOutboxWorker`: Cola de sincronización resiliente ante desconexión de red.
