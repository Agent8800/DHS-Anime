# DonghuaHub Admin — Mirror Link Manager

A dependency-free web panel for adding **third-party mirror links** (Mega,
GDrive, Terabox, Telegram, MediaFire, Torrent, Direct) to episodes. Links
appear instantly in the app's download sheet, and **every newly added
episode or donghua broadcasts a notification to all users** (push when the
user granted permission, otherwise the in-app bell icon only).

## Run it

No build step — it is plain HTML/CSS/JS:

```bash
cd admin_panel
python3 -m http.server 8080   # or any static server / VS Code Live Server
# open http://localhost:8080
```

## Modes

| Mode | How | Data |
|------|-----|------|
| **Demo** | Click "✨ Try Demo Mode" | Seeded sample data, persisted to `localStorage` — perfect for previewing the UX with no backend. |
| **Live** | API base URL (e.g. `http://localhost:5000/api`) + an **admin JWT** | Talks to the real backend. The token is stored in `localStorage`. |

Get an admin JWT by signing in through the app (Clerk Google) with an
account whose `role` is `admin` in MongoDB, then copy the token returned by
`POST /api/auth/sync`.

## Backend endpoints used

| Action | Endpoint |
|--------|----------|
| List anime | `GET /api/anime?limit=200` |
| Episodes + folders (with links) | `GET /api/admin/anime/:animeId/episodes` |
| Save mirror links | `PUT /api/admin/episodes/:id` (`{ downloadLinks }`) |
| Add episode (🔔 notifies users) | `POST /api/admin/episodes` |
| Add donghua (🔔 notifies users) | `POST /api/admin/anime` |
| Auto-create first folder | `POST /api/admin/folders` |

## Bulk paste format

One link per line; everything except the URL is optional:

```
https://mega.nz/file/xyz
Mega HD | https://mega.nz/file/xyz | 1080p | 480 MB
GDrive | https://drive.google.com/file/d/abc
Telegram | https://t.me/c/1234/56 | 720p
magnet:?xt=urn:btih:...
```

- **Host** is auto-detected from the URL (Mega, GDrive, Terabox, Telegram,
  MediaFire, Torrent, else "Direct").
- **Quality** is picked up from any segment (`1080p`, `720p`, …) or from the
  filename inside the URL; defaults to `720p`.
- **Size** accepts `480 MB` / `1.2 GB` style values.
- Rows can then be relabelled, toggled (visible/hidden in the app) or deleted
  before saving.
