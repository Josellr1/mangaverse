// MangaVerse — API Module (MangaDex · Multi-Proxy Fallback System)
const API_BASE = 'https://api.mangadex.org';
const UPLOADS   = 'https://uploads.mangadex.org';

// ── PROXY POOL ──────────────────────────────────────────────────────────────
// Se prueban en orden hasta que uno funciona. El índice exitoso se guarda
// en sessionStorage para no repetir la detección en cada petición.
// Todos estos proxies tienen soporte para content-type JSON.
const PROXIES = [
  (url) => `https://api.allorigins.win/raw?url=${encodeURIComponent(url)}`,
  (url) => `https://corsproxy.io/?${encodeURIComponent(url)}`,
  (url) => `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(url)}`,
  (url) => `https://thingproxy.freeboard.io/fetch/${url}`,
  (url) => `https://cors.sh/?${encodeURIComponent(url)}`,
];

let _proxyIdx = (() => {
  const saved = sessionStorage.getItem('mv_proxy_idx');
  return saved !== null ? parseInt(saved) : 0;
})();

function proxyUrl(url) {
  return PROXIES[_proxyIdx % PROXIES.length](url);
}

/** Fetch con proxy con fallback automático entre proxies y reintentos */
async function fetchProxy(url, maxRetries = PROXIES.length + 1) {
  let lastErr;
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const idx = (_proxyIdx + attempt) % PROXIES.length;
    const proxied = PROXIES[idx](url);
    try {
      const res = await fetchWithTimeout(proxied, 10000);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      // Si éxito, fijamos este proxy para las próximas peticiones
      if (attempt > 0) {
        _proxyIdx = idx;
        sessionStorage.setItem('mv_proxy_idx', idx);
        console.info(`[API] Proxy #${idx} funciona, lo usaremos de ahora en adelante.`);
      }
      return res;
    } catch (e) {
      lastErr = e;
      console.warn(`[API] Proxy #${idx} falló (${e.message}), probando siguiente...`);
    }
  }
  throw lastErr || new Error('Todos los proxies fallaron');
}

/** fetch con timeout (AbortController) */
function fetchWithTimeout(url, ms = 12000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), ms);
  return fetch(url, { signal: ctrl.signal }).finally(() => clearTimeout(timer));
}

// ── API OBJECT ──────────────────────────────────────────────────────────────
const MangaAPI = {

  /** Obtiene mangas populares o hace búsqueda por título */
  async search(query = '', limit = 24, offset = 0, lang = '') {
    try {
      const url = new URL(`${API_BASE}/manga`);
      if (query) url.searchParams.set('title', query);
      url.searchParams.set('limit', limit);
      url.searchParams.set('offset', offset);
      url.searchParams.append('includes[]', 'cover_art');
      url.searchParams.append('includes[]', 'author');
      url.searchParams.set('order[followedCount]', 'desc');
      ['safe', 'suggestive'].forEach(r => url.searchParams.append('contentRating[]', r));

      if (lang === 'es') {
        url.searchParams.append('availableTranslatedLanguage[]', 'es');
        url.searchParams.append('availableTranslatedLanguage[]', 'es-la');
      } else if (lang === 'en') {
        url.searchParams.append('availableTranslatedLanguage[]', 'en');
      }

      const res = await fetchProxy(url.toString());
      const data = await res.json();
      return data.data || [];
    } catch (e) {
      console.error('[API] search:', e);
      return [];
    }
  },

  /** Detalles de un manga por ID */
  async getManga(id) {
    try {
      const url = `${API_BASE}/manga/${id}?includes[]=cover_art&includes[]=author&includes[]=artist`;
      const res = await fetchProxy(url);
      const data = await res.json();
      return data.data;
    } catch (e) {
      console.error('[API] getManga:', e);
      return null;
    }
  },

  /**
   * Capítulos de un manga.
   * lang: 'es' | 'en' | 'all'
   */
  async getChapters(mangaId, lang = 'es', limit = 120, offset = 0) {
    try {
      const url = new URL(`${API_BASE}/manga/${mangaId}/feed`);
      url.searchParams.set('limit', limit);
      url.searchParams.set('offset', offset);
      url.searchParams.set('order[chapter]', 'desc');
      url.searchParams.append('includes[]', 'scanlation_group');

      if (lang === 'es') {
        url.searchParams.append('translatedLanguage[]', 'es');
        url.searchParams.append('translatedLanguage[]', 'es-la');
      } else if (lang === 'en') {
        url.searchParams.append('translatedLanguage[]', 'en');
      }

      const res = await fetchProxy(url.toString());
      const data = await res.json();
      return data.data || [];
    } catch (e) {
      console.error('[API] getChapters:', e);
      return [];
    }
  },

  /**
   * URLs de páginas de un capítulo vía @home.
   * SIEMPRE usa proxy (el endpoint at-home bloquea CORS desde GitHub Pages).
   * Las imágenes finales se sirven desde uploads.mangadex.org (CORS abierto).
   */
  async getChapterImages(chapterId) {
    try {
      const atHomeUrl = `${API_BASE}/at-home/server/${chapterId}`;
      const res = await fetchProxy(atHomeUrl);
      const data = await res.json();

      if (!data?.chapter) throw new Error('Respuesta at-home inválida');

      const chapter = data.chapter;
      const pages   = chapter.dataSaver || chapter.data || [];
      const quality = chapter.dataSaver ? 'data-saver' : 'data';

      const baseUrl = data.baseUrl || UPLOADS;

      // Usar la baseUrl proporcionada por el nodo (CORS no es problema para etiquetas <img>)
      return pages.map(p => `${baseUrl}/${quality}/${chapter.hash}/${p}`);
    } catch (e) {
      console.error('[API] getChapterImages:', e);
      return [];
    }
  },

  /** URL de portada */
  getCoverUrl(manga, size = 256) {
    const coverRel = manga.relationships?.find(r => r.type === 'cover_art');
    const fileName  = coverRel?.attributes?.fileName;
    if (!fileName) return `https://placehold.co/200x300/1a1d2e/8B5CF6?text=Sin+Portada`;
    return `${UPLOADS}/covers/${manga.id}/${fileName}.${size}.jpg`;
  },

  /** Título en español, inglés o el primero disponible */
  getTitle(manga) {
    const t = manga.attributes?.title || {};
    return t['es'] || t['es-la'] || t['en'] || Object.values(t)[0] || 'Sin título';
  },

  /** Descripción */
  getDescription(manga) {
    const d = manga.attributes?.description || {};
    return d['es'] || d['es-la'] || d['en'] || Object.values(d)[0] || 'Sin descripción disponible.';
  },

  /** Nombre del autor */
  getAuthor(manga) {
    const authorRel = manga.relationships?.find(r => r.type === 'author');
    return authorRel?.attributes?.name || 'Desconocido';
  }
};

// Alias global para compatibilidad con ui.js
const ComickAPI = MangaAPI;
