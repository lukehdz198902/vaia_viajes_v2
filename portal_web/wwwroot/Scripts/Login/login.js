(function () {
    var apiBase = window.__VAIA_API_BASE__;
    if (!apiBase) {
        console.error('[Vaia] __VAIA_API_BASE__ no esta definido. Verifica que _VaiaConfig.cshtml se haya renderizado y que appsettings.json tenga la clave VaiaApi:BaseUrl.');
        apiBase = '';
    }

    var $form = $('#frmLogin');
    var $account = $('#txtAccount');
    var $pass = $('#txtPass');
    var $btn = $('#btnLogin');
    var $btnLabel = $btn.find('.btn-label');
    var $spinner = $btn.find('.btn-spinner');
    var $error = $('#dvError');
    var $togglePass = $('#btnTogglePass');

    $togglePass.on('click', function () {
        var isPassword = $pass.attr('type') === 'password';
        $pass.attr('type', isPassword ? 'text' : 'password');
        $togglePass.find('i').toggleClass('fa-eye fa-eye-slash');
        $togglePass.attr('aria-label', isPassword ? 'Ocultar contrasena' : 'Mostrar contrasena');
    });

    $form.on('submit', function (e) {
        e.preventDefault();
        var account = $account.val().trim();
        var pass = $pass.val().trim();
        if (!account || !pass) {
            mostrarError('Ingrese usuario y contrasena');
            return;
        }

        setLoading(true);
        hideError();

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
                    mostrarError(msg.mensaje || msg.message || 'Error del servidor');
                } catch (e) {
                    mostrarError('Error al conectar con el servidor');
                }
            },
            complete: function () {
                setLoading(false);
            }
        });
    });

    function setLoading(loading) {
        $btn.prop('disabled', loading);
        $btn.toggleClass('is-loading', loading);
        $btnLabel.text(loading ? 'Ingresando...' : 'Ingresar');
    }

    function mostrarError(msg) {
        $error.html('<i class="fas fa-exclamation-circle"></i> ' + msg).addClass('is-visible');
    }

    function hideError() {
        $error.removeClass('is-visible').empty();
    }

    $account.add($pass).on('input', hideError);
})();