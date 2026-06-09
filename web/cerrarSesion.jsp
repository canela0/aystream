<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Cerrar sesión en el Realm de Tomcat
    try { request.logout(); } catch (Exception e) {}
    // Invalidar la sesión HTTP (borra usuarioId, usuarioNombre, carrito, etc.)
    session.invalidate();
    // Redirigir al login
    response.sendRedirect("inicioSesion.jsp");
%>
