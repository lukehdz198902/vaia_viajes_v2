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
        var stats = {
            ingresos: 45890.00,
            cambioIngresos: 38500.00,
            pasajeros: 284,
            cambioPasajeros: 250,
            conductores: 96,
            cambioConductores: 88,
            viajesHoy: 47,
            cambioViajes: 42
        };
        $('#dvStatsCards').html(window.fnHome.renderStatsCards(stats));
    }

    function cargarServicios() {
        window.jnAjaxHome.obtenerUltimosServicios(1, 10, function (res) {
            var data = res && res.data ? res.data : (Array.isArray(res) ? res : []);
            var servicios = data.slice(0, 10).map(function (s) {
                return {
                    idServicio: s.IdServicio || s.idServicio || 0,
                    pasajero: s.NombrePasajero || s.pasajero || '--',
                    conductor: s.NombreConductor || s.conductor || '--',
                    origen: s.DirOrigen || s.origen || '--',
                    destino: s.DirDestino || s.destino || '--',
                    fecha: s.FechaServicio || s.fecha || null,
                    monto: s.MontoTotal || s.monto || 0,
                    estatus: s.EstatusViaje || s.estatus || '--'
                };
            });
            $('#dvTablaServicios').html(window.fnHome.renderServiciosTable(servicios));
        });
    }

    function cargarActividad() {
        window.jnAjaxHome.obtenerActividadReciente(function (res) {
            var data = res && res.data ? res.data : (Array.isArray(res) ? res : []);
            var items = data.slice(0, 6).map(function (a) {
                return {
                    fecha: a.Fecha || a.fecha || new Date(),
                    texto: (a.Accion || a.accion || '') + ' en ' + (a.Tabla || a.tabla || ''),
                    tipo: 'general',
                    accion: 'info'
                };
            });
            if (items.length === 0) {
                items = [
                    { fecha: new Date(), texto: 'Nuevo servicio <strong>#1243</strong> completado', tipo: 'servicio', accion: 'completado' },
                    { fecha: new Date(Date.now() - 3600000), texto: 'Conductor <strong>Juan Perez</strong> asignado', tipo: 'servicio', accion: 'info' },
                    { fecha: new Date(Date.now() - 7200000), texto: 'Incidente <strong>#89</strong> reportado', tipo: 'incidente', accion: 'info' },
                    { fecha: new Date(Date.now() - 10800000), texto: 'Pago de <strong>$450.00</strong> procesado', tipo: 'general', accion: 'completado' }
                ];
            }
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
                    borderColor: '#5B6ABF',
                    backgroundColor: 'rgba(91, 106, 191, 0.08)',
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: '#5B6ABF',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    borderWidth: 2
                }, {
                    label: 'Meta',
                    data: [3500, 3500, 3500, 5000, 5000, 5000, 5000],
                    borderColor: '#6CC4A1',
                    backgroundColor: 'transparent',
                    borderDash: [6, 4],
                    fill: false,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 0,
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        labels: { usePointStyle: true, padding: 16, font: { size: 12 } }
                    },
                    tooltip: {
                        backgroundColor: '#2D3748',
                        titleFont: { size: 12 },
                        bodyFont: { size: 13 },
                        padding: 12,
                        cornerRadius: 8
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(0,0,0,0.04)', drawBorder: false },
                        ticks: { font: { size: 11 }, color: '#718096' }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { font: { size: 11 }, color: '#718096' }
                    }
                }
            }
        });
    }

    window.cambiarPeriodo = function (periodo) {
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
        alert('Detalle del servicio #' + id);
    };

    function inicializarEventos() {
        $('#txtBuscarServicio').on('keyup', function () {
            var termino = $(this).val().toLowerCase();
            $('#dvTablaServicios .table-custom tbody tr').each(function () {
                var texto = $(this).text().toLowerCase();
                $(this).toggle(texto.indexOf(termino) > -1);
            });
        });
    }

    inicializar();
});
