# ProNear (near_pro1): App Audit & Code Guide

Audit date: 2026-11-18. Scope: the full `lib/` folder (about 36k lines), Android and iOS config, and every Supabase call made from the app.
I can't see the Supabase dashboard, so RLS policies, storage bucket settings and DB triggers are **not verified**. Section 6 has the SQL to check them.

---

## 1. What the app does

ProNear is a marketplace that finds nearby service providers (electrician, plumber, AC technician, carpenter and so on) and also lets local businesses sell products.

| Role | Stored as `users.role` | Can do |
|---|---|---|
| Customer | `user` | Find providers on a map or in a list, see a provider's profile and portfolio, send a service request or product order, chat once the request is accepted |
| Provider (individual) | `provider` | Email OTP, then CNIC front and back, then face check, then CV/profile, then dashboard. Accept or reject requests and chat |
| Business | starts as `business`, changed to `provider` on the Business Type screen | Same verification, then business setup, category and products |

Backend: **Supabase** (Auth, Postgres, Storage, Realtime). No other server.

---

## 2. Project structure

```
lib/
  main.dart                     Supabase init, local notifications, realtime notification listener, Providers, router
  app/routes.dart               GoRouter: every route (no auth guard / redirect)
  app/theme.dart
  core/services/
    supabase_service.dart       ALL DB / storage / realtime calls (singleton)
    email_otp_services.dart     OTP helper (registration & forgot-password screens call Supabase directly instead)
    global_error_handler.dart   run() wrapper → snackbar messages; camera permission helper
    notification_service.dart   flutter_local_notifications (foreground only)
  features/
    splash/                     Checks session → role → routes
    auth/                       role selection, login, register (5-step), forgot password, OCR, face detection
    provider/                   dashboard, requests, chat, CV, portfolio, profile, business_setup/*, ChangeNotifier providers
    user/                       home, categories, search (voice), map, provider detail, request, business products/checkout, chat, profile, notifications
    chat/chat_list_screen.dart  Shared chat list (role = user | provider)
  models/, widgets/, utils/
```

State management: `provider` with `AuthProvider`, `ProviderProvider`, `RequestProvider` and `ChatProvider`. Many screens skip these and call `Supabase.instance.client` directly.

### Supabase tables used
`users`, `providers`, `provider_services`, `provider_certificates`, `provider_portfolio`, `categories`, `business_categories`, `business_products`, `service_requests`, `chat_rooms`, `messages`, `notifications`, `favorites`, `reviews`, `profiles` (only in `EmailOtpService.userExists`)
RPCs: `delete_my_account`, `delete_message_for_everyone`

### Storage buckets used
| Bucket | What goes in | Path used | URL type |
|---|---|---|---|
| `verification_images` | **CNIC front, CNIC back, face photo** | `verification/{userId}_{type}_{ts}.jpg` | **public URL** |
| `profiles` | Profile photos, business photo, **product images** | `public/profile_{ts}.jpg`, `business/products/product_{ts}.jpg` | public URL |
| `portfolio_media` | Portfolio images/videos | `portfolio/{providerId}_{ts}.jpg` | public URL |
| `chat_images` | Chat pictures | `{userId}/chat_{ts}.jpg` | public URL |

---

## 3. Flows, screen by screen

### 3.1 App start
`main.dart` initializes Supabase and local notifications (and asks for notification permission straight away). It also listens to the `notifications` table over Realtime and shows a local notification for any unread row created in the last 15 s.
`SplashScreen` waits 2.5 s. With no session it goes to `/role-selection`. With a session it reads `users.role`: a provider goes to `/provider/dashboard` if a `providers` row exists (otherwise `/provider/cv`), and anyone else goes to `/user/home`. If the `users` row is missing, it signs the user out.

### 3.2 Registration (`register_screen.dart`)
1. **Email OTP**: `signInWithOtp(shouldCreateUser: true)` then `verifyOTP(type: email)`. This creates the auth user and logs them in.
2. **Provider/business only:** they take a CNIC front and back photo with the camera. ML Kit OCR reads the **CNIC number from the front image only**, and `getUserByCNIC` checks for duplicates.
3. **Face**: one camera photo. ML Kit face detection passes if at least one eye is "open" (probability above 0.5).
4. **Personal info**: name, phone and password, saved with `auth.updateUser(password, metadata)`.
5. Providers' 3 images go to `verification_images`, then `users` is updated with `cnic`, the image URLs, `face_embedding`, `cnic_verified = true` and `face_verified = true`.
6. Providers go to `/business/type`. Customers go to `/user/home`.

