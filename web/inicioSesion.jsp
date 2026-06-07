<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.DriverManager"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    String correo = request.getParameter("correoElectronico");
    String contrasena = request.getParameter("contrasena");

    boolean error = false;

    if (correo != null && contrasena != null) {
        Connection conecta = null;
        PreparedStatement st = null;
        ResultSet rs = null;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conecta = DriverManager.getConnection("jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0");

            st = conecta.prepareStatement("SELECT * FROM usuarios WHERE correo=? AND contrasena=?");
            st.setString(1, correo);
            st.setString(2, contrasena);
            rs = st.executeQuery();

            if (rs.next()) {
                session.setAttribute("usuarioId", rs.getInt("id"));
                session.setAttribute("usuarioNombre", rs.getString("nombre"));
                response.sendRedirect("dashboard.jsp");
                return;
            } else {
                error = true;
            }
        } catch (Exception e) {
            error = true;
        } finally {
            if (rs != null) rs.close();
            if (st != null) st.close();
            if (conecta != null) conecta.close();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Inicio de sesion</title>
    <link rel="stylesheet" href="estilo.css" />
    <script src="validaFormulario.js"></script>
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
                    <a id="mensajeErrorCorreo" class="mensajeError"></a>
                </div>
                <div class="grupo-input">
                    <label style="margin-top: 18px">Contrasena</label>
                    <input class="input-datos" type="password" id="j_password" name="j_password"
                           placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;"/>
                    <a id="mensajeErrorContra" class="mensajeError"></a>
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