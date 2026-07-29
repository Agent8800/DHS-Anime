# DonghuaHub

Modern Android & iOS application for **downloading** and watching Donghua (Chinese Animation) **offline**. All episodes and download links are uploaded manually by the administrator.

## 🎬 Features

### For Users
- **Home Screen** - Continue Watching, Recently Updated, Trending, Popular, Latest Episodes, Genres, Top Rated, Random Picks, Banner Slider, Announcements — with a **floating glass header**
- **Download-First Episodes** - Every episode is downloaded from **third-party mirror links** (Mega, GDrive, Terabox, Telegram, Direct). In-app streaming has been removed by design.
- **Download Location Settings** - Choose where files go in **Settings → Downloads → Download Location**. Default: a `DHS Anime` folder on internal storage (`/storage/emulated/0/DHS Anime`), created automatically.
- **Built-in Offline Player** - Downloaded episodes play in the app's own player: Landscape/Portrait, skip intro, brightness/volume/seek gestures, lock screen, auto position tracking.
- **Notifications** - A bell icon in the header shows every **new episode** and **new donghua** announcement. Users who granted the notification permission also receive an FCM push; users who denied it still see everything in the in-app feed (bell icon only).
- **Search** - Instant search with filters (Genre, Year, Status, Studio, Language, Sort)
- **Anime Details** - Banner, Poster, Description, Genres, Studios, Rating, Episode List, Recommendations, Characters, Related Series, Trailer
- **Download System** - Premium: Direct links | Free: Solve Shortener → Unlock for 4 Hours
- **Bookmarks** - Unlimited, Cloud Sync
- **Watch History** - Auto Save, Resume from last position
- **Settings** - Dark Mode, AMOLED Mode, Theme Colour, Preferred Quality/Language, Download Location, Storage Permission, Cache Cleaner

### Auth
- **Clerk + Google only** - Sign in and sign up happen with a single "Continue with Google" button. Email/password signup has been removed (enable *only* the Google provider in your Clerk dashboard).

### For Admin
- **Dashboard** - Total Users, Premium Users, Anime, Episodes, Today's Views, Downloads, Revenue, Charts
- **Upload Anime** - Fetch metadata from AniList API (auto-fills everything except episodes). Every new anime automatically notifies all users.
- **Upload Episode** - Anime, Folder, Episode, Video, Thumbnail, Subtitle, Language, Quality, **Download Links** (multiple third-party mirrors per episode). Every new episode automatically notifies all users.
- **Folder Manager** - Create/Rename/Delete Folders, Move Episodes, Reorder
- **Premium Manager** - Grant/Expire/Lifetime/Monthly Premium
- **Notifications** - Broadcasts for New Episode / New Donghua (automatic), Maintenance, Offers, Announcements
- **Reports** - View and manage user reports
- **Backup & Restore** - Export/Import all MongoDB data to JSON

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Riverpod** - State Management
- **Go Router** - Navigation
- **Material 3** - UI Design
- **Cached Network Image** - Image Caching
- **Better Player** - Video Player
- **Dio** - HTTP Client
- **Hive** - Offline Cache

### Backend (Node.js)
- **Express.js** - API Server
- **MongoDB + Mongoose** - Database
- **JWT** - Authentication
- **Clerk** - Authentication Provider
- **Cloudflare R2 / Wasabi / Bunny Storage** - Episode Storage
- **FFmpeg** - Thumbnail Generation
- **Socket.IO** - Real-time Features

## 📁 Project Structure

