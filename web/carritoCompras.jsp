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

    if ("eliminar".equals(accion) && request.getParameter("productoId") != null) {
        int elimId = Integer.parseInt(request.getParameter("productoId"));
        ArrayList<int[]> carritoElim = (ArrayList<int[]>) session.getAttribute("carrito");
        if (carritoElim != null) {
            carritoElim.removeIf(item -> item[0] == elimId);
            if (carritoElim.isEmpty()) session.removeAttribute("carrito");
            else session.setAttribute("carrito", carritoElim);
        }
        response.sendRedirect("carritoCompras.jsp");
        return;
    }
%>

<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Carrito de Compras - PayStream</title>
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

<body>
<section class="seccion">

    <div class="page-header">
        <div class="page-header-top">
          <nav class="breadcrumb">
            <a href="menu.jsp" class="btn-nav"><span class="nav-icon">&#8962;</span>Inicio</a>
            <span>›</span>
            <a href="ventas.jsp" class="btn-nav"><span class="nav-icon">&#8592;</span>Ventas</a>
            <span>›</span>
            <span class="breadcrumb-actual">Carrito</span>
          </nav>
          <a href="ventas.jsp" class="btn-nav"><span class="nav-icon">&#8592;</span>Volver</a>
        </div>
        <h2 class="page-title">Carrito de Compras</h2>
        <p class="page-subtitle">Revisa y confirma tu venta</p>
    </div>

    <div class="caja-seccion2 tarjeta">

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
                    con = com.devbiz.util.DB.getConnection();
        %>

        <table>
            <thead>
                <tr>
                    <th>Producto</th>
                    <th>Precio</th>
                    <th>Cantidad</th>
                    <th>Subtotal</th>
                    <th>Stock</th>
                    <th></th>
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
                    <td><strong><%= nombre %></strong></td>
                    <td>$<%= String.format("%.2f", precio) %></td>
                    <td><%= cantidad %></td>
                    <td>$<%= String.format("%.2f", subtotal) %></td>
                    <td style="color: <%= sinStock ? "red" : "green" %>">
                        <%= sinStock ? "Insuficiente (" + stockActual + " disp.)" : "OK (" + stockActual + ")" %>
                    </td>
                    <td>
                        <form action="carritoCompras.jsp" method="post" style="margin:0;">
                            <input type="hidden" name="accion"     value="eliminar"/>
                            <input type="hidden" name="productoId" value="<%= idProducto %>"/>
                            <button type="submit" style="background:none;border:none;cursor:pointer;color:#DC2626;font-size:18px;padding:2px 6px;" title="Quitar del carrito">✕</button>
                        </form>
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