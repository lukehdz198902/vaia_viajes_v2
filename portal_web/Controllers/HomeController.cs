using Microsoft.AspNetCore.Mvc;

namespace VaiaViajes.Web.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Login() { return View(); }
        public IActionResult Logout() { return RedirectToAction("Login"); }
        public IActionResult Index() { return View(); }
        public IActionResult Usuarios() { ViewBag.Title = "Usuarios"; return View(); }
        public IActionResult Pasajeros() { ViewBag.Title = "Pasajeros"; return View(); }
        public IActionResult Conductores() { ViewBag.Title = "Conductores"; return View(); }
        public IActionResult Servicios() { ViewBag.Title = "Servicios"; return View(); }
        public IActionResult Monitoreo() { ViewBag.Title = "Monitoreo"; return View(); }
        public IActionResult Analitica() { ViewBag.Title = "Analitica"; return View(); }
        public IActionResult Reportes() { ViewBag.Title = "Reportes"; return View(); }
        public IActionResult Incidentes() { ViewBag.Title = "Incidentes"; return View(); }
        public IActionResult Promociones() { ViewBag.Title = "Promociones"; return View(); }
        public IActionResult Zonas() { ViewBag.Title = "Zonas"; return View(); }
        public IActionResult Configuracion() { ViewBag.Title = "Configuracion"; return View(); }
        public IActionResult Compania() { ViewBag.Title = "Compania"; return View(); }
        public IActionResult Cortes() { ViewBag.Title = "Cortes"; return View(); }
        public IActionResult Notificaciones() { ViewBag.Title = "Notificaciones"; return View(); }
        public IActionResult Avisos() { ViewBag.Title = "Avisos"; return View(); }
        public IActionResult Auditoria() { ViewBag.Title = "Auditoria"; return View(); }
    }
}
