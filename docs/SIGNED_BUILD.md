# Signed Build Instructions

NutriGuide uses **Play App Signing**: you keep an *upload key*, Google manages
the final app-signing key.

## 1. Create an upload keystore (once)

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 9125 -alias upload
```

Store `upload-keystore.jks` securely (a secret manager / CI secret). Never
commit it.

## 2. Provide key.properties (git-ignored)

Create `app/android/key.properties` (already git-ignored):

```
storePassword=<upload store password>
keyPassword=<upload key password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

When `key.properties` is absent, the release build falls back to debug signing
so `flutter run --release` still works locally (see `build.gradle.kts`).

## 3. Build the App Bundle (target SDK 36)

```bash
cd app
flutter build appbundle --release \
  --dart-define=APP_ENV=prod \
  --dart-define=USE_DEV_STUB=false \
  --dart-define=FIREBASE_PROJECT_ID=<prod-project> \
  --dart-define=FIREBASE_API_KEY=<public-web-api-key> \
  --dart-define=BACKEND_BASE_URL=<functions-base-url>
```

Output: `app/build/app/outputs/bundle/release/app-release.aab`

## 4. Upload

Upload the `.aab` to the Play Console (closed testing first). Enroll in Play
App Signing on first upload. Verify the version code increments each release.

## CI

`.github/workflows/ci.yml` builds a **debug-signed** AAB for verification.
Production AABs should be built by a release job that injects the upload
keystore from CI secrets — never commit signing material.
