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

    Connection con = null;
    PreparedStatement st = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/PAYSTREAM","root","n0m3l0"
        );

        // Verificar que el producto pertenece al usuario en sesión
        st = con.prepareStatement(
            "SELECT nombre, cantidad, precio FROM productos WHERE id = ? AND usuario_id = ?"
        );
        st.setInt(1, id);
        st.setInt(2, usuarioId);
        rs = st.executeQuery();

        if (rs.next()) {
            nombre = rs.getString("nombre");
            cantidad = rs.getInt("cantidad");
            precio = rs.getDouble("precio");
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
</head>

<body class="inicio">
<section class="inicio-seccion">

    <div class="boton-volver">
        <input type="button" class="boton boton-borde"
               value="← Volver al menú"
               onclick="location.href='menu.html';">
    </div>

    <div class="boton-volver2">
        <input type="button" class="boton boton-borde"
               value="← Volver"
               onclick="location.href='productos.html';">
        <h2 class="titulo-seccion">Editar producto</h2>
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
                    <label>Precio por unidad ($)</label>
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
