<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.ArrayList"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    // ── Agregar producto al carrito ──────────────────────────────────
    String accion      = request.getParameter("accion");
    String idStr       = request.getParameter("productoId");
    String cantStr     = request.getParameter("cantidad");

    if ("agregar".equals(accion) && idStr != null && cantStr != null) {
        try {
            int prodId  = Integer.parseInt(idStr);
            int cant    = Integer.parseInt(cantStr);
            if (cant > 0) {
                ArrayList<int[]> carrito =
                    (ArrayList<int[]>) session.getAttribute("carrito");
                if (carrito == null) carrito = new ArrayList<>();

                // Si ya está en el carrito, sumar cantidad
                boolean encontrado = false;
                for (int[] item : carrito) {
                    if (item[0] == prodId) {
                        item[1] += cant;
                        encontrado = true;
                        break;
                    }
                }
                if (!encontrado) carrito.add(new int[]{prodId, cant});
                session.setAttribute("carrito", carrito);
            }
        } catch (Exception e) { /* ignorar */ }
        response.sendRedirect("ventas.jsp");
        return;
    }

    // ── Vaciar carrito ───────────────────────────────────────────────
    if ("vaciar".equals(accion)) {
        session.removeAttribute("carrito");
        response.sendRedirect("ventas.jsp");
        return;
    }

    // ── Leer carrito actual ──────────────────────────────────────────
    ArrayList<int[]> carrito =
        (ArrayList<int[]>) session.getAttribute("carrito");
    int itemsEnCarrito = carrito != null ? carrito.size() : 0;
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

    .ventas-header { margin-bottom: 28px; display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
    .ventas-header-left {}
    .ventas-header-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-bottom: 6px; }
    .ventas-header-title { font-size: 22px; font-weight: 700; color: var(--text); }
    .ventas-header-sub   { font-size: 13px; color: var(--muted); margin-top: 4px; }

    .carrito-btn {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 18px;
      background: var(--primary);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      transition: background .15s, box-shadow .15s;
      font-family: inherit;
    }
    .carrito-btn:hover { background: var(--primary-h); box-shadow: var(--shadow-md); }

    .carrito-badge {
      background: #fff;
      color: var(--primary);
      border-radius: 99px;
      font-size: 11px;
      font-weight: 700;
      padding: 1px 7px;
    }

    /* Grid de productos */
    .productos-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: 16px;
    }

    .producto-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 20px;
      box-shadow: var(--shadow-sm);
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .producto-card.sin-stock {
      opacity: .55;
    }

    .producto-nombre {
      font-size: 15px;
      font-weight: 600;
      color: var(--text);
    }

    .producto-precio {
      font-size: 20px;
      font-weight: 700;
      color: var(--primary);
    }

    .producto-stock {
      font-size: 12px;
      color: var(--muted);
    }

    .producto-stock.bajo { color: var(--red); font-weight: 600; }

    .agregar-form {
      display: flex;
      gap: 8px;
      align-items: center;
      margin-top: 4px;
    }

    .qty-input {
      width: 70px;
      padding: 8px 10px;
      border: 1.5px solid var(--border);
      border-radius: 8px;
      font-size: 14px;
      font-family: inherit;
      text-align: center;
      transition: border-color .2s;
    }
    .qty-input:focus { outline: none; border-color: var(--primary); }

    .btn-agregar {
      flex: 1;
      padding: 8px 12px;
      background: var(--primary);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      font-family: inherit;
      transition: background .15s;
    }
    .btn-agregar:hover { background: var(--primary-h); }
    .btn-agregar:disabled { background: #cbd5e1; cursor: not-allowed; }

    .sin-productos {
      grid-column: 1 / -1;
      text-align: center;
      padding: 64px 0;
      color: var(--muted);
    }

    .buscar-bar {
      margin-bottom: 20px;
    }
    .buscar-input {
      width: 100%;
      max-width: 360px;
      padding: 10px 14px;
      border: 1.5px solid var(--border);
      border-radius: 8px;
      font-size: 14px;
      font-family: inherit;
      background: var(--surface);
      transition: border-color .2s;
    }
    .buscar-input:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37,99,235,.1); }
  </style>
