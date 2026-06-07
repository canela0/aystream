<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Registro producto</title>
</head>
<body>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    String nombre      = request.getParameter("nombre");
    String cantidadStr = request.getParameter("cantidad");
    String precioStr   = request.getParameter("precio");

    Connection con = null;
    PreparedStatement stProd = null;
    PreparedStatement stMov  = null;

    try {
        int    cantidad = Integer.parseInt(cantidadStr);
        double precio   = Double.parseDouble(precioStr);

        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
        );

        // 1. Insertar producto
        stProd = con.prepareStatement(
            "INSERT INTO productos (usuario_id, nombre, cantidad, precio) VALUES (?, ?, ?, ?)",
            Statement.RETURN_GENERATED_KEYS
        );
        stProd.setInt(1, usuarioId);
        stProd.setString(2, nombre);
        stProd.setInt(3, cantidad);
        stProd.setDouble(4, precio);
        stProd.executeUpdate();

        // Obtener el id del producto recien insertado
        ResultSet rsKeys = stProd.getGeneratedKeys();
        int idProducto = rsKeys.next() ? rsKeys.getInt(1) : -1;
        rsKeys.close();

        // 2. Registrar movimiento tipo ALTA
        stMov = con.prepareStatement(
            "INSERT INTO movimientos_inventario " +
            "(producto_id, usuario_id, tipo_movimiento, cantidad_nueva, precio_nuevo, descripcion) " +
            "VALUES (?, ?, 'ALTA', ?, ?, ?)"
        );
        stMov.setInt(1, idProducto);
        stMov.setInt(2, usuarioId);
        stMov.setInt(3, cantidad);
        stMov.setDouble(4, precio);
        stMov.setString(5, "Alta de producto: " + nombre);
        stMov.executeUpdate();
%>
        <script>
            alert("Producto registrado correctamente");
            window.location.href = "productos.html";
        </script>
<%
    } catch (Exception e) {
%>
        <script>
            alert("Error al registrar el producto");
            window.history.back();
        </script>
<%
    } finally {
        if (stMov  != null) stMov.close();
        if (stProd != null) stProd.close();
        if (con    != null) con.close();
    }
%>
</body>
</html>