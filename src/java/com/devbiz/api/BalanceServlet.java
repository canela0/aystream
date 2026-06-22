package com.devbiz.api;

import com.devbiz.util.DB;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.time.*;
import java.time.temporal.*;

@WebServlet("/api/balance")
public class BalanceServlet extends HttpServlet {

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
            con = DB.getConnection();

            int usuarioId = Integer.parseInt(usuarioIdStr);

            // Ventas de hoy
            PreparedStatement stHoy = con.prepareStatement(
                "SELECT COALESCE(SUM(total),0) as hoy, COUNT(*) as num FROM ventas " +
                "WHERE usuario_id=? AND DATE(fecha)=CURDATE()"
            );
            stHoy.setInt(1, usuarioId);
            ResultSet rsHoy = stHoy.executeQuery();
            double ventasHoy = 0; int numHoy = 0;
            if (rsHoy.next()) { ventasHoy = rsHoy.getDouble("hoy"); numHoy = rsHoy.getInt("num"); }
            rsHoy.close(); stHoy.close();

            // Valor inventario
            PreparedStatement stInv = con.prepareStatement(
                "SELECT COALESCE(SUM(precio*cantidad),0) as valor, COUNT(*) as total FROM productos WHERE usuario_id=?"
            );
            stInv.setInt(1, usuarioId);
            ResultSet rsInv = stInv.executeQuery();
            double valorInventario = 0; int totalProductos = 0;
            if (rsInv.next()) { valorInventario = rsInv.getDouble("valor"); totalProductos = rsInv.getInt("total"); }
            rsInv.close(); stInv.close();

            // Balance últimas 4 semanas
            LocalDate hoy = LocalDate.now();
            StringBuilder semanas = new StringBuilder("[");
            for (int s = 0; s < 4; s++) {
                LocalDate lunes   = hoy.minusWeeks(s).with(DayOfWeek.MONDAY);
                LocalDate domingo = lunes.plusDays(6);

                PreparedStatement stS = con.prepareStatement(
                    "SELECT COALESCE(SUM(total),0) as vendido, COUNT(*) as ventas FROM ventas " +
                    "WHERE usuario_id=? AND DATE(fecha) BETWEEN ? AND ?"
                );
                stS.setInt(1, usuarioId);
                stS.setString(2, lunes.toString());
                stS.setString(3, domingo.toString());
                ResultSet rsS = stS.executeQuery();
                double vendido = 0; int numVentas = 0;
                if (rsS.next()) { vendido = rsS.getDouble("vendido"); numVentas = rsS.getInt("ventas"); }
                rsS.close(); stS.close();

                PreparedStatement stI = con.prepareStatement(
                    "SELECT COALESCE(SUM(cantidad_nueva*precio_anterior),0) as inv FROM movimientos_inventario " +
                    "WHERE usuario_id=? AND tipo_movimiento='ALTA' AND DATE(fecha) BETWEEN ? AND ?"
                );
                stI.setInt(1, usuarioId);
                stI.setString(2, lunes.toString());
                stI.setString(3, domingo.toString());
                ResultSet rsI = stI.executeQuery();
                double inversion = rsI.next() ? rsI.getDouble("inv") : 0;
                rsI.close(); stI.close();

                if (s > 0) semanas.append(",");
                semanas.append("{")
                    .append("\"semana\":\"").append(lunes).append(" al ").append(domingo).append("\",")
                    .append("\"vendido\":").append(vendido).append(",")
                    .append("\"inversion\":").append(inversion).append(",")
                    .append("\"balance\":").append(vendido - inversion).append(",")
                    .append("\"numVentas\":").append(numVentas)
                    .append("}");
            }
            semanas.append("]");

            out.print("{" +
                "\"ventasHoy\":" + ventasHoy + "," +
                "\"numVentasHoy\":" + numHoy + "," +
                "\"valorInventario\":" + valorInventario + "," +
                "\"totalProductos\":" + totalProductos + "," +
                "\"semanas\":" + semanas.toString() +
            "}");

        } catch (Exception e) {
            res.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        } finally {
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }
}