```
DHS-Anime/
├── backend/               # Node.js Backend
│   ├── src/
│   │   ├── config/        # Database configuration
│   │   ├── controllers/   # Route handlers
│   │   ├── models/        # Mongoose models
│   │   ├── routes/        # API routes (incl. /api/notifications)
│   │   ├── middleware/     # Auth, Clerk webhook, Shortner
│   │   ├── services/      # Backup, Notification, Push (FCM) services
│   │   └── utils/         # Signed URL utility
│   ├── scripts/           # Backup, Restore, Seed scripts
│   └── uploads/           # Local uploads (dev only)
│
├── flutter_app/           # Flutter Frontend
│   ├── android/           # Android manifest + setup notes (storage, FCM, Clerk OAuth)
│   ├── lib/
│   │   ├── config/        # API config, Router
│   │   ├── core/          # Theme, Constants, Utils
│   │   ├── features/      # Feature modules
│   │   │   ├── auth/      # Clerk Google sign-in (no email/password)
│   │   │   ├── home/      # Home screen + floating header
│   │   │   ├── anime/     # Anime details
│   │   │   ├── episode/   # Episode list → download links
│   │   │   ├── player/    # Built-in offline player
│   │   │   ├── notification/ # Bell feed + FCM registration
│   │   │   ├── search/    # Search
│   │   │   ├── download/  # Downloads (location, records)
│   │   │   ├── bookmark/  # Bookmarks
│   │   │   ├── settings/  # Settings
│   │   │   └── admin/     # Admin panel
│   │   └── shared/        # Shared widgets
│   └── assets/            # Images, Animations, Fonts
│
├── admin_panel/           # Mirror Link Manager — dependency-free web panel
│                          # for pasting third-party episode download links
│                          # (bulk paste with host auto-detect, demo + live modes)
├── previews/              # UI design previews (admin panel + app screens)
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- MongoDB 6+
- Flutter 3.2+
- Clerk Account (Google provider enabled, Email/Password disabled)
- Firebase project (optional — for push notifications)
- Third-party mirrors for episodes (Mega, GDrive, Terabox, Telegram, …) —
  episode files are not hosted by or streamed through this backend.

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Update `.env` with your credentials

5. Seed the database:
```bash
npm run seed
```

6. Start the server:
```bash
npm run dev
```

### Flutter Setup

1. Navigate to flutter_app directory:
```bash
cd flutter_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Provide your Clerk publishable key (Google-only app):
```bash
flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_xxxx
```
(or set `AppConstants.clerkPublishableKey` in `lib/core/constants/app_constants.dart`)

4. Run the app:
```bash
flutter run
```

### Android notes
- Downloads write to the public `DHS Anime` folder by default — on
  Android 11+ the app requests "All files access" (`MANAGE_EXTERNAL_STORAGE`);
  below that, standard storage permission. Users who deny it transparently
  fall back to the app-private folder.
- Declare in `android/app/src/main/AndroidManifest.xml`:
  `WRITE_EXTERNAL_STORAGE` (maxSdk 29), `MANAGE_EXTERNAL_STORAGE`,
  `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, and
  `android:requestLegacyExternalStorage="true"` (targetSdk 29).
- Firebase push requires `google-services.json` in `android/app/` and the
  service account JSON on the backend (`FIREBASE_SERVICE_ACCOUNT_JSON` or
  `FCM_SERVICE_ACCOUNT_PATH`). Without it, notifications still appear in
  the in-app bell feed — just no system push.

## 📊 Database Collections

- **users** - User profiles, preferences, devices
- **anime** - Anime metadata (from AniList/MAL)
- **episodes** - Episode data with third-party download links
- **folders** - Folder structure for episodes
- **notifications** - Personal + broadcast notifications (new episode, new donghua, announcements)
- **downloads** - Download tracking
- **watch_history** - Watch progress
- **bookmarks** - User bookmarks
- **premium** - Premium subscription records
- **shortner_sessions** - Shortener verification sessions
- **app_settings** - App configuration
- **announcements** - Admin announcements
- **reports** - User reports

## 🔐 Security

- Token authentication (JWT + Clerk, Google-only)
- Download links gated by shortener verification for free users
- Rate limiting
- No video files hosted on the backend — episodes download from third-party mirrors
- Device management

## 📱 UI Design

- Modern Glassmorphism
- Floating Cards
- Material 3
- Rounded Corners
- Gradient Accents
- Dynamic Colour
- Smooth Animations
- Lottie Animations
- Hero Transitions
- Shimmer/Skeleton Loading
- Parallax Banner
- Floating Bottom Navigation

## 📄 License

This project is proprietary. All rights reserved.