### 3.3 Provider onboarding
`/business/type` sets `users.role = 'provider'` and `is_business`. Individual providers go to `/provider/cv`, which saves location, profile image, a `providers` row and certificates, and then shows the dashboard.
Businesses go through `/business/setup`, `/business/category-selection`, `/business/products` (images go to the `profiles` bucket) and then the dashboard.

### 3.4 Customer: find and request
Home, map and search use `getNearbyProviders`. It loads **all** available providers, filters by distance on the phone and sorts by km. Search has voice input through `speech_to_text`.
Provider detail shows the profile, services, portfolio, reviews and favourite button, plus a request button that opens `/user/request/:id` or the business route.
`createServiceRequest` inserts a `service_requests` row (status `pending`) and a `notifications` row for the provider's user.

### 3.5 Provider: accept and chat
Requests come from the dashboard or `/provider/requests`. On accept, the app calls `updateServiceRequest(status: accepted)`, which notifies the customer. Then `getOrCreateChatRoom(user, provider)` runs and the provider is sent to the chat.
Chat has Realtime messages, image messages, read receipts and delete-for-everyone. Every message also inserts a `notifications` row for the receiver.
The customer reaches the chat from the chat list.

### 3.6 Profile and account deletion
Both profile screens delete storage files first and then call RPC `delete_my_account`. This is good, because Play Store requires in-app account deletion.

---

## 4. Issues: what can go wrong at publish

### 🔴 BLOCKERS: fix before uploading to Play Store

| # | Problem | Where | Fix |
|---|---|---|---|
| B1 | **The release build is signed with the debug key.** Play Console rejects it. | `android/app/build.gradle.kts` `signingConfig = debug` | Create an upload keystore and add a `release` signingConfig through `key.properties`, which must not be committed |
| B2 | **The package name is `com.example.near_pro1`.** Play rejects `com.example.*`, and the name can never change after the first upload. | `build.gradle.kts` (`namespace`, `applicationId`) | Change it to something like `com.pronear.app`, move `MainActivity.kt` into the matching folder, then update the Maps key restriction |
| B3 | **CNIC and face photos are in a public bucket and shared with public URLs.** Anyone with the link can open them without logging in. They are **not encrypted**. | `uploadVerificationImage` → `getPublicUrl` | Make the `verification_images` bucket **private**, store the **path** (not a URL), and add storage RLS so only the owner can upload/read. Admins can view through `createSignedUrl`. See section 5 |
| B4 | **Verification is set by the app itself.** `cnic_verified` and `face_verified` are always written as `true` from the phone. OCR only reads a 13-digit number (any paper with those digits passes), the back image is never checked, the face is never compared with the CNIC photo, and `face_embedding` is just `"face_<timestamp>"`. Any user can also run `users.update({cnic_verified:true})` with the anon key. | `register_screen.dart`, `face_recoganization.dart`, `saveUserWithVerification` | Save `verification_status = 'pending'`. An admin checks the images and sets `approved` (with a DB trigger or column privileges so users cannot change it). Only show the ✔ badge when approved |
| B5 | **Supabase's built-in email only goes to your own team's addresses**, and it has a very low hourly limit. Real users will **never receive the OTP**. | Supabase → Auth → SMTP | Set up custom SMTP (Resend, Brevo, SendGrid, Gmail SMTP). Also make the "Magic Link" / "Confirm signup" templates include `{{ .Token }}` so a 6-digit code is sent instead of only a link |
| B6 | **RLS is unknown and probably too open.** The app reads other users' rows by CNIC (`getUserByCNIC`), inserts notifications for other users, and updates any `service_requests` row by id. If RLS lets this through, any logged-in person can read every user's **CNIC number, phone, email and face image URL** using the anon key in the APK. | DB | Run the checks in section 6. Move the CNIC duplicate check to an RPC (`security definer`) that returns only true/false. Add `UNIQUE(cnic)` |
| B7 | **The Play Data Safety form and a privacy policy are mandatory.** You collect government ID, face images, precise location, photos and messages. | Play Console | Publish a privacy policy page, fill in Data Safety honestly, and add an account-deletion **web URL** (Play asks for one even though in-app deletion exists) |

### 🟠 HIGH: functional bugs users will hit

