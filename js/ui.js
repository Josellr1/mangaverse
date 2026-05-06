// MangaVerse — UI Module (MangaDex schema)
const UI = {

    renderGrid(mangas, gridEl) {
        gridEl.innerHTML = '';
        if (!mangas || mangas.length === 0) {
            gridEl.innerHTML = `<div class="grid-loader"><span style="color:var(--text-muted);">No se encontraron resultados. Intenta otro título.</span></div>`;
            return;
        }
        mangas.forEach(manga => {
            const title   = MangaAPI.getTitle(manga);
            const cover   = MangaAPI.getCoverUrl(manga, 256);
            const tags    = (manga.attributes?.tags || []).slice(0, 2).map(t => t.attributes?.name?.en || '').filter(Boolean);
            const tagHTML = tags.map(t => `<span class="manga-card-tag">${t}</span>`).join(' ');
            const isFav   = Storage.isFavorite(manga.id);

            const card = document.createElement('div');
            card.className = 'manga-card';
            card.innerHTML = `
                ${isFav ? '<span class="card-fav-badge">❤️</span>' : ''}
                <img class="manga-cover" src="${cover}" alt="${title}" loading="lazy" referrerpolicy="no-referrer"
                     onerror="this.src='https://placehold.co/200x300/1a1d2e/8B5CF6?text=Sin+Portada'">
                <div class="manga-card-info">
                    <div class="manga-card-title" title="${title}">${title}</div>
                    <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px;">${tagHTML}</div>
                </div>
            `;
            card.addEventListener('click', () => App.openDetail(manga.id));
            gridEl.appendChild(card);
        });
    },

    renderFavsGrid(favs, gridEl) {
        gridEl.innerHTML = '';
        if (!favs || favs.length === 0) {
            gridEl.innerHTML = `
                <div class="grid-loader" style="flex-direction:column;gap:1rem;">
                    <span style="font-size:3rem;">💔</span>
                    <span style="color:var(--text-muted);">No tienes favoritos aún.<br>Toca ❤️ en el detalle de un manga.</span>
                </div>`;
            return;
        }
        favs.forEach(fav => {
            const card = document.createElement('div');
            card.className = 'manga-card';
            card.innerHTML = `
                <span class="card-fav-badge">❤️</span>
                <img class="manga-cover" src="${fav.coverUrl || 'https://placehold.co/200x300/1a1d2e/8B5CF6?text=Sin+Portada'}"
                     alt="${fav.title}" loading="lazy" referrerpolicy="no-referrer"
                     onerror="this.src='https://placehold.co/200x300/1a1d2e/8B5CF6?text=Sin+Portada'">
                <div class="manga-card-info">
                    <div class="manga-card-title" title="${fav.title}">${fav.title}</div>
                    <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px;">
                        ${(fav.tags || []).map(t => `<span class="manga-card-tag">${t}</span>`).join('')}
                    </div>
                </div>
            `;
            card.addEventListener('click', () => App.openDetail(fav.id));
            gridEl.appendChild(card);
        });
    },

    renderHistoryList(history, container) {
        container.innerHTML = '';
        if (!history || history.length === 0) {
            container.innerHTML = `
                <div style="text-align:center;padding:4rem 2rem;color:var(--text-muted);">
                    <div style="font-size:3.5rem;margin-bottom:1rem;">📖</div>
                    <p style="font-size:1rem;">No has leído nada todavía.</p>
                    <p style="font-size:0.9rem;margin-top:0.5rem;">Los capítulos que leas aparecerán aquí.</p>
                </div>`;
            return;
        }
        history.forEach(entry => {
            const item = document.createElement('div');
            item.className = 'history-item';
            item.innerHTML = `
                <img class="history-cover" src="${entry.coverUrl || 'https://placehold.co/48x68/1a1d2e/8B5CF6?text=M'}"
                     alt="${entry.mangaTitle}" loading="lazy" referrerpolicy="no-referrer"
                     onerror="this.src='https://placehold.co/48x68/1a1d2e/8B5CF6?text=M'">
                <div class="history-info">
                    <div class="history-manga-title">${entry.mangaTitle}</div>
                    <div class="history-ch-title">${entry.chapterTitle}</div>
                    <div class="history-time">🕒 ${Storage.timeAgo(entry.readAt)}</div>
                </div>
                <i class="fa-solid fa-chevron-right" style="color:var(--text-muted);font-size:0.85rem;"></i>
            `;
            item.addEventListener('click', () => App.openDetail(entry.mangaId));
            container.appendChild(item);
        });
    },

    renderDetail(manga, chapters, container) {
        const title       = MangaAPI.getTitle(manga);
        const cover       = MangaAPI.getCoverUrl(manga, 512);
        const desc        = MangaAPI.getDescription(manga);
        const author      = MangaAPI.getAuthor(manga);
        const status      = manga.attributes?.status || 'unknown';
        const statusLabel = { ongoing: '🟢 En Curso', completed: '✅ Completado', hiatus: '⏸️ Hiatus', cancelled: '❌ Cancelado' }[status] || status;
        const year        = manga.attributes?.year || '';
        const tags        = (manga.attributes?.tags || []).slice(0, 5).map(t => t.attributes?.name?.en || '').filter(Boolean);
        const isFav       = Storage.isFavorite(manga.id);

        container.innerHTML = `
            <div class="detail-wrapper">
                <div class="detail-header">
                    <img class="detail-cover" src="${cover}" alt="${title}" referrerpolicy="no-referrer"
                         onerror="this.src='https://placehold.co/200x300/1a1d2e/8B5CF6?text=Sin+Portada'">
                    <div class="detail-info">
                        <h2 class="detail-title">${title}</h2>
                        <p class="detail-author">✍️ ${author}</p>
                        <div class="detail-meta">
                            <span class="meta-tag">${statusLabel}</span>
                            ${year ? `<span class="meta-tag">📅 ${year}</span>` : ''}
                            ${tags.map(t => `<span class="meta-tag" style="background:rgba(6,182,212,0.1);border-color:rgba(6,182,212,0.3);color:var(--accent-secondary)">${t}</span>`).join('')}
                        </div>
                        <p class="detail-desc">${desc.replace(/\n/g, '<br>').substring(0, 600)}${desc.length > 600 ? '...' : ''}</p>
                        <button class="fav-btn ${isFav ? 'fav-active' : ''}" id="fav-btn" data-id="${manga.id}">
                            <i class="fa-${isFav ? 'solid' : 'regular'} fa-heart"></i>
                            ${isFav ? 'En Favoritos' : 'Añadir a Favoritos'}
                        </button>
                    </div>
                </div>
                <div class="chapters-section">
                    <h3>📖 Capítulos Disponibles (${chapters.length})</h3>
                    <div class="chapters-list" id="chapters-list">
                        ${chapters.length === 0
                            ? '<p style="color:var(--text-muted);padding:1rem;">No hay capítulos en este idioma. Prueba con <strong>"Todos"</strong>.</p>'
                            : chapters.map(ch => this._chapterHTML(ch)).join('')}
                    </div>
                </div>
            </div>`;

        // Fav toggle
        const favBtn = container.querySelector('#fav-btn');
        if (favBtn) {
            favBtn.addEventListener('click', () => {
                const nowFav = Storage.isFavorite(manga.id);
                Storage.toggleFavorite(manga);
                const active = !nowFav;
                favBtn.className = `fav-btn ${active ? 'fav-active' : ''}`;
                favBtn.innerHTML = `<i class="fa-${active ? 'solid' : 'regular'} fa-heart"></i> ${active ? 'En Favoritos' : 'Añadir a Favoritos'}`;
            });
        }

        container.querySelectorAll('.chapter-item').forEach(el => {
            el.addEventListener('click', () => App.openChapter(el.dataset.id, el.dataset.label, manga));
        });
    },

    _chapterHTML(ch) {
        const chapNum   = ch.attributes?.chapter ? `Cap. ${ch.attributes.chapter}` : 'Oneshot';
        const chapTitle = ch.attributes?.title ? ` — ${ch.attributes.title}` : '';
        const lang      = ch.attributes?.translatedLanguage || '';
        const langFlag  = lang === 'es' || lang === 'es-la' ? '🇪🇸' : lang === 'en' ? '🇺🇸' : lang.toUpperCase();
        const date      = ch.attributes?.publishAt ? new Date(ch.attributes.publishAt).toLocaleDateString('es') : '';
        const label     = `${chapNum}${chapTitle}`;
        const group     = ch.relationships?.find(r => r.type === 'scanlation_group')?.attributes?.name || '';

        return `
            <div class="chapter-item" data-id="${ch.id}" data-label="${label.replace(/"/g, '&quot;')}">
                <div>
                    <div class="ch-title">${chapNum}${chapTitle}</div>
                    <div class="ch-meta">
                        <span class="ch-lang">${langFlag} ${lang}</span>
                        ${group ? `<span style="color:var(--text-muted);font-size:0.78rem;">${group}</span>` : ''}
                    </div>
                </div>
                <div class="ch-meta">${date}</div>
            </div>`;
    },

    renderPages(urls, container) {
        container.innerHTML = '';
        if (!urls || urls.length === 0) {
            container.innerHTML = `<div class="grid-loader"><span style="color:var(--text-muted);text-align:center;padding:2rem;">No se pudieron cargar las páginas.<br>El servidor de MangaDex puede estar saturado. Intenta de nuevo.</span></div>`;
            return;
        }
        urls.forEach((url, i) => {
            const img = document.createElement('img');
            img.className = 'page-img';
            img.src       = url;
            img.alt       = `Página ${i + 1}`;
            img.loading   = 'lazy';
            img.referrerPolicy = 'no-referrer';
            container.appendChild(img);
        });
    },

    showScreen(id) {
        ['screen-home', 'screen-detail', 'screen-chapter'].forEach(s => {
            const el = document.getElementById(s);
            if (el) el.style.display = s === id ? 'block' : 'none';
        });
    }
};
