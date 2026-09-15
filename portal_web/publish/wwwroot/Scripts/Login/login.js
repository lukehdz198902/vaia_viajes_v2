(function () {
    var apiBase = window.__VAIA_API_BASE__ || 'https://vaia.com.mx/api_v2/api/';

    $('#btnTogglePass').on('click', function () {
        var $input = $('#txtPass');
        var type = $input.attr('type') === 'password' ? 'text' : 'password';
        $input.attr('type', type);
        $(this).find('i').toggleClass('fa-eye fa-eye-slash');
    });

    $('#frmLogin').on('submit', function (e) {
        e.preventDefault();
        var account = $('#txtAccount').val().trim();
        var pass = $('#txtPass').val().trim();
        if (!account || !pass) { mostrarError('Ingrese usuario y contrasena'); return; }

        $('#btnLogin').prop('disabled', true);
        $('#lblBtnText').text('Ingresando...');
        $('#spinnerBtn').removeClass('d-none');
        $('#dvError').addClass('d-none');

        $.ajax({
            url: apiBase + 'admin/IniciarSesion',
            method: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ account: account, pass: pass }),
            success: function (res) {
                var data = Array.isArray(res) ? res[0] : res;
                if (data && data.id && data.id > 0) {
                    sessionStorage.setItem('usr_id', data.id);
                    sessionStorage.setItem('usr_nombre', data.nombre || '');
                    sessionStorage.setItem('usr_appaterno', data.appaterno || '');
                    sessionStorage.setItem('usr_account', data.account || account);
                    sessionStorage.setItem('usr_rol', data.rolnombre || data.rol || '');
                    sessionStorage.setItem('usr_idRol', data.idRol || data.idrol || '');
                    sessionStorage.setItem('usr_correo', data.correo || '');
                    sessionStorage.setItem('usr_idCompania', data.idcompania || data.idCompania || '');
                    window.location.href = '/Home/Index';
                } else {
                    mostrarError(data && data.mensaje ? data.mensaje : 'Credenciales invalidas');
                }
            },
            error: function (xhr) {
                try {
                    var msg = JSON.parse(xhr.responseText);
                    mostrarError(msg.mensaje || 'Error del servidor');
                } catch (e) {
                    mostrarError('Error al conectar con el servidor');
                }
            },
            complete: function () {
                $('#btnLogin').prop('disabled', false);
                $('#lblBtnText').text('Ingresar');
                $('#spinnerBtn').addClass('d-none');
            }
        });
    });

    function mostrarError(msg) {
        $('#dvError').text(msg).removeClass('d-none');
    }

    $('#txtAccount, #txtPass').on('keydown', function () {
        $('#dvError').addClass('d-none');
    });
})();
