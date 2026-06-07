<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    // Filtro por tipo recibido por GET (puede ser null = todos)
    String filtro = request.getParameter("tipo");
    if (filtro == null) filtro = "TODOS";
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Movimientos de Inventario - PayStream</title>
    <link rel="stylesheet" href="estilo.css" />
    <style>
      .filtros { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 18px; }
      .btn-filtro {
        padding: 6px 16px; border-radius: 20px; border: 1px solid #D1D5DB;
        background: white; cursor: pointer; font-size: 13px; font-weight: 500;
        text-decoration: none; color: #374151; transition: 0.15s;
      }
      .btn-filtro:hover  { background: #EFF6FF; border-color: #2563EB; color: #2563EB; }
      .btn-filtro.activo { background: #2563EB; color: white; border-color: #2563EB; }

      .badge-alta   { background:#DCFCE7; color:#166534; display:inline-block; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600; }
      .badge-baja   { background:#FEE2E2; color:#991B1B; display:inline-block; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600; }
      .badge-ajuste { background:#FEF9C3; color:#854D0E; display:inline-block; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600; }
      .badge-venta  { background:#E0E7FF; color:#3730A3; display:inline-block; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600; }
      .sin-datos    { text-align:center; color:#9CA3AF; padding:40px; }
      .variacion-pos { color: #16A34A; font-weight: 600; }
      .variacion-neg { color: #DC2626; font-weight: 600; }
    </style>
  </head>
  <body class="inicio">
    <section class="inicio-seccion">

      <div class="boton-volver">
        <input type="button" class="boton boton-borde"
               value="← Volver al menu"
               onclick="location.href='menu.html'" />
      </div>
      <div class="boton-volver2">
        <input type="button" class="boton boton-borde"
               value="← Volver"
               onclick="location.href='reportes.jsp'" />
        <h2 class="titulo-seccion">Movimientos de Inventario</h2>
      </div>

      <div class="grupo-formulario2">
        <div class="caja-seccion2 tarjeta">
          <div class="texto-centro">
            <p class="titulo-seccion2">Historial de cambios al inventario</p>
            <p class="subtitulo-seccion2">Altas, bajas, ajustes manuales y descuentos por venta</p>
          </div>

          <%-- Botones de filtro --%>
          <div class="filtros">
            <a href="reporteInventario.jsp"               class="btn-filtro <%= "TODOS".equals(filtro)  ? "activo" : "" %>">Todos</a>
            <a href="reporteInventario.jsp?tipo=ALTA"     class="btn-filtro <%= "ALTA".equals(filtro)   ? "activo" : "" %>">Altas</a>
            <a href="reporteInventario.jsp?tipo=BAJA"     class="btn-filtro <%= "BAJA".equals(filtro)   ? "activo" : "" %>">Bajas</a>
            <a href="reporteInventario.jsp?tipo=AJUSTE"   class="btn-filtro <%= "AJUSTE".equals(filtro) ? "activo" : "" %>">Ajustes</a>
            <a href="reporteInventario.jsp?tipo=VENTA"    class="btn-filtro <%= "VENTA".equals(filtro)  ? "activo" : "" %>">Ventas</a>
          </div>

          <%
            Connection con = null;
            PreparedStatement st = null;
            ResultSet rs = null;

            try {
              Class.forName("com.mysql.cj.jdbc.Driver");
              con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
              );

              String sql =
                "SELECT m.id, p.nombre AS producto, m.tipo_movimiento, " +
                "       m.cantidad_anterior, m.cantidad_nueva, " +
                "       m.precio_anterior, m.precio_nuevo, " +
                "       m.descripcion, m.fecha " +
                "FROM movimientos_inventario m " +
                "LEFT JOIN productos p ON m.producto_id = p.id " +
                "WHERE m.usuario_id = ? ";

              if (!"TODOS".equals(filtro)) {
                sql += "AND m.tipo_movimiento = ? ";
              }
              sql += "ORDER BY m.fecha DESC";

              st = con.prepareStatement(sql);
              st.setInt(1, usuarioId);
              if (!"TODOS".equals(filtro)) {
                st.setString(2, filtro);
              }
              rs = st.executeQuery();

              boolean hayDatos = false;
          %>

          <table>
            <thead>
              <tr>
                <th>Fecha</th>
                <th>Producto</th>
                <th>Tipo</th>
                <th>Cant. anterior</th>
                <th>Cant. nueva</th>
                <th>Variacion</th>
                <th>Precio</th>
                <th>Inversión / Valor</th>
              </tr>
            </thead>
            <tbody>
            <%
              while (rs.next()) {
                hayDatos = true;
                String tipo    = rs.getString("tipo_movimiento");
                String prod    = rs.getString("producto");
                if (prod == null) prod = "(producto eliminado)";

                int    cantAnt = rs.getInt("cantidad_anterior");
                boolean cantAntNull = rs.wasNull();
                int    cantNue = rs.getInt("cantidad_nueva");
                boolean cantNueNull = rs.wasNull();

                double precAnt = rs.getDouble("precio_anterior");
                boolean precAntNull = rs.wasNull();
                double precNue = rs.getDouble("precio_nuevo");
                boolean precNueNull = rs.wasNull();

                String badgeClass = "badge-" + tipo.toLowerCase();

                int variacion = 0;
                String varStr = "—";
                String varClass = "";
                if (!cantAntNull && !cantNueNull) {
                  variacion = cantNue - cantAnt;
                  varStr = (variacion >= 0 ? "+" : "") + variacion;
                  varClass = variacion >= 0 ? "variacion-pos" : "variacion-neg";
                } else if (cantAntNull && !cantNueNull) {
                  varStr = "+" + cantNue;
                  varClass = "variacion-pos";
                } else if (!cantAntNull && cantNueNull) {
                  varStr = "-" + cantAnt;
                  varClass = "variacion-neg";
                }
            %>
              <%
                // Calcular valor de inversión según el tipo
                String valorStr = "—";
                String valorClass = "";
                if ("ALTA".equals(tipo) && !cantNueNull && !precNueNull) {
                    double inversion = cantNue * precNue;
                    valorStr = "-$" + String.format("%.2f", inversion);
                    valorClass = "variacion-neg";
                } else if ("VENTA".equals(tipo) && !cantAntNull && !precAntNull) {
                    double ingreso = (cantAnt - (cantNueNull ? 0 : cantNue)) * precAnt;
                    if (ingreso < 0) ingreso = -ingreso;
                    valorStr = "+$" + String.format("%.2f", ingreso);
                    valorClass = "variacion-pos";
                } else if ("BAJA".equals(tipo) && !cantAntNull && !precAntNull) {
                    double perdida = (cantAnt - (cantNueNull ? 0 : cantNue)) * precAnt;
                    if (perdida < 0) perdida = -perdida;
                    valorStr = "-$" + String.format("%.2f", perdida);
                    valorClass = "variacion-neg";
                }
                double precio = precNueNull ? (precAntNull ? 0 : precAnt) : precNue;
              %>
              <tr>
                <td><%= rs.getString("fecha") %></td>
                <td><strong><%= prod %></strong></td>
                <td><span class="<%= badgeClass %>"><%= tipo %></span></td>
                <td><%= cantAntNull ? "—" : cantAnt %></td>
                <td><%= cantNueNull ? "—" : cantNue %></td>
                <td class="<%= varClass %>"><%= varStr %></td>
                <td>$<%= String.format("%.2f", precio) %></td>
                <td class="<%= valorClass %>"><strong><%= valorStr %></strong></td>
              </tr>
            <%
              }
              if (!hayDatos) {
            %>
              <tr><td colspan="8" class="sin-datos">No hay movimientos registrados.</td></tr>
            <%
              }
            %>
            </tbody>
          </table>

          <%
            } catch (Exception e) {
              out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
            } finally {
              if (rs  != null) rs.close();
              if (st  != null) st.close();
              if (con != null) con.close();
            }
          %>
        </div>
      </div>

    </section>
  </body>
</html>
