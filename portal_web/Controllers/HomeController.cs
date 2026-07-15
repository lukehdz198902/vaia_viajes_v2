using Microsoft.AspNetCore.Mvc;

namespace VaiaViajes.Web.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
