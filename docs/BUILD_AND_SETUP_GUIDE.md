# 🛠 DHS Anime — Complete Build & Setup Guide (VS Code)

Build the full stack from zero on your own machine: **Flutter app** (frontend), **Node/Express/MongoDB API** (backend), and the **Admin Panel** (web). Every step is copy-paste friendly.

---

## 📑 Table of Contents

1. [What you are building](#1-what-you-are-building)
2. [Prerequisites](#2-prerequisites)
3. [VS Code extensions](#3-vs-code-extensions)
4. [Get the code](#4-get-the-code)
5. [Part A — Backend setup](#part-a--backend-setup-api)
6. [Part B — Flutter app setup](#part-b--flutter-app-frontend)
7. [Part C — Admin panel setup](#part-c--admin-panel-web)
8. [End-to-end checklist](#end-to-end-checklist)
9. [Building release APK](#building-the-release-apk)
10. [Troubleshooting](#troubleshooting)
11. [Cheat sheets](#cheat-sheets)

---

## 1. What you are building

```
┌──────────────────┐      HTTPS       ┌────────────────────┐      ┌────────────┐
│  DHS Anime App    │ ──────────────▶ │  Backend API        │ ───▶ │  MongoDB   │
│  (Flutter/Android)│  /api/...       │  Express · port 5000│      └────────────┘
│  downloads+player │                 │  users · episodes · │
└──────────────────┘                  │  notifications ·    │
                                      │  premium codes      │
┌──────────────────┐                  └─────────▲──────────┘
│  Admin Panel      │  /api/admin/... (JWT)     │
│  (static web)     │ ──────────────────────────┘
│  mirror links +   │
│  premium codes    │
└──────────────────┘
```

| Piece | Folder | Tech |
|---|---|---|
| Mobile app | `flutter_app/` | Flutter 3.x, Dart, Riverpod, Hive, Clerk (Google-only), flutter_downloader |
| Backend API | `backend/` | Node 18+, Express 4, MongoDB (Mongoose), JWT, Socket.IO, FCM (optional) |
| Admin panel | `admin_panel/` | Dependency-free HTML/CSS/JS (open with Live Server) |

**How the product works:** the admin pastes third-party mirror links (Mega / GDrive / Terabox / Telegram…) per episode in the admin panel → users get a **new episode / new donghua notification** → free users **solve a shortener** to unlock downloads, **premium** users (activated with dev-generated codes) skip the gate → files download to the `DHS Anime` folder on internal storage → watched in the built-in **offline player**.

---

## 2. Prerequisites

Install these first (Windows / macOS / Linux all work):

| Tool | Version | Get it |
|---|---|---|
| **VS Code** | latest | https://code.visualstudio.com |
| **Node.js LTS** | ≥ 18 | https://nodejs.org |
| **Git** | latest | https://git-scm.com |
| **Flutter SDK** | ≥ 3.16 (stable) | https://docs.flutter.dev/get-started/install |
| **Android Studio** *(SDK, emulator)* | latest | https://developer.android.com/studio |
| **MongoDB** — local *or* free **Atlas** cluster | ≥ 6 | https://www.mongodb.com/try/download/community or https://cloud.mongodb.com |
| **Java JDK** | 17 | comes with Android Studio |

After installing Flutter, run once in a terminal:

```bash
flutter doctor            # verify everything has a green check
flutter doctor --android-licenses
```

> ℹ️ You only need *Android Studio* for its **SDK + emulator** — all coding happens in VS Code.

---

## 3. VS Code extensions

Open VS Code → `Ctrl+Shift+X` → install:

| Extension | ID | Why |
|---|---|---|
| **Flutter** | `Dart-Code.flutter` | run/debug the app, device picker |
| **Dart** | `Dart-Code.dart-code` | (auto-installed with Flutter) |
| **Live Server** | `ritwickdey.LiveServer` | serve `admin_panel/` in one click |
| **ESLint** | `dbaeumer.vscode-eslint` | lint backend JS |
| **MongoDB for VS Code** *(optional)* | `mongodb.mongodb-vscode` | browse the DB, flip admin roles |
| **Thunder Client** *(optional)* | `rangav.vscode-thunder-client` | test API endpoints inside VS Code |
| **Error Lens** *(optional)* | `usernamehw.errorlens` | inline errors |

---

## 4. Get the code

```bash
git clone https://github.com/Agent8800/DHS-Anime.git
cd DHS-Anime
code .          # opens the whole repo in VS Code
```

Repo layout:

```
DHS-Anime/
├── backend/         # Node + Express + MongoDB API          → Part A
├── flutter_app/     # The Android app                        → Part B
├── admin_panel/     # Static web panel (links/codes/stats)   → Part C
├── previews/        # UI preview images
└── docs/            # ← this guide
```

> 💡 Recommended: VS Code → *File → Add Folder to Workspace…* `backend/`, `flutter_app/`, `admin_panel/` — one window, three roots.

---

## Part A — Backend setup (API)

### A.1 Install dependencies

```bash
cd backend
npm install
```

### A.2 Create `.env`

```bash
cp .env.example .env
```

Open `.env` in VS Code and fill it in:

| Variable | Required | What to put |
|---|---|---|
| `PORT` | ✅ | `5000` |
| `MONGODB_URI` | ✅ | Local: `mongodb://localhost:27017/donghuahub` — Atlas: paste your `mongodb+srv://…` string |
| `JWT_SECRET` | ✅ | Any long random string (e.g. `openssl rand -hex 32`) |
| `JWT_EXPIRE` | ✅ | `7d` |
| `CLERK_SECRET_KEY` | ✅ | Clerk dashboard → *API Keys* → Secret key (`sk_test_…`) |
| `CLERK_PUBLISHABLE_KEY` | ✅ | Same page → Publishable key (`pk_test_…`) |
| `CLERK_WEBHOOK_SECRET` | optional | only if you enable Clerk webhooks |
| `FIREBASE_SERVICE_ACCOUNT_JSON` **or** `FCM_SERVICE_ACCOUNT_PATH` | optional | enables **push** notifications; without it, notifications still appear in the in-app bell feed |
| `STORAGE_*`, `SMTP_*` | optional | legacy/media features — safe to leave blank |

**Clerk setup (60 s):** https://dashboard.clerk.com → *New application* → name it → in *User & Authentication → Social Connections* enable **only Google** (turn *Email address* **off** — this app is Google-only by design) → copy both keys into `.env`.

### A.3 Start MongoDB

- **Local:** `mongod` (or it runs as a service after install)
- **Atlas:** create a free cluster → *Database Access* add a user → *Network Access* allow your IP → use the `mongodb+srv://` URI in `.env`.

### A.4 Run the API

```bash
npm run dev        # nodemon, auto-restarts on save
# → “Server running on port 5000” + “MongoDB connected”
```

Test it (Thunder Client or a new terminal):

```bash
curl http://localhost:5000/api/anime
# {"success":true,"data":{...}}
```

### A.5 Create your admin account

1. Open `backend/scripts/seed.js` (optional demo data): `npm run seed`
2. Sign in once from the **app** (Part B) with your Google account — a `users` document is created with `role: "user"`.
3. Promote it to admin — either in the MongoDB VS Code extension / Compass / `mongosh`:

```js
use donghuahub
db.users.updateOne({ email: "you@gmail.com" }, { $set: { role: "admin" } })
```

4. Call `POST /api/auth/sync` again (or just re-open the app) — the JWT it returns now has the admin role. **Copy that token**, the admin panel needs it (Part C).

> The token is also saved on the device (secure storage). Easiest way to read it: `adb logcat`, or call `POST /api/auth/sync` from Thunder Client with your `clerkId` + `email` body and copy `data.token` from the response.

---

## Part B — Flutter app (frontend)

### B.1 Project setup

```bash
cd flutter_app
flutter pub get
```

### B.2 Point the app at your backend

Open `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';   // Android emulator → host machine
```

| Where the app runs | Use this base URL |
|---|---|
| Android emulator | `http://10.0.2.2:5000/api` ✅ (default, leave as-is) |
| Real phone, same Wi-Fi | `http://<your-PC-LAN-IP>:5000/api` (find via `ipconfig` / `ip a`) |
| Production server | `https://api.yourdomain.com/api` |

### B.3 Clerk key

The publishable key is injected at build time (never hard-code it):

```bash
flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_XXXXXXXX
```

> 💡 VS Code tip: create `.vscode/launch.json` inside `flutter_app/` so `F5` always passes it:
> ```json
> {
>   "version": "0.2.0",
>   "configurations": [
>     {
>       "name": "DHS Anime",
>       "request": "launch",
>       "type": "dart",
>       "program": "lib/main.dart",
>       "args": ["--dart-define=CLERK_PUBLISHABLE_KEY=pk_test_XXXXXXXX"]
>     }
>   ]
> }
> ```

### B.4 Pick a device & run

1. Status bar (bottom-right) → select your **emulator** or a USB-debugging phone.
2. Press **F5** (or `flutter run --dart-define=...`).
3. First build takes 3–6 min (Gradle). Later runs use hot reload (`r` in terminal).

### B.5 Push notifications (optional)

Without them everything still works — users see updates inside the bell-icon feed.

1. https://console.firebase.google.com → create project → add Android app with package **`com.donghuahub.app`**.
2. Download `google-services.json` → put it in `flutter_app/android/app/`.
3. Download the *service account JSON* (Project settings → Service accounts) → set its absolute path as `FCM_SERVICE_ACCOUNT_PATH` **on the backend** `.env` and restart.

### B.6 Downloads / storage behaviour (already coded — just verify)

- Default folder `Internal Storage/DHS Anime` is created automatically; changeable in **Settings → Downloads → Download Location**.
- Android 11+ asks for *All files access* (`MANAGE_EXTERNAL_STORAGE`) when a public folder is chosen — grant it on your test phone.
- Demo episode cards need real backend data — use the admin panel (Part C) to add a donghua + mirror links, then pull-to-refresh the app.

---

## Part C — Admin panel (web)

### C.1 Open it

- **Easiest:** VS Code → open `admin_panel/index.html` → right-click → **“Open with Live Server”** → http://127.0.0.1:5500
- Or from the terminal: `cd admin_panel && python3 -m http.server 8080`

It’s fully **responsive** — works on your phone browser too (hamburger menu ☰ opens the anime drawer).

### C.2 Two modes

| Mode | How | What happens |
|---|---|---|
| **DEMO** ✨ | click *Try Demo Mode* | seeded fake data saved to browser localStorage — perfect for exploring UI, generating demo codes, trying stats |
| **LIVE** 🔗 | paste **API base** `http://localhost:5000/api` **+ your admin JWT** (from A.5) → *Connect* | everything reads/writes the real database |

### C.3 Daily workflow

1. **📊 Dashboard tab** — see **Total Users**, **Daily Active Users** (signed-in last 24 h), **Total Premium Users** (ever had premium), **Active Premium Users** (premium valid now), **Total Downloads**.
2. **Add a donghua** — *＋ New Donghua* → fill title → every app user gets a **new donghua notification** automatically.
3. **🔗 Mirror Links tab** — pick the anime → *＋ Add Episode* (notifies users) → click **Edit Links** → **bulk-paste** mirrors, one per line:
   ```
   Mega HD | https://mega.nz/file/xxxx | 1080p | 480 MB
   https://drive.google.com/file/d/yyyy
   Telegram | https://t.me/c/123/456 | 720p
   ```
   Host, quality and size are **auto-detected**. *Save* → links appear instantly in the app's download sheet.
4. **Generate premium codes** — Dashboard → ⚡ Generate (count + days + optional note) → share codes (📋 copy) with users → they redeem in the app at **Account → Activate with Code**. Codes are single-use and **stack** if a user is already premium. The table shows who redeemed each code.

---

## End-to-end checklist

Do these in order for a full working system:

- [ ] `backend/.env` filled, `npm run dev` → *MongoDB connected*
- [ ] App signs in with Google → user document appears in MongoDB
- [ ] Your user promoted to `role: "admin"`
- [ ] Admin panel (LIVE) connects with the JWT → Dashboard shows real stats
- [ ] Added 1 donghua from the panel → app shows it + bell badge appears
- [ ] Added 1 episode with 2 mirror links → download sheet lists them
- [ ] Free account → asks to solve shortener before download ✅ gate works
- [ ] Generated premium code → redeemed in app (Account page) → same episode now unlocks **without** shortener
- [ ] File lands in `Internal Storage/DHS Anime` → plays in the built-in player, offline
- [ ] (Optional) Firebase wired → system push arrives for new episode

---

## Building the release APK

```bash
cd flutter_app
flutter build apk --release \
  --dart-define=CLERK_PUBLISHABLE_KEY=pk_live_XXXXXXXX
```

Output: `flutter_app/build/app/outputs/flutter-apk/app-release.apk` → copy to phones / Play Console / your site.

| Variant | Command |
|---|---|
| Split per ABI (smaller) | `flutter build apk --release --split-per-abi --dart-define=CLERK_PUBLISHABLE_KEY=...` |
| Play Store bundle | `flutter build appbundle --release --dart-define=CLERK_PUBLISHABLE_KEY=...` |

**Before releasing:** switch `api_config.dart` to your `https://` production URL, sign the APK with your own keystore (see `flutter_app/android/README.md`), and use **live** Clerk keys (`pk_live_…` / `sk_live_…`).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `MongoServerError: connect ECONNREFUSED` | MongoDB not running (`mongod`) or wrong `MONGODB_URI`. Atlas: whitelist your IP + URL-encode the password. |
| App: *“Could not load download links”* forever | Wrong `baseUrl`. Emulator must use `10.0.2.2`, real phone must use your PC's LAN IP **and** the PC firewall must allow port 5000. |
| Login sheet closes instantly | `CLERK_PUBLISHABLE_KEY` missing — run with `--dart-define=...` (see launch.json). |
| Google login works but no session | Backend `CLERK_*` keys missing/wrong → check `npm run dev` console during `POST /auth/sync`. |
| Admin panel: *Request failed (401)* | Token expired (7 days) — re-sync and paste the new JWT. Not an admin → run the `updateOne` from A.5. |
| Download stuck at 0% | Mirror blocks direct downloads (e.g. Terabox HTML pages). Use a direct-file mirror (Mega/GDrive direct / Telegram file) or copy the link into a browser. |
| `MANAGE_EXTERNAL_STORAGE` denied | App falls back to its private folder automatically; or re-grant from **Settings → Storage Permission**. |
| Notifications only in bell, no push | Firebase not configured — that's the designed fallback; add the service-account JSON to enable push. |
| Gradle build fails | `flutter clean && flutter pub get` and ensure JDK 17 (`java -version`). |
| Codes say "Invalid" in app | Code is case-insensitive-checked but must exist & be unused — verify in the panel's codes table. |

---

## Cheat sheets

**Backend**
```bash
npm run dev        # dev server (nodemon)
npm start          # production
npm run seed       # demo data
```

**Flutter**
```bash
flutter pub get
flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_...
flutter analyze                  # static checks
flutter build apk --release --dart-define=CLERK_PUBLISHABLE_KEY=...
```

**Admin panel**
```bash
python3 -m http.server 8080      # or Live Server extension
```

**Key files you'll touch**

| What | Where |
|---|---|
| API base URL | `flutter_app/lib/config/api_config.dart` |
| Brand colors / theme | `flutter_app/lib/core/theme/app_theme.dart` |
| Download folder name (`DHS Anime`) | `app_constants.dart` → `appFolderName` |
| API routes | `backend/src/routes/` |
| Premium code logic | `backend/src/controllers/adminController.js` + `authController.js` (`redeemPremiumCode`) |
| Notification text | `backend/src/services/notificationService.js` |
| Admin UI | `admin_panel/{index.html,styles.css,app.js}` |

---

*Questions? Open an issue on the repo — and screenshots for every screen live in `previews/`.*
