'use strict';

/* ════════════════════════════════════════════════════════════════
   DonghuaHub Admin — Mirror Link Manager
   Dependency-free. Two modes:
     • LIVE — talks to the DHS-Anime backend admin API (JWT)
     • DEMO — seeded sample data persisted to localStorage
   ════════════════════════════════════════════════════════════════ */

// ── Host catalogue ────────────────────────────────────────────────
const HOSTS = [
  { key: 'mega',     name: 'Mega',      color: '#f1485b', test: u => /mega\.(nz|io)/i.test(u) },
  { key: 'gdrive',   name: 'GDrive',    color: '#34a853', test: u => /drive\.google|docs\.google/i.test(u) },
  { key: 'terabox',  name: 'Terabox',   color: '#06a7ff', test: u => /terabox|1024tera|terashare|4funbox|mirrobox/i.test(u) },
  { key: 'telegram', name: 'Telegram',  color: '#229ed9', test: u => /(^|\.)t\.me|telegram\./i.test(u) },
  { key: 'mediafire',name: 'MediaFire', color: '#1299f3', test: u => /mediafire\./i.test(u) },
  { key: 'torrent',  name: 'Torrent',   color: '#c07f18', test: u => /^magnet:|\.torrent(\?|$)/i.test(u) },
];
const FALLBACK_HOST = { key: 'direct', name: 'Direct', color: '#6c63ff' };

const QUALITIES = ['4K', '1080p', '720p', '480p', '360p'];

// ── State ─────────────────────────────────────────────────────────
const state = {
  mode: 'demo',
  apiBase: 'http://localhost:5000/api',
  token: '',
  anime: [],
  episodes: [],
  folders: [],
  selectedAnime: null,
  search: '',
  editingEpisode: null,   // episode whose links are being edited
  draftLinks: [],         // working copy inside the editor
};

const $ = id => document.getElementById(id);
const LS_CFG = 'dhs_admin_cfg';
const LS_DEMO = 'dhs_admin_demo_v1';

// ── Helpers ───────────────────────────────────────────────────────
const uid = p => `${p}_${Math.random().toString(36).slice(2, 10)}`;

function detectHost(url) {
  const clean = (url || '').trim();
  return HOSTS.find(h => h.test(clean)) || FALLBACK_HOST;
}

function formatSize(bytes) {
  const b = Number(bytes) || 0;
  if (b <= 0) return '';
  if (b >= 1 << 30) return `${(b / 2 ** 30).toFixed(2)} GB`;
  if (b >= 1 << 20) return `${Math.round(b / 2 ** 20)} MB`;
  return `${Math.round(b / 2 ** 10)} KB`;
}

function parseSize(text) {
  const m = String(text || '').match(/(\d+(?:\.\d+)?)\s*(gb|mb|kb)/i);
  if (!m) return 0;
  const n = parseFloat(m[1]);
  const unit = m[2].toLowerCase();
  if (unit === 'gb') return Math.round(n * 2 ** 30);
  if (unit === 'mb') return Math.round(n * 2 ** 20);
  return Math.round(n * 2 ** 10);
}

let toastTimer = null;
function toast(message, type = '') {
  const el = $('toast');
  el.textContent = message;
  el.className = `toast ${type}`;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.add('hidden'), 3200);
}

// ── Bulk paste parser ─────────────────────────────────────────────
/**
 * Accepts one mirror link per line:
 *   https://mega.nz/file/xxx
 *   Mega HD | https://mega.nz/file/xxx | 1080p | 480 MB
 * Label, quality and size are auto-detected from any segment and are
 * all optional — a bare URL is enough.
 */
