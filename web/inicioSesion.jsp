<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Si ya está autenticado, ir directo al dashboard
    if (request.getUserPrincipal() != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    boolean error = "1".equals(request.getParameter("error"));
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Inicio de sesion</title>
    <link rel="stylesheet" href="estilo.css" />
</head>
<body>
    <div class="contenedor-login">
        <div class="caja-login tarjeta texto-centro">
            <div class="titulos">
                <h1 class="titulo-login">PayStream</h1>
                <p class="subtitulo-login">creado por devbiz</p>
            </div>
            <div>
                <p class="titulo-seccion">Iniciar Sesion</p>
                <p class="subtitulo-seccion">Ingresa tus datos para continuar</p>
            </div>
            <form class="grupo-formulario" method="post" action="j_security_check">
                <div class="grupo-input">
                    <label>Correo Electronico</label>
                    <input class="input-datos" type="email" id="j_username" name="j_username"
                           placeholder="correo@ejemplo.com"/>
                </div>
                <div class="grupo-input">
                    <label style="margin-top: 18px">Contrasena</label>
                    <input class="input-datos" type="password" id="j_password" name="j_password"
                           placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;"/>
                </div>
                <% if (error) { %>
                    <p style="color:red; text-align:left;">Correo o contrasena incorrectos.</p>
                <% } %>
                <button class="boton boton-primario" style="margin-top: 20px" type="submit">
                    Iniciar Sesion
                </button>
            </form>
            <div class="div-enlace">
                <a href="registro.html" class="enlace">No tienes una cuenta? Crear cuenta</a>
            </div>
        </div>
    </div>
</body>
</html>
