# DualisCheckUp — CI/CD Pipeline & Environment Configuration Guide

This repository contains automated Continuous Integration and Continuous Deployment (CI/CD) workflows powered by **GitHub Actions**:

1. **Backend Deployment to Google Cloud Run** (`.github/workflows/deploy-backend.yml`):
   - Multi-stage Docker containerization of the NestJS Fastify backend.
   - Pushes images to Google Artifact Registry.
   - Automatically injects environment variables/secrets.
   - Deploys the service to Google Cloud Run (`southamerica-east1` region for Brazilian LGPD compliance).
2. **Mobile Android APK Build** (`.github/workflows/build-mobile-apk.yml`):
   - Runs Flutter analysis and test suites.
   - Injects the backend `API_BASE_URL` at compile time via `--dart-define`.
   - Compiles release (or debug) Android APK (`app-release.apk`).
   - Uploads APK directly as a downloadable GitHub Actions artifact and attaches it to GitHub Releases.

---

## 1. Environment Variables Overview

Both the backend on Google Cloud Run and the mobile Flutter client require specific environment variables:

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│   Settings > Secrets and variables > Actions                │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
                ▼                             ▼
┌───────────────────────────────┐ ┌───────────────────────────┐
│     Cloud Run (Backend)       │ │     Android APK (Mobile)  │
│  - BACKEND_ENV (or individual)│ │  - API_BASE_URL           │
│  - DATABASE_URL               │ │  - ANDROID_KEYSTORE_*     │
│  - ENCRYPTION_MASTER_KEY      │ └───────────────────────────┘
│  - GEMINI_API_KEY             │
│  - SUPABASE_* / SMTP_*        │
└───────────────────────────────┘
```

---

## 2. Backend Environment Variables (Google Cloud Run)

### Required & Supported Variables

| Variable Name | Required | Description | Example / Notes |
|---|:---:|---|---|
| `NODE_ENV` | Yes | Runtime mode (set automatically to `production`) | `production` |
| `PORT` | Yes | Listening port (injected by Cloud Run, defaults to `8080`) | `8080` |
| `DATABASE_URL` | **Yes** | PostgreSQL connection string with SSL / RLS | `postgresql://user:pass@host:5432/dualis` |
| `DATABASE_CA_CERT` | Optional | Custom CA certificate string for PostgreSQL SSL | `-----BEGIN CERTIFICATE-----...` |
| `DATABASE_SSL_REJECT_UNAUTHORIZED` | Optional | Set to `'false'` if using self-signed internal certs | `false` |
| `ENCRYPTION_MASTER_KEY` | **Yes** | 64-char hex key (32 bytes) for AES-256-GCM PHI encryption | `0123456789abcdef0123456789abcdef...` |
| `GEMINI_API_KEY` | **Yes** | Google Gemini API Key for clinical AI triage | `AIzaSy...` |
| `GEMINI_MODEL` | Optional | Gemini model override (defaults to `gemini-2.5-flash`) | `gemini-2.5-flash` |
| `DISCLAIMER_VERSION` | Optional | Current clinical disclaimer version | `2026.1` |
| `JWT_SECRET` | Optional | Secret for signing auth tokens (defaults to master key) | `your-jwt-secret` |
| `SMTP_HOST` | Optional | SMTP host for verification / transactional emails | `smtp-pulse.com` |
| `SMTP_PORT` | Optional | SMTP port | `587` |
| `SMTP_USER` | Optional | SMTP username | `dev@example.com` |
| `SMTP_PASS` | Optional | SMTP password | `password` |
| `MAIL_FROM` | Optional | From email header | `"DualisCheckUp <no-reply@dualis.health>"` |
| `SUPABASE_URL` | **Yes** | Supabase project URL for storage & services | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | **Yes** | Supabase anonymous public key | `eyJhbGciOi...` |
| `SUPABASE_SERVICE_ROLE_KEY` | **Yes** | Supabase service role key (for backend admin operations) | `eyJhbGciOi...` |
| `SUPABASE_AVATAR_BUCKET` | Optional | Avatar storage bucket name | `avatars` |

### How to Provide Environment Variables in CI/CD

You can provide the backend environment variables using **any** of the following 3 approaches:

#### Approach A: Paste Full `.env` into a Single Secret (Quickest)
1. Go to **Settings > Secrets and variables > Actions > Secrets**.
2. Create a secret named **`BACKEND_ENV`**.
3. Paste the entire contents of your production `.env` file directly into it.
4. The GitHub Actions workflow will parse this into `cloudrun-env.yaml` and pass it to Cloud Run automatically!

