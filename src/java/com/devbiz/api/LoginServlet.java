package com.devbiz.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/api/login")
public class LoginServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/payStream";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "n0m3l0";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.setHeader("Access-Control-Allow-Origin", "*");

        String correo    = req.getParameter("correo");
        String contrasena = req.getParameter("contrasena");
        PrintWriter out  = res.getWriter();

        if (correo == null || contrasena == null) {
            res.setStatus(400);
            out.print("{\"error\":\"Faltan datos\"}");
            return;
        }

        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            PreparedStatement st = con.prepareStatement(
                "SELECT id, nombre, apellido, correo FROM usuarios " +
                "WHERE correo=? AND contrasena=?"
            );
            st.setString(1, correo.trim());
            st.setString(2, contrasena.trim());
            ResultSet rs = st.executeQuery();

            if (rs.next()) {
                out.print("{" +
                    "\"ok\":true," +
                    "\"id\":"       + rs.getInt("id")              + "," +
                    "\"nombre\":\""  + rs.getString("nombre")       + "\"," +
                    "\"apellido\":\"" + rs.getString("apellido")    + "\"," +
                    "\"correo\":\""  + rs.getString("correo")       + "\"" +
                "}");
            } else {
                res.setStatus(401);
                out.print("{\"ok\":false,\"error\":\"Correo o contrasena incorrectos\"}");
            }
            rs.close(); st.close();

        } catch (Exception e) {
            res.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        } finally {
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse res) {
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type");
        res.setStatus(200);
    }
}
