<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>

<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width initial-scale=1.0" />
    <title>Consultar Productos</title>
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
          onclick="location.href = 'menu.html'"
        />
      </div>

      <div class="boton-volver2">
        <input
          type="button"
          class="boton boton-borde"
          value="← Volver"
          onclick="location.href = 'productos.html'"
        />
        <h2 class="titulo-seccion">Lista de Productos</h2>
      </div>

      <div class="grupo-formulario2">
        <div class="caja-seccion2 tarjeta">
          <div class="texto-centro">
            <p class="titulo-seccion2">Inventario Completo</p>
            <p class="subtitulo-seccion2">
              Lista de todos los productos registrados en el sistema
            </p>
          </div>

          <div class="tabla">
            <table>
              <thead>
                <tr>
                  <th>Nombre del Producto</th>
                  <th>Cantidad</th>
                  <th>Precio Unitario</th>
                  <th>Valor Total</th>
                </tr>
              </thead>

              <tbody>
                <%
                  Connection con = null;
                  PreparedStatement st = null;
                  ResultSet rs = null;
                  double totalInventario = 0;

                  try {
                      Class.forName("com.mysql.cj.jdbc.Driver");
                      con = DriverManager.getConnection(
                          "jdbc:mysql://localhost:3306/PAYSTREAM", "root", "n0m3l0"
                      );

                      // Filtrar solo los productos del usuario en sesión
                      st = con.prepareStatement(
                          "SELECT nombre, cantidad, precio FROM productos WHERE usuario_id = ? AND cantidad > 0 ORDER BY nombre ASC"
                      );
                      st.setInt(1, usuarioId);
                      rs = st.executeQuery();

                      while(rs.next()) {
                          String nombre = rs.getString("nombre");
                          int cantidad = rs.getInt("cantidad");
                          double precio = rs.getDouble("precio");
                          double valorTotal = cantidad * precio;
                          totalInventario += valorTotal;
                %>
                <tr>
                  <td><%= nombre %></td>
                  <td><%= cantidad %></td>
                  <td>$<%= String.format("%.2f", precio) %></td>
                  <td>$<%= String.format("%.2f", valorTotal) %></td>
                </tr>
                <%
                      }
                  } catch(Exception e) {
                      out.println("<tr><td colspan='4'>Error: " + e.getMessage() + "</td></tr>");
                  } finally {
                      if(rs != null) rs.close();
                      if(st != null) st.close();
                      if(con != null) con.close();
                  }
                %>
              </tbody>

              <tfoot>
                <tr>
                  <th>Total del Inventario</th>
                  <th></th>
                  <th></th>
                  <th>$<%= String.format("%.2f", totalInventario) %></th>
                </tr>
              </tfoot>
            </table>
          </div>

        </div>
      </div>

    </section>
  </body>
</html>
