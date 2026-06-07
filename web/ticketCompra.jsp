<%@page contentType="text/html; charset=UTF-8"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.sql.*"%>
<%@page import="java.time.LocalDateTime"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    ArrayList<int[]> carrito = (ArrayList<int[]>) session.getAttribute("carrito");
    if (carrito == null || carrito.isEmpty()) {
        response.sendRedirect("registroCompra.jsp");
        return;
    }

    // Limpiar carrito de sesion ANTES de procesar (evita doble descuento si recarga)
    session.removeAttribute("carrito");

    Connection con = null;

    int    idVenta   = 0;
    double total     = 0;
    java.util.List<String>   nombres    = new java.util.ArrayList<>();
    java.util.List<Double>   precios    = new java.util.ArrayList<>();
    java.util.List<Integer>  cantidades = new java.util.ArrayList<>();
    java.util.List<Double>   subtotales = new java.util.ArrayList<>();
    java.util.List<String>   alertas    = new java.util.ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
        );

        // ── Paso 1: Recopilar datos de cada item del carrito ──────────────
        for (int[] item : carrito) {
            int idProducto     = item[0];
            int cantidadPedida = item[1];

            PreparedStatement stSel = con.prepareStatement(
                "SELECT nombre, precio, cantidad FROM productos WHERE id=? AND usuario_id=?"
            );
            stSel.setInt(1, idProducto);
            stSel.setInt(2, usuarioId);
            ResultSet rs = stSel.executeQuery();

            if (rs.next()) {
                String nombre      = rs.getString("nombre");
                double precio      = rs.getDouble("precio");
                int    stockActual = rs.getInt("cantidad");

                int cantidadADescontar = Math.min(cantidadPedida, stockActual);

                if (cantidadPedida > stockActual) {
                    alertas.add("Stock insuficiente para \"" + nombre + "\". " +
                        "Pediste " + cantidadPedida + ", disponibles: " + stockActual +
                        ". Se procesaron " + stockActual + ".");
                }

                if (cantidadADescontar > 0) {
                    double subtotal = precio * cantidadADescontar;
                    total += subtotal;
                    nombres.add(nombre);
                    precios.add(precio);
                    cantidades.add(cantidadADescontar);
                    subtotales.add(subtotal);
                }
            }
            rs.close();
            stSel.close();
        }

        // ── Paso 2: Insertar cabecera de venta ────────────────────────────
        PreparedStatement stVenta = con.prepareStatement(
            "INSERT INTO ventas (usuario_id, total) VALUES (?, ?)",
            Statement.RETURN_GENERATED_KEYS
        );
        stVenta.setInt(1, usuarioId);
        stVenta.setDouble(2, total);
        stVenta.executeUpdate();

        ResultSet rsKeys = stVenta.getGeneratedKeys();
        idVenta = rsKeys.next() ? rsKeys.getInt(1) : -1;
        rsKeys.close();
        stVenta.close();

        // ── Paso 3: Insertar detalle, descontar stock y registrar movimiento
        for (int i = 0; i < nombres.size(); i++) {
            // Buscar id del producto por nombre y usuario (carrito ya fue limpiado)
            PreparedStatement stIdProd = con.prepareStatement(
                "SELECT id, cantidad FROM productos WHERE nombre=? AND usuario_id=? LIMIT 1"
            );
            stIdProd.setString(1, nombres.get(i));
            stIdProd.setInt(2, usuarioId);
            ResultSet rsId = stIdProd.executeQuery();
            int idProducto  = -1;
            int stockActual = 0;
            if (rsId.next()) {
                idProducto  = rsId.getInt("id");
                stockActual = rsId.getInt("cantidad");
            }
            rsId.close(); stIdProd.close();

            // a) detalle_venta
            PreparedStatement stDet = con.prepareStatement(
                "INSERT INTO detalle_venta " +
                "(venta_id, producto_id, nombre_producto, cantidad, precio_unitario, subtotal) " +
                "VALUES (?, ?, ?, ?, ?, ?)"
            );
            stDet.setInt(1, idVenta);
            if (idProducto != -1) stDet.setInt(2, idProducto); else stDet.setNull(2, Types.INTEGER);
            stDet.setString(3, nombres.get(i));
            stDet.setInt(4, cantidades.get(i));
            stDet.setDouble(5, precios.get(i));
            stDet.setDouble(6, subtotales.get(i));
            stDet.executeUpdate();
            stDet.close();

            if (idProducto != -1) {
                int cantNueva = stockActual - cantidades.get(i);

                // b) descontar stock e incrementar numero_compras
                PreparedStatement stUpd = con.prepareStatement(
                    "UPDATE productos SET cantidad = cantidad - ?, " +
                    "numero_compras = numero_compras + ? WHERE id=? AND usuario_id=?"
                );
                stUpd.setInt(1, cantidades.get(i));
                stUpd.setInt(2, cantidades.get(i));
                stUpd.setInt(3, idProducto);
                stUpd.setInt(4, usuarioId);
                stUpd.executeUpdate();
                stUpd.close();

                // c) movimiento tipo VENTA
                PreparedStatement stMov = con.prepareStatement(
                    "INSERT INTO movimientos_inventario " +
                    "(producto_id, usuario_id, tipo_movimiento, " +
                    " cantidad_anterior, cantidad_nueva, precio_anterior, venta_id, descripcion) " +
                    "VALUES (?, ?, 'VENTA', ?, ?, ?, ?, ?)"
                );
                stMov.setInt(1, idProducto);
                stMov.setInt(2, usuarioId);
                stMov.setInt(3, stockActual);
                stMov.setInt(4, cantNueva);
                stMov.setDouble(5, precios.get(i));
                stMov.setInt(6, idVenta);
                stMov.setString(7, "Venta #" + idVenta + ": " + cantidades.get(i) + " x " + nombres.get(i));
                stMov.executeUpdate();
                stMov.close();
            }
        }

    } catch (Exception e) {
        out.println("<p style='color:red'>Error al procesar la compra: " + e.getMessage() + "</p>");
    } finally {
        if (con != null) con.close();
    }

    DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    String fechaHora = LocalDateTime.now().format(fmt);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Ticket #<%= idVenta %> – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    html, body { background: var(--bg); }

    .ticket-page {
      padding: 40px 24px 60px;
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    /* ── Acciones (no se imprimen) ── */
    .ticket-actions {
      display: flex;
      gap: 10px;
      margin-bottom: 28px;
      width: 100%;
      max-width: 360px;
    }

    .ticket-actions .boton { flex: 1; text-align: center; }

    /* ── Ticket ── */
    .ticket {
      width: 100%;
      max-width: 360px;
      background: #fff;
      border-radius: 4px;
      box-shadow: 0 2px 8px rgba(0,0,0,.12), 0 0 0 1px rgba(0,0,0,.04);
      font-family: "Courier New", Courier, monospace;
      font-size: 13px;
      color: #1a1a1a;
      position: relative;

      /* Borde dentado superior */
      padding-top: 20px;
    }

    /* Efecto papel dentado arriba */
    .ticket::before {
      content: "";
      position: absolute;
      top: -10px; left: 0; right: 0;
      height: 20px;
      background:
        radial-gradient(circle at 10px -2px, transparent 10px, #fff 10px) -10px 0 / 20px 20px repeat-x,
        radial-gradient(circle at 10px 22px, var(--bg) 10px, transparent 10px) 0 0 / 20px 20px repeat-x;
    }

    /* Efecto papel dentado abajo */
    .ticket::after {
      content: "";
      position: absolute;
      bottom: -10px; left: 0; right: 0;
      height: 20px;
      background:
        radial-gradient(circle at 10px 22px, transparent 10px, #fff 10px) -10px 0 / 20px 20px repeat-x,
        radial-gradient(circle at 10px -2px, var(--bg) 10px, transparent 10px) 0 0 / 20px 20px repeat-x;
    }

    .ticket-inner { padding: 8px 24px 32px; }

    /* Encabezado */
    .ticket-brand {
      text-align: center;
      padding-bottom: 14px;
      margin-bottom: 14px;
      border-bottom: 1px dashed #ccc;
    }
    .ticket-brand-name {
      font-size: 20px;
      font-weight: 900;
      letter-spacing: 3px;
      text-transform: uppercase;
    }
    .ticket-brand-sub {
      font-size: 11px;
      color: #666;
      margin-top: 2px;
      letter-spacing: 1px;
    }

    /* Meta info */
    .ticket-meta {
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      color: #555;
      margin-bottom: 14px;
    }

    .ticket-folio {
      text-align: center;
      font-size: 11px;
      color: #888;
      margin-bottom: 14px;
      letter-spacing: 1px;
    }

    /* Separador */
    .sep {
      border: none;
      border-top: 1px dashed #ccc;
      margin: 12px 0;
    }

    /* Items */
    .ticket-items { width: 100%; border-collapse: collapse; }

    .ticket-items th {
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: .05em;
      color: #888;
      padding: 4px 0;
      border-bottom: 1px dashed #ccc;
      font-weight: 700;
      background: transparent;
    }

    .ticket-items th:last-child,
    .ticket-items td:last-child { text-align: right; }

    .ticket-items td {
      padding: 6px 0;
      font-size: 12px;
      border-bottom: none;
      vertical-align: top;
    }

    .ticket-items td.nombre { width: 50%; }
    .ticket-items td.cant   { width: 15%; text-align: center; color: #555; }
    .ticket-items td.precio { width: 17%; text-align: right; color: #555; }
    .ticket-items td.sub    { width: 18%; text-align: right; font-weight: 600; }

    /* Total */
    .ticket-total {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      margin-top: 4px;
      padding-top: 10px;
      border-top: 2px solid #1a1a1a;
    }
    .ticket-total-label { font-size: 14px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; }
    .ticket-total-value { font-size: 22px; font-weight: 900; }

    /* Alertas stock */
    .ticket-alerta {
      font-size: 11px;
      color: #b45309;
      background: #fef3c7;
      border-radius: 4px;
      padding: 6px 8px;
      margin-top: 10px;
    }

    /* Pie */
    .ticket-footer {
      text-align: center;
      margin-top: 18px;
      padding-top: 14px;
      border-top: 1px dashed #ccc;
      font-size: 11px;
      color: #888;
      line-height: 1.8;
    }
    .ticket-footer strong { font-size: 13px; color: #333; display: block; letter-spacing: 1px; }

    /* ── Print ── */
    @media print {
      html, body { background: #fff; }
      .ticket-actions { display: none; }
      .ticket {
        box-shadow: none;
        max-width: 100%;
        border-radius: 0;
      }
      .ticket::before, .ticket::after { display: none; }
      .ticket-inner { padding: 0; }
    }
  </style>
</head>
<body>
<div class="ticket-page">

  <!-- Botones (no se imprimen) -->
  <div class="ticket-actions">
    <button class="boton boton-borde" onclick="location.href='ventas.jsp'">
      + Nueva venta
    </button>
    <button class="boton boton-primario" onclick="window.print()">
      Imprimir
    </button>
  </div>

  <!-- Ticket -->
  <div class="ticket">
    <div class="ticket-inner">

      <div class="ticket-brand">
        <div class="ticket-brand-name">PayStream</div>
        <div class="ticket-brand-sub">by DevBiz</div>
      </div>

      <div class="ticket-folio">FOLIO #<%= String.format("%04d", idVenta) %></div>

      <div class="ticket-meta">
        <span><%= fechaHora.split(" ")[0] %></span>
        <span><%= fechaHora.split(" ")[1] %></span>
      </div>

      <hr class="sep"/>

      <table class="ticket-items">
        <thead>
          <tr>
            <th class="nombre">Artículo</th>
            <th class="cant">Cant</th>
            <th class="precio">P/U</th>
            <th class="sub">Total</th>
          </tr>
        </thead>
        <tbody>
          <% for (int i = 0; i < nombres.size(); i++) { %>
          <tr>
            <td class="nombre"><%= nombres.get(i) %></td>
            <td class="cant"><%= cantidades.get(i) %></td>
            <td class="precio">$<%= String.format("%.2f", precios.get(i)) %></td>
            <td class="sub">$<%= String.format("%.2f", subtotales.get(i)) %></td>
          </tr>
          <% } %>
        </tbody>
      </table>

      <% for (String alerta : alertas) { %>
        <div class="ticket-alerta">⚠ <%= alerta %></div>
      <% } %>

      <hr class="sep"/>

      <div class="ticket-total">
        <span class="ticket-total-label">Total</span>
        <span class="ticket-total-value">$<%= String.format("%.2f", total) %></span>
      </div>

      <div class="ticket-footer">
        <strong>¡Gracias por su compra!</strong>
        Conserve este ticket
      </div>

    </div>
  </div>

</div>
</body>
</html>