| # | Problem | Where | Fix |
|---|---|---|---|
| H1 | **Voice search can't work.** `RECORD_AUDIO` is missing from the manifest, and Android 11+ also needs a `<queries>` entry for `android.speech.RecognitionService`. | `AndroidManifest.xml` | Add both (snippet in section 7) |
| H2 | **There are no push notifications when the app is closed.** Notifications only come through Realtime while the app is open, so a provider won't know about a new request. This is the core flow. | `main.dart` | Add FCM (`firebase_messaging`) and a Supabase Edge Function or DB webhook on `notifications` insert. If you can't before launch, say so in the store listing |
| H3 | **Customer accounts may have no `public.users` row.** The OTP path never inserts into `users` (only `signUp()` does, and the registration screen doesn't use it). Without a DB trigger, the app signs customers out on next launch, and the provider CNIC `update` hits 0 rows silently. | `register_screen._completeRegistration` | Check for a trigger on `auth.users` (section 6). If there is none, call `ensureUserExists(...)` at the end of registration |
| H4 | **A business user who logs in before finishing the Business Type screen lands on the customer home.** `login_screen` only checks `== 'provider'`, while splash maps `business` to `provider`. | `login_screen.dart` (~line 442) | Treat `business` as `provider` there too |
| H5 | **There is no "Mark completed" button.** `RequestProvider.completeRequest()` is never called. Nothing in the app inserts into `reviews`, so ratings stay at 0 forever. Dashboard "earnings" is fake (`completedJobs × 500`). | provider request/dashboard, user side | Add a Complete action for the provider and a Rate dialog for the customer. Hide earnings or compute them from real prices |
| H6 | **The customer has no "My Requests" screen.** `loadUserRequests`/`listenToUserRequests` are never used, so a customer can't see pending/accepted/rejected requests or cancel one. | `features/user` | Add a simple list screen |
| H7 | **Import casing is wrong.** `routes.dart` imports `role_selection_screen.dart`, but the file is `role_Selection_screen.dart`. It works on Windows but **fails on macOS/Linux**, which includes the iOS build and CI. | `lib/app/routes.dart:14` | Rename the file to `role_selection_screen.dart` |
| H8 | **Storage paths aren't scoped to the user** (`public/profile_ts.jpg`, `business/products/...`). You can't write owner-only policies, so one user may be able to overwrite or delete another's files (`upsert: true`). | profile/CV/business screens | Use `'{userId}/…'` as the first folder in every bucket and add the policy from section 5 |
| H9 | Customer account deletion looks up portfolio with `provider_id = userId` (that is the wrong id). | `user/profile_screen.dart` | Harmless for customers, but worth fixing |
| H10 | `Supabase.initialize` failure is caught, but the next line uses `Supabase.instance`, so the app **crashes** offline on first launch. | `main.dart` | Show an error screen or retry |

### 🟡 MEDIUM: size, performance, store review

| # | Problem | Fix |
|---|---|---|
| M1 | **About 15 unused packages**: `camera`, `video_player`, `v_video_compressor`, `chewie`, `url_launcher`, `flutter_phone_direct_caller`, `connectivity_plus`, `image_cropper`, `shimmer`, `flutter_svg`, `flutter_staggered_animations`, `google_mlkit_face_detection`, `google_mlkit_text_recognition` (the code uses the `google_ml_kit` umbrella). The **`google_ml_kit` umbrella pulls in every ML Kit plugin** (smart reply, language id and more), which is why your build ran 12 Kotlin tasks and took 20 min | Replace `google_ml_kit` with `google_mlkit_text_recognition` and `google_mlkit_face_detection`, change the 2 imports, and remove the unused packages |
| M2 | The Chinese, Devanagari, Japanese and Korean OCR models are bundled (tens of MB). CNIC only needs Latin | Remove those 4 `implementation(...)` lines |
| M3 | The Google Maps API key is hard-coded and visible in the APK | In Google Cloud, restrict it to Android apps, your package name and your release + Play signing SHA-1 |
| M4 | `getNearbyProviders` downloads **every** provider (and their email) and filters on the phone | Fine for launch, but later use a PostGIS RPC. Don't select `email` |
| M5 | `print()` writes CNIC numbers and emails to logcat in release | Use `debugPrint` / `kDebugMode` |
| M6 | iOS: `Info.plist` has **no** camera, photo, location or microphone usage strings, so the app crashes on the first prompt. There is no Google Maps key in `AppDelegate`, and the display name is "Near Pro1" | Required only if you publish iOS |
| M7 | `minSdk = 28` excludes Android 8.x and older | OK if intended |
| M8 | `gradle.properties` gives Gradle `-Xmx8G`. The two `hs_err_pid*.log` files in `android/` are JVM crashes (out of memory) | Use `-Xmx4G` if your PC has 8–16 GB RAM |
| M9 | Chat images are public URLs | Acceptable. A private bucket with signed URLs is better |
| M10 | No route guards: GoRouter has no `redirect`, so any screen can be opened without a session | Add a redirect that checks `currentSession` and role |

---

## 5. CNIC / face image security: how to check and fix

**How to check it yourself (2 minutes):**
1. Supabase Dashboard → Storage → `verification_images`. If it says **Public**, the files are open to the internet.
2. Table Editor → `users` → copy any `cnic_front_image` URL and open it in an incognito browser. If the image loads, anyone can see it.
3. Encryption: Supabase encrypts disks at rest (AES-256), but that does **not** protect against public URLs or weak RLS. Access control is the real protection.

**Fix (DB side):**
```sql
-- 1) make bucket private
update storage.buckets set public = false where id = 'verification_images';

-- 2) only the owner can upload/read their own files (path must start with their uid)
create policy "own verification upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'verification_images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own verification read" on storage.objects for select to authenticated
  using (bucket_id = 'verification_images' and (storage.foldername(name))[1] = auth.uid()::text);
```
**Fix (app side, `uploadVerificationImage`):** change the path to `'$userId/${type}_$timestamp.jpg'` and **return `filePath`** instead of `getPublicUrl`. Store the path in `users`. When an admin needs to see it, call `storage.from('verification_images').createSignedUrl(path, 600)` from the admin tool or service role.
Old rows that already hold public URLs need their files moved, or the users re-verified.

---

## 6. SQL checks to run in the Supabase SQL editor

```sql
-- RLS on/off per table
select tablename, rowsecurity from pg_tables where schemaname = 'public' order by 1;

-- All policies
select tablename, policyname, cmd, roles, qual, with_check from pg_policies where schemaname='public' order by 1;

-- Is there a trigger that creates public.users on signup?  (H3)
select tgname, pg_get_triggerdef(t.oid) from pg_trigger t
join pg_class c on c.oid = t.tgrelid join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'auth' and c.relname = 'users' and not tgisinternal;

-- Do the RPCs exist?
select proname, prosecdef from pg_proc where proname in ('delete_my_account','delete_message_for_everyone');

-- Bucket visibility
select id, public from storage.buckets;
```
What "good" looks like:
- `users`: a user can select and update **only their own row**. Others can only see non-sensitive columns through a view (`full_name`, `profile_image`, `is_online`), never `cnic`, `phone` or `face_*`.
- Users cannot update `cnic_verified`, `face_verified` or `role` themselves (use a trigger or column grants).
- `service_requests`: insert where `user_id = auth.uid()`. Update only by the provider who owns `provider_id`, or the customer for a cancel.
- `messages` / `chat_rooms`: only the two participants.
- `notifications`: select/update/delete own rows. Inserts should come from a trigger, not the client.

---

## 7. Snippets

**AndroidManifest.xml** (fixes H1):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
...
<queries>
    <intent><action android:name="android.speech.RecognitionService" /></intent>
    <intent><action android:name="android.intent.action.PROCESS_TEXT"/><data android:mimeType="text/plain"/></intent>
</queries>
```

**Release signing** (`android/app/build.gradle.kts`, fixes B1):
```kotlin
import java.util.Properties
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties"); if (f.exists()) load(f.inputStream())
}
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
}
```
Create the keystore with: `keytool -genkey -v -keystore D:\keys\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. **Back up this file and its password. If you lose it, you can't update the app.**

---

## 8. Pre-publish checklist

- [ ] B1 release keystore · [ ] B2 package name · [ ] B3 private verification bucket · [ ] B4 pending-verification status
- [ ] B5 custom SMTP + OTP template · [ ] B6 RLS reviewed · [ ] B7 privacy policy + Data Safety + deletion URL
- [ ] H1 RECORD_AUDIO · [ ] H3 users row trigger confirmed · [ ] H4 business login route · [ ] H7 file rename
- [ ] `flutter build appbundle --release` succeeds, then install the release build on a **real phone** and test: register a customer, register a provider (CNIC + face), send a request, accept it, chat, send an image, delete the account
- [ ] Store listing: icon 512px, feature graphic, screenshots, content rating, target audience
