window.jnAjaxHome = (function () {
    var apiBase = window.__VAIA_API_BASE__ || 'https://vaia.com.mx/api_v2/api/';

    function _ajax(url, metodo, datos, onOk, onError) {
        $.ajax({
            url: apiBase + url,
            method: metodo || 'GET',
            contentType: 'application/json',
            data: metodo === 'GET' ? datos : (datos ? JSON.stringify(datos) : null),
            success: function (res) {
                if (typeof onOk === 'function') onOk(res);
            },
            error: function (xhr) {
                console.error('Error en API:', url, xhr.responseText);
                if (typeof onError === 'function') onError(xhr);
                else alert('Error al conectar con el servidor.');
            }
        });
    }

    function obtenerDashboard(onOk, onError) {
        _ajax('admin/ReporteServicios?fi=' + encodeURIComponent(new Date().toISOString().split('T')[0]) + '&ff=' + encodeURIComponent(new Date().toISOString().split('T')[0]), 'GET', null, onOk, onError);
    }

    function obtenerStats(onOk, onError) {
        _ajax('admin/ListarPasajeros?pagina=1&tamano=1', 'GET', null, null, null);
        _ajax('admin/ListarConductores?pagina=1&tamano=1', 'GET', null, null, null);
        _ajax('admin/ReporteIngresos?fi=' + encodeURIComponent(new Date().toISOString().split('T')[0]) + '&ff=' + encodeURIComponent(new Date().toISOString().split('T')[0]), 'GET', null, null, null);
        if (typeof onOk === 'function') onOk();
    }

    function obtenerUltimosServicios(pagina, tamano, onOk, onError) {
        var fi = new Date();
        fi.setDate(fi.getDate() - 7);
        var ff = new Date();
        _ajax('admin/ListarServicios?pagina=' + (pagina || 1) + '&tamano=' + (tamano || 10) + '&fi=' + fi.toISOString().split('T')[0] + '&ff=' + ff.toISOString().split('T')[0], 'GET', null, onOk, onError);
    }

    function obtenerActividadReciente(onOk, onError) {
        var fi = new Date();
        fi.setDate(fi.getDate() - 1);
        var ff = new Date();
        _ajax('admin/ListarAuditoria?pagina=1&tamano=10&fi=' + fi.toISOString().split('T')[0] + '&ff=' + ff.toISOString().split('T')[0], 'GET', null, onOk, onError);
    }

    return {
        obtenerDashboard: obtenerDashboard,
        obtenerStats: obtenerStats,
        obtenerUltimosServicios: obtenerUltimosServicios,
        obtenerActividadReciente: obtenerActividadReciente
    };
})();
