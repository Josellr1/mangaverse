// MangaVerse — App Controller
const App = {
    state: {
        currentMangaId:    null,
        currentMangaObj:   null,
        currentChapterId:  null,
        chapters:          [],
        activeLang:        'all',
        firstLoad:         true,
    },

    els: {},

    init() {
        this.els = {
            viewLanding:      document.getElementById('view-landing'),
            viewReaderApp:    document.getElementById('view-reader-app'),
            viewDownload:     document.getElementById('view-download'),
            viewFavorites:    document.getElementById('view-favorites'),
            viewHistory:      document.getElementById('view-history'),
            mangaGrid:        document.getElementById('manga-grid'),
            favsGrid:         document.getElementById('favs-grid'),
            historyList:      document.getElementById('history-list'),
            homeLoader:       document.getElementById('home-loader'),
            chapterLoader:    document.getElementById('chapter-loader'),
            searchInput:      document.getElementById('search-input'),
            searchBtn:        document.getElementById('search-btn'),
            resultsTitle:     document.getElementById('results-title'),
            detailContainer:  document.getElementById('detail-container'),
            pagesContainer:   document.getElementById('pages-container'),
            chapterLabel:     document.getElementById('chapter-label'),
            btnPrevCh:        document.getElementById('btn-prev-ch'),
            btnNextCh:        document.getElementById('btn-next-ch'),
            btnPrevCh2:       document.getElementById('btn-prev-ch-2'),
            btnNextCh2:       document.getElementById('btn-next-ch-2'),
        };
        this.bindEvents();
        this.initParticles();
    },

    bindEvents() {
        // Landing <-> Reader
        const toReader = (e) => { if(e) e.preventDefault(); this.showReader(); };
        document.getElementById('hero-read-btn').addEventListener('click', toReader);
        document.getElementById('nav-read-btn').addEventListener('click', toReader);
        const mob = document.getElementById('mob-read-btn');
        if (mob) mob.addEventListener('click', toReader);

        // Back to landing
        document.getElementById('btn-to-landing').addEventListener('click', () => this.showLanding());
        const btnDl = document.getElementById('btn-to-landing-dl');
        if (btnDl) btnDl.addEventListener('click', () => this.showLanding());
        const btnFavBack = document.getElementById('btn-to-landing-fav');
        if (btnFavBack) btnFavBack.addEventListener('click', () => this.showLanding());
        const btnHistBack = document.getElementById('btn-to-landing-hist');
        if (btnHistBack) btnHistBack.addEventListener('click', () => this.showLanding());

        document.getElementById('nav-logo-btn').addEventListener('click', (e) => { e.preventDefault(); this.showLanding(); });

        // Android download -> dedicated view
        const androidBtn = document.getElementById('android-btn');
        if (androidBtn) {
            androidBtn.addEventListener('click', (e) => { e.preventDefault(); this.showDownload(); });
        }

        // Back buttons in reader
        document.getElementById('btn-back-to-home').addEventListener('click', () => { UI.showScreen('screen-home'); window.scrollTo(0,0); });
        document.getElementById('btn-back-to-detail').addEventListener('click', () => { UI.showScreen('screen-detail'); window.scrollTo(0,0); });

        // Search
        this.els.searchBtn.addEventListener('click', () => this.handleSearch());
        this.els.searchInput.addEventListener('keydown', e => { if (e.key === 'Enter') this.handleSearch(); });

        // Language filter
        document.querySelectorAll('.lang-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.state.activeLang = btn.dataset.lang;
                // Reload the grid with new language
                this.loadPopular();
            });
        });

        // Chapter nav
        this.els.btnPrevCh.addEventListener('click', () => this.navigateChapter(-1));
        this.els.btnNextCh.addEventListener('click', () => this.navigateChapter(1));
        this.els.btnPrevCh2.addEventListener('click', () => this.navigateChapter(-1));
        this.els.btnNextCh2.addEventListener('click', () => this.navigateChapter(1));

        // Hamburger
        const hb = document.getElementById('hamburger');
        const mm = document.getElementById('mobile-menu');
        if (hb && mm) hb.addEventListener('click', () => mm.classList.toggle('open'));

        // Reader nav links
        const navFavBtn = document.getElementById('nav-favs-btn');
        if (navFavBtn) navFavBtn.addEventListener('click', (e) => { e.preventDefault(); this.showFavorites(); });
        const navHistBtn = document.getElementById('nav-hist-btn');
        if (navHistBtn) navHistBtn.addEventListener('click', (e) => { e.preventDefault(); this.showHistory(); });

        // History clear button
        const clearHistBtn = document.getElementById('clear-hist-btn');
        if (clearHistBtn) {
            clearHistBtn.addEventListener('click', () => {
                if (confirm('¿Borrar todo el historial de lectura?')) {
                    Storage.clearHistory();
                    this._renderHistory();
                }
            });
        }

        // Navbar shadow on scroll
        window.addEventListener('scroll', () => {
            const nav = document.getElementById('navbar');
            if (nav) nav.style.boxShadow = window.scrollY > 10 ? '0 4px 30px rgba(0,0,0,0.5)' : 'none';
        }, { passive: true });
    },

    _hideAllViews() {
        ['view-landing','view-reader-app','view-download','view-favorites','view-history'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.style.display = 'none';
        });
    },

    showLanding() {
        this._hideAllViews();
        this.els.viewLanding.style.display = 'block';
        window.scrollTo(0, 0);
    },

    showReader() {
        this._hideAllViews();
        this.els.viewReaderApp.style.display = 'block';
        UI.showScreen('screen-home');
        window.scrollTo(0, 0);
        if (this.state.firstLoad) {
            this.state.firstLoad = false;
            this.loadPopular();
        }
    },

    showDownload() {
        this._hideAllViews();
        if (this.els.viewDownload) this.els.viewDownload.style.display = 'block';
        window.scrollTo(0, 0);
    },

    showFavorites() {
        this._hideAllViews();
        if (this.els.viewFavorites) {
            this.els.viewFavorites.style.display = 'block';
            this._renderFavorites();
        }
        window.scrollTo(0, 0);
    },

    showHistory() {
        this._hideAllViews();
        if (this.els.viewHistory) {
            this.els.viewHistory.style.display = 'block';
            this._renderHistory();
        }
        window.scrollTo(0, 0);
    },

    _renderFavorites() {
        const favs = Storage.getFavorites();
        if (this.els.favsGrid) UI.renderFavsGrid(favs, this.els.favsGrid);
    },

    _renderHistory() {
        const hist = Storage.getHistory();
        if (this.els.historyList) UI.renderHistoryList(hist, this.els.historyList);
    },

    async loadPopular() {
        this._showGridLoader();
        this.els.resultsTitle.textContent = '🔥 Populares Ahora';
        const lang = this.state.activeLang === 'all' ? '' : this.state.activeLang;
        const mangas = await MangaAPI.search('', 24, 0, lang);
        this._hideGridLoader();
        UI.renderGrid(mangas, this.els.mangaGrid);
    },

    async handleSearch() {
        const q = this.els.searchInput.value.trim();
        if (!q) return;
        this.els.resultsTitle.textContent = `Resultados para "${q}"`;
        this._showGridLoader();
        const mangas = await MangaAPI.search(q, 24, 0);
        this._hideGridLoader();
        UI.renderGrid(mangas, this.els.mangaGrid);
    },

    async openDetail(mangaId) {
        this.state.currentMangaId = mangaId;
        // Make sure reader view is visible
        this._hideAllViews();
        this.els.viewReaderApp.style.display = 'block';
        UI.showScreen('screen-detail');
        window.scrollTo(0, 0);

        this.els.detailContainer.innerHTML = `<div class="detail-wrapper"><div class="grid-loader" style="height:300px;display:flex;"><div class="loader-ring"></div><span>Cargando detalles...</span></div></div>`;

        const lang = this.state.activeLang === 'all' ? null : this.state.activeLang;
        const [manga, chapters] = await Promise.all([
            MangaAPI.getManga(mangaId),
            MangaAPI.getChapters(mangaId, lang || 'all', 120, 0)
        ]);

        this.state.chapters    = chapters;
        this.state.currentMangaObj = manga;

        if (manga) {
            UI.renderDetail(manga, chapters, this.els.detailContainer);
        } else {
            this.els.detailContainer.innerHTML = `<p style="padding:2rem;color:var(--text-muted);">Error al cargar el manga. Inténtalo de nuevo.</p>`;
        }
    },

    async openChapter(chapterId, label, manga) {
        this.state.currentChapterId = chapterId;
        UI.showScreen('screen-chapter');
        window.scrollTo(0, 0);

        this.els.chapterLabel.textContent = label || 'Cargando...';
        this.els.pagesContainer.innerHTML = '';
        this.els.chapterLoader.style.display = 'flex';
        this.els.pagesContainer.appendChild(this.els.chapterLoader);

        this._updateNavBtns(chapterId);

        const images = await MangaAPI.getChapterImages(chapterId);
        this.els.chapterLoader.style.display = 'none';
        UI.renderPages(images, this.els.pagesContainer);

        // Save to history
        if (manga) {
            Storage.addHistory({
                mangaId:      manga.id,
                mangaTitle:   MangaAPI.getTitle(manga),
                coverUrl:     MangaAPI.getCoverUrl(manga, 256),
                chapterId,
                chapterTitle: label,
            });
        } else if (this.state.currentMangaObj) {
            const m = this.state.currentMangaObj;
            Storage.addHistory({
                mangaId:      m.id,
                mangaTitle:   MangaAPI.getTitle(m),
                coverUrl:     MangaAPI.getCoverUrl(m, 256),
                chapterId,
                chapterTitle: label,
            });
        }
    },

    /** Retry loading the current chapter (called from inline button in UI) */
    retryChapter() {
        if (!this.state.currentChapterId) return;
        const label = this.els.chapterLabel.textContent;
        this.openChapter(this.state.currentChapterId, label, this.state.currentMangaObj);
    },

    _updateNavBtns(chapterId) {
        const idx = this.state.chapters.findIndex(c => c.id === chapterId);
        const hasPrev = idx < this.state.chapters.length - 1;
        const hasNext = idx > 0;
        [this.els.btnPrevCh, this.els.btnPrevCh2].forEach(b => b.disabled = !hasPrev);
        [this.els.btnNextCh, this.els.btnNextCh2].forEach(b => b.disabled = !hasNext);
    },

    navigateChapter(dir) {
        const idx = this.state.chapters.findIndex(c => c.id === this.state.currentChapterId);
        if (idx === -1) return;
        const next = dir === -1 ? idx + 1 : idx - 1;
        if (next < 0 || next >= this.state.chapters.length) return;
        const ch = this.state.chapters[next];
        const label = ch.attributes?.chapter ? `Cap. ${ch.attributes.chapter}` : 'Oneshot';
        this.openChapter(ch.id, label, this.state.currentMangaObj);
    },

    _showGridLoader() {
        this.els.mangaGrid.innerHTML = '';
        const loader = this.els.homeLoader.cloneNode(true);
        loader.style.display = 'flex';
        loader.id = 'active-loader';
        this.els.mangaGrid.appendChild(loader);
    },
    _hideGridLoader() {
        const l = document.getElementById('active-loader');
        if (l) l.remove();
    },

    initParticles() {
        const canvas = document.getElementById('particles-canvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        let W, H, particles;

        const resize = () => {
            W = canvas.width  = canvas.offsetWidth;
            H = canvas.height = canvas.offsetHeight;
        };

        const mkP = () => ({
            x: Math.random() * W, y: Math.random() * H,
            r: Math.random() * 1.6 + 0.3,
            dx: (Math.random() - 0.5) * 0.25,
            dy: (Math.random() - 0.5) * 0.25,
            alpha: Math.random() * 0.45 + 0.1,
            col: Math.random() > 0.5 ? '139,92,246' : '6,182,212'
        });

        resize();
        particles = Array.from({ length: 90 }, mkP);
        window.addEventListener('resize', resize, { passive: true });

        const draw = () => {
            ctx.clearRect(0, 0, W, H);
            particles.forEach(p => {
                ctx.beginPath();
                ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
                ctx.fillStyle = `rgba(${p.col},${p.alpha})`;
                ctx.fill();
                p.x += p.dx; p.y += p.dy;
                if (p.x < 0 || p.x > W) p.dx *= -1;
                if (p.y < 0 || p.y > H) p.dy *= -1;
            });
            requestAnimationFrame(draw);
        };
        draw();
    }
};

document.addEventListener('DOMContentLoaded', () => App.init());