function parsePastedLinks(text) {
  const out = [];
  const lines = String(text || '').split(/\r?\n/);
  let mirrorCount = 0;

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line) continue;

    const segments = line.split('|').map(s => s.trim()).filter(Boolean);
    const url = segments.find(s => /^https?:\/\//i.test(s)) || '';

    if (!url) {
      // Whole-line bare URL or magnet link
      if (/^https?:\/\//i.test(line) || /^magnet:/i.test(line)) {
        segments.length = 0;
        segments.push(line);
      } else {
        continue; // not a usable line
      }
    }

    const resolvedUrl = url || segments[0];
    const rest = segments.filter(s => s !== resolvedUrl);

    // Quality / size from any leftover segment, the label is what remains
    let quality = '';
    let fileSize = 0;
    const labelParts = [];

    for (const seg of [...rest, ...(url ? [] : [])]) {
      const q = seg.match(/(2160p|4k|1080p|720p|480p|360p)/i);
      const s = seg.match(/(\d+(?:\.\d+)?)\s*(gb|mb|kb)/i);
      if (q && !quality) { quality = q[1].toUpperCase() === '4K' ? '4K' : q[1].toLowerCase(); continue; }
      if (s) { fileSize = parseSize(seg); continue; }
      labelParts.push(seg);
    }

    // Also sniff quality straight from the URL/filename (e.g. ..._720p.mp4)
    if (!quality) {
      const qInUrl = resolvedUrl.match(/(2160p|1080p|720p|480p|360p)/i);
      if (qInUrl) quality = qInUrl[1].toLowerCase();
    }

    const host = detectHost(resolvedUrl);
    mirrorCount += 1;

    out.push({
      _id: uid('link'),
      host: host.key,
      label: labelParts.join(' ') || `${host.name} Mirror ${mirrorCount}`,
      url: resolvedUrl,
      quality: quality || '720p',
      fileSize,
      language: 'Hindi',
      isActive: true,
    });
  }
  return out;
}

// ── Persistence (demo mode) ───────────────────────────────────────
function saveDemo() {
  localStorage.setItem(LS_DEMO, JSON.stringify({
    anime: state.anime,
    episodesByAnime: state.anime.reduce((acc, a) => {
      acc[a._id] = state.episodesByAnime[a._id] || [];
      return acc;
    }, {}),
  }));
}

function seedDemo() {
  const saved = localStorage.getItem(LS_DEMO);
  if (saved) {
    try {
      const data = JSON.parse(saved);
      state.anime = data.anime || [];
      state.episodesByAnime = data.episodesByAnime || {};
      return;
    } catch (e) { /* reseed below */ }
  }

  const a1 = 'demo-a1';
  const a2 = 'demo-a2';
  state.anime = [
    { _id: a1, title: 'Battle Through the Heavens', status: 'ongoing', totalEpisodes: 3 },
    { _id: a2, title: 'Soul Land 2: The Peerless Tang Sect', status: 'ongoing', totalEpisodes: 2 },
  ];
  state.episodesByAnime = {
    [a1]: [
      {
        _id: 'demo-e1', episodeNumber: 1, title: 'The Awakening', folder: 'f1',
        language: 'Hindi', isActive: true, downloadCount: 1240,
        downloadLinks: [
          { _id: uid('link'), host: 'mega', label: 'Mega HD', url: 'https://mega.nz/file/btth-e01-1080p', quality: '1080p', fileSize: 477626368, language: 'Hindi', isActive: true },
          { _id: uid('link'), host: 'gdrive', label: 'GDrive Mirror', url: 'https://drive.google.com/file/d/btth-e01-720p', quality: '720p', fileSize: 320864256, language: 'Hindi', isActive: true },
        ],
      },
      {
        _id: 'demo-e2', episodeNumber: 2, title: 'Flame Mantra', folder: 'f1',
        language: 'Hindi', isActive: true, downloadCount: 986,
        downloadLinks: [
          { _id: uid('link'), host: 'terabox', label: 'Terabox Fast', url: 'https://terabox.app/s/btth-e02-1080p', quality: '1080p', fileSize: 486539264, language: 'Hindi', isActive: true },
        ],
      },
      {
        _id: 'demo-e3', episodeNumber: 3, title: 'Episode 3', folder: 'f1',
        language: 'Hindi', isActive: true, downloadCount: 0, downloadLinks: [],
      },
    ],
    [a2]: [
      {
        _id: 'demo-e4', episodeNumber: 1, title: 'Spirit Master', folder: 'f1',
        language: 'Hindi', isActive: true, downloadCount: 2210,
        downloadLinks: [
          { _id: uid('link'), host: 'telegram', label: 'TG Channel', url: 'https://t.me/dhs_anime/sl2-e01-1080p', quality: '1080p', fileSize: 503316480, language: 'Hindi', isActive: true },
        ],
      },
      {
        _id: 'demo-e5', episodeNumber: 2, title: 'Shrek Academy', folder: 'f1',
        language: 'Hindi', isActive: true, downloadCount: 1875, downloadLinks: [],
      },
    ],
  };
  saveDemo();
}

