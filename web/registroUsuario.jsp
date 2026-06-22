<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.security.MessageDigest"%>
<%@page import="java.math.BigInteger"%>
<%!
  private String sha256(String input) {
    try {
      java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
      byte[] hash = md.digest(input.getBytes("UTF-8"));
      java.math.BigInteger bi = new java.math.BigInteger(1, hash);
      String hex = bi.toString(16);
      while (hex.length() < 64) hex = "0" + hex;
      return hex;
    } catch (Exception e) { return input; }
  }
%>
<html>
    <head>
        <meta charset="UTF-8"/>
        <title>Registro</title>
        <link rel="stylesheet" href="estilo.css"/>
    </head>
    <body>
        <%
            String nombre    = request.getParameter("nombreUsuario");
            String apellido  = request.getParameter("apellidoUsuario");
            String correo    = request.getParameter("correoElectronico");
            String contrasena = request.getParameter("contrasena");

            if (nombre == null || apellido == null || correo == null || contrasena == null
                    || nombre.trim().isEmpty() || apellido.trim().isEmpty()
                    || correo.trim().isEmpty() || contrasena.trim().isEmpty()) {
                response.sendRedirect("registro.html");
                return;
            }

            Connection conecta = null;
            PreparedStatement st = null;

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conecta = com.devbiz.util.DB.getConnection();

                st = conecta.prepareStatement(
                    "INSERT INTO usuarios (nombre, apellido, correo, contrasena) VALUES (?, ?, ?, ?)"
                );
                st.setString(1, nombre.trim());
                st.setString(2, apellido.trim());
                st.setString(3, correo.trim());
                st.setString(4, sha256(contrasena.trim()));
                st.executeUpdate();

                // Asignar rol admin para que el Realm permita el acceso
                PreparedStatement stRol = conecta.prepareStatement(
                    "INSERT IGNORE INTO user_roles (correo, role_name) VALUES (?, 'admin')"
                );
                stRol.setString(1, correo.trim());
                stRol.executeUpdate();
                stRol.close();

                response.sendRedirect("dashboard.jsp");

            } catch (java.sql.SQLIntegrityConstraintViolationException e) {
        %>
                <div class="contenedor-login">
                    <div class="caja-login tarjeta texto-centro">
                        <p class="titulo-seccion">Correo ya registrado</p>
                        <p class="subtitulo-seccion">El correo <strong><%= correo %></strong> ya tiene una cuenta.</p>
                        <a href="registro.html" class="boton boton-primario" style="display:block;margin-top:16px;">Intentar con otro correo</a>
                        <a href="inicioSesion.jsp" class="boton boton-secundario" style="display:block;margin-top:8px;">Ir a Iniciar Sesion</a>
                    </div>
                </div>
        <%
            } catch (Exception e) {
                out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
            } finally {
                if (st != null) st.close();
                if (conecta != null) conecta.close();
            }
        %>
    </body>
</html>
