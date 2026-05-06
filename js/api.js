// MangaVerse — API Module (MangaDex con soporte ampliado de idiomas)
const API_BASE = 'https://api.mangadex.org';
const UPLOADS = 'https://uploads.mangadex.org';

const MangaAPI = {

    /** Obtiene mangas populares o hace búsqueda por título */
    async search(query = '', limit = 24, offset = 0) {
        try {
            const url = new URL(`${API_BASE}/manga`);
            if (query) url.searchParams.set('title', query);
            url.searchParams.set('limit', limit);
            url.searchParams.set('offset', offset);
            url.searchParams.append('includes[]', 'cover_art');
            url.searchParams.append('includes[]', 'author');
            // Ordenar por popularidad descendente
            url.searchParams.set('order[followedCount]', 'desc');
            // Permitir todos los ratings
            ['safe', 'suggestive', 'erotica'].forEach(r => url.searchParams.append('contentRating[]', r));

            const res = await fetch(url);
            if (!res.ok) throw new Error('Search failed: ' + res.status);
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
            const res = await fetch(url);
            if (!res.ok) throw new Error('getManga failed');
            const data = await res.json();
            return data.data;
        } catch (e) {
            console.error('[API] getManga:', e);
            return null;
        }
    },

    /**
     * Obtiene capítulos de un manga.
     * Prioriza español, luego inglés, mostrando todos los disponibles.
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
            // 'all' = sin filtro de idioma

            const res = await fetch(url);
            if (!res.ok) throw new Error('getChapters failed');
            const data = await res.json();
            return data.data || [];
        } catch (e) {
            console.error('[API] getChapters:', e);
            return [];
        }
    },

    /** URLs de imágenes de un capítulo vía @home */
    async getChapterImages(chapterId) {
        try {
            const res = await fetch(`${API_BASE}/at-home/server/${chapterId}`);
            if (!res.ok) throw new Error('getChapterImages failed');
            const data = await res.json();
            const { chapter } = data;

            // Preferir data-saver (más ligero)
            const pages = chapter.dataSaver || chapter.data;
            const quality = chapter.dataSaver ? 'data-saver' : 'data';

            // Usar el CDN oficial de MangaDex que permite cross-origin
            const officialBase = 'https://uploads.mangadex.org';
            return pages.map(p => `${officialBase}/${quality}/${chapter.hash}/${p}`);
        } catch (e) {
            console.error('[API] getChapterImages:', e);
            return [];
        }
    },

    /** URL de portada a partir del objeto manga */
    getCoverUrl(manga, size = 256) {
        const coverRel = manga.relationships?.find(r => r.type === 'cover_art');
        const fileName = coverRel?.attributes?.fileName;
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
