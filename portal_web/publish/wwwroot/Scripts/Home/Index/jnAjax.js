window.jnAjaxHome = (function () {
    var apiBase = window.__VAIA_API_BASE__ || (function() {
        var stored = localStorage.getItem('vaia_api_base');
        return stored || 'https://vaia.com.mx/api_v2/api/';
    })();

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
                console.error('API Error:', url, xhr.responseText);
                if (typeof onError === 'function') onError(xhr);
            }
        });
    }

    function obtenerUltimosServicios(pagina, tamano, onOk, onError) {
        var fi = new Date(); fi.setDate(fi.getDate() - 7);
        var ff = new Date();
        _ajax('admin/ListarServicios?pagina=' + (pagina || 1) + '&tamano=' + (tamano || 10) + '&fi=' + fi.toISOString().split('T')[0] + '&ff=' + ff.toISOString().split('T')[0], 'GET', null, onOk, onError);
    }

    function obtenerActividadReciente(onOk, onError) {
        var fi = new Date(); fi.setDate(fi.getDate() - 1);
        var ff = new Date();
        _ajax('admin/ListarAuditoria?pagina=1&tamano=10&fi=' + fi.toISOString().split('T')[0] + '&ff=' + ff.toISOString().split('T')[0], 'GET', null, onOk, onError);
    }

    return { obtenerUltimosServicios: obtenerUltimosServicios, obtenerActividadReciente: obtenerActividadReciente };
})();
