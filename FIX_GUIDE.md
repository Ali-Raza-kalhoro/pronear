# ProNear: Fix Guide (step by step)

This guide covers every issue in [APP_AUDIT.md](APP_AUDIT.md).
- **Part A**: fixes already applied in the code. Nothing for you to do except test.
- **Part B**: things **you must do manually** (Supabase dashboard, Play Console, Google Cloud, keystore). Do them **in this order**.
- **Part C**: test checklist before upload.
- **Part D**: things left for after launch.

> ⚠️ Order matters. Run the SQL (B1) **before** you install the new build. The new app writes CNIC data to the `user_verifications` table, and provider registration fails until that table exists.

---

## Part A: done in code ✅

| ID | Problem | What was changed | Files |
|---|---|---|---|
| B2 | Package name `com.example.near_pro1` | Now **`com.pronear.app`** (Android namespace + applicationId, MainActivity moved, iOS bundle id) | `android/app/build.gradle.kts`, `android/app/src/main/kotlin/com/pronear/app/MainActivity.kt`, `ios/Runner.xcodeproj/project.pbxproj` |
| B1 | Release signed with debug key | Release now signs with `android/key.properties`. If that file is missing, the build prints a warning and falls back to debug (Play will reject it, so do step **M1**) | `android/app/build.gradle.kts` |
| B3 | CNIC/face photos public | The upload path is now `<userId>/cnic_front_<ts>.jpg` and the app stores the **path** instead of a public URL. `getVerificationImageUrl()` makes a 10-minute signed link for viewing | `lib/core/services/supabase_service.dart` |
| B3 | CNIC data in readable `users` table | CNIC number, image paths and face data now go to the new private table **`user_verifications`** (owner-only RLS) | `supabase_service.dart` (`saveUserWithVerification`, `getMyVerification`) |
| B4 | App marked itself verified | The app no longer writes `cnic_verified/face_verified = true`. Status is `pending` until an admin approves it. A DB trigger also blocks the app from setting these flags (SQL §4) | `supabase_service.dart`, `supabase/fixes.sql` |
| B6 | CNIC check read other users' rows (email, phone, CNIC) | It now uses the RPC `cnic_registration_info`, which returns only a masked email such as `mo***@gmail.com` and the role | `supabase_service.dart` |
| H1 | Voice search broken | Added the `RECORD_AUDIO` permission and the `RecognitionService` query | `AndroidManifest.xml` |
| H3 | Customer `users` row never created (OTP signup) | Registration now calls `ensureUserExists()` and saves name and phone | `register_screen.dart` |
| new | Every provider was saved with the name **"User"** (OCR never reads the name) | The Name field is now shown to providers too | `register_screen.dart` |
| H4 | Business account logged in to the customer home | `business` is treated as a provider. Unfinished business setup now goes to `/business/type` | `login_screen.dart`, `splash_screen.dart` |
| H5 | No way to complete a job, no ratings, fake earnings | Added a **Mark Completed** button (provider, accepted requests). Customers can **rate** after completion. Earnings are now the sum of completed job budgets. The DB trigger keeps `providers.rating` up to date (SQL §6) | `provider/request_screen.dart`, `provider/dashboard_screen.dart`, `user/my_requests_screen.dart` |
| H6 | No "My Requests" for the customer | New screen `/user/requests`: live list, filters, **Cancel** (pending), **Open chat** (accepted), **Rate** (completed) | `lib/features/user/my_requests_screen.dart` |
| new | Profile → "Favorite Providers" / "Request History" **crashed** (routes didn't exist) | Added `/user/favorites` (new screen) and `/user/requests` | `routes.dart`, `user/favorites_screen.dart` |
| new | Notification tap opened wrong or non-existent routes (`/user/requests/<id>`); providers got the customer chat list | Routing now follows the role. A message notification opens that chat room directly | `user/notification_screen.dart` |
| H7 | `role_Selection_screen.dart` casing broke Mac/iOS builds | Renamed to `role_selection_screen.dart` | `lib/features/auth/` |
| H8 | Storage paths not owned by the user | Every upload now goes under `<userId>/…` (profile, business photo, products, portfolio, chat already did). Product images also get an index so several images can't overwrite each other | profile, CV, business setup, products, `supabase_service.dart` |
| H9 | Customer account deletion used the wrong portfolio id | Fixed. Deletion also removes the new private verification files | both `profile_screen.dart` |
| H10 | App crashed offline on first start | It now shows a "Could not connect" screen | `main.dart` |
| M1 | About 12 unused packages and the `google_ml_kit` umbrella (it pulls in **every** ML Kit plugin) | Removed. The app now uses only `google_mlkit_text_recognition` (Latin) and `google_mlkit_face_detection` | `pubspec.yaml`, `ocr_service.dart`, `face_recoganization.dart` |
| M2 | Chinese, Japanese, Korean and Devanagari OCR models bundled | Removed (smaller APK) | `build.gradle.kts` |
| M5 | CNIC/email written to logcat | 69 `print()` calls changed to `debugPrint()`, and `debugPrint` is silenced in release builds | all `lib/` |
| M8 | Gradle 8 GB heap, JVM crash logs | 4 GB heap, crash logs deleted | `android/gradle.properties` |
| M10 | Any screen opened without login | GoRouter `redirect`: without a session, only splash, role selection, login, register and forgot-password are reachable | `routes.dart` |
| – | App label "PRONEAR" | "ProNear" | `AndroidManifest.xml` |
| B7 | No privacy policy / terms / account-deletion pages | In-app legal screens, links on role selection, login, register and profile, a required consent checkbox at registration, and a static site in `docs/` for GitHub Pages (generated by `tool/gen_legal_pages.dart`) | `lib/features/legal/*`, `docs/*`, `tool/gen_legal_pages.dart`, `routes.dart`, login/register/role-selection/profile screens |

---

## Part B: you must do these manually 🧑‍💻

### B1. Run the SQL (Supabase, about 10 min)  ← FIRST
- [x] **1.** SQL Editor → run `supabase/fixes.sql` sections 1 to 6. All returned "Success".
- [x] **2.** §7: your `status` CHECK already allows `'cancelled'`, so **no change is needed**.
- [x] **3.** §8 bucket check: `verification_images` is `public = false`.
- [x] **4.** **Storage policies (DONE, verified from the re-run of (0c)):** your (0c) output showed open policies (any logged-in user could read everyone's CNIC photos, and anyone, even logged out, could delete `profiles` files). Run **STEP S** in `supabase/rls.sql` (13 `drop policy` lines), then re-run (0c) and send me the output.
- [x] **5.** `provider_images` bucket: empty and unused by the code. Fine to leave it, or delete the bucket.
- [x] **6.** Queries (a) to (d) done. Results: functions exist, trigger `on_auth_user_created` exists. **But query (a) shows RLS is OFF on 14 tables** (see B1b below). The `true` policies on `providers` and `reviews` (read all) are intentional.
- [x] **7.** DONE: the `/object/public/verification_images/...` URL now returns `Bucket not found` (the earlier link was a signed URL from the dashboard, which is expected). Old note: CNIC URL still opened in incognito. See "CNIC image still opens" below.

**CNIC image still opens (item 7).** The bucket is private now, so a `/object/public/` URL should fail. The likely causes:
1. The URL you tested was from another bucket (`profiles` is public by design). Check that the URL contains `/verification_images/`.
2. Supabase's CDN cached the old public response, and it can keep serving it for a while after the bucket becomes private.

Fix: Storage → `verification_images` → select the old test files → **Delete**. Then retest after a few minutes with a fresh incognito window. Real users' files are in the new `<uid>/` folders and are private from the start. If the image **still** opens after deleting the file, send me the URL (hide the file name) and the output of query (0c).

### B1b. Turn on RLS (Supabase, about 15 min)  ← CRITICAL, do before launch
**Finding:** RLS is **OFF** on `users`, `providers`, `service_requests`, `messages`, `chat_rooms`, `notifications`, `favorites`, `business_products`, `provider_*`, `categories` and more. Policies exist on some of them but are **not enforced**. Anyone with the anon key in the APK can read, edit or delete every row: all emails, phones, chats, requests.
Also: the old `chat_rooms` / `service_requests` policies compared `auth.uid()` with `providers.id`. Those are different ids, so they would have locked every provider out of their chats and requests. The new file fixes that.

- [x] **1.** STEP 0 done: `delete_my_account`, `delete_message_for_everyone` and `handle_new_user` are all `security definer` (true), so they are safe once RLS is on.
- [x] **1b.** Original STEP 0 instructions, kept for reference:
  - If (0a) or (0b) shows `prosecdef = false`, run the `alter function ... security definer` line from the comments **first**. Otherwise account deletion or sign-up will break after step 3.
  - Send me the output of (0a), (0b) and (0c).
- [x] **2.** Run **STEP 1** (functions and policies). It has no effect yet, because RLS is still off.
- [x] **3.** Run **STEP 2** (enable RLS). Protection starts here.
- [x] **4.** (Tested on 2 phones: requests, accept, chat, map all work.) Test the whole app right away: log in as a customer and as a provider, then run the Part C checklist (requests, accept, chat, images, cancel, rate, delete account). **Test with two real accounts on two phones or an emulator.**
- [x] **5.** Nothing broke, so no rollback needed. (If something breaks, run the **ROLLBACK** block at the bottom of the file and send me the screen name and the exact error. I'll fix that policy. Don't leave it rolled back at launch.)

**What this still does not hide:** logged-in users can read other users' `phone` and `email` (the app needs names and photos from the same table). Anonymous visitors cannot. See Part D.

### B2. Email OTP: custom SMTP (about 15 min)  ← without this, real users get NO OTP
Supabase's built-in email only delivers to your project's team members, and only a few per hour.
- [x] **1.** SMTP provider account created and connected in Supabase (Authentication → Emails → SMTP Settings). **DONE.**
- [ ] **2.** Templates (Authentication → Emails → Templates): **Magic Link**, **Confirm signup** and **Reset Password** must contain `{{ .Token }}`, for example `Your ProNear code is: <h2>{{ .Token }}</h2>`. Without it users get a link instead of a 6-digit code.
- [ ] **3.** Authentication → Rate Limits: raise "emails per hour" (for example to 100).
- [ ] **4.** Test: register with an email address that is **not** a member of your Supabase team, and also try Forgot Password. Both must deliver a 6-digit code.

### M1. Create the release keystore (about 5 min)  ← required for Play upload
- [x] Step 1 `D:\keys\pronear-upload.jks` created · [x] Step 2 `android/key.properties` created · [ ] Step 3 **backup of the .jks file and password (2 places)** · [x] Step 4 SHA-1 noted
In PowerShell:
```powershell
New-Item -ItemType Directory -Force D:\keys
keytool -genkey -v -keystore D:\keys\pronear-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
(If `keytool` isn't found, use `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.)

Create the file `android/key.properties` (already ignored by git, **never share it**):
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=D:/keys/pronear-upload.jks
```
**Back up `pronear-upload.jks` and both passwords** (Google Drive, USB). If you lose them, you need Google support to reset the upload key.

Get the SHA-1 (needed in B4):
```powershell
keytool -list -v -keystore D:\keys\pronear-upload.jks -alias upload
```

### B3. Build and test
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```
The output is `build/app/outputs/bundle/release/app-release.aab`. To test on a phone: `flutter run --release`. Follow the Part C checklist.

### B4. Google Maps API key (about 5 min)
- [x] New Google Cloud project with billing, **Maps SDK for Android** enabled, new key created and set in `AndroidManifest.xml` (`AIzaSyB-FMn...`). The old key is gone from the project.
- [x] Restricted to Android apps: package `com.pronear.app` with the **release SHA-1** and the **debug SHA-1**.
- [x] Tested: **the map shows correctly** with `flutter run`.
- [ ] After the first Play upload, add the **Play App Signing SHA-1** (Play Console → Setup → App integrity → App signing key certificate) to the same key with package `com.pronear.app`. Otherwise the map is blank in builds installed from the Play Store.
- [ ] Test the **release APK** (`flutter build apk --release`) on a phone and check the map there too.
- [ ] Optional: delete or restrict the **old key** (`AIzaSyDQ...`) if you can still reach its project. It is in the git history.

### B5. Legal pages: GitHub Pages (about 15 min)  ← mandatory for Play Store
**Already done in code:** the legal pages exist both inside the app and as a static website in the [docs/](docs/) folder.

| Where | What |
|---|---|
| In the app | Public screens `/legal/privacy`, `/legal/terms`, `/legal/delete-account`. Links are on the **role selection**, **login** and **register** screens, and in both **profile** screens. The register screen has a **required checkbox** ("I agree to the Privacy Policy and Terms", plus a CNIC/face consent line for providers) |
| Website | `docs/index.html`, `privacy-policy.html`, `terms.html`, `delete-account.html` |
| Source text | `lib/features/legal/legal_content.dart` (one source for both) |

**What you must do:**
1. [x] **Support email set** in `lib/features/legal/legal_content.dart` (`kSupportEmail`). Note: it is public on the website.
2. [x] **Website text regenerated:** `dart run tool/gen_legal_pages.dart` (re-run this whenever you change the text).
3. [ ] Read all three pages once. They are a solid template, but **they are not legal advice**. Change anything that doesn't match how you actually run the business (for example, deletion time, who reviews the CNICs).
4. [ ] Push the repo to GitHub, then: Repo → **Settings → Pages → Source: "Deploy from a branch" → Branch `main` → Folder `/docs` → Save**.
5. [ ] After about 1 minute you get a URL like `https://<username>.github.io/<repo>/`. Your Play Console links are:
   - Privacy policy: `https://<username>.github.io/<repo>/privacy-policy.html`
   - Account deletion URL: `https://<username>.github.io/<repo>/delete-account.html`
6. [ ] Put your base URL in `kLegalBaseUrl` (same file), so you have it in one place. Open the three links in a browser and check that they load without login.
7. [ ] Make sure the repo doesn't contain secrets before you push: `android/key.properties`, `*.jks` (already ignored). Your Supabase anon key in `main.dart` is meant to be public, but only if RLS (B1) is done.

### B6. Play Console (about 1 hour)
1. Create the app: name **ProNear**, default language, App, Free.
2. **App content**:
   - Privacy policy URL (B5, the GitHub Pages link).
   - **Data safety**: declare collected data as Personal info (name, email, phone, **government ID** in "Other info"), Photos, Precise location, Messages. Mark them all as "encrypted in transit: yes" and "users can request deletion: yes".
   - **Data deletion**: in-app (yes) plus the `delete-account.html` URL (B5).
   - Ads: No. Target audience: 18+. Content rating questionnaire.
   - **Permissions**: camera (CNIC/face/portfolio photos), location (nearby providers), microphone (voice search). Be ready to explain these in the review.
3. Store listing: 512×512 icon, 1024×500 feature graphic, at least 2 phone screenshots, short and full description.
4. Upload `app-release.aab` to **Internal testing** first, install from the Play link, test, then promote to Production.
5. Personal developer accounts created after Nov 2023 must run a **closed test with 12+ testers for 14 days** before production access. Plan for this, because it means a production release "tomorrow" may not be possible.

### B7. Approving providers (ongoing, admin work)
New providers now stay **unverified** (no ✔ badge) until you approve them:
1. SQL Editor → run the "Pending list" query at the bottom of `fixes.sql`.
2. Storage → `verification_images` → open the folder named with the user id. Compare the CNIC photos with the face photo and the typed name.
3. Run the **Approve** (or Reject) SQL with that user id.

### B8. iOS (only if you publish on the App Store)
In `ios/Runner/Info.plist`, add `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`. Add the Google Maps key in `AppDelegate.swift` (`GMSServices.provideAPIKey`). Set `CFBundleDisplayName` to ProNear. Building needs a Mac.

---

## Part C: test checklist (real phone, release build)

- [ ] Fresh install, then the role selection screen appears
- [ ] **Customer**: register (OTP arrives at a **non-team** email, this is the SMTP test), close and reopen the app, still logged in, home shows nearby providers on the map
- [ ] Voice search: the mic permission prompt appears and speech fills the search box
- [x] **Provider**: register with CNIC front/back and face photos, then type selection, then CV. In Supabase, `user_verifications` has the row with status `pending`, the files are in `verification_images/<uid>/`, and `users.cnic` is empty
- [ ] Same CNIC again with another email → "already registered" with a masked email
- [ ] **Business**: register, then business setup, category and products (2+ images), all images display
- [x] Customer sends a request, provider sees it, **Accept**, chat opens
- [ ] Customer → Profile → **Request History** shows it as Accepted → Open chat works. Exchange text and image messages both ways
- [ ] Provider → **Mark Completed**. Customer → Rate → provider rating updates. Dashboard earnings show the budget
- [ ] Customer cancels a pending request, and the provider gets a notification
- [ ] Profile → **Favorite Providers** opens
- [ ] Tapping a notification goes to the right screen (both roles)
- [ ] Forgot password: OTP, then new password, then login
- [ ] **Delete account** (both roles), then login fails, and the storage files are gone
- [ ] Airplane mode on first launch shows "Could not connect" (no crash)

---

## Part D: after launch (not blocking)

1. **Push notifications when the app is closed** (FCM). Today, notifications only arrive while the app is open. A provider with the app closed won't know about a new request. Needs a Firebase project, `firebase_messaging`, a `device_tokens` table and a Supabase Edge Function or database webhook on `notifications` insert. This is the most important next feature.
2. **Real face matching** (compare the selfie with the CNIC photo) using a server-side service (AWS Rekognition, Azure Face) or keep manual admin review. The `face_embedding` value is still a placeholder.
3. **Tighten RLS** on `service_requests`, `messages`, `chat_rooms` and `notifications` after reading the §8 output. Notifications are currently inserted by the client for other users; move that to DB triggers.
4. Hide `phone` and `email` from other users (put the public columns into a view). Don't send provider **emails** to customers (`getNearbyProviders` selects `users.email`). Use a view with only the public columns.
5. Server-side nearby search (PostGIS RPC) instead of downloading every provider.
6. Replace the deprecated `withOpacity` calls with `withValues(alpha:)`. These are only warnings.