#### Approach B: Individual GitHub Secrets
Create individual secrets under **Repository Secrets** in GitHub:
- `DATABASE_URL`
- `ENCRYPTION_MASTER_KEY`
- `GEMINI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SMTP_USER`, `SMTP_PASS`, etc.

#### Approach C: Configure Once in Google Cloud Run (Recommended for Enterprise)
If you configure environment variables directly in the Google Cloud Console or bind them to **Google Secret Manager**, the CI/CD deployment will **preserve and maintain all existing environment variables** across every new container image revision!

---

## 3. Mobile Environment Variables (Flutter Android APK)

### Key Mobile Variables

| Variable / Define | Description | Default if omitted |
|---|---|---|
| `API_BASE_URL` | Root URL of the NestJS backend API | `http://10.0.2.2:3000` (Android emulator) or `http://localhost:3000` |

### How `API_BASE_URL` is Injected

The mobile app accesses this via `ApiEndpoints.baseUrl`:
```dart
static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
```

In the GitHub Actions workflow, `API_BASE_URL` is passed during `flutter build apk`:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-cloud-run-service.a.run.app
```

### How to Set `API_BASE_URL` in GitHub:

1. **Automatic for All Builds**:
   - Go to **Settings > Secrets and variables > Actions > Variables**.
   - Create a variable named **`API_BASE_URL`** (e.g. `https://dualis-backend-5612345678.southamerica-east1.run.app`).
   - Every automatic build (on push or release) will compile this URL into the APK.

2. **Manual Trigger (Override on demand)**:
   - When triggering the workflow manually via the **Run workflow** button, enter the `api_base_url` input field.

3. **Multiple Dart Defines (Optional)**:
   - To pass additional compile-time configurations, create a secret named `MOBILE_DART_DEFINES_JSON` with JSON key-values (e.g. `{"KEY": "VALUE"}`). The workflow passes it via `--dart-define-from-file`.

---

## 4. Google Cloud Run Setup Instructions

Run these commands using the `gcloud` CLI:

### 1. Enable Required GCP APIs
```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com
```

### 2. Create Artifact Registry Docker Repository
```bash
gcloud artifacts repositories create dualis \
  --repository-format=docker \
  --location=southamerica-east1 \
  --description="DualisCheckUp Docker Images"
```

### 3. Create Service Account & Grant Permissions
```bash
# Create deployer service account
gcloud iam service-accounts create dualis-github-deployer \
  --display-name="Dualis GitHub Actions Deployer"

# Assign Cloud Run Admin
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:dualis-github-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

# Assign Artifact Registry Writer
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:dualis-github-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Assign Service Account User
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:dualis-github-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### 4. GitHub Configuration Summary

#### Repository Variables (`Settings > Secrets and variables > Actions > Variables`):
| Variable | Value |
|---|---|
| `GCP_PROJECT_ID` | `YOUR_GCP_PROJECT_ID` |
| `GCP_REGION` | `southamerica-east1` (Default) |
| `GAR_REPOSITORY` | `dualis` (Default) |
| `GCP_SERVICE_NAME` | `dualis-backend` (Default) |
| `API_BASE_URL` | `https://dualis-backend-XXXXX.southamerica-east1.run.app` |

#### Repository Secrets (`Settings > Secrets and variables > Actions > Secrets`):
| Secret | Value |
|---|---|
| `GCP_SA_KEY` | Contents of Service Account JSON key (or use Workload Identity Federation) |
| `BACKEND_ENV` | *(Optional)* Full production `.env` contents for the backend |
| `ANDROID_KEYSTORE_BASE64` | *(Optional)* Base64-encoded `.keystore` for production APK signing |
| `ANDROID_KEYSTORE_PASSWORD` | *(Optional)* Keystore password |
| `ANDROID_KEY_ALIAS` | *(Optional)* Key alias |
| `ANDROID_KEY_PASSWORD` | *(Optional)* Key password |

---

## 5. Downloading the Built APK

1. In GitHub, navigate to the **Actions** tab.
2. Select **Mobile - Build Android APK** from the left workflow list.
3. Click on the latest workflow run.
4. Scroll down to the **Artifacts** section.
5. Click **dualis-mobile-release-apk** to download the ZIP file containing `app-release.apk`.
