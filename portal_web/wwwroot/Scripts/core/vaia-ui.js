window.VaiaUI = (function () {
    var prefersReducedMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var _toastContainer = null;
    var _modalIdCounter = 0;

    function fmtCurrency(n) {
        return '$' + Number(n || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
    function fmtNumber(n) {
        return Number(n || 0).toLocaleString('es-MX');
    }
    function escapeHtml(str) {
        if (str == null) return '';
        return String(str).replace(/[&<>"']/g, function (m) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[m];
        });
    }

    function countUp(selector, opts) {
        var defaults = { duration: 900, ease: 'easeOutCubic' };
        opts = Object.assign({}, defaults, opts || {});
        var els = typeof selector === 'string'
            ? document.querySelectorAll(selector)
            : (selector && selector.length ? selector : [selector]);

        var easingFns = {
            linear: function (t) { return t; },
            easeOutCubic: function (t) { return 1 - Math.pow(1 - t, 3); },
            easeOutQuart: function (t) { return 1 - Math.pow(1 - t, 4); }
        };
        var ease = easingFns[opts.ease] || easingFns.easeOutCubic;

        Array.prototype.forEach.call(els, function (el) {
            var target = parseFloat(el.getAttribute('data-countup'));
            if (isNaN(target)) return;
            var format = el.getAttribute('data-format') || 'number';
            var prefix = format === 'currency' ? '$' : '';
            var decimals = format === 'currency' ? 2 : 0;

            if (prefersReducedMotion) {
                el.textContent = prefix + target.toLocaleString('es-MX', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
                return;
            }

            var start = performance.now();
            function frame(now) {
                var t = Math.min(1, (now - start) / opts.duration);
                var v = target * t;
                var eased = ease(t);
                var cur = target * eased;
                el.textContent = prefix + cur.toLocaleString('es-MX', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
                if (t < 1) requestAnimationFrame(frame);
                else el.textContent = prefix + target.toLocaleString('es-MX', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
            }
            requestAnimationFrame(frame);
        });
    }

    function ensureToastContainer() {
        if (_toastContainer && document.body.contains(_toastContainer)) return _toastContainer;
        _toastContainer = document.createElement('div');
        _toastContainer.className = 'toast-container';
        _toastContainer.setAttribute('aria-live', 'polite');
        _toastContainer.setAttribute('aria-atomic', 'true');
        document.body.appendChild(_toastContainer);
        return _toastContainer;
    }

    function toast(options) {
        var opts = Object.assign({ type: 'info', title: '', message: '', duration: 3500 }, options || {});
        var container = ensureToastContainer();
        var typeMap = {
            success: { cls: 'toast--success', icon: 'fa-circle-check' },
            warning: { cls: 'toast--warning', icon: 'fa-triangle-exclamation' },
            danger:  { cls: 'toast--danger',  icon: 'fa-circle-xmark' },
            error:   { cls: 'toast--danger',  icon: 'fa-circle-xmark' },
            info:    { cls: 'toast--info',    icon: 'fa-circle-info' },
            accent:  { cls: 'toast--accent',  icon: 'fa-circle-check' }
        };
        var t = typeMap[opts.type] || typeMap.info;

        var node = document.createElement('div');
        node.className = 'toast ' + t.cls;
        node.setAttribute('role', opts.type === 'danger' || opts.type === 'error' ? 'alert' : 'status');
        node.innerHTML =
            '<div class="toast-icon"><i class="fas ' + t.icon + '"></i></div>' +
            '<div class="toast-body">' +
                (opts.title ? '<div class="toast-title">' + escapeHtml(opts.title) + '</div>' : '') +
                (opts.message ? '<div class="toast-message">' + escapeHtml(opts.message) + '</div>' : '') +
            '</div>' +
            '<button class="toast-close" aria-label="Cerrar"><i class="fas fa-xmark"></i></button>';
        container.appendChild(node);

        var dismiss = function () {
            node.classList.add('is-leaving');
            setTimeout(function () { if (node.parentNode) node.parentNode.removeChild(node); }, 220);
        };
        node.querySelector('.toast-close').addEventListener('click', dismiss);
        if (opts.duration > 0) setTimeout(dismiss, opts.duration);
        return { dismiss: dismiss };
    }

    function nextModalId() { return 'vaiaModal' + (++_modalIdCounter); }

    function modal(options) {
        var opts = Object.assign({
            title: '',
            titleHtml: false,
            body: '',
            footer: '',
            size: '',
            fullscreen: false,
            closable: true,
            onClose: null
        }, options || {});
        var id = nextModalId();
        var sizeCls = opts.size ? ' modal-dialog--' + opts.size : '';
        var fsCls = opts.fullscreen ? ' modal-dialog--full' : '';
        var wrapCls = opts.fullscreen ? ' modal--full' : '';

        var backdrop = document.createElement('div');
        backdrop.className = 'modal-backdrop';
        backdrop.setAttribute('data-modal-id', id);

        var dlg = document.createElement('div');
        dlg.className = 'modal-dialog' + sizeCls + fsCls;
        dlg.setAttribute('role', 'dialog');
        dlg.setAttribute('aria-modal', 'true');
        if (opts.title) dlg.setAttribute('aria-label', opts.title);
        dlg.innerHTML =
            (opts.title ? '<header class="modal-header"><h3 class="modal-title">' + (opts.titleHtml ? opts.title : escapeHtml(opts.title)) + '</h3>' + (opts.closable ? '<button class="modal-close" aria-label="Cerrar"><i class="fas fa-xmark"></i></button>' : '') + '</header>' : '') +
            '<div class="modal-body">' + opts.body + '</div>' +
            (opts.footer ? '<footer class="modal-footer">' + opts.footer + '</footer>' : '');

        var wrap = document.createElement('div');
        wrap.className = 'modal' + wrapCls;
        wrap.id = id;
        wrap.setAttribute('data-modal-id', id);
        wrap.appendChild(dlg);
        document.body.appendChild(backdrop);
        document.body.appendChild(wrap);
        document.body.classList.add('has-modal-open');

        function close() {
            backdrop.style.animation = 'vaia-fade-out 200ms ease both';
            dlg.style.animation = 'vaia-fade-out 200ms ease both';
            setTimeout(function () {
                if (backdrop.parentNode) backdrop.parentNode.removeChild(backdrop);
                if (wrap.parentNode) wrap.parentNode.removeChild(wrap);
                if (!document.querySelector('.modal')) document.body.classList.remove('has-modal-open');
                if (typeof opts.onClose === 'function') opts.onClose();
            }, 200);
        }

        if (opts.closable) {
            dlg.querySelectorAll('.modal-close').forEach(function (b) { b.addEventListener('click', close); });
            backdrop.addEventListener('click', close);
            dlg.addEventListener('click', function (e) {
                var target = e.target.closest('[data-close]');
                if (target) close();
            });
            var escHandler = function (e) { if (e.key === 'Escape') { close(); document.removeEventListener('keydown', escHandler); } };
            document.addEventListener('keydown', escHandler);
        }

        return { id: id, close: close, dialog: dlg };
    }

    function confirmDialog(title, message, onAccept, onCancel) {
        var m = modal({
            title: title || 'Confirmar',
            body: '<p style="margin:0;color:var(--text-muted);">' + escapeHtml(message || '') + '</p>',
            footer:
                '<button class="btn btn--ghost" data-action="cancel">Cancelar</button>' +
                '<button class="btn btn--primary" data-action="ok">Aceptar</button>',
            onClose: function () { if (typeof onCancel === 'function') onCancel(); }
        });
        m.dialog.querySelector('[data-action="cancel"]').addEventListener('click', function () {
            m.close();
            if (typeof onCancel === 'function') onCancel();
        });
        m.dialog.querySelector('[data-action="ok"]').addEventListener('click', function () {
            m.close();
            m.dialog.dataset._confirmed = '1';
            if (typeof onAccept === 'function') onAccept();
        });
        return m;
    }

    return {
        countUp: countUp,
        toast: toast,
        modal: modal,
        confirm: confirmDialog,
        fmtCurrency: fmtCurrency,
        fmtNumber: fmtNumber,
        escapeHtml: escapeHtml,
        prefersReducedMotion: prefersReducedMotion
    };
})();