// ── API layer ─────────────────────────────────────────────────────
async function apiFetch(path, options = {}) {
  const res = await fetch(`${state.apiBase}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${state.token}`,
      ...(options.headers || {}),
    },
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body.success === false) {
    throw new Error(body.message || `Request failed (${res.status})`);
  }
  return body.data || {};
}

const backend = {
  async listAnime() {
    if (state.mode === 'demo') return [...state.anime];
    const data = await apiFetch('/anime?limit=200');
    return data.anime || [];
  },

  async loadEpisodes(animeId) {
    if (state.mode === 'demo') {
      return {
        episodes: [...(state.episodesByAnime[animeId] || [])],
        folders: [{ _id: 'f1', name: 'Folder 1' }],
      };
    }
    const data = await apiFetch(`/admin/anime/${animeId}/episodes`);
    return { episodes: data.episodes || [], folders: data.folders || [] };
  },

  async saveLinks(episodeId, links) {
    if (state.mode === 'demo') {
      for (const list of Object.values(state.episodesByAnime)) {
        const ep = list.find(e => e._id === episodeId);
        if (ep) { ep.downloadLinks = links; break; }
      }
      saveDemo();
      return;
    }
    // New links carry temporary client-side ids — only keep real Mongo
    // ObjectIds for pre-existing links, let the DB mint the rest.
    const payload = links.map(l => {
      const { _id, ...rest } = l;
      return /^[0-9a-f]{24}$/i.test(_id || '') ? l : rest;
    });
    await apiFetch(`/admin/episodes/${episodeId}`, {
      method: 'PUT',
      body: JSON.stringify({ downloadLinks: payload }),
    });
  },

  async createEpisode(payload) {
    if (state.mode === 'demo') {
      const ep = { _id: uid('demo-e'), folder: 'f1', language: 'Hindi', isActive: true, downloadCount: 0, downloadLinks: [], ...payload };
      delete ep.folderId;
      (state.episodesByAnime[state.selectedAnime] =
        state.episodesByAnime[state.selectedAnime] || []).push(ep);
      const anime = state.anime.find(a => a._id === state.selectedAnime);
      if (anime) anime.totalEpisodes = (anime.totalEpisodes || 0) + 1;
      saveDemo();
      return ep;
    }
    const data = await apiFetch('/admin/episodes', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    return data.episode;
  },

  async createFolder(animeId) {
    if (state.mode === 'demo') return { _id: 'f1', name: 'Folder 1' };
    const data = await apiFetch('/admin/folders', {
      method: 'POST',
      body: JSON.stringify({ animeId, name: 'Folder 1', episodeRange: '1-500' }),
    });
    return data.folder;
  },

  async createAnime(payload) {
    if (state.mode === 'demo') {
      const anime = { _id: uid('demo-a'), totalEpisodes: 0, ...payload };
      state.anime.push(anime);
      saveDemo();
      return anime;
    }
    const data = await apiFetch('/admin/anime', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    return data.anime;
  },
};

// ── Rendering ─────────────────────────────────────────────────────
function hostChip(hostKey, quality) {
  const host = HOSTS.find(h => h.key === hostKey) || FALLBACK_HOST;
  return `<span class="host-chip" style="--hc:${host.color}">${host.name}${quality ? ` · ${quality}` : ''}</span>`;
}

function renderAnimeList() {
  const query = state.search.toLowerCase();
  const list = $('animeList');
  const items = state.anime.filter(a => (a.title || '').toLowerCase().includes(query));

  if (items.length === 0) {
    list.innerHTML = `<p class="muted tiny center" style="padding:20px">No anime found</p>`;
    return;
  }

  list.innerHTML = items.map(a => `
    <div class="anime-item ${a._id === state.selectedAnime ? 'active' : ''}" data-id="${a._id}">
      <div class="anime-poster">🎬</div>
      <div class="anime-item-info">
        <strong>${escapeHtml(a.title || 'Untitled')}</strong>
        <span>${a.totalEpisodes ?? 0} eps · ${a.status || 'ongoing'}</span>
      </div>
    </div>
  `).join('');

  list.querySelectorAll('.anime-item').forEach(el =>
    el.addEventListener('click', () => selectAnime(el.dataset.id)));
}

function renderStats() {
  const totalLinks = state.episodes.reduce((n, e) => n + (e.downloadLinks || []).length, 0);
  const hosts = new Set(state.episodes.flatMap(e => (e.downloadLinks || []).map(l => l.host)));
  $('statEpisodes').textContent = state.episodes.length;
  $('statLinks').textContent = totalLinks;
  $('statHosts').textContent = hosts.size;
}

function renderEpisodes() {
  const rows = $('episodeRows');

  if (state.episodes.length === 0) {
    rows.innerHTML = `<tr><td colspan="5" class="placeholder-cell">📭 No episodes yet — click “＋ Add Episode” (users get notified automatically)</td></tr>`;
  } else {
    rows.innerHTML = state.episodes.map(ep => {
      const links = (ep.downloadLinks || []).filter(l => l.isActive !== false);
      const chips = links.length
        ? `<div class="host-chips">${links.map(l => hostChip(l.host, l.quality)).join('')}</div>`
        : `<span class="no-links">no mirrors yet</span>`;
      return `
        <tr>
          <td><span class="ep-num">${ep.episodeNumber}</span></td>
          <td>${escapeHtml(ep.title || `Episode ${ep.episodeNumber}`)}</td>
          <td>${chips}</td>
          <td><span class="dl-count">⬇ ${ep.downloadCount || 0}</span></td>
          <td style="text-align:right">
            <button class="btn btn-sm btn-primary" data-edit="${ep._id}">🔗 Manage Links</button>
          </td>
        </tr>`;
    }).join('');
  }

  rows.querySelectorAll('[data-edit]').forEach(btn =>
    btn.addEventListener('click', () => openEditor(btn.dataset.edit)));
  renderStats();
}

function renderLinkList() {
  const list = $('linkList');

  if (state.draftLinks.length === 0) {
    list.innerHTML = `<p class="muted tiny center" style="padding:14px">No links — paste some above and hit “Detect &amp; Add Links”.</p>`;
    return;
  }

  list.innerHTML = state.draftLinks.map((link, i) => {
    const host = HOSTS.find(h => h.key === link.host) || FALLBACK_HOST;
    const size = formatSize(link.fileSize);
    return `
      <div class="link-row ${link.isActive === false ? 'link-row-off' : ''}">
        <span class="host-chip" style="--hc:${host.color}">${host.name}</span>
        <div class="link-meta">
          <strong>${escapeHtml(link.label || host.name)}</strong>
          <span class="link-sub">${link.quality || '—'}${size ? ` · ${size}` : ''} · ${escapeHtml(link.language || 'Hindi')}</span>
          <span class="link-url">${escapeHtml(link.url || '')}</span>
        </div>
        <div class="link-actions">
          <label class="switch" title="Visible in app">
            <input type="checkbox" data-active="${i}" ${link.isActive !== false ? 'checked' : ''} />
            <span class="slider"></span>
          </label>
          <button class="btn btn-sm btn-danger" data-del="${i}" title="Remove">🗑</button>
        </div>
      </div>`;
  }).join('');

  list.querySelectorAll('[data-active]').forEach(el =>
    el.addEventListener('change', () => {
      state.draftLinks[Number(el.dataset.active)].isActive = el.checked;
      renderLinkList();
    }));
  list.querySelectorAll('[data-del]').forEach(el =>
    el.addEventListener('click', () => {
      state.draftLinks.splice(Number(el.dataset.del), 1);
      renderLinkList();
    }));
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

// ── Flows ─────────────────────────────────────────────────────────
async function refreshAnimeList() {
  try {
    state.anime = await backend.listAnime();
  } catch (err) {
    toast(`Failed to load anime: ${err.message}`, 'error');
  }
  renderAnimeList();
}

async function selectAnime(id) {
  state.selectedAnime = id;
  const anime = state.anime.find(a => a._id === id);

  $('currentTitle').textContent = anime?.title || 'Anime';
  $('currentSub').textContent = `${anime?.totalEpisodes ?? 0} episodes · ${anime?.status || ''}`;
  $('addEpisodeBtn').disabled = false;
  renderAnimeList();

  try {
    const { episodes, folders } = await backend.loadEpisodes(id);
    state.episodes = episodes;
    state.folders = folders;
  } catch (err) {
    toast(`Failed to load episodes: ${err.message}`, 'error');
    state.episodes = [];
    state.folders = [];
  }
  renderEpisodes();
}

function openEditor(episodeId) {
  const ep = state.episodes.find(e => e._id === episodeId);
  if (!ep) return;
  state.editingEpisode = ep;
  state.draftLinks = (ep.downloadLinks || []).map(l => ({ ...l }));
  $('editorTitle').textContent = `Mirror Links — Episode ${ep.episodeNumber}`;
  $('pasteArea').value = '';
  renderLinkList();
  openModal('editorModal');
}

async function saveLinks() {
  const ep = state.editingEpisode;
  if (!ep) return;
  try {
    await backend.saveLinks(ep._id, state.draftLinks);
    ep.downloadLinks = [...state.draftLinks];
    closeModals();
    renderEpisodes();
    toast(`✅ Episode ${ep.episodeNumber} links saved`, 'success');
  } catch (err) {
    toast(`Save failed: ${err.message}`, 'error');
  }
}

async function createEpisode() {
  const animeId = state.selectedAnime;
  const number = Number($('epNumberInput').value);
  if (!animeId || !number) {
    toast('Episode number is required', 'error');
    return;
  }

  try {
    let folderId = state.folders[0]?._id;
    if (state.mode !== 'demo' && !folderId) {
      const folder = await backend.createFolder(animeId);
      folderId = folder._id;
      state.folders.push(folder);
    }

    await backend.createEpisode({
      animeId,
      folderId: folderId || 'f1',
      episodeNumber: number,
      title: $('epTitleInput').value.trim() || `Episode ${number}`,
    });

    closeModals();
    toast(`🔔 Episode ${number} added — all users have been notified!`, 'bell');
    await selectAnime(animeId);
  } catch (err) {
    toast(`Create failed: ${err.message}`, 'error');
  }
}

async function createAnime() {
  const title = $('animeTitleInput').value.trim();
  if (!title) {
    toast('Title is required', 'error');
    return;
  }
  try {
    await backend.createAnime({ title, status: $('animeStatusSelect').value });
    closeModals();
    $('animeTitleInput').value = '';
    toast('🔔 Donghua added — notification broadcast to all users!', 'bell');
    await refreshAnimeList();
  } catch (err) {
    toast(`Create failed: ${err.message}`, 'error');
  }
}

// ── Modal plumbing ────────────────────────────────────────────────
function openModal(id) { $(id).classList.remove('hidden'); }
function closeModals() {
  document.querySelectorAll('.modal-backdrop').forEach(m => m.classList.add('hidden'));
}

// ── Bootstrap ─────────────────────────────────────────────────────
function enterApp(mode) {
  state.mode = mode;
  $('loginScreen').classList.add('hidden');
  $('appShell').classList.remove('hidden');
  const badge = $('modeBadge');
  badge.textContent = mode === 'demo' ? 'DEMO' : 'LIVE';
  badge.className = `badge ${mode === 'demo' ? 'badge-demo' : 'badge-live'}`;
  if (mode === 'demo') seedDemo();
  refreshAnimeList();
}

function bindEvents() {
  $('connectBtn').addEventListener('click', async () => {
    state.apiBase = $('apiBaseInput').value.trim().replace(/\/+$/, '');
    state.token = $('tokenInput').value.trim();
    $('loginError').classList.add('hidden');

    if (!state.token) {
      $('loginError').textContent = 'Paste your admin JWT first — or try the demo.';
      $('loginError').classList.remove('hidden');
      return;
    }
    try {
      state.mode = 'live';
      const probe = state.anime.length ? [...state.anime] : await backend.listAnime();
      state.anime = probe;
      localStorage.setItem(LS_CFG, JSON.stringify({ apiBase: state.apiBase, token: state.token }));
      enterApp('live');
    } catch (err) {
      $('loginError').textContent = `Could not connect: ${err.message}`;
      $('loginError').classList.remove('hidden');
    }
  });

  $('demoBtn').addEventListener('click', () => enterApp('demo'));

  $('logoutBtn').addEventListener('click', () => {
    localStorage.removeItem(LS_CFG);
    location.reload();
  });

  $('refreshBtn').addEventListener('click', async () => {
    await refreshAnimeList();
    if (state.selectedAnime) await selectAnime(state.selectedAnime);
    toast('Refreshed');
  });

  $('animeSearch').addEventListener('input', e => {
    state.search = e.target.value;
    renderAnimeList();
  });

  $('parseBtn').addEventListener('click', () => {
    const parsed = parsePastedLinks($('pasteArea').value);
    if (parsed.length === 0) {
      toast('No valid links detected — make sure each line has a URL', 'error');
      return;
    }
    state.draftLinks.push(...parsed);
    $('pasteArea').value = '';
    renderLinkList();
    toast(`🔗 ${parsed.length} link${parsed.length > 1 ? 's' : ''} detected & added`);
  });

  $('clearPasteBtn').addEventListener('click', () => { $('pasteArea').value = ''; });
  $('saveLinksBtn').addEventListener('click', saveLinks);

  $('addEpisodeBtn').addEventListener('click', () => {
    if (!state.selectedAnime) return;
    const next = (state.episodes.reduce((max, e) => Math.max(max, e.episodeNumber || 0), 0) || 0) + 1;
    $('epNumberInput').value = next;
    $('epTitleInput').value = '';

    const select = $('folderSelect');
    select.innerHTML = state.folders.length
      ? state.folders.map(f => `<option value="${f._id}">${escapeHtml(f.name || 'Folder')}</option>`).join('')
      : `<option value="f1">Folder 1 (new)</option>`;
    openModal('episodeModal');
  });

  $('createEpisodeBtn').addEventListener('click', createEpisode);
  $('createAnimeBtn').addEventListener('click', createAnime);
  $('newAnimeBtn').addEventListener('click', () => openModal('animeModal'));

  document.querySelectorAll('[data-close]').forEach(btn =>
    btn.addEventListener('click', closeModals));
  document.querySelectorAll('.modal-backdrop').forEach(backdrop =>
    backdrop.addEventListener('click', e => {
      if (e.target === backdrop) closeModals();
    }));
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeModals();
  });
}

(function init() {
  bindEvents();
  const cfg = localStorage.getItem(LS_CFG);
  if (cfg) {
    try {
      const { apiBase, token } = JSON.parse(cfg);
      if (apiBase) $('apiBaseInput').value = apiBase;
      if (token) $('tokenInput').value = token;
    } catch (e) { /* ignore */ }
  }
});
