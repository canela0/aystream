<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    String accion     = request.getParameter("accion");
    String idStr      = request.getParameter("productoId");
    String cantStr    = request.getParameter("cantidad");
    String motivo     = request.getParameter("motivo");

    String mensajeOk  = null;
    String mensajeErr = null;

    if ("baja".equals(accion) && idStr != null && cantStr != null) {
        Connection con = null;
        try {
            int prodId   = Integer.parseInt(idStr);
            int cantBaja = Integer.parseInt(cantStr);
            if (cantBaja <= 0) throw new Exception("La cantidad debe ser mayor a 0");
            if (motivo == null || motivo.trim().isEmpty()) motivo = "Baja manual";

            Class.forName("com.mysql.cj.jdbc.Driver");
            con = com.devbiz.util.DB.getConnection();

            // Verificar stock actual
            PreparedStatement stSel = con.prepareStatement(
                "SELECT nombre, cantidad, precio FROM productos WHERE id=? AND usuario_id=?"
            );
            stSel.setInt(1, prodId); stSel.setInt(2, usuarioId);
            ResultSet rs = stSel.executeQuery();

            if (!rs.next()) throw new Exception("Producto no encontrado");

            String nombreProd  = rs.getString("nombre");
            int    stockActual = rs.getInt("cantidad");
            double precio      = rs.getDouble("precio");
            rs.close(); stSel.close();

            if (cantBaja > stockActual)
                throw new Exception("No puedes dar de baja más de lo que hay en stock (" + stockActual + " disponibles)");

            int stockNuevo = stockActual - cantBaja;

            // Descontar stock
            PreparedStatement stUpd = con.prepareStatement(
                "UPDATE productos SET cantidad=? WHERE id=? AND usuario_id=?"
            );
            stUpd.setInt(1, stockNuevo); stUpd.setInt(2, prodId); stUpd.setInt(3, usuarioId);
            stUpd.executeUpdate(); stUpd.close();

            // Registrar movimiento BAJA
            PreparedStatement stMov = con.prepareStatement(
                "INSERT INTO movimientos_inventario " +
                "(producto_id, usuario_id, tipo_movimiento, cantidad_anterior, cantidad_nueva, precio_anterior, descripcion) " +
                "VALUES (?, ?, 'BAJA', ?, ?, ?, ?)"
            );
            stMov.setInt(1, prodId);
            stMov.setInt(2, usuarioId);
            stMov.setInt(3, stockActual);
            stMov.setInt(4, stockNuevo);
            stMov.setDouble(5, precio);
            stMov.setString(6, "Baja: " + motivo.trim() + " (" + cantBaja + " x " + nombreProd + ")");
            stMov.executeUpdate(); stMov.close();

            mensajeOk = "Se dieron de baja " + cantBaja + " unidades de \"" + nombreProd + "\". Stock actual: " + stockNuevo;

        } catch (Exception e) {
            mensajeErr = e.getMessage();
        } finally {
            if (con != null) try { con.close(); } catch(Exception e){}
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Baja de Producto – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    html, body { background: var(--bg); }
    .baja-page { padding: 32px 40px 48px; }

    .baja-header { margin-bottom: 28px; }
    .baja-header-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-bottom: 6px; }
    .baja-header-title { font-size: 22px; font-weight: 700; color: var(--text); }
    .baja-header-sub   { font-size: 13px; color: var(--muted); margin-top: 4px; }

    .baja-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 28px 32px;
      max-width: 520px;
      box-shadow: var(--shadow-sm);
    }

    .alerta-ok  { background: #dcfce7; border: 1px solid #bbf7d0; color: #166534; border-radius: 8px; padding: 12px 16px; margin-bottom: 20px; font-size: 13px; font-weight: 500; }
    .alerta-err { background: #fee2e2; border: 1px solid #fecaca; color: #991b1b; border-radius: 8px; padding: 12px 16px; margin-bottom: 20px; font-size: 13px; font-weight: 500; }

    .form-group { margin-bottom: 18px; }

    select {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid var(--border);
      border-radius: 8px;
      font-size: 14px;
      font-family: inherit;
      background: #f8fafc;
      color: var(--text);
      transition: border-color .2s;
      appearance: none;
      cursor: pointer;
    }
    select:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37,99,235,.1); background: #fff; }

    .stock-info {
      font-size: 12px;
      color: var(--muted);
      margin-top: 6px;
      display: none;
    }
    .stock-info.visible { display: block; }
    .stock-info.bajo { color: var(--red); font-weight: 600; }

    .motivos-rapidos {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-top: 8px;
    }
    .motivo-chip {
      padding: 4px 12px;
      border: 1px solid var(--border);
      border-radius: 99px;
      font-size: 12px;
      color: var(--muted);
      cursor: pointer;
      transition: border-color .15s, color .15s, background .15s;
      background: transparent;
      font-family: inherit;
    }
    .motivo-chip:hover { border-color: var(--red); color: var(--red); background: #fff5f5; }

    .btn-baja {
      width: 100%;
      padding: 11px;
      background: var(--red);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      font-family: inherit;
      transition: background .15s;
      margin-top: 8px;
    }
    .btn-baja:hover { background: #dc2626; }

    /* ── Toast ── */
    .toast-container { position: fixed; bottom: 24px; right: 24px; z-index: 9999; display: flex; flex-direction: column; gap: 10px; }
    .toast { display: flex; align-items: center; gap: 12px; padding: 14px 18px; border-radius: 10px; font-size: 13px; font-weight: 500; box-shadow: 0 8px 24px rgba(0,0,0,.15); animation: slideIn .3s ease; min-width: 280px; max-width: 380px; }
    .toast.ok  { background: #166534; color: #fff; }
    .toast.err { background: #991b1b; color: #fff; }
    .toast-icon { font-size: 16px; flex-shrink: 0; }
    .toast-close { margin-left: auto; background: transparent; border: none; color: inherit; cursor: pointer; opacity: .7; font-size: 16px; padding: 0; }
    .toast-close:hover { opacity: 1; }
    @keyframes slideIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
    @keyframes slideOut { to { transform: translateX(120%); opacity: 0; } }

    /* ── Modal confirmación ── */
    .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 1000; align-items: center; justify-content: center; }
    .modal-overlay.visible { display: flex; }
    .modal-box { background: #fff; border-radius: 14px; padding: 28px 32px; max-width: 400px; width: 90%; box-shadow: 0 20px 60px rgba(0,0,0,.2); text-align: center; }
    .modal-icon { font-size: 40px; margin-bottom: 12px; }
    .modal-title { font-size: 18px; font-weight: 700; color: #111827; margin-bottom: 8px; }
    .modal-msg { font-size: 14px; color: #6b7280; margin-bottom: 24px; line-height: 1.5; }
    .modal-actions { display: flex; gap: 10px; justify-content: center; }
    .modal-cancel { padding: 9px 22px; border: 1.5px solid #D1D5DB; border-radius: 8px; background: #fff; font-size: 14px; font-weight: 600; cursor: pointer; color: #374151; }
    .modal-confirm { padding: 9px 22px; border: none; border-radius: 8px; background: #dc2626; color: #fff; font-size: 14px; font-weight: 600; cursor: pointer; }
  </style>
</head>
<body>
<div class="toast-container" id="toastContainer"></div>
<div class="baja-page">

  <div class="baja-header">
    <div class="baja-header-label">Inventario</div>
    <h1 class="baja-header-title">Registrar Baja</h1>
    <p class="baja-header-sub">Descuenta unidades por merma, pérdida o caducidad</p>
  </div>

  <div class="baja-card">

    <% if (mensajeOk != null) { %>
      <div class="alerta-ok">✓ <%= mensajeOk %></div>
    <% } %>
    <% if (mensajeErr != null) { %>
      <div class="alerta-err">✗ <%= mensajeErr %></div>
    <% } %>

    <form method="post" action="bajaProducto.jsp">
      <input type="hidden" name="accion" value="baja"/>

      <!-- Selector de producto -->
      <div class="form-group">
        <label>Producto</label>
        <select name="productoId" id="selectProducto" onchange="mostrarStock(this)" required>
          <option value="">— Selecciona un producto —</option>
          <%
            Connection conList = null;
            try {
              Class.forName("com.mysql.cj.jdbc.Driver");
              conList = com.devbiz.util.DB.getConnection();
              PreparedStatement stList = conList.prepareStatement(
                "SELECT id, nombre, cantidad FROM productos WHERE usuario_id=? AND cantidad > 0 ORDER BY nombre ASC"
              );
              stList.setInt(1, usuarioId);
              ResultSet rsList = stList.executeQuery();
              while (rsList.next()) {
                int    pid    = rsList.getInt("id");
                String pnom   = rsList.getString("nombre");
                int    pstock = rsList.getInt("cantidad");
                String sel    = (idStr != null && idStr.equals(String.valueOf(pid))) ? "selected" : "";
          %>
          <option value="<%= pid %>" data-stock="<%= pstock %>" <%= sel %>><%= pnom %> (stock: <%= pstock %>)</option>
          <%
              }
              rsList.close(); stList.close();
            } finally {
              if (conList != null) try { conList.close(); } catch(Exception e){}
            }
          %>
        </select>
        <div class="stock-info" id="stockInfo"></div>
      </div>

      <!-- Cantidad -->
      <div class="form-group">
        <label>Cantidad a dar de baja</label>
        <input class="input-datos2" type="number" name="cantidad" id="cantidad"
               min="1" placeholder="0" required
               value="<%= cantStr != null ? cantStr : "" %>"/>
      </div>

      <!-- Motivo -->
      <div class="form-group">
        <label>Motivo</label>
        <input class="input-datos2" type="text" name="motivo" id="motivo"
               placeholder="Ej: producto caducado, merma, pérdida..."
               value="<%= motivo != null ? motivo : "" %>"/>
        <div class="motivos-rapidos">
          <button type="button" class="motivo-chip" onclick="setMotivo('Producto caducado')">Caducado</button>
          <button type="button" class="motivo-chip" onclick="setMotivo('Producto dañado')">Dañado</button>
          <button type="button" class="motivo-chip" onclick="setMotivo('Pérdida o robo')">Pérdida / robo</button>
          <button type="button" class="motivo-chip" onclick="setMotivo('Error de inventario')">Error de inventario</button>
          <button type="button" class="motivo-chip" onclick="setMotivo('Merma')">Merma</button>
        </div>
      </div>

      <button class="btn-baja" type="button" onclick="pedirConfirmacion()">Registrar baja</button>
    </form>

    <!-- Modal confirmación -->
    <div class="modal-overlay" id="modalConfirm">
      <div class="modal-box">
        <div class="modal-icon">⚠️</div>
        <div class="modal-title">¿Confirmar baja?</div>
        <div class="modal-msg" id="modalMsg">¿Estás seguro de que deseas registrar esta baja? Esta acción no se puede deshacer.</div>
        <div class="modal-actions">
          <button class="modal-cancel" onclick="cerrarModal()">Cancelar</button>
          <button class="modal-confirm" onclick="confirmarBaja()">Sí, registrar baja</button>
        </div>
      </div>
    </div>

  </div>
</div>

<script>
  function mostrarStock(sel) {
    const opt   = sel.options[sel.selectedIndex];
    const stock = opt ? parseInt(opt.dataset.stock) : 0;
    const info  = document.getElementById('stockInfo');
    const cantInput = document.getElementById('cantidad');

    if (sel.value) {
      info.textContent = 'Stock disponible: ' + stock + ' unidades';
      info.className   = 'stock-info visible' + (stock <= 3 ? ' bajo' : '');
      cantInput.max    = stock;
    } else {
      info.className = 'stock-info';
    }
  }

  function setMotivo(texto) {
    document.getElementById('motivo').value = texto;
  }

  // Modal confirmación
  function pedirConfirmacion() {
    const form = document.querySelector('form');
    const prod = document.getElementById('selectProducto');
    const cant = document.getElementById('cantidad');
    if (!form.checkValidity()) { form.reportValidity(); return; }
    const opcion = prod.options[prod.selectedIndex];
    const nombre = opcion ? opcion.text.split(' (stock:')[0].trim() : '';
    document.getElementById('modalMsg').textContent =
      '¿Dar de baja ' + cant.value + ' unidad(es) de "' + nombre + '"? Esta acción no se puede deshacer.';
    document.getElementById('modalConfirm').classList.add('visible');
  }
  function cerrarModal() { document.getElementById('modalConfirm').classList.remove('visible'); }
  function confirmarBaja() { document.querySelector('form').submit(); }

  // Toast
  function showToast(msg, tipo) {
    const cont = document.getElementById('toastContainer');
    const t = document.createElement('div');
    t.className = 'toast ' + tipo;
    var icono = tipo === 'ok' ? '✓' : '✗';
    t.innerHTML = '<span class="toast-icon">' + icono + '</span><span>' + msg + '</span><button class="toast-close" onclick="this.parentElement.remove()">&#x2715;</button>';
    cont.appendChild(t);
    setTimeout(() => { t.style.animation = 'slideOut .3s ease forwards'; setTimeout(() => t.remove(), 300); }, 4000);
  }

  // Mostrar stock si ya hay producto seleccionado (tras submit con error)
  window.addEventListener('DOMContentLoaded', () => {
    const sel = document.getElementById('selectProducto');
    if (sel.value) mostrarStock(sel);
    <% if (mensajeOk != null) { %>
      showToast('<%= mensajeOk.replace("'", "\\'") %>', 'ok');
    <% } else if (mensajeErr != null) { %>
      showToast('<%= mensajeErr.replace("'", "\\'") %>', 'err');
    <% } %>
  });
</script>
</body>
</html>
