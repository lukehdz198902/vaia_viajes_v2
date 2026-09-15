var AdminApp = (function () {
    var apiBase = window.__VAIA_API_BASE__ || (function() {
        var stored = localStorage.getItem('vaia_api_base');
        return stored || 'https://vaia.com.mx/api_v2/api/';
    })();
    var state = { pagina: 1, tamano: 20, totalRegistros: 0, filtros: {} };
    var _blockCount = 0;

    function getUser() {
        return {
            id: sessionStorage.getItem('usr_id') || 0,
            nombre: sessionStorage.getItem('usr_nombre') || '',
            account: sessionStorage.getItem('usr_account') || '',
            rol: sessionStorage.getItem('usr_rol') || '',
            idRol: sessionStorage.getItem('usr_idRol') || '',
            idCompania: sessionStorage.getItem('usr_idCompania') || ''
        };
    }

    function getField(obj, key) {
        if (!obj || !key) return undefined;
        if (obj[key] !== undefined && obj[key] !== null) return obj[key];
        var alt = key.charAt(0).toUpperCase() + key.slice(1);
        if (obj[alt] !== undefined && obj[alt] !== null) return obj[alt];
        var lower = key.charAt(0).toLowerCase() + key.slice(1);
        if (obj[lower] !== undefined && obj[lower] !== null) return obj[lower];
        var upper = key.toUpperCase();
        if (obj[upper] !== undefined && obj[upper] !== null) return obj[upper];
        for (var prop in obj) {
            if (prop.toLowerCase() === key.toLowerCase()) return obj[prop];
        }
        return undefined;
    }

    function blockUI(msg) {
        _blockCount++;
        var id = 'blockui-overlay';
        if ($('#' + id).length) return;
        var h = '<div id="' + id + '" style="position:fixed;inset:0;z-index:99990;background:rgba(15,23,42,0.55);backdrop-filter:blur(4px);-webkit-backdrop-filter:blur(4px);display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity 0.25s ease;">';
        h += '<div style="background:#fff;border-radius:18px;padding:36px 44px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,0.18);transform:translateY(8px);transition:transform 0.25s ease;max-width:320px;">';
        h += '<div class="blockui-spinner" style="width:40px;height:40px;margin:0 auto 14px;border:3px solid #E2E8F0;border-top-color:var(--primary,#00B4D8);border-radius:50%;animation:blockui-spin 0.7s linear infinite;"></div>';
        h += '<p style="margin:0;color:#4A5568;font-size:0.88rem;font-weight:500;line-height:1.4;">' + (msg || 'Procesando...') + '</p>';
        h += '</div></div>';
        $('body').append(h);
        requestAnimationFrame(function () { $('#' + id).css('opacity', '1').find('> div').css('transform', 'translateY(0)'); });
        if (!$('#blockui-style').length) {
            $('<style id="blockui-style">@keyframes blockui-spin{to{transform:rotate(360deg)}}</style>').appendTo('head');
        }
    }

    function unblockUI() {
        if (_blockCount > 0) _blockCount--;
        if (_blockCount > 0) return;
        var id = 'blockui-overlay';
        var $el = $('#' + id);
        if (!$el.length) return;
        $el.css('opacity', '0').find('> div').css('transform', 'translateY(8px)');
        setTimeout(function () { $el.remove(); }, 260);
    }

    function ajax(url, metodo, datos, onOk, onError) {
        blockUI();
        var payload = datos ? JSON.parse(JSON.stringify(datos)) : null;
        $.ajax({ url: apiBase + url, method: metodo || 'GET', contentType: 'application/json',
            data: metodo === 'GET' ? datos : (payload ? JSON.stringify(payload) : null),
            success: function (res) { unblockUI(); if (typeof onOk === 'function') onOk(res); },
            error: function (xhr) { unblockUI(); console.error('API Error:', url, xhr.responseText);
                if (typeof onError === 'function') onError(xhr);
                else Toast.error('Error al conectar con el servidor'); }
        });
    }

    var Toast = {
        success: function (msg) { this._show(msg, '#00B4D8', '#E0F7FA'); },
        error: function (msg) { this._show(msg, '#F56565', '#FED7D7'); },
        warning: function (msg) { this._show(msg, '#FFD166', '#FFF8E1'); },
        _show: function (msg, bg, bgLight) {
            var $t = $('<div style="position:fixed;top:20px;right:20px;z-index:99999;padding:12px 18px;border-radius:10px;background:' + bgLight + ';color:#2D3748;font-size:0.85rem;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,0.12);border-left:4px solid ' + bg + ';max-width:380px;display:flex;align-items:center;gap:8px;"><i class="fas fa-check-circle" style="color:' + bg + '"></i> ' + msg + '</div>');
            $('body').append($t);
            $t.css({ opacity: 0, transform: 'translateY(-16px)' }).animate({ opacity: 1, transform: 'translateY(0)' }, 200);
            setTimeout(function () { $t.animate({ opacity: 0, transform: 'translateY(-16px)' }, 200, function () { $t.remove(); }); }, 3000);
        }
    };

    function formatearFecha(f) { if (!f) return '--'; try { var d = new Date(f); if (isNaN(d)) return f; return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }) + ' ' + d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' }); } catch(e) { return f; } }
    function formatearMoneda(v) { return '$' + Number(v || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }

    function renderPaginador(total, pagina, tamano) {
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
        apiBase: apiBase, state: state, Toast: Toast, getUser: getUser, getField: getField,
        blockUI: blockUI, unblockUI: unblockUI,
        ajax: ajax, fmtFecha: formatearFecha, fmtMoneda: formatearMoneda,
        paginador: renderPaginador, badge: badge,
        formatDate: function (d) { if (!d) return ''; try { var dt = new Date(d); return isNaN(dt) ? '' : dt.toISOString().split('T')[0]; } catch(e) { return ''; } },
        formatDateTimeLocal: function (d) { if (!d) return ''; try { var dt = new Date(d); return isNaN(dt) ? '' : dt.toISOString().slice(0, 16); } catch(e) { return ''; } },
        getVal: function (o, k, def) { var v = getField(o, k); return v !== undefined && v !== null ? v : (def || ''); },
        safeNum: function (v, def) { var n = Number(v); return isNaN(n) ? (def || 0) : n; },
        openModal: function (id) { $('#' + id).modal('show'); },
        closeModal: function (id) { $('#' + id).modal('hide'); $('#' + id + ' .modal-body').find('input,textarea,select').val('').trigger('change'); $('#' + id + ' .modal-body input[type=checkbox]').prop('checked', false); },
        loadSelect: function (url, selId, valField, txtField, selectedVal, emptyOption) {
            var $sel = $('#' + selId); $sel.html(emptyOption !== false ? '<option value="">-- Seleccionar --</option>' : '');
            ajax(url, 'GET', null, function (res) {
                var data = Array.isArray(res) ? res : (res.data || []);
                data.forEach(function (r) {
                    var v = getField(r, valField);
                    var t = getField(r, txtField);
                    if (v !== undefined) $sel.append('<option value="' + v + '"' + (selectedVal && v == selectedVal ? ' selected' : '') + '>' + (t || v) + '</option>');
                });
            });
        },
        formToObj: function (formId) {
            var obj = {}; $('#' + formId + ' [name]').each(function () { var $e = $(this), v = $e.val(); if ($e.attr('type') === 'checkbox') v = $e.is(':checked'); if (v !== '' && v !== null && v !== undefined) obj[$e.attr('name')] = v; }); return obj;
        },
        objToForm: function (formId, obj) {
            if (!obj) return;
            $('#' + formId + ' [name]').each(function () {
                var $e = $(this), k = $e.attr('name'), v = getField(obj, k);
                if (v !== undefined && v !== null) {
                    if ($e.attr('type') === 'checkbox') $e.prop('checked', v === true || v === 1 || v === 'true');
                    else $e.val(v);
                }
            });
        },
        confirm: function (titulo, mensaje, onConfirm) {
            var id='modalConfirm';
            if($('#'+id).length)$('#'+id).remove();
            var h='<div class="modal fade" id="'+id+'" tabindex="-1"><div class="modal-dialog modal-sm modal-dialog-centered"><div class="modal-content" style="border-radius:14px;padding:24px;text-align:center;">';
            h+='<div style="width:56px;height:56px;border-radius:50%;background:#FFF3E0;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;"><i class="fas fa-question-circle" style="font-size:28px;color:#FF9800;"></i></div>';
            h+='<h5 style="margin:0 0 6px;font-weight:600;">'+(titulo||'Confirmar')+'</h5>';
            h+='<p style="margin:0 0 20px;color:#718096;font-size:0.85rem;">'+(mensaje||'')+'</p>';
            h+='<div style="display:flex;gap:10px;justify-content:center;"><button class="btn-soft outline" data-bs-dismiss="modal" style="min-width:100px;">Cancelar</button><button id="btnConfirmOk" class="btn-soft" style="min-width:100px;background:var(--primary);color:#fff;">Aceptar</button></div>';
            h+='</div></div></div>';
            $('body').append(h);
            var modal=new bootstrap.Modal(document.getElementById(id));
            $('#'+id).on('hidden.bs.modal',function(){$(this).remove();});
            $('#btnConfirmOk').off('click').on('click',function(){modal.hide();if(typeof onConfirm==='function')onConfirm();});
            modal.show();
        },
        initPagination: function (containerId, total, pagina, tamano, callback) {
            var h = renderPaginador(total, pagina, tamano);
            $('#' + containerId).html(h);
            $('#' + containerId + ' .pages button').off('click').on('click', function () {
                state.pagina = parseInt($(this).data('p'));
                if (typeof callback === 'function') callback();
            });
        }
    };
})();
var Toast = AdminApp.Toast;
