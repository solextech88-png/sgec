# Building Smart Global Education Consult into an installable APK

Follow these in order. Total time on a machine that already has Docker and
Flutter installed: ~15 minutes. From a totally bare machine, budget 1–2
hours mostly for installer downloads.

---

## 0. Prerequisites

Install these first if you don't have them:

| Tool | Check you have it | Install |
|---|---|---|
| Flutter SDK (3.22+) | `flutter --version` | https://docs.flutter.dev/get-started/install |
| Android SDK / Android Studio | `flutter doctor` shows no Android issues | Installed alongside Android Studio, or via `sdkmanager` |
| Docker + Docker Compose | `docker --version` | https://docs.docker.com/get-docker/ |
| A JDK (17 recommended) | `java -version` | Bundled with Android Studio, or `apt install openjdk-17-jdk` |

Run `flutter doctor` and resolve anything it flags with a red ✗ before
continuing — almost every first-build failure traces back to something
`flutter doctor` already warned about (missing Android licenses, missing
`ANDROID_HOME`, etc.). Accept licenses with:
```bash
flutter doctor --android-licenses
```

---

## 1. Start the backend

The mobile app needs a real API to talk to — do this first.

```bash
cd sgec
docker compose up -d --build
```

This starts Postgres + the API on `http://localhost:4000`. First run only,
apply migrations and load sample data:

```bash
docker compose exec api npx prisma migrate deploy
docker compose exec api node prisma/seed.js
```

Confirm it's alive:
```bash
curl http://localhost:4000/health
# {"status":"ok"}
```

**If you're building the APK to install on a physical phone** (not an
emulator on the same machine), `localhost` won't be reachable from the
phone. Either:
- Run the backend on a machine reachable on your network and use its LAN
  IP (e.g. `http://192.168.1.20:4000/api`), or
- Deploy the backend to a real host (Railway, Render, Fly.io, a VPS, etc.)
  and use its public URL — do this before a release build meant for real
  users, since `docker compose` on a laptop isn't a production deployment.

---

## 2. Turn the Dart source into a real Flutter project

The `mobile_app/` folder ships as source only — the native `android/` and
`ios/` folders are machine-generated and regenerated here, not hand-written:

```bash
cd sgec/mobile_app
flutter create --platforms=android --org com.sgec .
```

This adds `android/` (and `.gitignore`/`analysis_options.yaml` if missing)
around your existing `lib/`, `pubspec.yaml`, and `assets/` without
touching them.

Then install dependencies:
```bash
flutter pub get
```

### Required manual edits (do these before building)

**`android/app/src/main/AndroidManifest.xml`** — add, inside `<manifest>`
and above `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```
(Camera/media permissions are needed for passport photo capture and
document upload via `image_picker`/`file_picker`.)

On the same file's `<application>` tag, set:
```xml
android:label="Smart Global Education Consult"
```

**`android/app/build.gradle`** (or `build.gradle.kts`) — set:
```gradle
applicationId "com.sgec.app"   // your real package name — can't change after first Play Store release
minSdkVersion 21
```

---

## 3. Point the app at your backend

Easiest: build with `--dart-define` so you never hand-edit source per
environment:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.20:4000/api
```

If you skip `--dart-define`, it falls back to the default in
`lib/core/constants.dart` (`http://10.0.2.2:4000/api`, which only works
from the Android emulator talking to a backend on the same machine).

---

## 4. Sign the release build (required to install outside a dev/debug flow)

Every release APK needs a signing key. Generate one once and keep it
somewhere safe — losing it means you can never publish an update under the
same app identity.

```bash
keytool -genkey -v -keystore ~/sgec-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias sgec
```

Create `android/key.properties` (already gitignored):
```
storePassword=<the password you set above>
keyPassword=<the password you set above>
keyAlias=sgec
storeFile=/absolute/path/to/sgec-release.jks
```

In `android/app/build.gradle`, above `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```
Inside `android { ... }`, add:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

---

## 5. Build the ready-to-install APK

```bash
cd sgec/mobile_app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend-url/api
```

Output:
```
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

Copy that file to a phone (USB, email, cloud drive, `adb install`) and
install it — Android will prompt to allow installs from that source if
it's not from the Play Store. Or, with a device connected via USB and
debugging enabled:
```bash
flutter install
```

---

## What you get with default settings

- The app talks to whatever `API_BASE_URL` you pass at build time.
- Seeded data (from step 1) gives you 3 real universities/programmes across
  UK/Ireland/Germany to browse immediately.
- Registration triggers an OTP that's currently just printed to the
  backend's console (`docker compose logs -f api`) rather than actually
  texted/emailed — wire up Twilio/SendGrid per `backend/src/utils/otp.js`
  before giving this to real users.
- AI features (`/api/ai/...`) need `ANTHROPIC_API_KEY` set in
  `backend/.env` (or the compose file's environment block) or they'll
  error — see `backend/.env.example`.

## Before this goes to real students

This scaffold is built to compile and run end-to-end, not to be
production-hardened. At minimum, before any real student data touches it:
switch document storage to S3 with encryption at rest, put the backend
behind HTTPS, get the consent-form legal text reviewed per jurisdiction,
add rate limiting/CAPTCHA to public endpoints, and replace the console OTP
sender with a real SMS/email provider. See `README.md` → "Security notes"
for the full list.
