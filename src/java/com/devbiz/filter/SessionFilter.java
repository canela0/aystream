package com.devbiz.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

/**
 * Filtro que traduce el principal autenticado por el Realm de Tomcat
 * en los atributos de sesión (usuarioId, usuarioNombre) que usan los JSPs.
 */
public class SessionFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);

        // Si ya tiene usuarioId en sesión, no hace falta hacer nada
        if (session != null && session.getAttribute("usuarioId") != null) {
            chain.doFilter(req, res);
            return;
        }

        // Si Realm autenticó al usuario, poblar la sesión desde la BD
        java.security.Principal principal = request.getUserPrincipal();
        if (principal != null) {
            if (session == null) session = request.getSession(true);
            String correo = principal.getName();
            Connection con = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                con = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
                );
                PreparedStatement st = con.prepareStatement(
                    "SELECT id, nombre FROM usuarios WHERE correo = ?"
                );
                st.setString(1, correo);
                ResultSet rs = st.executeQuery();
                if (rs.next()) {
                    session.setAttribute("usuarioId",     rs.getInt("id"));
                    session.setAttribute("usuarioNombre", rs.getString("nombre"));
                }
                rs.close();
                st.close();
            } catch (Exception e) {
                // Si falla la BD, el Realm ya denegó o permitió el acceso;
                // los JSPs redirigirán a login si usuarioId sigue nulo.
            } finally {
                if (con != null) try { con.close(); } catch (Exception ignored) {}
            }
        }

        chain.doFilter(req, res);
    }

    @Override public void init(FilterConfig fc) {}
    @Override public void destroy() {}
}
