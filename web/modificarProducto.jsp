<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>

<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width initial-scale=1.0" />
    <title>Modificar Productos</title>
    <link rel="stylesheet" href="estilo.css" />
  </head>

  <body class="inicio">
    <section class="inicio-seccion">

      <%
        // Verificar que hay sesión activa
        Integer usuarioId = (Integer) session.getAttribute("usuarioId");
        if (usuarioId == null) {
            response.sendRedirect("inicioSesion.jsp");
            return;
        }
      %>

      <div class="boton-volver">
        <input
          type="button"
          class="boton boton-borde"
          value="← Volver al menú"
          onclick="location.href='menu.html';"
        />
      </div>

      <div class="boton-volver2">
        <input
          type="button"
          class="boton boton-borde"
          value="← Volver"
          onclick="location.href='productos.html';"
        />
        <h2 class="titulo-seccion">Modificar Producto</h2>
      </div>

      <div class="division flex">

        <div class="izquierda">
          <form class="grupo-formulario2" method="get">

            <div class="caja-seccion tarjeta">
              <div class="texto-centro">
                <p class="titulo-seccion2">Modificar Producto</p>
                <p class="subtitulo-seccion2">
                  Busca un producto por su nombre para modificar sus datos
                </p>
              </div>

              <div>
                <label style="margin-top: 40px">Nombre del producto</label>
                <input
                  class="input-datos2"
                  type="text"
                  name="nombre"
                  value="<%= request.getParameter("nombre") != null ? request.getParameter("nombre") : "" %>"
                />
              </div>

              <button class="boton boton-primario" style="margin-top: 20px">
                Buscar
              </button>
            </div>
          </form>
        </div>

        <div class="derecha">
          <div class="caja-seccion tarjeta">
            <p class="subtitulo-seccion2 texto-centro">
              Selecciona producto a modificar
            </p>

            <table width="100%">
              <tr>
                <th>ID</th>
                <th>Nombre</th>
                <th>Cantidad</th>
                <th>Precio</th>
                <th>Acción</th>
              </tr>

              <%
                String nombre = request.getParameter("nombre");

                Connection con = null;
                PreparedStatement st = null;
                ResultSet rs = null;

                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    con = DriverManager.getConnection("jdbc:mysql://localhost:3306/payStream","root","n0m3l0");

                    if (nombre != null && !nombre.trim().isEmpty()) {
                        // Buscar por nombre filtrando por usuario en sesión
                        st = con.prepareStatement(
                            "SELECT * FROM productos WHERE nombre LIKE ? AND usuario_id = ?"
                        );
                        st.setString(1, "%" + nombre + "%");
                        st.setInt(2, usuarioId);
                    } else {
                        // Mostrar todos los productos del usuario en sesión
                        st = con.prepareStatement(
                            "SELECT * FROM productos WHERE usuario_id = ?"
                        );
                        st.setInt(1, usuarioId);
                    }

                    rs = st.executeQuery();

                    while (rs.next()) {
              %>
              <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= rs.getString("nombre") %></td>
                <td><%= rs.getInt("cantidad") %></td>
                <td>$<%= rs.getDouble("precio") %></td>
                <td>
                  <a href="editarProducto.jsp?id=<%= rs.getInt("id") %>">
                    Modificar
                  </a>
                </td>
              </tr>
              <%
                    }
                } catch (Exception e) {
                    out.println("Error: " + e.getMessage());
                } finally {
                    if (rs != null) rs.close();
                    if (st != null) st.close();
                    if (con != null) con.close();
                }
              %>

            </table>
          </div>
        </div>
      </div>
    </section>
  </body>
</html>
