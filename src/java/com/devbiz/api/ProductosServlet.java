package com.devbiz.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/api/productos")
public class ProductosServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/payStream";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "n0m3l0";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.setHeader("Access-Control-Allow-Origin", "*");

        String usuarioIdStr = req.getParameter("usuarioId");
        PrintWriter out = res.getWriter();

        if (usuarioIdStr == null) {
            res.setStatus(400);
            out.print("{\"error\":\"Falta usuarioId\"}");
            return;
        }

        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            PreparedStatement st = con.prepareStatement(
                "SELECT id, nombre, cantidad, precio FROM productos " +
                "WHERE usuario_id=? AND cantidad > 0 ORDER BY nombre ASC"
            );
            st.setInt(1, Integer.parseInt(usuarioIdStr));
            ResultSet rs = st.executeQuery();

            StringBuilder sb = new StringBuilder("[");
            boolean primero = true;
            while (rs.next()) {
                if (!primero) sb.append(",");
                sb.append("{")
                  .append("\"id\":").append(rs.getInt("id")).append(",")
                  .append("\"nombre\":\"").append(rs.getString("nombre")).append("\",")
                  .append("\"cantidad\":").append(rs.getInt("cantidad")).append(",")
                  .append("\"precio\":").append(rs.getDouble("precio"))
                  .append("}");
                primero = false;
            }
            sb.append("]");
            out.print(sb.toString());
            rs.close(); st.close();

        } catch (Exception e) {
            res.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        } finally {
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }
}
