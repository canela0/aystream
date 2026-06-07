<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    String idParam = request.getParameter("id");
    String accion  = request.getParameter("accion");

    if (idParam == null || accion == null) {
        response.sendRedirect("productos.html");
        return;
    }

    int id = Integer.parseInt(idParam);

    Connection con        = null;
    PreparedStatement st  = null;
    PreparedStatement stMov = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
        );

        // Leer valores actuales ANTES de modificar (necesarios para el movimiento)
        PreparedStatement stLeer = con.prepareStatement(
            "SELECT nombre, cantidad, precio FROM productos WHERE id=? AND usuario_id=?"
        );
        stLeer.setInt(1, id);
        stLeer.setInt(2, usuarioId);
        ResultSet rsLeer = stLeer.executeQuery();

        if (!rsLeer.next()) {
            rsLeer.close(); stLeer.close();
            response.sendRedirect("productos.html");
            return;
        }

        String nombreAnterior  = rsLeer.getString("nombre");
        int    cantidadAnterior = rsLeer.getInt("cantidad");
        double precioAnterior  = rsLeer.getDouble("precio");
        rsLeer.close(); stLeer.close();

        if ("actualizar".equals(accion)) {
            String nombreNuevo   = request.getParameter("nombre");
            int    cantidadNueva = Integer.parseInt(request.getParameter("cantidad"));
            double precioNuevo   = Double.parseDouble(request.getParameter("precio"));

            // 1. Actualizar producto
            st = con.prepareStatement(
                "UPDATE productos SET nombre=?, cantidad=?, precio=? WHERE id=? AND usuario_id=?"
            );
            st.setString(1, nombreNuevo);
            st.setInt(2, cantidadNueva);
            st.setDouble(3, precioNuevo);
            st.setInt(4, id);
            st.setInt(5, usuarioId);
            st.executeUpdate();

            // 2. Registrar movimiento tipo AJUSTE
            stMov = con.prepareStatement(
                "INSERT INTO movimientos_inventario " +
                "(producto_id, usuario_id, tipo_movimiento, " +
                " cantidad_anterior, cantidad_nueva, precio_anterior, precio_nuevo, descripcion) " +
                "VALUES (?, ?, 'AJUSTE', ?, ?, ?, ?, ?)"
            );
            stMov.setInt(1, id);
            stMov.setInt(2, usuarioId);
            stMov.setInt(3, cantidadAnterior);
            stMov.setInt(4, cantidadNueva);
            stMov.setDouble(5, precioAnterior);
            stMov.setDouble(6, precioNuevo);
            stMov.setString(7, "Ajuste manual: " + nombreAnterior + " -> " + nombreNuevo);
            stMov.executeUpdate();

        } else if ("eliminar".equals(accion)) {

            // 1. Registrar movimiento tipo BAJA antes de eliminar
            stMov = con.prepareStatement(
                "INSERT INTO movimientos_inventario " +
                "(producto_id, usuario_id, tipo_movimiento, " +
                " cantidad_anterior, precio_anterior, descripcion) " +
                "VALUES (?, ?, 'BAJA', ?, ?, ?)"
            );
            stMov.setInt(1, id);
            stMov.setInt(2, usuarioId);
            stMov.setInt(3, cantidadAnterior);
            stMov.setDouble(4, precioAnterior);
            stMov.setString(5, "Baja de producto: " + nombreAnterior);
            stMov.executeUpdate();

            // 2. Eliminar producto
            st = con.prepareStatement(
                "DELETE FROM productos WHERE id=? AND usuario_id=?"
            );
            st.setInt(1, id);
            st.setInt(2, usuarioId);
            st.executeUpdate();
        }

        response.sendRedirect("productos.html");

    } catch (Exception e) {
        out.println("<!DOCTYPE html><html><head><meta charset='UTF-8'>"
            + "<link rel='stylesheet' href='estilo.css'></head><body>");
        out.println("<div style='padding:40px'>");
        out.println("<p style='color:red'>Error al procesar la operacion: " + e.getMessage() + "</p>");
        out.println("<a href='modificarProducto.jsp' class='boton boton-borde'>Volver</a>");
        out.println("</div></body></html>");
    } finally {
        if (stMov != null) stMov.close();
        if (st    != null) st.close();
        if (con   != null) con.close();
    }
%>
