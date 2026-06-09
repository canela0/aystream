<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.time.*"%>
<%@page import="java.time.temporal.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    Connection con = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
        );

        LocalDate hoy = LocalDate.now();

        for (int s = 0; s < 8; s++) {
            LocalDate lunes   = hoy.minusWeeks(s).with(DayOfWeek.MONDAY);
            LocalDate domingo = lunes.plusDays(6);
            String strLunes   = lunes.toString();
            String strDomingo = domingo.toString();

            // 1. Total vendido (ingresos reales de ventas)
            PreparedStatement stTV = con.prepareStatement(
                "SELECT COALESCE(SUM(total), 0) FROM ventas " +
                "WHERE usuario_id=? AND DATE(fecha) BETWEEN ? AND ?");
            stTV.setInt(1, usuarioId); stTV.setString(2, strLunes); stTV.setString(3, strDomingo);
            ResultSet rsTV = stTV.executeQuery();
            double totalVendido = rsTV.next() ? rsTV.getDouble(1) : 0;
            rsTV.close(); stTV.close();

            // 2. Número de ventas
            PreparedStatement stNV = con.prepareStatement(
                "SELECT COUNT(*) FROM ventas " +
                "WHERE usuario_id=? AND DATE(fecha) BETWEEN ? AND ?");
            stNV.setInt(1, usuarioId); stNV.setString(2, strLunes); stNV.setString(3, strDomingo);
            ResultSet rsNV = stNV.executeQuery();
            int numVentas = rsNV.next() ? rsNV.getInt(1) : 0;
            rsNV.close(); stNV.close();

            // 3. Inversión de la semana = lo que costó dar de ALTA productos
            //    (cantidad_nueva * precio_nuevo de movimientos ALTA)
            PreparedStatement stInv = con.prepareStatement(
                "SELECT COALESCE(SUM(cantidad_nueva * precio_nuevo), 0) " +
                "FROM movimientos_inventario " +
                "WHERE usuario_id=? AND tipo_movimiento='ALTA' " +
                "AND DATE(fecha) BETWEEN ? AND ?");
            stInv.setInt(1, usuarioId); stInv.setString(2, strLunes); stInv.setString(3, strDomingo);
            ResultSet rsInv = stInv.executeQuery();
            double inversionSemana = rsInv.next() ? rsInv.getDouble(1) : 0;
            rsInv.close(); stInv.close();

            // 4. Número de altas y bajas
            PreparedStatement stMov = con.prepareStatement(
                "SELECT tipo_movimiento, COUNT(*) AS cnt " +
                "FROM movimientos_inventario " +
                "WHERE usuario_id=? AND DATE(fecha) BETWEEN ? AND ? " +
                "AND tipo_movimiento IN ('ALTA','BAJA') GROUP BY tipo_movimiento");
            stMov.setInt(1, usuarioId); stMov.setString(2, strLunes); stMov.setString(3, strDomingo);
            ResultSet rsMov = stMov.executeQuery();
            int altas = 0, bajas = 0;
            while (rsMov.next()) {
                if ("ALTA".equals(rsMov.getString("tipo_movimiento"))) altas = rsMov.getInt("cnt");
                else bajas = rsMov.getInt("cnt");
            }
            rsMov.close(); stMov.close();

            // 5. Valor actual del inventario (a precio de costo)
            PreparedStatement stVI = con.prepareStatement(
                "SELECT COALESCE(SUM(COALESCE(precio_costo, precio) * cantidad), 0) FROM productos WHERE usuario_id=?");
            stVI.setInt(1, usuarioId);
            ResultSet rsVI = stVI.executeQuery();
            double valorInvFin = rsVI.next() ? rsVI.getDouble(1) : 0;
            rsVI.close(); stVI.close();

            // valor inventario inicio = fin + lo vendido esta semana (a precio de venta)
            // - lo invertido esta semana (altas)
            double valorInvIni = valorInvFin - inversionSemana + totalVendido;
            if (valorInvIni < 0) valorInvIni = 0;

            // 6. Guardar/actualizar balance
            // Usamos costo_productos_vendidos para guardar la inversión de la semana
            PreparedStatement stBS = con.prepareStatement(
                "INSERT INTO balance_semanal " +
                "(usuario_id, semana_inicio, semana_fin, valor_inventario_inicio, " +
                " valor_inventario_fin, total_vendido, costo_productos_vendidos, " +
                " num_ventas, num_productos_agregados, num_productos_eliminados) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?) " +
                "ON DUPLICATE KEY UPDATE " +
                "  semana_fin                 = VALUES(semana_fin), " +
                "  valor_inventario_inicio    = VALUES(valor_inventario_inicio), " +
                "  valor_inventario_fin       = VALUES(valor_inventario_fin), " +
                "  total_vendido              = VALUES(total_vendido), " +
                "  costo_productos_vendidos   = VALUES(costo_productos_vendidos), " +
                "  num_ventas                 = VALUES(num_ventas), " +
                "  num_productos_agregados    = VALUES(num_productos_agregados), " +
                "  num_productos_eliminados   = VALUES(num_productos_eliminados)");
            stBS.setInt(1, usuarioId);   stBS.setString(2, strLunes);
            stBS.setString(3, strDomingo);
            stBS.setDouble(4, valorInvIni);   stBS.setDouble(5, valorInvFin);
            stBS.setDouble(6, totalVendido);  stBS.setDouble(7, inversionSemana);
            stBS.setInt(8, numVentas);        stBS.setInt(9, altas);
            stBS.setInt(10, bajas);
            stBS.executeUpdate(); stBS.close();
        }

    } catch (Exception e) {
        // continua hacia el HTML
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Balance Semanal – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    html, body { background: var(--bg); }

    .balance-page { padding: 32px 40px 48px; }

    /* ── Encabezado ── */
    .balance-header { margin-bottom: 28px; }
    .balance-header-label {
      font-size: 11px; font-weight: 700; text-transform: uppercase;
      letter-spacing: .08em; color: var(--muted); margin-bottom: 6px;
    }
    .balance-header-title { font-size: 22px; font-weight: 700; color: var(--text); }
    .balance-header-sub   { font-size: 13px; color: var(--muted); margin-top: 4px; }

    /* ── KPI cards ── */
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }
    .kpi-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 20px 22px;
      box-shadow: var(--shadow-sm);
    }
    .kpi-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .06em; color: var(--muted); margin-bottom: 8px; }
    .kpi-value { font-size: 24px; font-weight: 700; color: var(--text); }
    .kpi-sub   { font-size: 11px; color: var(--muted); margin-top: 4px; }
    .kpi-card.verde  { border-top: 3px solid var(--green); }
    .kpi-card.azul   { border-top: 3px solid var(--primary); }
    .kpi-card.naranja{ border-top: 3px solid var(--orange); }
    .kpi-card.morado { border-top: 3px solid var(--purple); }

    /* ── Tabla ── */
    .tabla-wrap { overflow-x: auto; }

    table { margin-top: 0; font-size: 13px; }
    th { font-size: 11px; }

    .semana-actual td { background: #eff6ff !important; }
    .semana-actual td:first-child { font-weight: 600; }

    .pos { color: #16a34a; font-weight: 600; }
    .neg { color: var(--red); font-weight: 600; }
    .neu { color: var(--muted); font-weight: 500; }

    .badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 99px;
      font-size: 11px;
      font-weight: 600;
    }
    .badge-green  { background: #dcfce7; color: #16a34a; }
    .badge-red    { background: #fee2e2; color: #dc2626; }
    .badge-gray   { background: #f1f5f9; color: #64748b; }

    .sin-datos { text-align: center; color: var(--muted); padding: 48px; }
  </style>
</head>
<body>
<div class="balance-page">

  <div class="balance-header">
    <div class="balance-header-label">Reportes</div>
    <h1 class="balance-header-title">Balance Semanal</h1>
    <p class="balance-header-sub">Últimas 8 semanas · Inversión vs Ventas</p>
  </div>

  <%
    PreparedStatement stLeer = null;
    ResultSet rsLeer = null;

    double kpiVentas4s     = 0;
    double kpiInversion4s  = 0;
    int    kpiNumVentas4s  = 0;
    double kpiInventario   = 0;

    java.util.List<java.util.Map<String,Object>> rows = new java.util.ArrayList<>();

    try {
      stLeer = con.prepareStatement(
        "SELECT * FROM balance_semanal WHERE usuario_id=? ORDER BY semana_inicio DESC LIMIT 8"
      );
      stLeer.setInt(1, usuarioId);
      rsLeer = stLeer.executeQuery();

      while (rsLeer.next()) {
        java.util.Map<String,Object> row = new java.util.LinkedHashMap<>();
        row.put("semana_inicio",    rsLeer.getString("semana_inicio"));
        row.put("semana_fin",       rsLeer.getString("semana_fin"));
        row.put("inv_inicio",       rsLeer.getDouble("valor_inventario_inicio"));
        row.put("inv_fin",          rsLeer.getDouble("valor_inventario_fin"));
        row.put("total_vendido",    rsLeer.getDouble("total_vendido"));
        row.put("inversion",        rsLeer.getDouble("costo_productos_vendidos")); // campo reutilizado
        row.put("num_ventas",       rsLeer.getInt("num_ventas"));
        row.put("altas",            rsLeer.getInt("num_productos_agregados"));
        row.put("bajas",            rsLeer.getInt("num_productos_eliminados"));
        rows.add(row);

        if (rows.size() <= 4) {
          kpiVentas4s    += (Double)  row.get("total_vendido");
          kpiInversion4s += (Double)  row.get("inversion");
          kpiNumVentas4s += (Integer) row.get("num_ventas");
        }
        if (rows.size() == 1) {
          kpiInventario = (Double) row.get("inv_fin");
        }
      }
    } catch (Exception e) {
      // silencioso
    } finally {
      if (rsLeer != null) try { rsLeer.close(); } catch(Exception e){}
      if (stLeer != null) try { stLeer.close(); } catch(Exception e){}
      if (con    != null) try { con.close();    } catch(Exception e){}
    }

    double kpiBalance4s = kpiVentas4s - kpiInversion4s;
  %>

  <!-- KPIs -->
  <div class="kpi-grid">
    <div class="kpi-card verde">
      <div class="kpi-label">Ventas (4 sem.)</div>
      <div class="kpi-value">$<%= String.format("%.2f", kpiVentas4s) %></div>
      <div class="kpi-sub">ingresos totales</div>
    </div>
    <div class="kpi-card naranja">
      <div class="kpi-label">Inversión (4 sem.)</div>
      <div class="kpi-value">$<%= String.format("%.2f", kpiInversion4s) %></div>
      <div class="kpi-sub">productos agregados</div>
    </div>
    <div class="kpi-card <%= kpiBalance4s >= 0 ? "verde" : "morado" %>">
      <div class="kpi-label">Balance neto (4 sem.)</div>
      <div class="kpi-value <%= kpiBalance4s >= 0 ? "pos" : "neg" %>">
        <%= kpiBalance4s >= 0 ? "+" : "" %>$<%= String.format("%.2f", kpiBalance4s) %>
      </div>
      <div class="kpi-sub">ventas − inversión</div>
    </div>
    <div class="kpi-card azul">
      <div class="kpi-label">Inventario actual</div>
      <div class="kpi-value">$<%= String.format("%.2f", kpiInventario) %></div>
      <div class="kpi-sub">valor en stock</div>
    </div>
    <div class="kpi-card azul">
      <div class="kpi-label">Transacciones (4 sem.)</div>
      <div class="kpi-value"><%= kpiNumVentas4s %></div>
      <div class="kpi-sub">ventas completadas</div>
    </div>
  </div>

  <!-- Tabla -->
  <div class="tabla-wrap">
    <table>
      <thead>
        <tr>
          <th>Semana</th>
          <th>Inversión</th>
          <th>Ventas</th>
          <th>Balance neto</th>
          <th>Inv. inicio</th>
          <th>Inv. fin</th>
          <th>Ventas #</th>
          <th>Altas</th>
          <th>Bajas</th>
        </tr>
      </thead>
      <tbody>
      <%
        if (rows.isEmpty()) {
      %>
        <tr><td colspan="9" class="sin-datos">No hay datos registrados todavía.</td></tr>
      <%
        } else {
          for (int i = 0; i < rows.size(); i++) {
            java.util.Map<String,Object> r = rows.get(i);
            double vendido   = (Double)  r.get("total_vendido");
            double inversion = (Double)  r.get("inversion");
            double balance   = vendido - inversion;
            String balStr    = (balance >= 0 ? "+" : "") + "$" + String.format("%.2f", balance);
            String balCls    = balance > 0 ? "pos" : (balance < 0 ? "neg" : "neu");
            String rowCls    = i == 0 ? "semana-actual" : "";
      %>
        <tr class="<%= rowCls %>">
          <td><%= r.get("semana_inicio") %> – <%= r.get("semana_fin") %></td>
          <td class="neg">$<%= String.format("%.2f", inversion) %></td>
          <td class="pos">$<%= String.format("%.2f", vendido) %></td>
          <td class="<%= balCls %>"><%= balStr %></td>
          <td>$<%= String.format("%.2f", (Double) r.get("inv_inicio")) %></td>
          <td>$<%= String.format("%.2f", (Double) r.get("inv_fin")) %></td>
          <td><%= r.get("num_ventas") %></td>
          <td><span class="badge badge-green">+<%= r.get("altas") %></span></td>
          <td><span class="badge badge-red">-<%= r.get("bajas") %></span></td>
        </tr>
      <%
          }
        }
      %>
      </tbody>
    </table>
  </div>

</div>
</body>
</html>
