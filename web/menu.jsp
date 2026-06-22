<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.time.LocalDate"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="java.util.LinkedHashMap"%>
<%@page import="java.util.Map"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Inicio – PayStream</title>
  <link rel="stylesheet" href="estilo.css" />
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <style>
    html, body { height: 100%; overflow-y: auto; }

    .home-page {
      padding: 48px 48px 40px;
      min-height: 100vh;
      background: var(--bg);
    }

    .home-greeting { margin-bottom: 48px; }
    .home-greeting-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-bottom: 6px; }
    .home-greeting-title { font-size: 26px; font-weight: 700; color: var(--text); letter-spacing: -.4px; }
    .home-greeting-sub { color: var(--muted); margin-top: 6px; font-size: 14px; }

    .section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-bottom: 14px; }

    .quick-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 48px; }

    .quick-btn {
      display: flex; align-items: center; gap: 10px; padding: 13px 20px;
      background: var(--surface); border: 1.5px solid var(--border); border-radius: 10px;
      font-size: 14px; font-weight: 600; color: var(--text); cursor: pointer;
      text-decoration: none; transition: border-color .15s, box-shadow .15s, transform .1s; font-family: inherit;
    }
    .quick-btn:hover { border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37,99,235,.1); transform: translateY(-1px); }
    .quick-btn:active { transform: scale(.98); }
    .quick-btn svg { flex-shrink: 0; }
    .quick-btn.primary { background: var(--primary); border-color: var(--primary); color: #fff; }
    .quick-btn.primary:hover { background: var(--primary-h); border-color: var(--primary-h); box-shadow: 0 4px 12px rgba(37,99,235,.3); }

    /* ── Chart card ── */
    .chart-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 24px 28px;
      margin-bottom: 40px;
      box-shadow: 0 1px 4px rgba(0,0,0,.06);
    }
    .chart-card-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 20px; }
    .chart-card-title { font-size: 15px; font-weight: 700; color: var(--text); margin: 0 0 2px; }
    .chart-card-sub { font-size: 12px; color: var(--muted); margin: 0; }
    .chart-total { font-size: 22px; font-weight: 700; color: var(--primary); }
    .chart-total-label { font-size: 11px; color: var(--muted); text-align: right; margin-top: 2px; }
    .chart-wrap { position: relative; height: 180px; }

    /* ── Tips ── */
    .tips-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 14px; }
    .tip-card { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 18px 20px; }
    .tip-icon { width: 34px; height: 34px; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-bottom: 12px; }
    .tip-icon.green  { background: #dcfce7; color: var(--green); }
    .tip-icon.orange { background: #ffedd5; color: var(--orange); }
    .tip-icon.purple { background: #ede9fe; color: var(--purple); }
    .tip-title { font-size: 13px; font-weight: 600; color: var(--text); margin-bottom: 4px; }
    .tip-desc  { font-size: 12px; color: var(--muted); line-height: 1.5; }
  </style>
</head>
<body>

<%
  Integer usuarioId = (Integer) session.getAttribute("usuarioId");
  String nombreUsuario = (String) session.getAttribute("nombre");
  if (usuarioId == null) { response.sendRedirect("inicioSesion.jsp"); return; }

  // Obtener ventas de los últimos 7 días
  Map<String, Double> ventasPorDia = new LinkedHashMap<>();
  DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM");
  LocalDate hoy = LocalDate.now();
  for (int i = 6; i >= 0; i--) {
      ventasPorDia.put(hoy.minusDays(i).format(fmt), 0.0);
  }

  double totalSemana = 0;
  Connection con = null;
  try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = com.devbiz.util.DB.getConnection();
      PreparedStatement st = con.prepareStatement(
          "SELECT DATE(fecha) AS dia, SUM(total) AS suma " +
          "FROM ventas WHERE usuario_id=? AND fecha >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
          "GROUP BY dia ORDER BY dia ASC"
      );
      st.setInt(1, usuarioId);
      ResultSet rs = st.executeQuery();
      while (rs.next()) {
          java.sql.Date dia = rs.getDate("dia");
          double suma = rs.getDouble("suma");
          LocalDate ld = dia.toLocalDate();
          String key = ld.format(fmt);
          if (ventasPorDia.containsKey(key)) ventasPorDia.put(key, suma);
          totalSemana += suma;
      }
      rs.close(); st.close();
  } catch (Exception e) { /* silent – chart shows zeros */ }
  finally { if (con != null) try { con.close(); } catch(Exception e){} }

  StringBuilder labels = new StringBuilder();
  StringBuilder datos  = new StringBuilder();
  for (Map.Entry<String, Double> e : ventasPorDia.entrySet()) {
      if (labels.length() > 0) { labels.append(","); datos.append(","); }
      labels.append("'").append(e.getKey()).append("'");
      datos.append(String.format("%.2f", e.getValue()));
  }
%>

<div class="home-page">

  <div class="home-greeting">
    <div class="home-greeting-label">Panel principal</div>
    <h1 class="home-greeting-title">¡Bienvenido<% if(nombreUsuario!=null){ %>, <%= nombreUsuario.split(" ")[0] %><% } %>!</h1>
    <p class="home-greeting-sub">¿Qué quieres hacer hoy?</p>
  </div>

  <div class="section-label">Acciones rápidas</div>
  <div class="quick-actions">

    <a class="quick-btn primary" href="ventas.jsp" target="_self">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
        <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
      </svg>
      Nueva venta
    </a>

    <a class="quick-btn" href="agregarProducto.html" target="_self">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
      </svg>
      Agregar producto
    </a>

    <a class="quick-btn" href="consultarProductos.jsp" target="_self">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
      Consultar stock
    </a>

    <a class="quick-btn" href="historialVentas.jsp" target="_self">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
      </svg>
      Ver historial
    </a>

    <a class="quick-btn" href="balanceSemanal.jsp" target="_self">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="20" x2="18" y2="10"/>
        <line x1="12" y1="20" x2="12" y2="4"/>
        <line x1="6"  y1="20" x2="6"  y2="14"/>
      </svg>
      Balance semanal
    </a>

  </div>

  <!-- Gráfico de ventas -->
  <div class="section-label">Ventas de los últimos 7 días</div>
  <div class="chart-card">
    <div class="chart-card-header">
      <div>
        <p class="chart-card-title">Ingresos por día</p>
        <p class="chart-card-sub">Ventas registradas en los últimos 7 días</p>
      </div>
      <div style="text-align:right;">
        <div class="chart-total">$<%= String.format("%.2f", totalSemana) %></div>
        <div class="chart-total-label">Total del período</div>
      </div>
    </div>
    <div class="chart-wrap">
      <canvas id="ventasChart"></canvas>
    </div>
  </div>

  <div class="section-label">Recordatorios</div>
  <div class="tips-grid">

    <div class="tip-card">
      <div class="tip-icon green">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
        </svg>
      </div>
      <div class="tip-title">Revisa tu inventario</div>
      <div class="tip-desc">Mantén el stock actualizado para evitar ventas fallidas.</div>
    </div>

    <div class="tip-card">
      <div class="tip-icon orange">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
          <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
          <line x1="3" y1="10" x2="21" y2="10"/>
        </svg>
      </div>
      <div class="tip-title">Balance semanal</div>
      <div class="tip-desc">El balance se genera automáticamente cada semana.</div>
    </div>

    <div class="tip-card">
      <div class="tip-icon purple">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
        </svg>
      </div>
      <div class="tip-title">Analiza tus ventas</div>
      <div class="tip-desc">Usa los reportes para identificar tus productos más vendidos.</div>
    </div>

  </div>

</div>

<script>
  const ctx = document.getElementById('ventasChart').getContext('2d');
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: [<%= labels %>],
      datasets: [{
        label: 'Ventas ($)',
        data: [<%= datos %>],
        backgroundColor: 'rgba(37,99,235,0.15)',
        borderColor: 'rgba(37,99,235,0.85)',
        borderWidth: 2,
        borderRadius: 6,
        borderSkipped: false,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: ctx => '$' + ctx.parsed.y.toFixed(2)
          }
        }
      },
      scales: {
        x: { grid: { display: false }, ticks: { font: { size: 11 } } },
        y: {
          beginAtZero: true,
          ticks: { font: { size: 11 }, callback: v => '$' + v },
          grid: { color: 'rgba(0,0,0,.05)' }
        }
      }
    }
  });
</script>
</body>
</html>
