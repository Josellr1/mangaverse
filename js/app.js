// MangaVerse — App Controller
const App = {
    state: {
        currentMangaId: null,
        currentChapterId: null,
        chapters: [],
        activeLang: 'es',
        firstLoad: true,
    },

    els: {},

    init() {
        this.els = {
            viewLanding:    document.getElementById('view-landing'),
            viewReaderApp:  document.getElementById('view-reader-app'),
            viewDownload:   document.getElementById('view-download'),
            mangaGrid:      document.getElementById('manga-grid'),
            homeLoader:     document.getElementById('home-loader'),
            chapterLoader:  document.getElementById('chapter-loader'),
            searchInput:    document.getElementById('search-input'),
            searchBtn:      document.getElementById('search-btn'),
            resultsTitle:   document.getElementById('results-title'),
            detailContainer:document.getElementById('detail-container'),
            pagesContainer: document.getElementById('pages-container'),
            chapterLabel:   document.getElementById('chapter-label'),
            btnPrevCh:      document.getElementById('btn-prev-ch'),
            btnNextCh:      document.getElementById('btn-next-ch'),
            btnPrevCh2:     document.getElementById('btn-prev-ch-2'),
            btnNextCh2:     document.getElementById('btn-next-ch-2'),
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

        document.getElementById('btn-to-landing').addEventListener('click', () => this.showLanding());
        const btnToLandingDl = document.getElementById('btn-to-landing-dl');
        if (btnToLandingDl) btnToLandingDl.addEventListener('click', () => this.showLanding());
        document.getElementById('nav-logo-btn').addEventListener('click', (e) => { e.preventDefault(); this.showLanding(); });

        // Download View link
        const androidBtn = document.getElementById('android-btn');
        if (androidBtn) {
            androidBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.showDownload();
            });
        }

        // Back buttons
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

        // Navbar shadow on scroll
        window.addEventListener('scroll', () => {
            const nav = document.getElementById('navbar');
            if (nav) nav.style.boxShadow = window.scrollY > 10 ? '0 4px 30px rgba(0,0,0,0.5)' : 'none';
        }, { passive: true });
    },

    showLanding() {
        this.els.viewLanding.style.display = 'block';
        this.els.viewReaderApp.style.display = 'none';
        if (this.els.viewDownload) this.els.viewDownload.style.display = 'none';
        window.scrollTo(0, 0);
    },

    showDownload() {
        this.els.viewLanding.style.display = 'none';
        this.els.viewReaderApp.style.display = 'none';
        if (this.els.viewDownload) this.els.viewDownload.style.display = 'block';
        window.scrollTo(0, 0);
    },

    showReader() {
        this.els.viewLanding.style.display = 'none';
        this.els.viewReaderApp.style.display = 'block';
        UI.showScreen('screen-home');
        window.scrollTo(0, 0);
        if (this.state.firstLoad) {
            this.state.firstLoad = false;
            this.loadPopular();
        }
    },

    async loadPopular() {
        this._showGridLoader();
        this.els.resultsTitle.textContent = '🔥 Populares Ahora';
        const mangas = await MangaAPI.search('', 24, 0);
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
        UI.showScreen('screen-detail');
        window.scrollTo(0, 0);

        this.els.detailContainer.innerHTML = `<div class="detail-wrapper"><div class="grid-loader" style="height:300px;display:flex;"><div class="loader-ring"></div><span>Cargando detalles...</span></div></div>`;

        const lang = this.state.activeLang === 'all' ? null : this.state.activeLang;
        const [manga, chapters] = await Promise.all([
            MangaAPI.getManga(mangaId),
            MangaAPI.getChapters(mangaId, lang || 'es', 120, 0)
        ]);

        this.state.chapters = chapters;

        if (manga) {
            UI.renderDetail(manga, chapters, this.els.detailContainer);
        } else {
            this.els.detailContainer.innerHTML = `<p style="padding:2rem;color:var(--text-muted);">Error al cargar el manga. Inténtalo de nuevo.</p>`;
        }
    },

    async openChapter(chapterId, label) {
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
    },

    _updateNavBtns(chapterId) {
        const idx = this.state.chapters.findIndex(c => c.id === chapterId);
        // Capítulos en orden desc: anterior = idx+1, siguiente = idx-1
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
        this.openChapter(ch.id, label);
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
            W = canvas.width = canvas.offsetWidth;
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
