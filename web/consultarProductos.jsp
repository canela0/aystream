<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>

<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width initial-scale=1.0" />
    <title>Consultar Productos</title>
    <link rel="stylesheet" href="estilo.css" />
    <style>
      .page-header { padding: 28px 40px 20px; border-bottom: 1px solid #E5E7EB; margin-bottom: 8px; }
      .page-header-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
      .breadcrumb { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #6B7280; }
      .breadcrumb-actual { color: #111827; font-weight: 600; }
      .page-title { font-size: 24px; font-weight: 700; color: #111827; margin: 0 0 4px; }
      .page-subtitle { font-size: 13px; color: #6B7280; margin: 0; }
      .btn-nav { display: inline-flex; align-items: center; gap: 6px; background: white; border: 1.5px solid #D1D5DB; border-radius: 999px; padding: 6px 14px 6px 10px; font-size: 12px; font-weight: 600; color: #374151; cursor: pointer; text-decoration: none; transition: all 0.2s ease; box-shadow: 0 1px 3px rgba(0,0,0,.06); }
      .btn-nav:hover { background: #EFF6FF; border-color: #2563EB; color: #2563EB; box-shadow: 0 4px 12px rgba(37,99,235,.15); transform: translateX(-3px); }
      .btn-nav .nav-icon { width: 20px; height: 20px; border-radius: 50%; background: #F3F4F6; display: inline-flex; align-items: center; justify-content: center; font-size: 12px; transition: background 0.2s; }
      .btn-nav:hover .nav-icon { background: #DBEAFE; }
    </style>
  </head>

  <body class="inicio">
    <section class="inicio-seccion">

      <%
        // Verificar que hay sesión activa
        Integer usuarioId = (Integer) session.getAttribute("usuarioId");
        if (usuarioId == null) {
            response.sendRedirect("inicioSesion.jsp");
            return;
        }
      %>

      <div class="page-header">
        <div class="page-header-top">
          <nav class="breadcrumb">
            <a href="menu.jsp" class="btn-nav"><span class="nav-icon">&#8962;</span>Inicio</a>
            <span>›</span>
            <a href="productos.html" class="btn-nav"><span class="nav-icon">&#8592;</span>Productos</a>
            <span>›</span>
            <span class="breadcrumb-actual">Consultar</span>
          </nav>
          <a href="productos.html" class="btn-nav"><span class="nav-icon">&#8592;</span>Volver</a>
        </div>
        <h2 class="page-title">Lista de Productos</h2>
        <p class="page-subtitle">Inventario completo de productos registrados</p>
      </div>

      <div class="grupo-formulario2">
        <div class="caja-seccion2 tarjeta">
          <div class="texto-centro">
            <p class="titulo-seccion2">Inventario Completo</p>
            <p class="subtitulo-seccion2">
              Lista de todos los productos registrados en el sistema
            </p>
          </div>

          <!-- Buscador en tiempo real -->
          <div style="margin-bottom:14px;">
            <input type="text" id="buscador" placeholder="🔍 Buscar producto..." oninput="filtrarTabla()"
              style="width:100%;padding:9px 14px;border:1.5px solid #D1D5DB;border-radius:8px;font-size:14px;font-family:inherit;outline:none;transition:border-color .2s;"
              onfocus="this.style.borderColor='#2563EB'" onblur="this.style.borderColor='#D1D5DB'"/>
            <div id="sinResultados" style="display:none;text-align:center;color:#9CA3AF;padding:20px;font-size:13px;">No se encontraron productos</div>
          </div>

          <div class="tabla">
            <table id="tablaProductos">
              <thead>
                <tr>
                  <th>Nombre del Producto</th>
                  <th>Cantidad</th>
                  <th>Precio de Costo</th>
                  <th>Precio de Venta</th>
                  <th>Valor en Stock (costo)</th>
                </tr>
              </thead>

              <tbody>
                <%
                  Connection con = null;
                  PreparedStatement st = null;
                  ResultSet rs = null;
                  double totalInventario = 0;

                  try {
                      Class.forName("com.mysql.cj.jdbc.Driver");
                      con = com.devbiz.util.DB.getConnection();

                      // Filtrar solo los productos del usuario en sesión
                      st = con.prepareStatement(
                          "SELECT nombre, cantidad, precio, COALESCE(precio_costo, precio) AS precio_costo " +
                          "FROM productos WHERE usuario_id = ? AND cantidad > 0 ORDER BY nombre ASC"
                      );
                      st.setInt(1, usuarioId);
                      rs = st.executeQuery();

                      while(rs.next()) {
                          String nombre = rs.getString("nombre");
                          int cantidad = rs.getInt("cantidad");
                          double precio = rs.getDouble("precio");
                          double precioCosto = rs.getDouble("precio_costo");
                          double valorTotal = cantidad * precioCosto;
                          totalInventario += valorTotal;
                %>
                <tr>
                  <td><%= nombre %></td>
                  <td><%= cantidad %></td>
                  <td>$<%= String.format("%.2f", precioCosto) %></td>
                  <td>$<%= String.format("%.2f", precio) %></td>
                  <td>$<%= String.format("%.2f", valorTotal) %></td>
                </tr>
                <%
                      }
                  } catch(Exception e) {
                      out.println("<tr><td colspan='5'>Error: " + e.getMessage() + "</td></tr>");
                  } finally {
                      if(rs != null) rs.close();
                      if(st != null) st.close();
                      if(con != null) con.close();
                  }
                %>
              </tbody>

              <tfoot>
                <tr>
                  <th>Total del Inventario</th>
                  <th></th>
                  <th></th>
                  <th></th>
                  <th>$<%= String.format("%.2f", totalInventario) %></th>
                </tr>
              </tfoot>
            </table>
          </div>

        </div>
      </div>

    </section>

  <script>
    function filtrarTabla() {
      const q = document.getElementById('buscador').value.toLowerCase();
      const filas = document.querySelectorAll('#tablaProductos tbody tr');
      let visibles = 0;
      filas.forEach(function(fila) {
        const nombre = fila.cells[0] ? fila.cells[0].textContent.toLowerCase() : '';
        const mostrar = nombre.includes(q);
        fila.style.display = mostrar ? '' : 'none';
        if (mostrar) visibles++;
      });
      document.getElementById('sinResultados').style.display = visibles === 0 && q !== '' ? 'block' : 'none';
    }
  </script>
  </body>
</html>
