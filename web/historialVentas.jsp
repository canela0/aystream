<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Historial de Ventas - PayStream</title>
    <link rel="stylesheet" href="estilo.css" />
    <style>
      .detalle-venta { display: none; }
      .fila-venta    { cursor: pointer; }
      .fila-venta:hover td { background: #EFF6FF; }
      .badge {
        display: inline-block;
        padding: 2px 10px;
        border-radius: 12px;
        font-size: 12px;
        font-weight: 600;
        background: #DCFCE7;
        color: #166534;
      }
      .tabla-detalle {
        width: 100%;
        margin: 0;
        background: #F8FAFF;
        border-radius: 0;
      }
      .tabla-detalle th { background: #E0E7FF; font-size: 13px; }
      .tabla-detalle td { font-size: 13px; border-bottom: 1px solid #E2E8F0; }
      .sin-datos { text-align: center; color: #9CA3AF; padding: 40px; }
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
        <h2 class="titulo-seccion">Historial de Ventas</h2>
      </div>

      <div class="grupo-formulario2">
        <div class="caja-seccion2 tarjeta">
          <div class="texto-centro">
            <p class="titulo-seccion2">Todas las ventas registradas</p>
            <p class="subtitulo-seccion2">Haz clic en una venta para ver su detalle</p>
          </div>

          <%
            Connection con = null;
            PreparedStatement stVentas = null;
            PreparedStatement stDetalle = null;
            ResultSet rsVentas = null;
            ResultSet rsDetalle = null;
            double granTotal = 0;
            int totalVentas = 0;

            try {
              Class.forName("com.mysql.cj.jdbc.Driver");
              con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
              );

              stVentas = con.prepareStatement(
                "SELECT id, fecha, total FROM ventas " +
                "WHERE usuario_id = ? ORDER BY fecha DESC"
              );
              stVentas.setInt(1, usuarioId);
              rsVentas = stVentas.executeQuery();

              boolean hayVentas = false;
          %>

          <table>
            <thead>
              <tr>
                <th># Venta</th>
                <th>Fecha y hora</th>
                <th>Total</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
            <%
              while (rsVentas.next()) {
                hayVentas = true;
                int idVenta   = rsVentas.getInt("id");
                String fecha  = rsVentas.getString("fecha");
                double total  = rsVentas.getDouble("total");
                granTotal    += total;
                totalVentas++;

                stDetalle = con.prepareStatement(
                  "SELECT nombre_producto, cantidad, precio_unitario, subtotal " +
                  "FROM detalle_venta WHERE venta_id = ?"
                );
                stDetalle.setInt(1, idVenta);
                rsDetalle = stDetalle.executeQuery();

                StringBuilder detalleHtml = new StringBuilder();
                detalleHtml.append("<tr class='detalle-venta' id='det-").append(idVenta).append("'>")
                           .append("<td colspan='4' style='padding:0'>")
                           .append("<table class='tabla-detalle'><thead><tr>")
                           .append("<th>Producto</th><th>Cantidad</th><th>Precio unit.</th><th>Subtotal</th>")
                           .append("</tr></thead><tbody>");

                while (rsDetalle.next()) {
                  detalleHtml.append("<tr>")
                    .append("<td>").append(rsDetalle.getString("nombre_producto")).append("</td>")
                    .append("<td>").append(rsDetalle.getInt("cantidad")).append("</td>")
                    .append("<td>$").append(String.format("%.2f", rsDetalle.getDouble("precio_unitario"))).append("</td>")
                    .append("<td>$").append(String.format("%.2f", rsDetalle.getDouble("subtotal"))).append("</td>")
                    .append("</tr>");
                }
                detalleHtml.append("</tbody></table></td></tr>");
                rsDetalle.close();
                stDetalle.close();
            %>
              <tr class="fila-venta" onclick="toggleDetalle(<%= idVenta %>)">
                <td><strong>#<%= idVenta %></strong></td>
                <td><%= fecha %></td>
                <td><strong>$<%= String.format("%.2f", total) %></strong></td>
                <td><span class="badge">Completada</span></td>
              </tr>
              <%= detalleHtml.toString() %>
            <%
              }

              if (!hayVentas) {
            %>
              <tr><td colspan="4" class="sin-datos">No hay ventas registradas aun.</td></tr>
            <%
              }
            %>
            </tbody>
            <tfoot>
              <tr>
                <th colspan="2">Total acumulado (<%= totalVentas %> ventas)</th>
                <th colspan="2">$<%= String.format("%.2f", granTotal) %></th>
              </tr>
            </tfoot>
          </table>

          <%
            } catch (Exception e) {
              out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
            } finally {
              if (rsVentas  != null) rsVentas.close();
              if (stVentas  != null) stVentas.close();
              if (con       != null) con.close();
            }
          %>
        </div>
      </div>

    </section>

    <script>
      function toggleDetalle(id) {
        var fila = document.getElementById("det-" + id);
        if (fila) {
          fila.style.display = fila.style.display === "table-row" ? "none" : "table-row";
        }
      }
    </script>
  </body>
</html>