</head>
<body>
<div class="ventas-page">

  <div class="ventas-header">
    <div class="ventas-header-left">
      <div class="ventas-header-label">Ventas</div>
      <h1 class="ventas-header-title">Nueva Venta</h1>
      <p class="ventas-header-sub">Selecciona productos y agrégalos al carrito</p>
    </div>

    <div style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
      <% if (itemsEnCarrito > 0) { %>
      <form method="post" action="ventas.jsp">
        <input type="hidden" name="accion" value="vaciar"/>
        <button type="submit" class="boton boton-borde" style="font-size:13px;">
          Vaciar carrito
        </button>
      </form>
      <% } %>
      <a class="carrito-btn" href="carritoCompras.jsp">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
          <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
        </svg>
        Ver carrito
        <% if (itemsEnCarrito > 0) { %>
          <span class="carrito-badge"><%= itemsEnCarrito %></span>
        <% } %>
      </a>
    </div>
  </div>

  <!-- Buscador -->
  <div class="buscar-bar">
    <input class="buscar-input" type="text" id="buscador"
           placeholder="Buscar producto por nombre..."
           oninput="filtrar(this.value)"/>
  </div>

  <!-- Grid de productos -->
  <div class="productos-grid" id="grid">
  <%
    Connection con = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
        );
        PreparedStatement st = con.prepareStatement(
            "SELECT id, nombre, precio, cantidad FROM productos " +
            "WHERE usuario_id=? AND cantidad > 0 ORDER BY nombre ASC"
        );
        st.setInt(1, usuarioId);
        ResultSet rs = st.executeQuery();
        boolean hayProductos = false;

        while (rs.next()) {
            hayProductos = true;
            int    id       = rs.getInt("id");
            String nombre   = rs.getString("nombre");
            double precio   = rs.getDouble("precio");
            int    stock    = rs.getInt("cantidad");
            boolean sinStock = stock == 0;
  %>
    <div class="producto-card <%= sinStock ? "sin-stock" : "" %>" data-nombre="<%= nombre.toLowerCase() %>">
      <div>
        <div class="producto-nombre"><%= nombre %></div>
        <div class="producto-precio">$<%= String.format("%.2f", precio) %></div>
        <div class="producto-stock <%= stock <= 3 && stock > 0 ? "bajo" : "" %>">
          Stock: <%= stock %> <%= sinStock ? "— Sin stock" : (stock <= 3 ? "— Poco stock" : "unidades") %>
        </div>
      </div>
      <form class="agregar-form" method="post" action="ventas.jsp">
        <input type="hidden" name="accion"     value="agregar"/>
        <input type="hidden" name="productoId" value="<%= id %>"/>
        <input class="qty-input" type="number" name="cantidad"
               value="1" min="1" max="<%= stock %>"
               <%= sinStock ? "disabled" : "" %>/>
        <button class="btn-agregar" type="submit"
                <%= sinStock ? "disabled" : "" %>>
          + Agregar
        </button>
      </form>
    </div>
  <%
        }
        if (!hayProductos) {
  %>
    <div class="sin-productos">
      <p style="font-size:15px; font-weight:600; margin-bottom:8px;">No tienes productos en inventario</p>
      <p style="font-size:13px;">Agrega productos desde la sección <a href="agregarProducto.html" class="enlace">Inventario</a></p>
    </div>
  <%
        }
        rs.close(); st.close();
    } catch (Exception e) {
        out.println("<div class='sin-productos'>Error al cargar productos: " + e.getMessage() + "</div>");
    } finally {
        if (con != null) try { con.close(); } catch(Exception e){}
    }
  %>
  </div>

</div>

<script>
  function filtrar(q) {
    const term = q.toLowerCase();
    document.querySelectorAll('.producto-card').forEach(card => {
      const nombre = card.dataset.nombre || '';
      card.style.display = nombre.includes(term) ? '' : 'none';
    });
  }
</script>

</body>
</html>
