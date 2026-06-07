<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }

    String nombre   = "";
    String apellido = "";
    String correo   = "";

    Connection conecta = null;
    PreparedStatement st = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conecta = DriverManager.getConnection("jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0");
        st = conecta.prepareStatement("SELECT nombre, apellido, correo FROM usuarios WHERE id = ?");
        st.setInt(1, usuarioId);
        rs = st.executeQuery();
        if (rs.next()) {
            nombre   = rs.getString("nombre");
            apellido = rs.getString("apellido");
            correo   = rs.getString("correo");
        }
    } catch (Exception e) {
        // silencioso
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (st != null) try { st.close(); } catch (Exception e) {}
        if (conecta != null) try { conecta.close(); } catch (Exception e) {}
    }

    String inicial = nombre.isEmpty() ? "U" : String.valueOf(nombre.charAt(0)).toUpperCase();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Mis datos – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    html, body { height: 100%; background: var(--bg); }

    .datos-page {
      padding: 40px 48px;
    }

    .datos-header {
      margin-bottom: 32px;
    }

    .datos-header-label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .08em;
      color: var(--muted);
      margin-bottom: 6px;
    }

    .datos-header-title {
      font-size: 22px;
      font-weight: 700;
      color: var(--text);
    }

    .perfil-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 32px;
      max-width: 480px;
      box-shadow: var(--shadow-sm);
    }

    .perfil-avatar {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: linear-gradient(135deg, #2563eb, #8b5cf6);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 28px;
      font-weight: 700;
      color: #fff;
      margin-bottom: 20px;
    }

    .perfil-nombre {
      font-size: 20px;
      font-weight: 700;
      color: var(--text);
      margin-bottom: 4px;
    }

    .perfil-correo {
      font-size: 13px;
      color: var(--muted);
      margin-bottom: 28px;
    }

    .perfil-divider {
      border: none;
      border-top: 1px solid var(--border);
      margin-bottom: 24px;
    }

    .perfil-campo {
      margin-bottom: 20px;
    }

    .perfil-campo-label {
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: .06em;
      color: var(--muted);
      margin-bottom: 6px;
    }

    .perfil-campo-valor {
      font-size: 15px;
      font-weight: 500;
      color: var(--text);
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 10px 14px;
    }
  </style>
</head>
    <body>

    <div class="datos-page">

      <div class="datos-header">
        <div class="datos-header-label">Cuenta</div>
        <h1 class="datos-header-title">Mis datos</h1>
      </div>

      <div class="perfil-card">

        <div class="perfil-avatar"><%= inicial %></div>
        <div class="perfil-nombre"><%= nombre %> <%= apellido %></div>
        <div class="perfil-correo"><%= correo %></div>

        <hr class="perfil-divider"/>

        <div class="perfil-campo">
          <div class="perfil-campo-label">Nombre</div>
          <div class="perfil-campo-valor"><%= nombre %></div>
        </div>

        <div class="perfil-campo">
          <div class="perfil-campo-label">Apellido</div>
          <div class="perfil-campo-valor"><%= apellido %></div>
        </div>

        <div class="perfil-campo">
          <div class="perfil-campo-label">Correo electrónico</div>
          <div class="perfil-campo-valor"><%= correo %></div>
        </div>

      </div>

    </div>

    </body>
</html>
