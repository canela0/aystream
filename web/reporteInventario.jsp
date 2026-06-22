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

    // Totales para las tarjetas de resumen
    int totalAltas = 0, totalBajas = 0, totalAjustes = 0, totalVentas = 0;
    double inversionNeta = 0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        java.sql.Connection conRes = com.devbiz.util.DB.getConnection();
        java.sql.PreparedStatement stRes = conRes.prepareStatement(
            "SELECT tipo_movimiento, COUNT(*) AS cnt, " +
            "       SUM(CASE WHEN tipo_movimiento='ALTA' THEN cantidad_nueva * COALESCE(precio_nuevo,0) ELSE 0 END) AS inv_alta, " +
            "       SUM(CASE WHEN tipo_movimiento='VENTA' THEN (cantidad_anterior - COALESCE(cantidad_nueva,0)) * COALESCE(precio_anterior,0) ELSE 0 END) AS ing_venta, " +
            "       SUM(CASE WHEN tipo_movimiento='BAJA' THEN (cantidad_anterior - COALESCE(cantidad_nueva,0)) * COALESCE(precio_anterior,0) ELSE 0 END) AS perd_baja " +
            "FROM movimientos_inventario WHERE usuario_id = ? GROUP BY tipo_movimiento");
        stRes.setInt(1, usuarioId);
        java.sql.ResultSet rsRes = stRes.executeQuery();
        double totalInv = 0, totalIng = 0, totalPerd = 0;
        while (rsRes.next()) {
            String t = rsRes.getString("tipo_movimiento");
            int cnt = rsRes.getInt("cnt");
            if ("ALTA".equals(t))   { totalAltas   = cnt; totalInv  = rsRes.getDouble("inv_alta"); }
            if ("BAJA".equals(t))   { totalBajas   = cnt; totalPerd = rsRes.getDouble("perd_baja"); }
            if ("AJUSTE".equals(t)) { totalAjustes = cnt; }
            if ("VENTA".equals(t))  { totalVentas  = cnt; totalIng  = rsRes.getDouble("ing_venta"); }
        }
        inversionNeta = totalIng - totalInv - totalPerd;
        rsRes.close(); stRes.close(); conRes.close();
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Movimientos de Inventario - PayStream</title>
    <link rel="stylesheet" href="estilo.css" />
    <style>
      .page-header { padding: 28px 40px 20px; border-bottom: 1px solid #E5E7EB; margin-bottom: 8px; }
      .page-header-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
      .breadcrumb { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #6B7280; }
      .breadcrumb a { color: #2563EB; text-decoration: none; }
      .breadcrumb a:hover { text-decoration: underline; }
      .breadcrumb-actual { color: #111827; font-weight: 600; }
      .page-title { font-size: 24px; font-weight: 700; color: #111827; margin: 0 0 4px; }
      .page-subtitle { font-size: 13px; color: #6B7280; margin: 0; }
      .btn-back {
        display: inline-flex; align-items: center; gap: 8px;
        background: white; border: 1.5px solid #D1D5DB; border-radius: 999px;
        padding: 7px 18px 7px 12px; font-size: 13px; font-weight: 600;
        color: #374151; cursor: pointer; text-decoration: none;
        transition: all 0.2s ease; box-shadow: 0 1px 3px rgba(0,0,0,.06);
      }
      .btn-back:hover {
        background: #EFF6FF; border-color: #2563EB; color: #2563EB;
        box-shadow: 0 4px 12px rgba(37,99,235,.15); transform: translateX(-3px);
      }
      .btn-back .arrow-icon {
        width: 24px; height: 24px; border-radius: 50%;
        background: #F3F4F6; display: flex; align-items: center; justify-content: center;
        font-size: 14px; transition: background 0.2s;
      }
      .btn-back:hover .arrow-icon { background: #DBEAFE; }

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

      .resumen-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 24px; }
      .resumen-card { border-radius: 12px; padding: 16px 20px; display: flex; flex-direction: column; gap: 4px; }
      .resumen-card .rc-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; opacity: .75; }
      .resumen-card .rc-valor { font-size: 26px; font-weight: 700; }
      .resumen-card .rc-sub   { font-size: 12px; opacity: .7; }
      .rc-altas   { background: #DCFCE7; color: #166534; }
      .rc-bajas   { background: #FEE2E2; color: #991B1B; }
      .rc-ajustes { background: #FEF9C3; color: #854D0E; }
      .rc-neta    { background: #EFF6FF; color: #1D4ED8; }

      table { table-layout: auto; width: 100%; }
      table th, table td { white-space: nowrap; vertical-align: middle; padding: 10px 12px; }
      table th:nth-child(3), table td:nth-child(3) { text-align: center; }
      table th:nth-child(4), table td:nth-child(4) { text-align: center; }
      table th:nth-child(5), table td:nth-child(5) { text-align: center; }
      table th:nth-child(6), table td:nth-child(6) { text-align: center; }
      table th:nth-child(7), table td:nth-child(7) { text-align: right; }
      table th:nth-child(8), table td:nth-child(8) { text-align: right; }
      /* Permitir scroll horizontal si la tabla es muy ancha en pantallas pequeñas */
      .tabla-wrap { overflow-x: auto; }
    </style>
  </head>
  <body class="inicio">
    <section class="inicio-seccion">

      <div class="page-header">
        <div class="page-header-top">
          <nav class="breadcrumb">
            <a href="menu.jsp" class="btn-back" style="padding:6px 14px 6px 10px; font-size:12px;">
              <span class="arrow-icon" style="width:20px;height:20px;font-size:12px;">⌂</span>
              Inicio
            </a>
            <span>›</span>
            <a href="reportes.jsp" class="btn-back" style="padding:6px 14px 6px 10px; font-size:12px;">
              <span class="arrow-icon" style="width:20px;height:20px;font-size:12px;">←</span>
              Reportes
            </a>
            <span>›</span>
            <span class="breadcrumb-actual">Inventario</span>
          </nav>
          <a href="reportes.jsp" class="btn-back">
            <span class="arrow-icon">←</span>
            Volver
          </a>
        </div>
        <h2 class="page-title">Movimientos de Inventario</h2>
        <p class="page-subtitle">Historial completo de altas, bajas, ajustes y ventas</p>
      </div>

      <div class="grupo-formulario2">
        <div class="caja-seccion2 tarjeta">
          <%-- Tarjetas de resumen --%>
          <div class="resumen-grid">
            <div class="resumen-card rc-altas">
              <span class="rc-label">Altas</span>
              <span class="rc-valor"><%= totalAltas %></span>
              <span class="rc-sub">entradas de stock</span>
            </div>
            <div class="resumen-card rc-bajas">
              <span class="rc-label">Bajas</span>
              <span class="rc-valor"><%= totalBajas %></span>
              <span class="rc-sub">salidas manuales</span>
            </div>
            <div class="resumen-card rc-ajustes">
              <span class="rc-label">Ventas</span>
              <span class="rc-valor"><%= totalVentas %></span>
              <span class="rc-sub">ventas registradas</span>
            </div>
            <div class="resumen-card rc-neta">
              <span class="rc-label">Balance neto</span>
              <span class="rc-valor"><%= (inversionNeta >= 0 ? "+" : "") + String.format("$%.2f", inversionNeta) %></span>
              <span class="rc-sub">ingresos - inversión</span>
            </div>
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
              con = com.devbiz.util.DB.getConnection();

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

          <div class="tabla-wrap">
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
          </div>

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
