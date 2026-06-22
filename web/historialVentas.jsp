<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }
    String fechaDesde = request.getParameter("desde");
    String fechaHasta = request.getParameter("hasta");
    // Defaults: último mes
    if (fechaDesde == null || fechaDesde.isEmpty()) fechaDesde = "";
    if (fechaHasta == null || fechaHasta.isEmpty()) fechaHasta = "";
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
      .page-header { padding: 28px 40px 20px; border-bottom: 1px solid #E5E7EB; margin-bottom: 8px; }
      .page-header-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
      .breadcrumb { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #6B7280; }
      .breadcrumb-actual { color: #111827; font-weight: 600; }
      .page-title { font-size: 24px; font-weight: 700; color: #111827; margin: 0 0 4px; }
      .page-subtitle { font-size: 13px; color: #6B7280; margin: 0; }
      .btn-nav {
        display: inline-flex; align-items: center; gap: 6px;
        background: white; border: 1.5px solid #D1D5DB; border-radius: 999px;
        padding: 6px 14px 6px 10px; font-size: 12px; font-weight: 600;
        color: #374151; cursor: pointer; text-decoration: none;
        transition: all 0.2s ease; box-shadow: 0 1px 3px rgba(0,0,0,.06);
      }
      .btn-nav:hover {
        background: #EFF6FF; border-color: #2563EB; color: #2563EB;
        box-shadow: 0 4px 12px rgba(37,99,235,.15); transform: translateX(-3px);
      }
      .btn-nav .nav-icon {
        width: 20px; height: 20px; border-radius: 50%;
        background: #F3F4F6; display: flex; align-items: center; justify-content: center;
        font-size: 12px; transition: background 0.2s;
      }
      .btn-nav:hover .nav-icon { background: #DBEAFE; }
    </style>
  </head>
  <body class="inicio">
    <section class="inicio-seccion">

            <div class="page-header">
        <div class="page-header-top">
          <nav class="breadcrumb">
            <a href="menu.jsp" class="btn-nav"><span class="nav-icon">⌂</span>Inicio</a>
            <span>›</span>
            <a href="reportes.jsp" class="btn-nav"><span class="nav-icon">←</span>Reportes</a>
            <span>›</span>
            <span class="breadcrumb-actual">Historial de Ventas</span>
          </nav>
          <a href="reportes.jsp" class="btn-nav"><span class="nav-icon">←</span>Volver</a>
        </div>
        <h2 class="page-title">Historial de Ventas</h2>
        <p class="page-subtitle">Registro completo de todas las ventas realizadas</p>
      </div>

      <div class="grupo-formulario2">
        <div class="caja-seccion2 tarjeta">
          <!-- Filtro por fechas -->
          <form method="get" action="historialVentas.jsp" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;margin-bottom:20px;">
            <div>
              <label style="display:block;font-size:12px;font-weight:600;color:#6B7280;margin-bottom:4px;">Desde</label>
              <input type="date" name="desde" value="<%= fechaDesde %>"
                style="padding:8px 12px;border:1.5px solid #D1D5DB;border-radius:8px;font-size:13px;font-family:inherit;"/>
            </div>
            <div>
              <label style="display:block;font-size:12px;font-weight:600;color:#6B7280;margin-bottom:4px;">Hasta</label>
              <input type="date" name="hasta" value="<%= fechaHasta %>"
                style="padding:8px 12px;border:1.5px solid #D1D5DB;border-radius:8px;font-size:13px;font-family:inherit;"/>
            </div>
            <button type="submit" class="boton boton-primario" style="padding:8px 20px;font-size:13px;">Filtrar</button>
            <% if (!fechaDesde.isEmpty() || !fechaHasta.isEmpty()) { %>
              <a href="historialVentas.jsp" style="font-size:13px;color:#6B7280;text-decoration:none;padding:8px 0;">✕ Limpiar</a>
            <% } %>
          </form>

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
              con = com.devbiz.util.DB.getConnection();

              String sql = "SELECT id, fecha, total FROM ventas WHERE usuario_id = ?";
              if (!fechaDesde.isEmpty()) sql += " AND DATE(fecha) >= ?";
              if (!fechaHasta.isEmpty()) sql += " AND DATE(fecha) <= ?";
              sql += " ORDER BY fecha DESC";
              stVentas = con.prepareStatement(sql);
              int idx = 1;
              stVentas.setInt(idx++, usuarioId);
              if (!fechaDesde.isEmpty()) stVentas.setString(idx++, fechaDesde);
              if (!fechaHasta.isEmpty()) stVentas.setString(idx++, fechaHasta);
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
