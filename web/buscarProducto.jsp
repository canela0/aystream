<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="jakarta.servlet.RequestDispatcher" %>

<html>
    <head></head>
    <body>
        <%
            // Verificar que hay sesión activa
            Integer usuarioId = (Integer) session.getAttribute("usuarioId");
            if (usuarioId == null) {
                response.sendRedirect("inicioSesion.jsp");
                return;
            }

            String nombreBuscado = request.getParameter("nombre");

            Connection conecta = null;
            PreparedStatement st = null;
            ResultSet rs = null;

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conecta = DriverManager.getConnection("jdbc:mysql://localhost:3306/payStream","root","n0m3l0");

                // Buscar el producto por nombre y que pertenezca al usuario en sesión
                st = conecta.prepareStatement(
                    "SELECT nombre, cantidad, precio FROM productos WHERE nombre = ? AND usuario_id = ?"
                );
                st.setString(1, nombreBuscado);
                st.setInt(2, usuarioId);
                rs = st.executeQuery();

                if (rs.next()) {
                    request.setAttribute("nombreProducto", rs.getString("nombre"));
                    request.setAttribute("cantidadProducto", rs.getInt("cantidad"));
                    request.setAttribute("precioProducto", rs.getDouble("precio"));
                } else {
                    request.setAttribute("errorBusqueda", "Producto no encontrado");
                }

                RequestDispatcher rd = request.getRequestDispatcher("modificarProducto.jsp");
                rd.forward(request, response);

            } catch (Exception e) {
                out.println("Error: " + e.getMessage());
            } finally {
                if (rs != null) rs.close();
                if (st != null) st.close();
                if (conecta != null) conecta.close();
            }
        %>
    </body>
</html>
