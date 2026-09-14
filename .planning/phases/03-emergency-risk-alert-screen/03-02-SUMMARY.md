# Phase 3 Plan 02: Screen 8 Emergency Modal, PopScope Lock, Trilingual Copy & Backend Audit Summary

**Phase:** 03-emergency-risk-alert-screen  
**Plan:** 02  
**Wave:** 2  
**Status:** Completed  
**Completed Date:** 2026-09-14  

---

## Executive Overview

Plan 03-02 delivered the complete user-facing and backend audit architecture for **Screen 8 (Emergency Risk Alert Screen - RF-006)**. When critical red-flag symptoms (Level 4–5 intensities on vital organs, stroke signs, thunderclap headache, suicidal crisis) are detected, the user is immediately routed to a full-bleed emergency red canvas (`#D32F2F`) locked against dismissal via `PopScope(canPop: false)`.

The screen provides 1-tap emergency dispatch (SAMU 192 for physical crises, CVV 188 for emotional crises, Bombeiros 193), emergency room hospital map location, tailored clinical instructions on `#FFEBEE` surface, a non-dismissible risk confirmation dialog upon exit attempts, and an automatic fallback dialog for devices lacking cellular telephony hardware. Furthermore, non-blocking asynchronous audit telemetry was wired to the NestJS backend under PostgreSQL Row Level Security (RLS) for Brazilian LGPD Art. 11 compliance.

---

## Key Deliverables & Accomplishments

