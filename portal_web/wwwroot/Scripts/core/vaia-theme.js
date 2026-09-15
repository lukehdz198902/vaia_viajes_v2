window.VaiaTheme = (function () {
    var STORAGE_KEY = 'vaia-theme';
    var MEDIA_QUERY = '(prefers-color-scheme: dark)';

    function getStored() {
        try { return localStorage.getItem(STORAGE_KEY); }
        catch (e) { return null; }
    }

    function store(theme) {
        try { localStorage.setItem(STORAGE_KEY, theme); }
        catch (e) { }
    }

    function getSystemPreference() {
        if (window.matchMedia && window.matchMedia(MEDIA_QUERY).matches) return 'dark';
        return 'light';
    }

    function resolveInitial() {
        var stored = getStored();
        if (stored === 'light' || stored === 'dark') return stored;
        return getSystemPreference();
    }

    function getCurrent() {
        return document.documentElement.getAttribute('data-theme') || 'light';
    }

    function apply(theme, persist) {
        if (theme !== 'light' && theme !== 'dark') theme = 'light';
        document.documentElement.setAttribute('data-theme', theme);
        if (persist !== false) store(theme);
        updateButtons(theme);
        dispatchChange(theme);
    }

    function dispatchChange(theme) {
        try {
            window.dispatchEvent(new CustomEvent('vaia:theme-changed', { detail: { theme: theme } }));
        } catch (e) { }
    }

    function updateButtons(theme) {
        var btns = document.querySelectorAll('[data-vaia-theme-toggle]');
        var i;
        for (i = 0; i < btns.length; i++) {
            var btn = btns[i];
            btn.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false');
            var label = theme === 'dark' ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro';
            btn.setAttribute('aria-label', label);
            btn.setAttribute('title', label);
            var icon = btn.querySelector('[data-theme-icon]');
            if (icon) {
                icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
            }
        }
    }

    function toggle() {
        apply(getCurrent() === 'dark' ? 'light' : 'dark');
    }

    function bind() {
        document.addEventListener('click', function (e) {
            var btn = e.target.closest('[data-vaia-theme-toggle]');
            if (!btn) return;
            e.preventDefault();
            toggle();
        });

        if (window.matchMedia) {
            var mq = window.matchMedia(MEDIA_QUERY);
            var handler = function (e) {
                if (getStored()) return;
                apply(e.matches ? 'dark' : 'light', false);
            };
            if (mq.addEventListener) mq.addEventListener('change', handler);
            else if (mq.addListener) mq.addListener(handler);
        }
    }

    function init() {
        apply(getCurrent(), false);
        bind();
    }

    return {
        init: init,
        apply: apply,
        toggle: toggle,
        getCurrent: getCurrent,
        resolveInitial: resolveInitial
    };
})();

(function () {
    function boot() {
        if (window.VaiaTheme && typeof window.VaiaTheme.init === 'function') {
            window.VaiaTheme.init();
        }
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
    } else {
        boot();
    }
})();