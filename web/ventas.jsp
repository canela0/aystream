<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.ArrayList"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) { response.sendRedirect("inicioSesion.jsp"); return; }

    String accion  = request.getParameter("accion");
    String idStr   = request.getParameter("productoId");
    String cantStr = request.getParameter("cantidad");
    String addedId = null;

    if ("agregar".equals(accion) && idStr != null && cantStr != null) {
        try {
            int prodId = Integer.parseInt(idStr);
            int cant   = Integer.parseInt(cantStr);
            if (cant > 0) {
                ArrayList<int[]> carrito = (ArrayList<int[]>) session.getAttribute("carrito");
                if (carrito == null) carrito = new ArrayList<>();
                boolean encontrado = false;
                for (int[] item : carrito) {
                    if (item[0] == prodId) { item[1] += cant; encontrado = true; break; }
                }
                if (!encontrado) carrito.add(new int[]{prodId, cant});
                session.setAttribute("carrito", carrito);
                addedId = idStr;
            }
        } catch (Exception e) {}
        response.sendRedirect("ventas.jsp?agregado=" + idStr);
        return;
    }

    if ("vaciar".equals(accion)) {
        session.removeAttribute("carrito");
        response.sendRedirect("ventas.jsp");
        return;
    }

    ArrayList<int[]> carrito = (ArrayList<int[]>) session.getAttribute("carrito");
    int itemsEnCarrito = 0;
    if (carrito != null) { for (int[] item : carrito) itemsEnCarrito += item[1]; }
    double totalCarrito = 0;

    // Calcular total del carrito para mostrarlo
    if (carrito != null && !carrito.isEmpty()) {
        Connection conCart = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conCart = com.devbiz.util.DB.getConnection();
            for (int[] item : carrito) {
                PreparedStatement stc = conCart.prepareStatement("SELECT precio FROM productos WHERE id=? AND usuario_id=?");
                stc.setInt(1, item[0]); stc.setInt(2, usuarioId);
                ResultSet rsc = stc.executeQuery();
                if (rsc.next()) totalCarrito += rsc.getDouble("precio") * item[1];
                rsc.close(); stc.close();
            }
        } catch (Exception e) {}
        finally { if (conCart != null) try { conCart.close(); } catch(Exception e){} }
    }

    String agregadoId = request.getParameter("agregado");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Nueva Venta – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    html, body { background: var(--bg); }
    .ventas-page { padding: 32px 40px 48px; }

    /* ── Header ── */
    .ventas-header { margin-bottom: 24px; display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
    .ventas-header-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-bottom: 6px; }
    .ventas-header-title { font-size: 22px; font-weight: 700; color: var(--text); }
    .ventas-header-sub   { font-size: 13px; color: var(--muted); margin-top: 4px; }

    /* ── Carrito flotante ── */
    .carrito-panel {
      background: var(--surface);
      border: 1.5px solid var(--border);
      border-radius: 12px;
      padding: 14px 18px;
      display: flex;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
      box-shadow: 0 2px 8px rgba(0,0,0,.07);
    }
    .carrito-info { display: flex; flex-direction: column; gap: 2px; }
    .carrito-info-label { font-size: 11px; color: var(--muted); font-weight: 600; text-transform: uppercase; letter-spacing: .05em; }
    .carrito-info-val   { font-size: 18px; font-weight: 700; color: var(--text); }
    .carrito-sep { width: 1px; height: 36px; background: var(--border); }
    .carrito-btn {
      display: flex; align-items: center; gap: 8px; padding: 10px 20px;
      background: var(--primary); color: #fff; border: none; border-radius: 8px;
      font-size: 14px; font-weight: 600; cursor: pointer; text-decoration: none;
      transition: background .15s, box-shadow .15s; font-family: inherit;
    }
    .carrito-btn:hover { background: var(--primary-h); box-shadow: var(--shadow-md); }
    .carrito-badge { background: #fff; color: var(--primary); border-radius: 99px; font-size: 11px; font-weight: 700; padding: 1px 7px; }
    .btn-vaciar {
      padding: 9px 16px; background: transparent; border: 1.5px solid #E5E7EB;
      border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer;
      color: #6B7280; font-family: inherit; transition: border-color .15s, color .15s;
    }
    .btn-vaciar:hover { border-color: #DC2626; color: #DC2626; }

    /* ── Buscador ── */
    .buscar-bar { margin-bottom: 20px; position: relative; max-width: 400px; }
    .buscar-bar svg { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9CA3AF; pointer-events: none; }
    .buscar-input {
      width: 100%; padding: 10px 14px 10px 38px;
      border: 1.5px solid var(--border); border-radius: 8px;
      font-size: 14px; font-family: inherit; background: var(--surface);
      transition: border-color .2s; box-sizing: border-box;
    }
    .buscar-input:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37,99,235,.1); }

    /* ── Grid ── */
    .productos-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }

    .producto-card {
      background: var(--surface); border: 1.5px solid var(--border);
      border-radius: 14px; padding: 0; overflow: hidden;
      box-shadow: 0 1px 4px rgba(0,0,0,.06);
      transition: box-shadow .2s, border-color .2s, transform .15s;
      display: flex; flex-direction: column;
    }
    .producto-card:hover { box-shadow: 0 6px 20px rgba(0,0,0,.1); border-color: #CBD5E1; transform: translateY(-2px); }
    .producto-card.recien-agregado { border-color: #16A34A; box-shadow: 0 0 0 3px rgba(22,163,74,.15); animation: pulseGreen .5s ease; }
    @keyframes pulseGreen { 0%,100% { box-shadow: 0 0 0 3px rgba(22,163,74,.15); } 50% { box-shadow: 0 0 0 6px rgba(22,163,74,.25); } }

    .card-top {
      padding: 18px 18px 14px;
      border-bottom: 1px solid #F3F4F6;
      flex: 1;
    }
    .producto-nombre { font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 8px; }
    .producto-precio { font-size: 24px; font-weight: 800; color: var(--primary); margin-bottom: 6px; }
    .stock-bar-wrap { display: flex; align-items: center; gap: 8px; margin-top: 8px; }
    .stock-bar-bg { flex: 1; height: 4px; background: #E5E7EB; border-radius: 99px; overflow: hidden; }
    .stock-bar-fill { height: 100%; border-radius: 99px; transition: width .4s; }
    .stock-bar-fill.ok   { background: #16A34A; }
    .stock-bar-fill.med  { background: #D97706; }
    .stock-bar-fill.bajo { background: #DC2626; }
    .stock-label { font-size: 12px; color: var(--muted); white-space: nowrap; }
    .stock-label.bajo { color: #DC2626; font-weight: 600; }

    .en-carrito-tag {
      display: inline-flex; align-items: center; gap: 5px;
      background: #DCFCE7; color: #16A34A; border-radius: 99px;
      font-size: 11px; font-weight: 700; padding: 3px 10px; margin-top: 8px;
    }

    .card-bottom { padding: 14px 18px; }
    .agregar-form { display: flex; gap: 8px; align-items: center; }
    .qty-input {
      width: 68px; padding: 9px 10px; border: 1.5px solid var(--border);
      border-radius: 8px; font-size: 14px; font-family: inherit;
      text-align: center; transition: border-color .2s;
    }
    .qty-input:focus { outline: none; border-color: var(--primary); }
    .btn-agregar {
      flex: 1; padding: 9px 12px; background: var(--primary); color: #fff;
      border: none; border-radius: 8px; font-size: 13px; font-weight: 600;
      cursor: pointer; font-family: inherit; transition: background .15s;
      display: flex; align-items: center; justify-content: center; gap: 6px;
    }
    .btn-agregar:hover { background: var(--primary-h); }
    .btn-agregar:disabled { background: #CBD5E1; cursor: not-allowed; }

    .sin-productos { grid-column: 1/-1; text-align: center; padding: 64px 0; color: var(--muted); }

    /* ── Toast ── */
    .toast-container { position: fixed; bottom: 24px; right: 24px; z-index: 9999; display: flex; flex-direction: column; gap: 10px; }
    .toast { display: flex; align-items: center; gap: 12px; padding: 14px 18px; border-radius: 10px; font-size: 13px; font-weight: 500; box-shadow: 0 8px 24px rgba(0,0,0,.15); min-width: 260px; max-width: 360px; background: #166534; color: #fff; animation: slideIn .3s ease; }
    @keyframes slideIn { from { transform: translateX(100%); opacity:0; } to { transform: translateX(0); opacity:1; } }
    @keyframes slideOut { to { transform: translateX(120%); opacity:0; } }

    /* contador de resultados */
    .resultados-label { font-size: 12px; color: var(--muted); margin-bottom: 12px; }
  </style>
</head>
<body>
<div class="toast-container" id="toastContainer"></div>
<div class="ventas-page">

  <div class="ventas-header">
    <div>
      <div class="ventas-header-label">Ventas</div>
      <h1 class="ventas-header-title">Nueva Venta</h1>
      <p class="ventas-header-sub">Selecciona productos y agrégalos al carrito</p>
    </div>

    <div class="carrito-panel">
      <div class="carrito-info">
        <span class="carrito-info-label">Productos en carrito</span>
        <span class="carrito-info-val"><%= itemsEnCarrito %> <%= itemsEnCarrito == 1 ? "artículo" : "artículos" %></span>
      </div>
      <% if (itemsEnCarrito > 0) { %>
      <div class="carrito-sep"></div>
      <div class="carrito-info">
        <span class="carrito-info-label">Total estimado</span>
        <span class="carrito-info-val" style="color:var(--primary);">$<%= String.format("%.2f", totalCarrito) %></span>
      </div>
      <div class="carrito-sep"></div>
      <form method="post" action="ventas.jsp" style="margin:0;">
        <input type="hidden" name="accion" value="vaciar"/>
        <button type="submit" class="btn-vaciar">Vaciar</button>
      </form>
      <% } %>
      <a class="carrito-btn" href="carritoCompras.jsp">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
          <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
        </svg>
        Ver carrito
        <% if (itemsEnCarrito > 0) { %><span class="carrito-badge"><%= itemsEnCarrito %></span><% } %>
      </a>
    </div>
  </div>

  <div class="buscar-bar">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
    </svg>
    <input class="buscar-input" type="text" id="buscador" placeholder="Buscar producto por nombre..." oninput="filtrar(this.value)"/>
  </div>
  <div class="resultados-label" id="resultadosLabel"></div>

  <div class="productos-grid" id="grid">
  <%
    Connection con = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = com.devbiz.util.DB.getConnection();
        PreparedStatement st = con.prepareStatement(
            "SELECT id, nombre, precio, cantidad FROM productos WHERE usuario_id=? AND cantidad > 0 ORDER BY nombre ASC"
        );
        st.setInt(1, usuarioId);
        ResultSet rs = st.executeQuery();
        boolean hayProductos = false;
        int maxStock = 1;

        // Pre-scan para máximo stock (para la barra proporcional)
        java.util.List<int[]>    idsList    = new java.util.ArrayList<>();
        java.util.List<String>   nombresList = new java.util.ArrayList<>();
        java.util.List<Double>   preciosList = new java.util.ArrayList<>();
        java.util.List<Integer>  stockList  = new java.util.ArrayList<>();
        while (rs.next()) {
            idsList.add(new int[]{rs.getInt("id")});
            nombresList.add(rs.getString("nombre"));
            preciosList.add(rs.getDouble("precio"));
            int s = rs.getInt("cantidad");
            stockList.add(s);
            if (s > maxStock) maxStock = s;
            hayProductos = true;
        }
        rs.close(); st.close();

        for (int i = 0; i < idsList.size(); i++) {
            int    id     = idsList.get(i)[0];
            String nombre = nombresList.get(i);
            double precio = preciosList.get(i);
            int    stock  = stockList.get(i);

            // ¿Está en el carrito?
            int enCarrito = 0;
            if (carrito != null) {
                for (int[] item : carrito) {
                    if (item[0] == id) { enCarrito = item[1]; break; }
                }
            }

            int pct = (int)((double)stock / maxStock * 100);
            String barClass = stock <= 3 ? "bajo" : (stock <= 10 ? "med" : "ok");
            boolean recienAgregado = String.valueOf(id).equals(agregadoId);
  %>
    <div class="producto-card <%= recienAgregado ? "recien-agregado" : "" %>" data-nombre="<%= nombre.toLowerCase() %>" id="card-<%= id %>">
      <div class="card-top">
        <div class="producto-nombre"><%= nombre %></div>
        <div class="producto-precio">$<%= String.format("%.2f", precio) %></div>
        <div class="stock-bar-wrap">
          <div class="stock-bar-bg"><div class="stock-bar-fill <%= barClass %>" style="width:<%= pct %>%"></div></div>
          <span class="stock-label <%= stock <= 3 ? "bajo" : "" %>">
            <%= stock <= 3 ? "⚠ " : "" %><%= stock %> uds.
          </span>
        </div>
        <% if (enCarrito > 0) { %>
          <div class="en-carrito-tag">✓ <%= enCarrito %> en carrito</div>
        <% } %>
      </div>
      <div class="card-bottom">
        <form class="agregar-form" method="post" action="ventas.jsp">
          <input type="hidden" name="accion"     value="agregar"/>
          <input type="hidden" name="productoId" value="<%= id %>"/>
          <input class="qty-input" type="number" name="cantidad" value="1" min="1" max="<%= stock %>"/>
          <button class="btn-agregar" type="submit">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Agregar
          </button>
        </form>
      </div>
    </div>
  <%
        }
        if (!hayProductos) {
  %>
    <div class="sin-productos">
      <p style="font-size:15px;font-weight:600;margin-bottom:8px;">No tienes productos en inventario</p>
      <p style="font-size:13px;">Agrega productos desde la sección <a href="agregarProducto.html">Inventario</a></p>
    </div>
  <%
        }
    } catch (Exception e) {
        out.println("<div class='sin-productos'>Error: " + e.getMessage() + "</div>");
    } finally {
        if (con != null) try { con.close(); } catch(Exception e){}
    }
  %>
  </div>
</div>

<script>
  function filtrar(q) {
    const term = q.toLowerCase();
    const cards = document.querySelectorAll('.producto-card');
    let vis = 0;
    cards.forEach(c => {
      const show = (c.dataset.nombre || '').includes(term);
      c.style.display = show ? '' : 'none';
      if (show) vis++;
    });
    const lbl = document.getElementById('resultadosLabel');
    lbl.textContent = q ? vis + ' resultado' + (vis !== 1 ? 's' : '') + ' encontrado' + (vis !== 1 ? 's' : '') : '';
  }

  function showToast(msg) {
    const cont = document.getElementById('toastContainer');
    const t = document.createElement('div');
    t.className = 'toast';
    t.innerHTML = '<span>✓</span><span>' + msg + '</span>';
    cont.appendChild(t);
    setTimeout(function() { t.style.animation = 'slideOut .3s ease forwards'; setTimeout(function(){ t.remove(); }, 300); }, 3000);
  }

  <% if (agregadoId != null) { %>
    window.addEventListener('DOMContentLoaded', function() {
      showToast('Producto agregado al carrito');
      var card = document.getElementById('card-<%= agregadoId %>');
      if (card) { card.scrollIntoView({ behavior: 'smooth', block: 'nearest' }); }
    });
  <% } %>
</script>
</body>
</html>