### 1. Trilingual Localization & Emergency Color Palette
- Updated [app_pt.arb](file:///Users/ricardorincon/workspace/dualis/mobile/lib/l10n/app_pt.arb), [app_es.arb](file:///Users/ricardorincon/workspace/dualis/mobile/lib/l10n/app_es.arb), and [app_en.arb](file:///Users/ricardorincon/workspace/dualis/mobile/lib/l10n/app_en.arb) with 29 new Screen 8 keys covering titles, category badges, physical and emotional instructions, emergency service labels (SAMU, CVV, Bombeiros, Polícia), exit dialogs, and tablet telephony fallbacks.
- Extended [app_colors.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/core/constants/app_colors.dart) with WCAG AA/AAA-compliant emergency palette tokens:
  - `emergencyCrimson` (`Color(0xFFD32F2F)`)
  - `emergencyDarkRed` (`Color(0xFFB71C1C)`)
  - `emergencySurfaceRed` (`Color(0xFFFFEBEE)`)
  - `emergencyTextDark` (`Color(0xFF5A0C0C)`)

### 2. Screen 8 Component Architecture & Navigation Lock
- **`PopScope` Gesture Lock**: Root view enforces `canPop: false`. Android hardware back buttons, iOS edge swipes, and in-app exit buttons intercept pops and invoke `EmergencyExitConfirmationDialog` (`barrierDismissible: false`).
- **[EmergencyBadge](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/widgets/emergency_badge.dart)**: High-visibility pill container with semi-translucent white background, 1.5px border, and category icon dynamically reflecting the trigger acuity.
- **[EmergencyInstructionsCard](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/widgets/emergency_instructions_card.dart)**: `#FFEBEE` surface card rendering 3 numbered clinical action steps tailored to physical vs emotional crises in dark crimson (`#5A0C0C`).
- **[EmergencyActionButton](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/widgets/emergency_action_button.dart)**: Standardized 56px height action button supporting primary (white filled, crimson text) and secondary (white outlined, white text) styles.
- **[EmergencyExitConfirmationDialog](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/widgets/emergency_exit_confirmation_dialog.dart)**: Non-dismissible dialog warning users of life safety risks before allowing navigation back to `/home`.
- **[TelephonyFallbackDialog](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/widgets/telephony_fallback_dialog.dart)**: Automatically displayed if `canLaunchUrl` or `launchUrl` fails (e.g. Wi-Fi-only tablets), rendering the emergency number in 36pt font with a 1-tap clipboard copy action.
- **[EmergencyScreen](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/screens/emergency_screen.dart)**: Assembled full-bleed screen with `SafeArea` and `SingleChildScrollView(physics: BouncingScrollPhysics())` preventing `RenderFlex` overflow across any viewport size.

### 3. NestJS Backend Audit Telemetry & Database RLS
- **[triage-emergency-events.schema.ts](file:///Users/ricardorincon/workspace/dualis/backend/src/database/schema/triage-emergency-events.schema.ts)**: Declares `triage_emergency_events` table in Drizzle ORM with strict RLS policy restricting queries to `app.current_user_id`.
- **[0003_triage_emergency_events.sql](file:///Users/ricardorincon/workspace/dualis/backend/src/database/migrations/0003_triage_emergency_events.sql)**: Migration establishing table, foreign keys, indexes, and RLS policies.
- **[create-emergency-event.dto.ts](file:///Users/ricardorincon/workspace/dualis/backend/src/modules/triage-audit/dto/create-emergency-event.dto.ts)**: Validates incoming telemetry using `class-validator` (`@Min(4)`, `@Max(5)`, `@IsIn(['PHYSICAL', 'EMOTIONAL'])`, `@IsISO8601()`).
- **[TriageAuditService](file:///Users/ricardorincon/workspace/dualis/backend/src/modules/triage-audit/triage-audit.service.ts) & [TriageAuditController](file:///Users/ricardorincon/workspace/dualis/backend/src/modules/triage-audit/triage-audit.controller.ts)**: Implements `POST /v1/triage/emergency-event` endpoint guarded with `OptionalJwtAuthGuard`.
- **[EmergencyAuditService](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/services/emergency_audit_service.dart)**: Client-side service executing non-blocking fire-and-forget (`unawaited`) reporting via `ApiClient` without delaying clinical UI operations.

---

## Test Verification Summary

### Automated Test Suites Executed

1. **Screen 8 Widget Test Suite** ([emergency_screen_test.dart](file:///Users/ricardorincon/workspace/dualis/mobile/test/features/emergency/emergency_screen_test.dart)):
   - Visual invariants: Full-bleed `#D32F2F` canvas, category badge, stark title and subtitle (Passed)
   - Physical variant: SAMU 192 primary button, Bombeiros 193 secondary button, physical instructions card (Passed)
   - Emotional variant: CVV 188 primary button, SAMU 192 secondary button, emotional instructions card (Passed)
   - PopScope lock: Back navigation attempts intercept pop and present `EmergencyExitConfirmationDialog` (Passed)
   - Exit stay: Dismisses dialog, keeping user on emergency screen (Passed)
   - Exit leave: Confirms risks, resets state, and routes to `/home` (Passed)
   - Dialer dispatch: Tapping SAMU 192 launches `tel:192` external intent (Passed)
   - Tablet fallback: When dialer fails, renders `TelephonyFallbackDialog` with copyable number in clipboard (Passed)
   - Trilingual localization: Renders correctly in Spanish and English (Passed)

2. **Backend Emergency Audit E2E Suite** ([emergency-event.e2e-spec.ts](file:///Users/ricardorincon/workspace/dualis/backend/test/e2e/emergency-event.e2e-spec.ts)):
   - `POST /v1/triage/emergency-event` with valid anonymous payload returns 201 Created (Passed)
   - `POST /v1/triage/emergency-event` with severityLevel < 4 returns 400 Bad Request (Passed)
   - `POST /v1/triage/emergency-event` with severityLevel > 5 returns 400 Bad Request (Passed)
   - `POST /v1/triage/emergency-event` with invalid sourceVertical returns 400 Bad Request (Passed)
   - `POST /v1/triage/emergency-event` with invalid timestamp returns 400 Bad Request (Passed)
   - `POST /v1/triage/emergency-event` with Bearer token associates event with authenticated user (Passed)

3. **Full Regression Results**:
   - Mobile: **90 / 90 tests passed (100% green)**, `flutter analyze` clean with 0 issues.
   - Backend: **16 / 16 E2E tests passed (100% green)** across all modules.

---

## Git Commit Log

- `feat(03-02): implement trilingual localization for Screen 8 emergency alert` (`ef66786`)
- `feat(03-02): implement Screen 8 full-screen emergency alert with PopScope lock` (`974e898`)
- `feat(03-02): implement asynchronous LGPD emergency event audit telemetry` (`33b223a`)

---

## Conclusion & Readiness

Phase 3 is now complete across Wave 1 and Wave 2. The life-safety emergency risk alert screen satisfies all medical regulatory, UX, interaction, security, and LGPD audit requirements defined in `03-UI-SPEC.md`, `03-RESEARCH.md`, and `03-VALIDATION.md`.
