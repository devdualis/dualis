# Phase 10 UI Specification: Privacy Center & LGPD Data Sovereignty

## 1. Visual Identity & Tone

The Privacy Center (`PrivacyCenterScreen`) is designed with high transparency, professional clarity, and calm authority.
- Primary colors: Dualis Clinical Teal (`#00796B`) for data sovereignty actions, Alert Crimson (`#D32F2F`) for destructive account elimination.
- Typography: Plus Jakarta Sans / Inter.

## 2. Screen Structure & Components

### 2.1 AppBar & Navigation
- Title: *"Central de Privacidade & LGPD"* (localized in pt, es, en).
- Back button returning to `HomeScreen`.

### 2.2 Data Sovereignty Section (Art. 18, V)
- Card: *"Exportação de Dados Pessoais & Clínicos"*.
- Explanation: *"Conforme o Art. 18 da LGPD, você tem direito à portabilidade de todos os seus dados pessoais, termos de consentimento e histórico de triagens em formato aberto (JSON)."*
- Action Button: *"Exportar Meus Dados"* (FilledButton with icon `download_rounded`).
- Displays formatted JSON preview dialog or initiates file download.

### 2.3 Account Elimination Section (Art. 18, VI)
- Card: *"Exclusão Permanente da Conta & Prontuário"*.
- Background: `#FFF5F5`, border: `#FFCDD2`.
- Warning text: *"Esta ação é irreversível. Todos os seus dados pessoais, históricos de sintomas, avaliações e termos de consentimento serão permanentemente apagados dos servidores e do seu dispositivo."*
- Action Button: *"Excluir Minha Conta Permanentemente"* (OutlinedButton with icon `delete_forever_rounded`, color `#D32F2F`).
- High-friction Confirmation Dialog:
  - Requires user to confirm password or type "EXCLUIR" to prevent accidental data loss.
  - Buttons: *"Cancelar"* (neutral) and *"Confirmar Exclusão Irreversível"* (Destructive Red).

## 3. Copywriting (Trilingual Keys)

- `privacyCenterTitle`: "Privacidade & Dados (LGPD)" / "Privacidad y Datos (LGPD)" / "Privacy & Data (LGPD)"
- `exportDataTitle`: "Exportação de Dados" / "Exportación de Datos" / "Data Export"
- `exportDataDesc`: "Baixe uma cópia completa dos seus dados pessoais e histórico clínico em formato JSON." / "Descarga una copia completa de tus datos personales e historial clínico en formato JSON." / "Download a complete copy of your personal data and clinical history in JSON format."
- `exportDataButton`: "Exportar Dados (JSON)" / "Exportar Datos (JSON)" / "Export Data (JSON)"
- `deleteAccountTitle`: "Exclusão Permanente da Conta" / "Eliminación Permanente de Cuenta" / "Permanent Account Deletion"
- `deleteAccountDesc`: "Apague definitivamente sua conta e todos os registros de saúde conforme o Art. 18 da LGPD. Esta ação não pode ser desfeita." / "Elimina definitivamente tu cuenta y todos los registros de salud según el Art. 18 de la LGPD. Esta acción no se puede deshacer." / "Permanently delete your account and all health records under LGPD Art. 18. This action cannot be undone."
- `deleteAccountButton`: "Excluir Minha Conta" / "Eliminar Mi Cuenta" / "Delete My Account"
- `deleteConfirmTitle`: "Confirmar Exclusão Definitiva" / "Confirmar Eliminación Definitiva" / "Confirm Permanent Deletion"
- `deleteConfirmDesc`: "Para confirmar a exclusão irreversível da sua conta e de todos os dados de saúde, digite sua senha:" / "Para confirmar la eliminación irreversible de tu cuenta y todos los datos de salud, ingresa tu contraseña:" / "To confirm the irreversible deletion of your account and all health data, enter your password:"
- `deleteSuccessMessage`: "Conta e dados excluídos com sucesso." / "Cuenta y datos eliminados con éxito." / "Account and data deleted successfully."
