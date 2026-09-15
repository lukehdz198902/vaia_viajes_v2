$(function () {
    window.chartIngresos = null;

    function inicializar() {
        cargarStats();
        cargarServicios();
        cargarActividad();
        inicializarChart();
        inicializarEventos();
    }

    function cargarStats() {
        var stats = { ingresos: 45890.00, cambioIngresos: 38500.00, pasajeros: 284, cambioPasajeros: 250, conductores: 96, cambioConductores: 88, viajesHoy: 47, cambioViajes: 42 };
        $('#dvStatsCards').html(window.fnHome.renderStatsCards(stats));
    }

    function cargarServicios() {
        window.jnAjaxHome.obtenerUltimosServicios(1, 10, function (res) {
            var data = Array.isArray(res) ? res : (res && res.data ? res.data : []);
            var servicios = data.slice(0, 10).map(function (s) {
                var pNombre = s.P_nombre || s.p_nombre || s.NombrePasajero || s.pasajero || s.Pasajero || '';
                var pApe = s.P_appaterno || s.p_appaterno || '';
                var cNombre = s.C_nombre || s.c_nombre || s.NombreConductor || s.conductor || s.Conductor || '';
                var cApe = s.C_appaterno || s.c_appaterno || '';
                return {
                    idServicio: s.Id || s.id || s.IdServicio || s.idServicio || 0,
                    pasajero: (pNombre + ' ' + pApe).trim() || '--',
                    conductor: (cNombre + ' ' + cApe).trim() || '--',
                    origen: s.Direccionorigen || s.direccionorigen || s.DirOrigen || s.origen || s.DireccionOrigen || '--',
                    destino: s.Direcciondestination || s.direcciondestination || s.DirDestino || s.destino || s.DireccionDestination || '--',
                    fecha: s.Fechacreacion || s.fechacreacion || s.FechaServicio || s.fecha || s.FechaCreacion || null,
                    monto: s.Costoestimado || s.costoestimado || s.MontoTotal || s.monto || 0,
                    estatus: s.Estatus || s.estatus || s.EstatusViaje || '--'
                };
            });
            $('#dvTablaServicios').html(window.fnHome.renderServiciosTable(servicios));
        });
    }

    function cargarActividad() {
        window.jnAjaxHome.obtenerActividadReciente(function (res) {
            var data = Array.isArray(res) ? res : (res && res.data ? res.data : []);
            if (data.length === 0) {
                $('#dvTimeline').html('<div class="empty-state"><i class="fas fa-clock"></i><h5>Sin actividad reciente</h5></div>');
                return;
            }
            var items = data.slice(0, 6).map(function (a) {
                var tabla = a.Tablaafectada || a.tablaafectada || a.Tabla || a.tabla || '';
                return { fecha: a.Fechacreacion || a.fechacreacion || a.Fecha || a.fecha || new Date(), texto: (a.Accion || a.accion || '') + ' en ' + tabla, tipo: 'general', accion: 'info' };
            });
            $('#dvTimeline').html(window.fnHome.renderTimeline(items));
        });
    }

    function inicializarChart() {
        var ctx = document.getElementById('chartIngresos');
        if (!ctx) return;
        window.chartIngresos = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'],
                datasets: [{
                    label: 'Ingresos',
                    data: [3200, 4100, 3800, 5200, 4900, 6100, 5800],
                    borderColor: '#00B4D8', backgroundColor: 'rgba(0,180,216,0.08)',
                    fill: true, tension: 0.4, pointBackgroundColor: '#00B4D8',
                    pointBorderColor: '#fff', pointBorderWidth: 2, pointRadius: 4, pointHoverRadius: 6, borderWidth: 2
                }, {
                    label: 'Meta',
                    data: [3500, 3500, 3500, 5000, 5000, 5000, 5000],
                    borderColor: '#FFD166', backgroundColor: 'transparent',
                    borderDash: [6, 4], fill: false, tension: 0.4, pointRadius: 0, pointHoverRadius: 0, borderWidth: 2
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: {
                    legend: { display: true, position: 'top', labels: { usePointStyle: true, padding: 14, font: { size: 11 } } },
                    tooltip: { backgroundColor: '#2D3748', titleFont: { size: 11 }, bodyFont: { size: 12 }, padding: 10, cornerRadius: 8 }
                },
                scales: {
                    y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.04)', drawBorder: false }, ticks: { font: { size: 10 }, color: '#718096' } },
                    x: { grid: { display: false }, ticks: { font: { size: 10 }, color: '#718096' } }
                }
            }
        });
    }

    window.cambiarPeriodo = function (periodo) {
        if (!window.chartIngresos) return;
        if (periodo === 'mes') {
            window.chartIngresos.data.labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
            window.chartIngresos.data.datasets[0].data = [18500, 21000, 19800, 22400];
            window.chartIngresos.data.datasets[1].data = [18000, 18000, 20000, 20000];
        } else {
            window.chartIngresos.data.labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
            window.chartIngresos.data.datasets[0].data = [3200, 4100, 3800, 5200, 4900, 6100, 5800];
            window.chartIngresos.data.datasets[1].data = [3500, 3500, 3500, 5000, 5000, 5000, 5000];
        }
        window.chartIngresos.update();
    };

    window.verDetalleServicio = function (id) {
        window.location.href = '/Home/Servicios';
    };

    function inicializarEventos() {
        $('#txtBuscarServicio').on('keyup', function () {
            var termino = $(this).val().toLowerCase();
            $('#dvTablaServicios .table-custom tbody tr').each(function () {
                $(this).toggle($(this).text().toLowerCase().indexOf(termino) > -1);
            });
        });
    }

    inicializar();
});
