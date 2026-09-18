using System;

namespace VaiaViajes.Api.Services
{
    /// <summary>
    /// Plantillas de correo con el logotipo de Vaia (adjunto como cid:vaialogo).
    /// </summary>
    public static class EmailTemplates
    {
        public static string Base(string titulo, string contenidoHtml, string subtitulo = "Vaia Conductor")
        {
            return "<div style=\"font-family:Arial,Helvetica,sans-serif;background:#f1f5f9;padding:26px;\">"
                + "<div style=\"max-width:560px;margin:auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 10px 30px rgba(15,23,42,0.10);\">"
                + "<div style=\"background:#0F172A;padding:24px;text-align:center;\">"
                + "<img src=\"cid:vaialogo\" alt=\"Vaia\" style=\"height:56px;\" />"
                + "<div style=\"color:#ffffff;font-size:20px;font-weight:800;margin-top:10px;letter-spacing:-0.3px;\">" + subtitulo + "</div>"
                + "</div>"
                + "<div style=\"padding:28px;\">"
                + "<h2 style=\"margin:0 0 14px;color:#0F172A;font-size:18px;font-weight:700;\">" + titulo + "</h2>"
                + contenidoHtml
                + "</div>"
                + "<div style=\"background:#f8fafc;padding:14px 28px;color:#94a3b8;font-size:12px;text-align:center;\">"
                + "Mensaje automatico de Vaia Viajes. No respondas a este correo."
                + "</div>"
                + "</div></div>";
        }

        public static string CodigoVerificacion(string nombre, string codigo)
        {
            var c = "<p style=\"margin:0 0 12px;color:#475569;\">Hola " + nombre + ",</p>"
                + "<p style=\"margin:0 0 16px;color:#475569;\">Usa el siguiente codigo para verificar tu correo electronico:</p>"
                + "<div style=\"text-align:center;margin:20px 0;\">"
                + "<span style=\"display:inline-block;background:#FEF3C7;color:#92400E;font-size:30px;font-weight:800;letter-spacing:8px;padding:14px 24px;border-radius:12px;\">" + codigo + "</span>"
                + "</div>"
                + "<p style=\"margin:0;color:#94a3b8;font-size:13px;\">El codigo expira en 15 minutos. Si no lo solicitaste, ignora este mensaje.</p>";
            return Base("Verifica tu correo", c);
        }

        public static string Bienvenida(string nombre)
        {
            var c = "<p style=\"margin:0 0 12px;color:#475569;\">Hola " + nombre + ",</p>"
                + "<p style=\"margin:0 0 12px;color:#475569;\">Tu cuenta de conductor fue creada correctamente.</p>"
                + "<p style=\"margin:0;color:#475569;\">El siguiente paso es <b>subir tu documentacion</b> para que sea revisada. Una vez aprobada podras conectarte y empezar a recibir servicios.</p>";
            return Base("Bienvenido a Vaia Conductor", c);
        }

        public static string DocumentacionAprobada(string nombre)
        {
            var c = "<p style=\"margin:0 0 12px;color:#475569;\">Hola " + nombre + ",</p>"
                + "<p style=\"margin:0 0 12px;color:#475569;\">Tu documentacion fue <b style=\"color:#059669;\">aprobada</b>. Ya puedes conectarte y comenzar a recibir servicios.</p>"
                + "<p style=\"margin:0;color:#475569;\">Bienvenido a bordo.</p>";
            return Base("Documentacion aprobada", c);
        }

        public static string DocumentacionCorreccion(string nombre, string comentario)
        {
            var c = "<p style=\"margin:0 0 12px;color:#475569;\">Hola " + nombre + ",</p>"
                + "<p style=\"margin:0 0 12px;color:#475569;\">Tu documentacion requiere <b style=\"color:#D97706;\">correcciones</b>:</p>"
                + "<div style=\"background:#FFF7ED;border-left:4px solid #F59E0B;padding:12px 16px;border-radius:8px;color:#92400E;margin:0 0 12px;\">" + (comentario ?? "") + "</div>"
                + "<p style=\"margin:0;color:#475569;\">Ingresa a la aplicacion para corregirla.</p>";
            return Base("Correcciones en tu documentacion", c);
        }

        public static string CambioPassword(string nombre)
        {
            var c = "<p style=\"margin:0 0 12px;color:#475569;\">Hola " + nombre + ",</p>"
                + "<p style=\"margin:0 0 12px;color:#475569;\">Tu contrasena fue actualizada correctamente.</p>"
                + "<p style=\"margin:0;color:#94a3b8;font-size:13px;\">Si no realizaste este cambio, contacta a soporte de inmediato.</p>";
            return Base("Contrasena actualizada", c);
        }

        public static string ServicioFinalizado(string nombre, string servicioId, string total)
        {
            var c = "<p style=\"margin:0 0 12px;color:#475569;\">Hola " + nombre + ",</p>"
                + "<p style=\"margin:0 0 12px;color:#475569;\">Tu servicio <b>#" + servicioId + "</b> ha finalizado.</p>"
                + "<p style=\"margin:0;color:#475569;\">Total del viaje: <b>$" + total + "</b></p>";
            return Base("Servicio finalizado", c);
        }
    }
}
