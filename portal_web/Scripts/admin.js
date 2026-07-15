var AdminApp = (function () {
    var apiBase = 'http://localhost:5000/api/';
    var state = { pagina: 1, tamano: 20, totalRegistros: 0, filtros: {} };

    function ajax(url, metodo, datos, onOk, onError) {
        $.ajax({ url: apiBase + url, method: metodo || 'GET', contentType: 'application/json',
            data: metodo === 'GET' ? datos : (datos ? JSON.stringify(datos) : null),
            success: function (res) { if (typeof onOk === 'function') onOk(res); },
            error: function (xhr) { console.error('API Error:', url, xhr.responseText);
                if (typeof onError === 'function') onError(xhr);
                else Toast.error('Error al conectar con el servidor'); }
        });
    }

    var Toast = {
        success: function (msg) { this._show(msg, '#48BB78', '#C6F6D5'); },
        error: function (msg) { this._show(msg, '#F56565', '#FED7D7'); },
        warning: function (msg) { this._show(msg, '#F6AD55', '#FEEBC8'); },
        _show: function (msg, bg, bgLight) {
            var $t = $('<div style="position:fixed;top:20px;right:20px;z-index:99999;padding:14px 20px;border-radius:12px;background:' + bgLight + ';color:#2D3748;font-size:0.9rem;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,0.15);border-left:4px solid ' + bg + ';max-width:400px;display:flex;align-items:center;gap:10px;"><i class="fas fa-check-circle" style="color:' + bg + '"></i> ' + msg + '</div>');
            $('body').append($t);
            $t.css({ opacity: 0, transform: 'translateY(-20px)' }).animate({ opacity: 1, transform: 'translateY(0)' }, 250);
            setTimeout(function () { $t.animate({ opacity: 0, transform: 'translateY(-20px)' }, 250, function () { $t.remove(); }); }, 3500);
        }
    };

    function formatearFecha(f) { if (!f) return '--'; var d = new Date(f); return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }) + ' ' + d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' }); }
    function formatearMoneda(v) { return '$' + Number(v || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }

    function renderPaginador(total, pagina, tamano, fn) {
        var totalPages = Math.ceil(total / tamano) || 1;
        if (total === 0) return '<div class="info">Sin registros</div>';
        var h = '<div class="info">' + ((pagina - 1) * tamano + 1) + '-' + Math.min(pagina * tamano, total) + ' de ' + total + '</div><div class="pages">';
        if (pagina > 1) h += '<button data-p="' + (pagina - 1) + '"><i class="fas fa-chevron-left"></i></button>';
        for (var i = Math.max(1, pagina - 2); i <= Math.min(totalPages, pagina + 2); i++) { h += '<button data-p="' + i + '" class="' + (i === pagina ? 'active' : '') + '">' + i + '</button>'; }
        if (pagina < totalPages) h += '<button data-p="' + (pagina + 1) + '"><i class="fas fa-chevron-right"></i></button>';
        h += '</div>';
        return h;
    }

    function badge(cond, tActive, tInactive, clsActive, clsInactive) {
        return cond ? '<span class="status-badge ' + (clsActive || 'active') + '">' + (tActive || 'Activo') + '</span>'
                    : '<span class="status-badge ' + (clsInactive || 'inactive') + '">' + (tInactive || 'Inactivo') + '</span>';
    }

    return {
        apiBase: apiBase, state: state, Toast: Toast,
        ajax: ajax, fmtFecha: formatearFecha, fmtMoneda: formatearMoneda,
        paginador: renderPaginador, badge: badge,
        formatDate: function (d) { if (!d) return ''; var dt = new Date(d); return dt.toISOString().split('T')[0]; },
        formatDateTimeLocal: function (d) { if (!d) return ''; var dt = new Date(d); return dt.toISOString().slice(0, 16); },
        getVal: function (o, k, def) { var v = o[k]; return v !== null && v !== undefined ? v : (def || ''); },
        safeNum: function (v, def) { var n = Number(v); return isNaN(n) ? (def || 0) : n; },
        openModal: function (id) { $('#' + id).modal('show'); },
        closeModal: function (id) { $('#' + id).modal('hide'); $('#' + id + ' .modal-body').find('input,textarea,select').val('').trigger('change'); },
        loadSelect: function (url, selId, val, txt, selectedVal, emptyOption) {
            var $sel = $('#' + selId); $sel.html(emptyOption !== false ? '<option value="">-- Seleccionar --</option>' : '');
            ajax(url, 'GET', null, function (res) {
                var data = Array.isArray(res) ? res : (res.data || []);
                data.forEach(function (r) { var v = typeof val === 'function' ? val(r) : r[val]; var t = typeof txt === 'function' ? txt(r) : r[txt]; $sel.append('<option value="' + v + '"' + (selectedVal && v == selectedVal ? ' selected' : '') + '>' + t + '</option>'); });
            });
        },
        formToObj: function (formId) {
            var obj = {}; $('#' + formId + ' [name]').each(function () { var $e = $(this), v = $e.val(); if ($e.attr('type') === 'checkbox') v = $e.is(':checked'); if (v !== '' && v !== null) obj[$e.attr('name')] = v; }); return obj;
        },
        objToForm: function (formId, obj) {
            $('#' + formId + ' [name]').each(function () { var $e = $(this), k = $e.attr('name'), v = obj[k]; if (v !== undefined && v !== null) { if ($e.attr('type') === 'checkbox') $e.prop('checked', v === true || v === 1 || v === 'true'); else $e.val(v); } });
        }
    };
})();
var Toast = AdminApp.Toast;
