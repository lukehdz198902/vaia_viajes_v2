window.fnHome = (function () {
    function formatearMoneda(valor) {
        return '$' + Number(valor || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    function formatearFecha(fechaISO) {
        if (!fechaISO) return '--';
        var d = new Date(fechaISO);
        return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
    }

    function formatearHora(fechaISO) {
        if (!fechaISO) return '';
        var d = new Date(fechaISO);
        return d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
    }

    function calcularCambio(actual, anterior) {
        if (!anterior || anterior === 0) return { porcentaje: 100, clase: 'up', icono: 'fa-arrow-up' };
        var diff = ((actual - anterior) / anterior) * 100;
        return {
            porcentaje: Math.abs(diff).toFixed(1),
            clase: diff >= 0 ? 'up' : 'down',
            icono: diff >= 0 ? 'fa-arrow-up' : 'fa-arrow-down'
        };
    }

    function renderStatsCards(data) {
        var html = '';
        var cards = [
            { key: 'ingresos', label: 'Ingresos Totales', icono: 'fa-dollar-sign', clase: 'ingresos', valor: formatearMoneda(data.ingresos), cambio: data.cambioIngresos },
            { key: 'pasajeros', label: 'Pasajeros Activos', icono: 'fa-user', clase: 'pasajeros', valor: data.pasajeros || 0, cambio: data.cambioPasajeros },
            { key: 'conductores', label: 'Conductores', icono: 'fa-id-card', clase: 'conductores', valor: data.conductores || 0, cambio: data.cambioConductores },
            { key: 'viajes', label: 'Viajes Hoy', icono: 'fa-route', clase: 'viajes', valor: data.viajesHoy || 0, cambio: data.cambioViajes }
        ];
        cards.forEach(function (c) {
            var cambio = calcularCambio(c.valor, c.cambio);
            html += '<div class="col-md-6 col-xl-3 fade-in">';
            html += '  <div class="stat-card ' + c.clase + '">';
            html += '    <i class="fas ' + c.icono + ' stat-icon-bg"></i>';
            html += '    <div class="icon-circle"><i class="fas ' + c.icono + '"></i></div>';
            html += '    <div class="stat-label">' + c.label + '</div>';
            html += '    <div class="stat-value">' + c.valor + '</div>';
            html += '    <div class="stat-change ' + cambio.clase + '">';
            html += '      <i class="fas ' + cambio.icono + '"></i> ' + cambio.porcentaje + '% vs ayer';
            html += '    </div>';
            html += '  </div>';
            html += '</div>';
        });
        return html;
    }

    function renderTimeline(items) {
        if (!items || items.length === 0) {
            return '<div class="empty-state"><i class="fas fa-clock"></i><h5>Sin actividad reciente</h5></div>';
        }
        var html = '';
        items.forEach(function (item) {
            var dotClass = item.tipo === 'servicio' ? 'green' : item.tipo === 'incidente' ? 'pink' : '';
            var iconClass = item.accion === 'completado' ? 'fa-circle-check' : item.accion === 'cancelado' ? 'fa-circle-xmark' : 'fa-circle-info';
            html += '<div class="timeline-item">';
            html += '  <div class="dot ' + dotClass + '"></div>';
            html += '  <div class="time">' + formatearFecha(item.fecha) + ' ' + formatearHora(item.fecha) + '</div>';
            html += '  <div class="content"><i class="fas ' + iconClass + ' me-1"></i> ' + item.texto + '</div>';
            html += '</div>';
        });
        return html;
    }

    function renderServiciosTable(servicios) {
        if (!servicios || servicios.length === 0) {
            return '<div class="empty-state"><i class="fas fa-route"></i><h5>No hay servicios recientes</h5></div>';
        }
        var html = '<table class="table-custom">';
        html += '<thead><tr><th>ID</th><th>Pasajero</th><th>Conductor</th><th>Origen</th><th>Destino</th><th>Fecha</th><th>Monto</th><th>Estatus</th><th></th></tr></thead>';
        html += '<tbody>';
        servicios.forEach(function (s) {
            var statusClass = s.estatus === 'Completado' ? 'active' : s.estatus === 'Cancelado' ? 'inactive' : s.estatus === 'En Proceso' ? 'info' : 'pending';
            html += '<tr>';
            html += '  <td><strong>#' + s.idServicio + '</strong></td>';
            html += '  <td>' + (s.pasajero || '--') + '</td>';
            html += '  <td>' + (s.conductor || '--') + '</td>';
            html += '  <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">' + (s.origen || '--') + '</td>';
            html += '  <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">' + (s.destino || '--') + '</td>';
            html += '  <td>' + formatearFecha(s.fecha) + '</td>';
            html += '  <td><strong>' + formatearMoneda(s.monto) + '</strong></td>';
            html += '  <td><span class="status-badge ' + statusClass + '">' + (s.estatus || '--') + '</span></td>';
            html += '  <td><button class="accion-btn" onclick="window.verDetalleServicio(' + s.idServicio + ')" title="Ver detalle"><i class="fas fa-eye"></i></button></td>';
            html += '</tr>';
        });
        html += '</tbody></table>';
        return html;
    }

    return {
        formatearMoneda: formatearMoneda,
        formatearFecha: formatearFecha,
        formatearHora: formatearHora,
        renderStatsCards: renderStatsCards,
        renderTimeline: renderTimeline,
        renderServiciosTable: renderServiciosTable
    };
})();
