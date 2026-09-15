$(function () {
    window.chartIngresos = null;

    function inicializar() {
        cargarStats();
        cargarServicios();
        cargarActividad();
        inicializarChart();
        inicializarEventos();
        aplicarTemaChart();
    }

    function cargarStats() {
        $('#dvStatsCards').html(window.fnHome.renderSkeletonStats(4));
        setTimeout(function () {
            var stats = { ingresos: 45890.00, cambioIngresos: 38500.00, pasajeros: 284, cambioPasajeros: 250, conductores: 96, cambioConductores: 88, viajesHoy: 47, cambioViajes: 42 };
            $('#dvStatsCards').html(window.fnHome.renderStatsCards(stats));
            if (window.VaiaUI && typeof window.VaiaUI.countUp === 'function') {
                window.VaiaUI.countUp('#dvStatsCards [data-countup]');
            }
        }, 300);
    }

    function cargarServicios() {
        if (window.jnAjaxHome && typeof window.jnAjaxHome.obtenerUltimosServicios === 'function') {
            window.jnAjaxHome.obtenerUltimosServicios(1, 10, function (res) {
                var data = Array.isArray(res) ? res : (res && res.data ? res.data : []);
                var servicios = data.slice(0, 10).map(function (s) {
                    return {
                        id: s.Id || s.id || s.IdServicio || s.idServicio || 0,
                        pasajeroNombre: s.P_nombre || s.p_nombre || s.NombrePasajero || '',
                        pasajeroApellido: s.P_appaterno || s.p_appaterno || '',
                        pasajeroTelefono: s.P_tel || s.p_tel || s.telefono || '',
                        pasajero: s.Pasajero || s.pasajero || '',
                        conductorNombre: s.C_nombre || s.c_nombre || s.NombreConductor || '',
                        conductorApellido: s.C_appaterno || s.c_appaterno || '',
                        conductor: s.Conductor || s.conductor || '',
                        origen: s.Direccionorigen || s.direccionorigen || s.DirOrigen || s.origen || '--',
                        destino: s.Direcciondestination || s.direcciondestination || s.DirDestino || s.destino || '--',
                        fecha: s.Fechacreacion || s.fechacreacion || s.FechaServicio || s.fecha || null,
                        monto: s.Costoestimado || s.costoestimado || s.MontoTotal || s.monto || 0,
                        estatus: s.Estatus || s.estatus || s.EstatusViaje || '--'
                    };
                });
                $('#dvTablaServicios').html(window.fnHome.renderServiciosTable(servicios));
            }, function () {
                $('#dvTablaServicios').html('<div class="alert alert--danger">No se pudieron cargar los servicios.</div>');
            });
        } else {
            $('#dvTablaServicios').html('<div class="empty-state"><div class="empty-state__icon"><i class="fas fa-route"></i></div><h4 class="empty-state__title">Sin servicios</h4><p class="empty-state__message">No hay servicios para mostrar.</p></div>');
        }
    }

    function cargarActividad() {
        if (window.jnAjaxHome && typeof window.jnAjaxHome.obtenerActividadReciente === 'function') {
            window.jnAjaxHome.obtenerActividadReciente(function (res) {
                var data = Array.isArray(res) ? res : (res && res.data ? res.data : []);
                var items = data.slice(0, 8).map(function (a) {
                    var tabla = a.Tablaafectada || a.tablaafectada || a.Tabla || a.tabla || '';
                    var accion = (a.Accion || a.accion || '').toUpperCase();
                    var tipo = 'info';
                    if (tabla.toLowerCase().indexOf('incidente') >= 0) tipo = 'incidente';
                    else if (accion === 'CANCELADO' || accion === 'BLOQUEO') tipo = 'incidente';
                    return { fecha: a.Fechacreacion || a.fechacreacion || a.Fecha || a.fecha || new Date(), texto: accion + (tabla ? ' en ' + tabla : ''), tipo: tipo, accion: accion.toLowerCase() };
                });
                $('#dvActividad').html(window.fnHome.renderTimeline(items));
            }, function () {
                $('#dvActividad').html('<div class="empty-state"><div class="empty-state__icon"><i class="fas fa-clock"></i></div><h4 class="empty-state__title">Sin actividad</h4></div>');
            });
        } else {
            $('#dvActividad').html(window.fnHome.renderTimeline([]));
        }
    }

    function inicializarChart() {
        var ctx = document.getElementById('chartIngresos');
        if (!ctx) return;
        var c = window.fnHome.chartColors();
        window.chartIngresos = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'],
                datasets: [{
                    label: 'Ingresos',
                    data: [3200, 4100, 3800, 5200, 4900, 6100, 5800],
                    borderColor: c.accent,
                    backgroundColor: c.accentFill,
                    fill: true, tension: 0.4,
                    pointBackgroundColor: c.accent,
                    pointBorderColor: '#fff', pointBorderWidth: 2,
                    pointRadius: 4, pointHoverRadius: 7,
                    borderWidth: 2.5
                }, {
                    label: 'Meta',
                    data: [3500, 3500, 3500, 5000, 5000, 5000, 5000],
                    borderColor: c.hexToRgba(c.text, 0.5),
                    backgroundColor: 'transparent',
                    borderDash: [6, 4], fill: false, tension: 0.4,
                    pointRadius: 0, pointHoverRadius: 0,
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                interaction: { mode: 'index', intersect: false },
                plugins: {
                    legend: {
                        display: true, position: 'top', align: 'end',
                        labels: { usePointStyle: true, padding: 14, font: { size: 11 }, color: c.text }
                    },
                    tooltip: {
                        backgroundColor: 'rgba(15, 23, 42, 0.92)',
                        titleFont: { size: 11, weight: '600' },
                        bodyFont: { size: 12 },
                        padding: 10, cornerRadius: 8, displayColors: true,
                        boxPadding: 4
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: c.hexToRgba(c.gridBorder, 0.5), drawBorder: false },
                        ticks: { font: { size: 10 }, color: c.text, callback: function (v) { return '$' + v.toLocaleString('es-MX'); } }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { font: { size: 10 }, color: c.text }
                    }
                },
                animation: { duration: 800, easing: 'easeOutQuart' }
            }
        });
    }

    function aplicarTemaChart() {
        if (!window.chartIngresos) return;
        var c = window.fnHome.chartColors();
        var ds = window.chartIngresos.data.datasets;
        ds[0].borderColor = c.accent;
        ds[0].backgroundColor = c.accentFill;
        ds[0].pointBackgroundColor = c.accent;
        ds[1].borderColor = c.hexToRgba(c.text, 0.5);
        if (window.chartIngresos.options.scales.y) {
            window.chartIngresos.options.scales.y.grid.color = c.hexToRgba(c.gridBorder, 0.5);
            window.chartIngresos.options.scales.y.ticks.color = c.text;
        }
        if (window.chartIngresos.options.scales.x) {
            window.chartIngresos.options.scales.x.ticks.color = c.text;
        }
        if (window.chartIngresos.options.plugins.legend) {
            window.chartIngresos.options.plugins.legend.labels.color = c.text;
        }
        window.chartIngresos.update('none');
    }

    function cambiarPeriodo(periodo) {
        if (!window.chartIngresos) return;
        var lbl = document.getElementById('lblPeriodo');
        if (periodo === 'mes') {
            window.chartIngresos.data.labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
            window.chartIngresos.data.datasets[0].data = [18500, 21000, 19800, 22400];
            window.chartIngresos.data.datasets[1].data = [18000, 18000, 20000, 20000];
            if (lbl) lbl.textContent = 'Ultimo mes';
        } else {
            window.chartIngresos.data.labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
            window.chartIngresos.data.datasets[0].data = [3200, 4100, 3800, 5200, 4900, 6100, 5800];
            window.chartIngresos.data.datasets[1].data = [3500, 3500, 3500, 5000, 5000, 5000, 5000];
            if (lbl) lbl.textContent = 'Ultimos 7 dias';
        }
        window.chartIngresos.update();
    }

    window.cambiarPeriodo = cambiarPeriodo;
    window.verDetalleServicio = function (id) { window.location.href = '/Home/Servicios'; };

    function inicializarEventos() {
        $('#txtBuscarServicio').on('input', function () {
            var termino = $(this).val().toLowerCase();
            $('#dvTablaServicios .data-table tbody tr').each(function () {
                $(this).toggle($(this).text().toLowerCase().indexOf(termino) > -1);
            });
        });

        $('[data-period]').on('click', function () {
            $('[data-period]').removeClass('btn--soft').addClass('btn--ghost');
            $(this).removeClass('btn--ghost').addClass('btn--soft');
            cambiarPeriodo($(this).data('period'));
        });

        $('#btnRefreshDashboard').on('click', function () {
            cargarStats();
            cargarServicios();
            cargarActividad();
            if (window.VaiaUI && typeof window.VaiaUI.toast === 'function') {
                window.VaiaUI.toast({ type: 'accent', title: 'Actualizado', message: 'Dashboard sincronizado' });
            }
        });

        window.addEventListener('vaia:theme-changed', aplicarTemaChart);
    }

    inicializar();
});