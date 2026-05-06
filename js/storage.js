// MangaVerse — Storage Module (localStorage)
const Storage = (() => {
    const FAVS_KEY   = 'mv_favorites';
    const HIST_KEY   = 'mv_history';
    const MAX_HIST   = 100;

    // ─── HELPERS ────────────────────────────────────────────────
    const _get = (key) => {
        try { return JSON.parse(localStorage.getItem(key)) || []; }
        catch { return []; }
    };
    const _set = (key, val) => localStorage.setItem(key, JSON.stringify(val));

    // ─── FAVORITES ──────────────────────────────────────────────
    const getFavorites = () => _get(FAVS_KEY);

    const isFavorite = (id) => getFavorites().some(m => m.id === id);

    const toggleFavorite = (manga) => {
        const list = getFavorites();
        const idx  = list.findIndex(m => m.id === manga.id);
        if (idx >= 0) {
            list.splice(idx, 1);
        } else {
            // Store a minimal snapshot so we can re-render the card
            list.push({
                id:       manga.id,
                title:    MangaAPI.getTitle(manga),
                coverUrl: MangaAPI.getCoverUrl(manga, 256),
                author:   MangaAPI.getAuthor(manga),
                status:   manga.attributes?.status || '',
                tags:     (manga.attributes?.tags || []).slice(0, 2)
                             .map(t => t.attributes?.name?.en || '').filter(Boolean),
            });
        }
        _set(FAVS_KEY, list);
        return !isFavorite(manga.id); // returns new state
    };

    const removeFavorite = (id) => {
        const list = getFavorites().filter(m => m.id !== id);
        _set(FAVS_KEY, list);
    };

    const clearFavorites = () => localStorage.removeItem(FAVS_KEY);

    // ─── HISTORY ────────────────────────────────────────────────
    const getHistory = () => _get(HIST_KEY);

    const addHistory = ({ mangaId, mangaTitle, coverUrl, chapterId, chapterTitle }) => {
        const list = getHistory().filter(e => e.chapterId !== chapterId); // remove dupe
        list.unshift({ mangaId, mangaTitle, coverUrl, chapterId, chapterTitle, readAt: Date.now() });
        _set(HIST_KEY, list.slice(0, MAX_HIST));
    };

    const clearHistory = () => localStorage.removeItem(HIST_KEY);

    // ─── TIME AGO ───────────────────────────────────────────────
    const timeAgo = (ts) => {
        const diff = Date.now() - ts;
        const m = Math.floor(diff / 60000);
        if (m < 60)  return `Hace ${m || 1} min`;
        const h = Math.floor(m / 60);
        if (h < 24)  return `Hace ${h}h`;
        const d = Math.floor(h / 24);
        if (d < 7)   return `Hace ${d}d`;
        return new Date(ts).toLocaleDateString('es');
    };

    return { getFavorites, isFavorite, toggleFavorite, removeFavorite,
             clearFavorites, getHistory, addHistory, clearHistory, timeAgo };
})();
