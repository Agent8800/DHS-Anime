# DonghuaHub

Modern Android & iOS application for streaming and downloading Donghua (Chinese Animation). All episodes are uploaded manually by the administrator.

## 🎬 Features

### For Users
- **Home Screen** - Continue Watching, Recently Updated, Trending, Popular, Latest Episodes, Genres, Top Rated, Random Picks, Banner Slider, Announcements
- **Search** - Instant search with filters (Genre, Year, Status, Studio, Language, Sort)
- **Anime Details** - Banner, Poster, Description, Genres, Studios, Rating, Episode List, Recommendations, Characters, Related Series, Trailer
- **Video Player** - Landscape/Portrait, Speed Control, Subtitle Selection, Skip Intro, Next/Previous Episode, Brightness/Volume/Seek Gestures, Lock Screen, Quality Selector, Fullscreen, Auto Resume
- **Download System** - Premium: Direct Download | Free: Solve Shortener → Unlock for 4 Hours
- **Streaming** - Same as download logic
- **Bookmarks** - Unlimited, Cloud Sync
- **Watch History** - Auto Save, Resume from last position
- **Settings** - Dark Mode, AMOLED Mode, Theme Colour, Subtitle Settings, Video Quality, Download Folder, Cache Cleaner

### For Admin
- **Dashboard** - Total Users, Premium Users, Anime, Episodes, Today's Views, Downloads, Revenue, Charts
- **Upload Anime** - Fetch metadata from AniList API (auto-fills everything except episodes)
- **Upload Episode** - Anime, Folder, Episode, Video, Thumbnail, Subtitle, Language, Quality
- **Folder Manager** - Create/Rename/Delete Folders, Move Episodes, Reorder
- **Premium Manager** - Grant/Expire/Lifetime/Monthly Premium
- **Notifications** - Push Notifications for New Episode, Maintenance, Offers, Announcements
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
│   │   ├── routes/        # API routes
│   │   ├── middleware/     # Auth, Clerk webhook, Shortner
│   │   ├── services/      # Backup service
│   │   └── utils/         # Signed URL utility
│   ├── scripts/           # Backup, Restore, Seed scripts
│   └── uploads/           # Local uploads (dev only)
│
├── flutter_app/           # Flutter Frontend
│   ├── lib/
│   │   ├── config/        # API config, Router
│   │   ├── core/          # Theme, Constants, Utils
│   │   ├── features/      # Feature modules
│   │   │   ├── auth/      # Authentication
│   │   │   ├── home/      # Home screen
│   │   │   ├── anime/     # Anime details
│   │   │   ├── episode/   # Episode list
│   │   │   ├── player/    # Video player
│   │   │   ├── search/    # Search
│   │   │   ├── download/  # Downloads
│   │   │   ├── bookmark/  # Bookmarks
│   │   │   ├── settings/  # Settings
│   │   │   └── admin/     # Admin panel
│   │   └── shared/        # Shared widgets
│   └── assets/            # Images, Animations, Fonts
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- MongoDB 6+
- Flutter 3.2+
- Clerk Account (for authentication)
- Cloudflare R2 / Wasabi / Bunny Storage (for episodes)

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

3. Run the app:
```bash
flutter run
```

## 📊 Database Collections

- **users** - User profiles, preferences, devices
- **anime** - Anime metadata (from AniList/MAL)
- **episodes** - Episode data with video sources
- **folders** - Folder structure for episodes
- **downloads** - Download tracking
- **watch_history** - Watch progress
- **bookmarks** - User bookmarks
- **premium** - Premium subscription records
- **shortner_sessions** - Shortener verification sessions
- **app_settings** - App configuration
- **announcements** - Admin announcements
- **reports** - User reports

## 🔐 Security

- Signed URLs for video access
- Encrypted links
- Token authentication (JWT + Clerk)
- Rate limiting
- No direct video URL exposure
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
