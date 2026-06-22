package com.devbiz.api;

import com.devbiz.util.DB;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/api/ventas")
public class VentasServlet extends HttpServlet {

    // GET /api/ventas?usuarioId=X  → historial de ventas
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

            PreparedStatement st = con.prepareStatement(
                "SELECT v.id, v.fecha, v.total, " +
                "COUNT(dv.id) as num_productos " +
                "FROM ventas v " +
                "LEFT JOIN detalle_venta dv ON v.id = dv.venta_id " +
                "WHERE v.usuario_id=? " +
                "GROUP BY v.id ORDER BY v.fecha DESC LIMIT 50"
            );
            st.setInt(1, Integer.parseInt(usuarioIdStr));
            ResultSet rs = st.executeQuery();

            StringBuilder sb = new StringBuilder("[");
            boolean primero = true;
            while (rs.next()) {
                if (!primero) sb.append(",");
                sb.append("{")
                  .append("\"id\":").append(rs.getInt("id")).append(",")
                  .append("\"fecha\":\"").append(rs.getString("fecha")).append("\",")
                  .append("\"total\":").append(rs.getDouble("total")).append(",")
                  .append("\"numProductos\":").append(rs.getInt("num_productos"))
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

    // POST /api/ventas → registrar nueva venta
    // Body: usuarioId, items=[{productoId,cantidad}]
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.setHeader("Access-Control-Allow-Origin", "*");

        PrintWriter out = res.getWriter();
        String usuarioIdStr = req.getParameter("usuarioId");
        String[] productoIds = req.getParameterValues("productoId");
        String[] cantidades  = req.getParameterValues("cantidad");

        if (usuarioIdStr == null || productoIds == null || cantidades == null) {
            res.setStatus(400);
            out.print("{\"error\":\"Faltan datos\"}");
            return;
        }

        Connection con = null;
        try {
            con = DB.getConnection();
            con.setAutoCommit(false);

            int usuarioId = Integer.parseInt(usuarioIdStr);
            double total = 0;

            // Calcular total
            for (int i = 0; i < productoIds.length; i++) {
                int prodId = Integer.parseInt(productoIds[i]);
                int cant   = Integer.parseInt(cantidades[i]);
                PreparedStatement stP = con.prepareStatement(
                    "SELECT precio FROM productos WHERE id=? AND usuario_id=?"
                );
                stP.setInt(1, prodId); stP.setInt(2, usuarioId);
                ResultSet rsP = stP.executeQuery();
                if (rsP.next()) total += rsP.getDouble("precio") * cant;
                rsP.close(); stP.close();
            }

            // Insertar venta
            PreparedStatement stV = con.prepareStatement(
                "INSERT INTO ventas (usuario_id, total) VALUES (?,?)",
                Statement.RETURN_GENERATED_KEYS
            );
            stV.setInt(1, usuarioId);
            stV.setDouble(2, total);
            stV.executeUpdate();
            ResultSet rsV = stV.getGeneratedKeys();
            int ventaId = rsV.next() ? rsV.getInt(1) : -1;
            rsV.close(); stV.close();

            // Insertar detalles y descontar stock
            for (int i = 0; i < productoIds.length; i++) {
                int prodId = Integer.parseInt(productoIds[i]);
                int cant   = Integer.parseInt(cantidades[i]);

                PreparedStatement stProd = con.prepareStatement(
                    "SELECT nombre, precio, cantidad FROM productos WHERE id=? AND usuario_id=?"
                );
                stProd.setInt(1, prodId); stProd.setInt(2, usuarioId);
                ResultSet rsProd = stProd.executeQuery();

                if (rsProd.next()) {
                    String nombre  = rsProd.getString("nombre");
                    double precio  = rsProd.getDouble("precio");
                    int    stock   = rsProd.getInt("cantidad");
                    int    cantReal = Math.min(cant, stock);
                    double subtotal = precio * cantReal;

                    // Detalle
                    PreparedStatement stD = con.prepareStatement(
                        "INSERT INTO detalle_venta (venta_id,producto_id,nombre_producto,cantidad,precio_unitario,subtotal) VALUES (?,?,?,?,?,?)"
                    );
                    stD.setInt(1, ventaId); stD.setInt(2, prodId);
                    stD.setString(3, nombre); stD.setInt(4, cantReal);
                    stD.setDouble(5, precio); stD.setDouble(6, subtotal);
                    stD.executeUpdate(); stD.close();

                    // Descontar stock
                    PreparedStatement stU = con.prepareStatement(
                        "UPDATE productos SET cantidad=cantidad-?, numero_compras=numero_compras+? WHERE id=?"
                    );
                    stU.setInt(1, cantReal); stU.setInt(2, cantReal); stU.setInt(3, prodId);
                    stU.executeUpdate(); stU.close();

                    // Movimiento VENTA
                    PreparedStatement stM = con.prepareStatement(
                        "INSERT INTO movimientos_inventario (producto_id,usuario_id,tipo_movimiento,cantidad_anterior,cantidad_nueva,precio_anterior,venta_id,descripcion) VALUES (?,?,'VENTA',?,?,?,?,?)"
                    );
                    stM.setInt(1, prodId); stM.setInt(2, usuarioId);
                    stM.setInt(3, stock); stM.setInt(4, stock - cantReal);
                    stM.setDouble(5, precio); stM.setInt(6, ventaId);
                    stM.setString(7, "Venta #" + ventaId + " via app");
                    stM.executeUpdate(); stM.close();
                }
                rsProd.close(); stProd.close();
            }

            con.commit();
            out.print("{\"ok\":true,\"ventaId\":" + ventaId + ",\"total\":" + total + "}");

        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ex) {}
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
