<%@ Application Inherits="System.Web.HttpApplication" Language="C#" %>
<script RunAt="server">
    protected void Application_Start(object sender, EventArgs e)
    {
        System.Web.Http.GlobalConfiguration.Configure(WebApiConfig.Register);
    }
</script>