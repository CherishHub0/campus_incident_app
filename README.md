# Campus Incident Reporter (Flutter + Firebase)

State management: **Provider** (`ChangeNotifier` + `ChangeNotifierProxyProvider`).
Backend: Firebase Auth (ALU email + email verification), Cloud Firestore, and Cloudinary image uploads.
Firebase project: `campus-incident-app-9a977`

## Folder structure

```
lib/
  main.dart                  app entry, providers, AuthGate
  core/                      theme, constants (allowed email domains, locations), utils
  models/                    Incident, AppUser, enums
  services/                  Firebase and Cloudinary access
  providers/                 AuthProvider, IncidentProvider (state + business logic)
  screens/                   auth, verify email, home, reports, report form, details, profile
  widgets/                   reusable: IncidentCard, StatusBadge, StatusTimeline, SummaryTile...
firestore.rules  firebase.json
```

## Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Connect the app to your Firebase project
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=campus-incident-app-9a977
```
Pick Android (and iOS if you want). This generates `lib/firebase_options.dart`
which `main.dart` imports. Android needs `minSdkVersion 23` or higher
(`android/app/build.gradle.kts`: set `minSdk = 23` if required by your FlutterFire plugins).

### 3. Configure Cloudinary image uploads
1. Create a Cloudinary account and copy the **Cloud name** from the Cloudinary dashboard.
2. In **Settings -> Upload -> Upload presets**, create an **unsigned** upload preset.
   Restrict it to image formats (JPG, PNG, and WebP), set a 5 MB maximum file size,
   and use the `campus_incidents` folder.
3. In VS Code, press F5 and provide the cloud name and preset when prompted. From
   a terminal, pass the same values directly:
   ```bash
   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
   ```

The cloud name and unsigned preset are public identifiers, not API secrets. Never
put your Cloudinary API secret in the Flutter app. Anyone with an unsigned preset
can upload, so keep its size and format restrictions enabled.

**Assignment note:** the supplied brief explicitly requires Firebase Storage for
incident photos. Cloudinary is a substitute, not a way to satisfy that requirement;
confirm the substitution with your instructor.

### 4. Enable the services in the Firebase Console
1. **Authentication -> Get started -> Sign-in method -> Email/Password -> Enable.**
2. **Firestore Database -> Create database** -> production mode -> choose a region.

### 5. Deploy the Firestore security rules
Either paste `firestore.rules` into *Firestore -> Rules* and click **Publish**, or run:
```bash
firebase deploy --only firestore:rules --project campus-incident-app-9a977
```

### 6. Run
```bash
flutter run   # on an Android emulator or a physical phone
```

## Account roles

Register and sign in with an ALU email and password. A verified `@alustudent.com`
account is a student; a verified `@alueducation.com` account is staff. The sign-up
form stores the registrant's full name, which is shown in the home-page greeting.
Users can request a password reset email from the sign-in screen. Firebase Auth
persists the session between app launches; sign out from the Profile tab.

An administrator can also promote another account by setting its `role` field to
`staff` in that account's Firestore `users/{uid}` document. Students cannot change
their own role from the app.

The security rules enforce this server-side: a student cannot change a status or
promote themselves, even by modifying the app.

## Firestore data model

`users/{uid}`: `fullName`, `email`, `role` (`student` | `staff`), `createdAt`

`incidents/{autoId}`: `title`, `description`, `category` (facilities | water | electricity |
safety | sanitation), `location`, `imageUrl`, `imagePublicId`, `status`
(`submitted` | `in_progress` | `resolved`), `reporterId`, `reporterName`, `isAnonymous`,
`createdAt`, `updatedAt`, `staffNote`, `statusHistory[] {status, at, by}`

Images: Cloudinary secure URL and public ID are stored on the incident document. Deleting
an incident does not delete its Cloudinary asset; secure deletion requires a server-side
endpoint because Cloudinary's API secret must not be embedded in the mobile app.

## Allowed email domains
Edit `lib/core/constants.dart` (`allowedEmailDomains`) if your ALU domains differ.

## Notes for the report (talking points)
- Auth flow: register -> role assigned from the ALU email domain -> verification email ->
  `AuthGate` shows the verify screen until `emailVerified` is true -> main app.
- Only verified users can read and write incident reports (`email_verified` token claim in rules).
- Provider separation: UI -> Providers -> Services -> Firebase/Cloudinary. Screens never call backends directly.
- Real-time updates: Firestore `snapshots()` stream feeds `IncidentProvider`, so a staff
  status change shows up instantly on every student's screens.
- Privacy: optional anonymous reporting; `reporterId` is kept only so owners can manage their own report.
- Misuse prevention: ALU-email-only accounts, verified email required, 5 MB image-only uploads,
  min-length validation, owners can only delete reports that are still "submitted".
