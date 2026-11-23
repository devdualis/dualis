# DualisCheckUp - App Store Review Information & Notes

> **Instrucciones para el envío:** Copia y pega las siguientes notas en el campo **App Review Information (Notas de Revisión)** en App Store Connect y en las notas para revisores de Google Play Console.

---

### 1. SCREEN RECORDING & DEMO
- **Demo Video URL:** *[Insert link to unlisted demo video if requested by review team]*
- **Flujos incluidos en la demostración:**
  - Onboarding y presentación del propósito de bienestar preventivo.
  - Autenticación segura (Login, Registro con consentimiento explícito LGPD).
  - Check-in diario de bienestar y registro de hábitos (sueño, hidratación).
  - Acceso a pantalla de ajustes y función de **Eliminación Permanente de Cuenta** (LGPD Art. 18 / GDPR / Apple 5.1.1(v)).
  - Diálogos de permisos del sistema explicados contextualmente (Cámara, Galería, Micrófono, Reconocimiento de Voz, Ubicación).

---

### 2. APP PURPOSE & INTENDED USE
- **Propósito:** DualisCheckUp es una plataforma móvil de salud preventiva, seguimiento de hábitos y bienestar personal.
- **Aviso Médico / Medical Disclaimer (Apple Guideline 1.4.1):**
  DualisCheckUp no es un dispositivo médico. No proporciona diagnósticos médicos, no clasifica síntomas de emergencia, no prescribe tratamientos médicos ni reemplaza la consulta con un profesional de la salud colegiado. El usuario recibe avisos claros para contactar a servicios de emergencia (SAMU 192 / CVV 188 / 911) ante cualquier urgencia física o emocional.

---

### 3. ACCESS INSTRUCTIONS & TEST CREDENTIALS
- **Instrucciones de acceso:** La aplicación permite inicio de sesión directo sin 2FA obligatorio para el revisor.
- **Usuario de prueba (Demo Account):** `reviewer@dualischeckup.com`
- **Contraseña de prueba:** `DualisDemo2026!`
- **Vigencia:** Esta cuenta se mantendrá activa permanentemente durante todo el proceso de revisión.

---

### 4. EXTERNAL SERVICES & DATA COLLECTION
- **Backend API:** `https://api.dualischeckup.com` (Todas las conexiones son TLS 1.3/HTTPS estrictas; `usesCleartextTraffic` y `NSAllowsArbitraryLoads` desactivados).
- **Google Maps SDK:** Utilizado exclusivamente para ubicar servicios de bienestar y salud en mapa interactivo local.
- **Almacenamiento Local Seguro:** Base de datos SQLite cifrada/aislada mediante Drift y Secure Storage (Keychain en iOS / Keystore en Android).

---

### 5. PERMISSIONS & PRIVACY MANIFEST DECLARATION
- **iOS Privacy Manifest (`PrivacyInfo.xcprivacy`):**
  - **NSPrivacyTracking:** `false` (No realiza tracking entre apps de terceros ni comparte IDFA).
  - **Datos recolectados:** Datos de salud y bienestar (`NSPrivacyCollectedDataTypeHealthAndFitness`), Correo electrónico (`NSPrivacyCollectedDataTypeEmailAddress`), ID de usuario (`NSPrivacyCollectedDataTypeUserID`), todos con propósito exclusivo de funcionalidad interna de la app (`NSPrivacyCollectedDataTypePurposeAppFunctionality`).
  - **APIs de motivo requerido:** Declaradas formalmente con sus respectivos reason codes de Apple (`UserDefaults CA92.1`, `FileTimestamp C617.1`, `SystemBootTime 35F9.1`, `DiskSpace E174.1`).

---

### 6. MONETIZATION & IN-APP PURCHASES
- Esta versión de DualisCheckUp se distribuye como acceso gratuito para funcionalidades esenciales de diario de salud y bienestar.
- No se procesan compras de bienes digitales fuera de la aplicación.
