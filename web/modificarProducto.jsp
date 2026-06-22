<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>

<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width initial-scale=1.0" />
    <title>Modificar Productos</title>
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
            <span class="breadcrumb-actual">Modificar</span>
          </nav>
          <a href="productos.html" class="btn-nav"><span class="nav-icon">&#8592;</span>Volver</a>
        </div>
        <h2 class="page-title">Modificar Producto</h2>
        <p class="page-subtitle">Busca y edita los datos de un producto</p>
      </div>

      <div class="division flex">

        <div class="izquierda">
          <form class="grupo-formulario2" method="get">

            <div class="caja-seccion tarjeta">
              <div class="texto-centro">
                <p class="titulo-seccion2">Modificar Producto</p>
                <p class="subtitulo-seccion2">
                  Busca un producto por su nombre para modificar sus datos
                </p>
              </div>

              <div>
                <label style="margin-top: 40px">Nombre del producto</label>
                <input
                  class="input-datos2"
                  type="text"
                  name="nombre"
                  value="<%= request.getParameter("nombre") != null ? request.getParameter("nombre") : "" %>"
                />
              </div>

              <button class="boton boton-primario" style="margin-top: 20px">
                Buscar
              </button>
            </div>
          </form>
        </div>

        <div class="derecha">
          <div class="caja-seccion tarjeta">
            <p class="subtitulo-seccion2 texto-centro">
              Selecciona producto a modificar
            </p>

            <div style="overflow-x:auto;">
            <table style="width:100%;white-space:nowrap;">
              <tr>
                <th>ID</th>
                <th>Nombre</th>
                <th>Cantidad</th>
                <th>Precio</th>
                <th>Acción</th>
              </tr>

              <%
                String nombre = request.getParameter("nombre");

                Connection con = null;
                PreparedStatement st = null;
                ResultSet rs = null;

                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    con = com.devbiz.util.DB.getConnection();

                    if (nombre != null && !nombre.trim().isEmpty()) {
                        st = con.prepareStatement(
                            "SELECT * FROM productos WHERE nombre LIKE ? AND usuario_id = ? AND cantidad > 0 ORDER BY nombre ASC"
                        );
                        st.setString(1, "%" + nombre + "%");
                        st.setInt(2, usuarioId);
                    } else {
                        st = con.prepareStatement(
                            "SELECT * FROM productos WHERE usuario_id = ? AND cantidad > 0 ORDER BY nombre ASC"
                        );
                        st.setInt(1, usuarioId);
                    }

                    rs = st.executeQuery();

                    while (rs.next()) {
              %>
              <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= rs.getString("nombre") %></td>
                <td><%= rs.getInt("cantidad") %></td>
                <td>$<%= rs.getDouble("precio") %></td>
                <td>
                  <a href="editarProducto.jsp?id=<%= rs.getInt("id") %>">
                    Modificar
                  </a>
                </td>
              </tr>
              <%
                    }
                } catch (Exception e) {
                    out.println("Error: " + e.getMessage());
                } finally {
                    if (rs != null) rs.close();
                    if (st != null) st.close();
                    if (con != null) con.close();
                }
              %>

            </table>
            </div>
          </div>
        </div>
      </div>
    </section>
  </body>
</html>
