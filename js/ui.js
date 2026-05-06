// MangaVerse — UI Module (MangaDex schema)
const UI = {

    renderGrid(mangas, gridEl) {
        gridEl.innerHTML = '';
        if (!mangas || mangas.length === 0) {
            gridEl.innerHTML = `<div class="grid-loader"><span style="color:var(--text-muted);">No se encontraron resultados. Intenta otro título.</span></div>`;
            return;
        }
        mangas.forEach(manga => {
            const title = MangaAPI.getTitle(manga);
            const cover = MangaAPI.getCoverUrl(manga, 256);
            const tags = (manga.attributes?.tags || []).slice(0, 2).map(t => t.attributes?.name?.en || '').filter(Boolean);
            const tagHTML = tags.map(t => `<span class="manga-card-tag">${t}</span>`).join(' ');

            const card = document.createElement('div');
            card.className = 'manga-card';
            card.innerHTML = `
                <img class="manga-cover" src="${cover}" alt="${title}" loading="lazy"
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

    renderDetail(manga, chapters, container) {
        const title = MangaAPI.getTitle(manga);
        const cover = MangaAPI.getCoverUrl(manga, 512);
        const desc = MangaAPI.getDescription(manga);
        const author = MangaAPI.getAuthor(manga);
        const status = manga.attributes?.status || 'unknown';
        const statusLabel = { ongoing: '🟢 En Curso', completed: '✅ Completado', hiatus: '⏸️ Hiatus', cancelled: '❌ Cancelado' }[status] || status;
        const year = manga.attributes?.year || '';
        const tags = (manga.attributes?.tags || []).slice(0, 5).map(t => t.attributes?.name?.en || '').filter(Boolean);

        container.innerHTML = `
            <div class="detail-wrapper">
                <div class="detail-header">
                    <img class="detail-cover" src="${cover}" alt="${title}"
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

        container.querySelectorAll('.chapter-item').forEach(el => {
            el.addEventListener('click', () => App.openChapter(el.dataset.id, el.dataset.label));
        });
    },

    _chapterHTML(ch) {
        const chapNum = ch.attributes?.chapter ? `Cap. ${ch.attributes.chapter}` : 'Oneshot';
        const chapTitle = ch.attributes?.title ? ` — ${ch.attributes.title}` : '';
        const lang = ch.attributes?.translatedLanguage || '';
        const langFlag = lang === 'es' || lang === 'es-la' ? '🇪🇸' : lang === 'en' ? '🇺🇸' : lang.toUpperCase();
        const date = ch.attributes?.publishAt ? new Date(ch.attributes.publishAt).toLocaleDateString('es') : '';
        const label = `${chapNum}${chapTitle}`;
        // Grupo de scanlation
        const group = ch.relationships?.find(r => r.type === 'scanlation_group')?.attributes?.name || '';

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
            img.src = url;
            img.alt = `Página ${i + 1}`;
            img.loading = 'lazy';
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
