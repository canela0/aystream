<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>

<%
    // Verificar que hay sesión activa
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    int id = Integer.parseInt(request.getParameter("id"));

    String nombre = "";
    int cantidad = 0;
    double precio = 0;
    double precioCosto = 0;

    Connection con = null;
    PreparedStatement st = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = com.devbiz.util.DB.getConnection();

        // Verificar que el producto pertenece al usuario en sesión
        st = con.prepareStatement(
            "SELECT nombre, cantidad, precio, COALESCE(precio_costo, precio) AS precio_costo FROM productos WHERE id = ? AND usuario_id = ?"
        );
        st.setInt(1, id);
        st.setInt(2, usuarioId);
        rs = st.executeQuery();

        if (rs.next()) {
            nombre = rs.getString("nombre");
            cantidad = rs.getInt("cantidad");
            precio = rs.getDouble("precio");
            precioCosto = rs.getDouble("precio_costo");
        } else {
            // El producto no existe o no pertenece a este usuario
            response.sendRedirect("productos.html");
            return;
        }
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    } finally {
        if (rs != null) rs.close();
        if (st != null) st.close();
        if (con != null) con.close();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width initial-scale=1.0">
    <title>Editar producto</title>
    <link rel="stylesheet" href="estilo.css">
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

    <div class="page-header">
        <div class="page-header-top">
          <nav class="breadcrumb">
            <a href="menu.jsp" class="btn-nav"><span class="nav-icon">&#8962;</span>Inicio</a>
            <span>›</span>
            <a href="productos.html" class="btn-nav"><span class="nav-icon">&#8592;</span>Productos</a>
            <span>›</span>
            <span class="breadcrumb-actual">Editar</span>
          </nav>
          <a href="productos.html" class="btn-nav"><span class="nav-icon">&#8592;</span>Volver</a>
        </div>
        <h2 class="page-title">Editar Producto</h2>
        <p class="page-subtitle">Modifica los datos del producto seleccionado</p>
    </div>

    <form class="grupo-formulario2"
          action="editarProductoAccion.jsp"
          method="post"
          onsubmit="return validaRegistroProducto()">

        <div class="caja-seccion tarjeta">

            <div class="texto-centro">
                <p class="titulo-seccion2">Editar Producto</p>
                <p class="subtitulo-seccion2">
                    Modifica o elimina el producto del inventario
                </p>
            </div>

            <input type="hidden" name="id" value="<%= id %>">

            <div>
                <label style="margin-top:40px">Nombre del producto</label>
                <input class="input-datos2"
                       type="text"
                       id="nombre"
                       name="nombre"
                       value="<%= nombre %>">
                <a id="mensajeErrorNombre" class="mensajeError"></a>
            </div>

            <div class="flex" style="gap:10px">
                <div>
                    <label>Cantidad disponible</label>
                    <input class="input-datos3"
                           type="number"
                           id="cantidad"
                           name="cantidad"
                           value="<%= cantidad %>"
                           step="1"
                           min="0">
                    <a id="mensajeErrorCantidad" class="mensajeError"></a>
                </div>

                <div>
                    <label>Precio de costo ($)</label>
                    <input class="input-datos3"
                           type="number"
                           id="precio_costo"
                           name="precio_costo"
                           value="<%= precioCosto %>"
                           step="0.01"
                           min="0">
                    <a id="mensajeErrorPrecioCosto" class="mensajeError"></a>
                </div>

                <div>
                    <label>Precio de venta ($)</label>
                    <input class="input-datos3"
                           type="number"
                           id="precio"
                           name="precio"
                           value="<%= precio %>"
                           step="0.01"
                           min="0">
                    <a id="mensajeErrorPrecio" class="mensajeError"></a>
                </div>
            </div>

            <button class="boton boton-primario"
                    style="margin-top:20px"
                    type="submit"
                    name="accion"
                    value="actualizar">
                Guardar cambios
            </button>

            <button class="boton boton-primario2"
                    style="margin-top:10px"
                    type="submit"
                    name="accion"
                    value="eliminar"
                    onclick="return confirm('¿Eliminar este producto?');">
                Eliminar producto
            </button>

        </div>
    </form>

</section>

<script src="validaFormulario.js"></script>
</body>
</html>
