window.fnHome = (function () {
    function formatearMoneda(valor) {
        return '$' + Number(valor || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    function formatearFecha(fechaISO) {
        if (!fechaISO) return '--';
        var d = new Date(fechaISO);
        if (isNaN(d)) return '--';
        return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
    }

    function formatearHora(fechaISO) {
        if (!fechaISO) return '';
        var d = new Date(fechaISO);
        if (isNaN(d)) return '';
        return d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
    }

    function tiempoRelativo(fechaISO) {
        if (!fechaISO) return '';
        var d = new Date(fechaISO);
        if (isNaN(d)) return '';
        var diff = (Date.now() - d.getTime()) / 1000;
        if (diff < 60) return 'hace ' + Math.floor(diff) + 's';
        if (diff < 3600) return 'hace ' + Math.floor(diff / 60) + ' min';
        if (diff < 86400) return 'hace ' + Math.floor(diff / 3600) + ' h';
        return 'hace ' + Math.floor(diff / 86400) + ' d';
    }

    function calcularCambio(actual, anterior) {
        if (!anterior || anterior === 0) return { porcentaje: '0.0', clase: 'up', icono: 'fa-arrow-up', sentido: 'up' };
        var diff = ((actual - anterior) / anterior) * 100;
        return {
            porcentaje: Math.abs(diff).toFixed(1),
            clase: diff >= 0 ? 'up' : 'down',
            icono: diff >= 0 ? 'fa-arrow-up' : 'fa-arrow-down',
            sentido: diff >= 0 ? 'up' : 'down'
        };
    }

    function renderStatsCards(data) {
        var cards = [
            { key: 'ingresos',    label: 'Ingresos totales',  icono: 'fa-dollar-sign',  valor: formatearMoneda(data.ingresos), cambio: data.cambioIngresos,   cambioLabel: 'vs ayer' },
            { key: 'pasajeros',   label: 'Pasajeros activos', icono: 'fa-users',        valor: data.pasajeros || 0,             cambio: data.cambioPasajeros,  cambioLabel: 'vs ayer' },
            { key: 'conductores', label: 'Conductores',       icono: 'fa-id-card',      valor: data.conductores || 0,           cambio: data.cambioConductores,cambioLabel: 'vs ayer' },
            { key: 'viajes',      label: 'Viajes hoy',       icono: 'fa-route',        valor: data.viajesHoy || 0,             cambio: data.cambioViajes,     cambioLabel: 'vs ayer' }
        ];

        var html = '';
        cards.forEach(function (c) {
            var cambio = calcularCambio(parseFloat(String(c.valor).replace(/[^0-9.-]/g, '')) || 0, c.cambio);
            var deltaCls = cambio.sentido === 'up' ? 'kpi-card__delta--up' : 'kpi-card__delta--down';
            html += '<article class="kpi-card">';
            html += '  <div class="kpi-card__icon"><i class="fas ' + c.icono + '"></i></div>';
            html += '  <div class="kpi-card__label">' + c.label + '</div>';
            html += '  <div class="kpi-card__value" data-countup="' + (parseFloat(String(c.valor).replace(/[^0-9.-]/g, '')) || 0) + '" data-format="currency">' + c.valor + '</div>';
            html += '  <div class="kpi-card__delta ' + deltaCls + '"><i class="fas ' + cambio.icono + '"></i> ' + cambio.porcentaje + '% ' + c.cambioLabel + '</div>';
            html += '</article>';
        });
        return html;
    }

    function renderSkeletonStats(count) {
        var html = '';
        for (var i = 0; i < (count || 4); i++) {
            html += '<article class="kpi-card">';
            html += '  <div class="skeleton" style="width:44px;height:44px;border-radius:12px;"></div>';
            html += '  <div class="skeleton skeleton--text"></div>';
            html += '  <div class="skeleton skeleton--value"></div>';
            html += '  <div class="skeleton skeleton--text-sm"></div>';
            html += '</article>';
        }
        return html;
    }

    function renderTimeline(items) {
        if (!items || items.length === 0) {
            return '<div class="empty-state"><div class="empty-state__icon"><i class="fas fa-clock"></i></div><h4 class="empty-state__title">Sin actividad reciente</h4><p class="empty-state__message">Cuando haya acciones en el sistema, apareceran aqui.</p></div>';
        }
        var html = '';
        items.forEach(function (item) {
            var iconCls = 'activity-icon';
            var icon = 'fa-circle-info';
            if (item.tipo === 'servicio' || item.accion === 'completado') { icon = 'fa-circle-check'; }
            else if (item.accion === 'cancelado' || item.tipo === 'incidente') { icon = 'fa-circle-xmark'; iconCls += ' activity-icon--danger'; }
            else if (item.tipo === 'warning') { iconCls += ' activity-icon--warning'; }
            else if (item.tipo === 'info') { iconCls += ' activity-icon--info'; }

            html += '<div class="activity-item">';
            html += '  <div class="' + iconCls + '"><i class="fas ' + icon + '"></i></div>';
            html += '  <div class="activity-content">';
            html += '    <div class="activity-title">' + (item.texto || '') + '</div>';
            html += '    <div class="activity-meta">' + tiempoRelativo(item.fecha) + ' &middot; ' + formatearFecha(item.fecha) + ' ' + formatearHora(item.fecha) + '</div>';
            html += '  </div>';
            html += '</div>';
        });
        return html;
    }

    function badgeClass(estatus) {
        var e = (estatus || '').toLowerCase();
        if (e.indexOf('complet') >= 0 || e.indexOf('finaliz') >= 0 || e.indexOf('pagado') >= 0) return 'badge--success';
        if (e.indexOf('cancel') >= 0 || e.indexOf('rechaz') >= 0) return 'badge--danger';
        if (e.indexOf('proceso') >= 0 || e.indexOf('camino') >= 0 || e.indexOf('viaje') >= 0) return 'badge--info';
        if (e.indexOf('pendiente') >= 0 || e.indexOf('espera') >= 0) return 'badge--warning';
        return 'badge--neutral';
    }

    function escapeHtml(str) {
        if (str == null) return '';
        return String(str).replace(/[&<>"']/g, function (m) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[m];
        });
    }

    function renderServiciosTable(servicios) {
        if (!servicios || servicios.length === 0) {
            return '<div class="empty-state"><div class="empty-state__icon"><i class="fas fa-route"></i></div><h4 class="empty-state__title">No hay servicios recientes</h4><p class="empty-state__message">Los servicios registrados en los ultimos dias apareceran aqui.</p></div>';
        }
        var html = '<div class="data-table-wrap"><table class="data-table records-table">';
        html += '<thead><tr>';
        html += '<th class="col-id">ID</th>';
        html += '<th>Pasajero</th>';
        html += '<th>Conductor</th>';
        html += '<th>Ruta</th>';
        html += '<th>Fecha</th>';
        html += '<th>Monto</th>';
        html += '<th class="col-status">Estatus</th>';
        html += '<th class="col-actions"></th>';
        html += '</tr></thead><tbody>';
        servicios.forEach(function (s) {
            var pasajeroFull = ((s.pasajeroNombre || '') + ' ' + (s.pasajeroApellido || '')).trim() || s.pasajero || '--';
            var conductorFull = ((s.conductorNombre || '') + ' ' + (s.conductorApellido || '')).trim() || s.conductor || '--';
            html += '<tr>';
            html += '  <td class="col-id">#' + s.id + '</td>';
            html += '  <td><div class="col-name">' + escapeHtml(pasajeroFull) + '</div><div class="col-meta">' + escapeHtml(s.pasajeroTelefono || '') + '</div></td>';
            html += '  <td><div class="col-name">' + escapeHtml(conductorFull) + '</div></td>';
            html += '  <td class="td-truncate" title="' + escapeHtml((s.origen || '') + ' -> ' + (s.destino || '')) + '">' + escapeHtml(s.origen || '--') + ' &rarr; ' + escapeHtml(s.destino || '--') + '</td>';
            html += '  <td>' + formatearFecha(s.fecha) + ' ' + formatearHora(s.fecha) + '</td>';
            html += '  <td><strong>' + formatearMoneda(s.monto) + '</strong></td>';
            html += '  <td class="col-status"><span class="badge ' + badgeClass(s.estatus) + '"><span class="dot"></span>' + escapeHtml(s.estatus || '--') + '</span></td>';
            html += '  <td class="col-actions"><button class="btn btn--ghost btn--icon btn--sm" onclick="window.verDetalleServicio(' + s.id + ')" title="Ver detalle" aria-label="Ver detalle"><i class="fas fa-eye"></i></button></td>';
            html += '</tr>';
        });
        html += '</tbody></table></div>';
        return html;
    }

    function getCssVar(name) {
        return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    }

    function chartColors() {
        var accent = getCssVar('--accent') || '#14B8A6';
        var accentLight = getCssVar('--accent-200') || '#99F6E4';
        var text = getCssVar('--text-muted') || '#64748B';
        var border = getCssVar('--border') || '#E2E8F0';
        var surface2 = getCssVar('--surface-2') || '#F8FAFC';

        function hexToRgba(hex, a) {
            var h = (hex || '').replace('#', '');
            if (h.length === 3) h = h.split('').map(function (c) { return c + c; }).join('');
            var n = parseInt(h, 16);
            var r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
            return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')';
        }

        return {
            accent: accent,
          accentFill: hexToRgba(accent, 0.12),
          accentFillStrong: hexToRgba(accent, 0.25),
            accentSoft: accentLight,
          text: text,
          gridBorder: border,
            surface2: surface2,
            hexToRgba: hexToRgba
        };
    }

    return {
        formatearMoneda: formatearMoneda,
        formatearFecha: formatearFecha,
        formatearHora: formatearHora,
        tiempoRelativo: tiempoRelativo,
        escapeHtml: escapeHtml,
        renderStatsCards: renderStatsCards,
        renderSkeletonStats: renderSkeletonStats,
        renderTimeline: renderTimeline,
        renderServiciosTable: renderServiciosTable,
        badgeClass: badgeClass,
        chartColors: chartColors
    };
})();