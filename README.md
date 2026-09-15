# IIM Shillong Community Timetable

Flutter + Firebase POC for PGP/PGPEx students at IIM Shillong.

Students sign in with an `@iimshillong.ac.in` email, ingest the official office Excel timetable, pick electives, see only the classes that apply to them, and get a local reminder 15 minutes before each session. Usage events are sent to Firebase Analytics so you can read KPIs in the Firebase console.

## Student flow

1. **Login / register** with an institute email (Firebase Auth when configured; local demo mode otherwise).
2. **Upload** the office `.xlsx` file, or load the bundled sample timetable.
3. **Select electives**. Core subjects are always included.
4. **Personalized timetable** shows core + chosen electives only.
5. **Reminders** are scheduled with `flutter_local_notifications` (Asia/Kolkata, 15 minutes before start).

## Excel layout

Header row (names are matched case-insensitively; extra columns are ignored):

| Day | Start Time | End Time | Course Code | Subject | Type | Faculty | Venue |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Monday | 09:00 | 10:30 | PGPEX-C1 | Managerial Economics | Core | Faculty A | CH-1 |
| Monday | 11:00 | 12:30 | PGPEX-E1 | FinTech Strategy | Elective | Faculty B | CH-2 |

`Type` should be `Core` or `Elective`. Times may be 24-hour (`14:00`) or 12-hour (`2:00 PM`).

## Project structure

```
lib/
  main.dart
  app.dart                  # auth + session routing
  app_bootstrap.dart        # Firebase / demo-mode startup
  firebase_options.dart     # replace with flutterfire configure
  models/
  screens/
  services/
  utils/
assets/sample_timetable.xlsx
android/                    # applicationId in.ac.iimshillong.iim_shillong_community
ios/                        # bundle id in.ac.iimshillong.iimShillongCommunity
firestore.rules
```

## Firebase setup

1. Create a Firebase project.
2. Enable **Authentication → Email/Password**.
3. Create a Firestore database and publish `firestore.rules`.
4. Enable **Google Analytics** (linked automatically on most new projects).
5. From this repo:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

That command overwrites `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`. Until you do this, the app still **builds and runs in demo mode** (auth and timetable stay on-device).

Optional Auth restriction: Firebase Console → Authentication → Settings → User actions, or block non-institute domains with a Cloud Function. The app also rejects any email that is not `@iimshillong.ac.in`.

## Analytics KPIs (Firebase console)

Events logged by the app (Analytics → Events):

| Event | When |
| --- | --- |
| `app_open` | App launch |
| `login` | Successful sign-in / register |
| `file_upload` | Office Excel ingested |
| `subject_selection` | Electives saved |
| `reminder_trigger` | Reminder scheduled (`phase=scheduled`) or opened (`phase=opened`) |

You do not need an in-app admin dashboard. As project owner (`shubham.pgpex26@iimshillong.ac.in`), open [Firebase Analytics](https://console.firebase.google.com/) → **Analytics → Events / Dashboard** for login, upload, selection, reminder, and app-open counts.

Publish security rules with `firebase deploy --only firestore:rules` after `firebase login` (uses `firebase.json` + `firestore.rules` in this repo).

## Run locally

```bash
flutter pub get
dart run tool/generate_sample_timetable.dart
flutter test
flutter run
```

- **Android:** `flutter build apk --debug` (verified in this environment)
- **iOS:** on macOS, `flutter build ios --debug --no-codesign` (Xcode is required for a native iOS binary). GitHub Actions on `macos-latest` runs that compile. This Linux environment still compiles the Dart/iOS asset bundle with `flutter build bundle --target-platform=ios`.

## Android / iOS notes

- minSdk 24, Java 17 desugaring for exact local notifications.
- Notification permissions are requested at startup.
- iOS requires a development team in Xcode for a device build.
