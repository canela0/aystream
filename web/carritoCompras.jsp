<%@page contentType="text/html; charset=UTF-8"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.sql.*"%>
<%-- CORRECCIONES:
     1. Formularios de Cancelar/Confirmar incluyen action="carritoCompras.jsp"
     2. Se procesa la acción ANTES de renderizar para evitar respuesta dividida
--%>

<%
    // Verificar sesión activa
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    // CORRECCIÓN 1: procesar acción antes del HTML
    String accion = request.getParameter("accion");

    if ("cancelar".equals(accion)) {
        session.removeAttribute("carrito");
        response.sendRedirect("ventas.jsp");
        return;
    }

    if ("confirmar".equals(accion)) {
        response.sendRedirect("ticketCompra.jsp");
        return;
    }
%>

<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Carrito de Compras - PayStream</title>
    <link rel="stylesheet" href="estilo.css" />
</head>

<body>
<section class="seccion">

    <div class="boton-volver">
        <input
            type="button"
            class="boton boton-borde"
            value="← Volver"
            onclick="location.href='ventas.jsp';"
        />
    </div>

    <h2 class="titulo-seccion">Carrito de Compras</h2>

    <div class="caja-seccion tarjeta">

        <%
            ArrayList<int[]> carrito =
                (ArrayList<int[]>) session.getAttribute("carrito");

            if (carrito == null || carrito.isEmpty()) {
        %>

            <p class="subtitulo-seccion texto-centro">
                No hay productos en el carrito.
            </p>

            <div class="centrado">
                <a href="ventas.jsp" class="boton boton-borde">
                    Volver a productos
                </a>
            </div>

        <%
            } else {

                Connection con = null;
                PreparedStatement st = null;
                ResultSet rs = null;
                double total = 0;

                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    con = DriverManager.getConnection(
                        "jdbc:mysql://localhost:3306/PAYSTREAM",
                        "root",
                        "n0m3l0"
                    );
        %>

        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Producto</th>
                    <th>Precio</th>
                    <th>Cantidad</th>
                    <th>Subtotal</th>
                    <th>Stock</th>
                </tr>
            </thead>
            <tbody>

        <%
                boolean hayProblemaStock = false;

                for (int[] item : carrito) {
                    int idProducto = item[0];
                    int cantidad   = item[1];

                    st = con.prepareStatement(
                        "SELECT nombre, precio, cantidad FROM productos WHERE id = ? AND usuario_id = ?"
                    );
                    st.setInt(1, idProducto);
                    st.setInt(2, usuarioId);
                    rs = st.executeQuery();

                    if (rs.next()) {
                        String nombre      = rs.getString("nombre");
                        double precio      = rs.getDouble("precio");
                        int    stockActual = rs.getInt("cantidad");
                        double subtotal    = precio * cantidad;
                        total += subtotal;

                        boolean sinStock = cantidad > stockActual;
                        if (sinStock) hayProblemaStock = true;
        %>

                <tr style="<%= sinStock ? "background-color: #fff3cd;" : "" %>">
                    <td><%= idProducto %></td>
                    <td><%= nombre %></td>
                    <td>$<%= String.format("%.2f", precio) %></td>
                    <td><%= cantidad %></td>
                    <td>$<%= String.format("%.2f", subtotal) %></td>
                    <td style="color: <%= sinStock ? "red" : "green" %>">
                        <%= sinStock ? "Insuficiente (" + stockActual + " disp.)" : "OK (" + stockActual + ")" %>
                    </td>
                </tr>

        <%
                    }
                    rs.close();
                    st.close();
                }
        %>

            </tbody>
            <tfoot>
                <tr>
                    <th colspan="5">Total</th>
                    <th>$<%= String.format("%.2f", total) %></th>
                </tr>
            </tfoot>
        </table>

        <% if (hayProblemaStock) { %>
            <p style="color: orange; margin-top: 10px;">
                Algunos productos no tienen stock suficiente.
                Al confirmar se procesará la cantidad disponible.
            </p>
        <% } %>

        <div style="margin-top:20px;" class="centrado">

            <%-- CORRECCIÓN 1: action explícito en ambos formularios --%>
            <form action="carritoCompras.jsp" method="post" style="margin-right:10px;">
                <button class="boton boton-primario2"
                        type="submit"
                        name="accion"
                        value="cancelar">
                    Cancelar compra
                </button>
            </form>

            <form action="carritoCompras.jsp" method="post" style="margin-right:10px;">
                <button class="boton boton-primario"
                        type="submit"
                        name="accion"
                        value="confirmar">
                    Confirmar compra
                </button>
            </form>

            <a href="ventas.jsp" class="boton boton-borde">
                Seguir comprando
            </a>

        </div>

        <%
                } catch (Exception e) {
                    out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
                } finally {
                    if (con != null) con.close();
                }
            }
        %>

    </div>
</section>

</body>
</html>