<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.security.MessageDigest"%>
<%@page import="java.math.BigInteger"%>
<%!
  private String sha256(String input) {
    try {
      java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
      byte[] hash = md.digest(input.getBytes("UTF-8"));
      java.math.BigInteger bi = new java.math.BigInteger(1, hash);
      String hex = bi.toString(16);
      while (hex.length() < 64) hex = "0" + hex;
      return hex;
    } catch (Exception e) { return input; }
  }
%>
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
        conecta = com.devbiz.util.DB.getConnection();
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

    // Cambiar contraseña
    String passOk  = null;
    String passErr = null;
    if ("cambiar".equals(request.getParameter("accion"))) {
        String actual   = request.getParameter("passActual");
        String nueva    = request.getParameter("passNueva");
        String confirma = request.getParameter("passConfirma");
        if (actual == null || nueva == null || nueva.length() < 8) {
            passErr = "La nueva contraseña debe tener al menos 8 caracteres.";
        } else if (!nueva.equals(confirma)) {
            passErr = "Las contraseñas no coinciden.";
        } else {
            Connection conP = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conP = com.devbiz.util.DB.getConnection();
                PreparedStatement stP = conP.prepareStatement("SELECT contrasena FROM usuarios WHERE id=?");
                stP.setInt(1, usuarioId);
                ResultSet rsP = stP.executeQuery();
                if (rsP.next() && rsP.getString("contrasena").equals(sha256(actual.trim()))) {
                    rsP.close(); stP.close();
                    PreparedStatement stU = conP.prepareStatement("UPDATE usuarios SET contrasena=? WHERE id=?");
                    stU.setString(1, sha256(nueva.trim()));
                    stU.setInt(2, usuarioId);
                    stU.executeUpdate(); stU.close();
                    passOk = "Contraseña actualizada correctamente.";
                } else {
                    rsP.close(); stP.close();
                    passErr = "La contraseña actual es incorrecta.";
                }
            } catch(Exception e) { passErr = "Error: " + e.getMessage(); }
            finally { if(conP!=null) try{conP.close();}catch(Exception e){} }
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Mis datos – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    html, body { height: 100%; background: var(--bg); overflow-y: auto; }
    .input-pass-wrap { position: relative; }
    .input-pass-wrap input { padding-right: 42px !important; box-sizing: border-box; }
    .btn-ojo { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #9CA3AF; padding: 4px; display: flex; align-items: center; }
    .btn-ojo:hover { color: #374151; }
    .alerta-ok  { background:#dcfce7; border:1px solid #bbf7d0; color:#166534; border-radius:8px; padding:10px 14px; font-size:13px; font-weight:500; margin-bottom:16px; }
    .alerta-err { background:#fee2e2; border:1px solid #fecaca; color:#991b1b; border-radius:8px; padding:10px 14px; font-size:13px; font-weight:500; margin-bottom:16px; }
    .pass-section-title { font-size:15px; font-weight:700; color:var(--text); margin-bottom:16px; padding-top:24px; border-top:1px solid var(--border); }

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

        <!-- Cambiar contraseña -->
        <p class="pass-section-title">Cambiar contraseña</p>

        <% if (passOk != null) { %><div class="alerta-ok">✓ <%= passOk %></div><% } %>
        <% if (passErr != null) { %><div class="alerta-err">✗ <%= passErr %></div><% } %>

        <form method="post" action="misDatos.jsp" onsubmit="return validarPass()">
          <input type="hidden" name="accion" value="cambiar"/>

          <div class="perfil-campo">
            <div class="perfil-campo-label">Contraseña actual</div>
            <div class="input-pass-wrap">
              <input class="input-datos2" type="password" id="passActual" name="passActual" placeholder="••••••••" style="width:100%;"/>
              <button type="button" class="btn-ojo" onclick="toggleOjo('passActual','ojo0')" tabindex="-1">
                <svg id="ojo0" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                </svg>
              </button>
            </div>
          </div>

          <div class="perfil-campo">
            <div class="perfil-campo-label">Nueva contraseña</div>
            <div class="input-pass-wrap">
              <input class="input-datos2" type="password" id="passNueva" name="passNueva" placeholder="Min. 8 caracteres" style="width:100%;"/>
              <button type="button" class="btn-ojo" onclick="toggleOjo('passNueva','ojo1')" tabindex="-1">
                <svg id="ojo1" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                </svg>
              </button>
            </div>
            <a id="errNueva" class="mensajeError"></a>
          </div>

          <div class="perfil-campo">
            <div class="perfil-campo-label">Confirmar nueva contraseña</div>
            <div class="input-pass-wrap">
              <input class="input-datos2" type="password" id="passConfirma" name="passConfirma" placeholder="••••••••" style="width:100%;"/>
              <button type="button" class="btn-ojo" onclick="toggleOjo('passConfirma','ojo2')" tabindex="-1">
                <svg id="ojo2" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                </svg>
              </button>
            </div>
            <a id="errConfirma" class="mensajeError"></a>
          </div>

          <button class="boton boton-primario" type="submit" style="width:100%;margin-top:8px;">
            Actualizar contraseña
          </button>
        </form>

      </div>

    </div>

    <script>
      function toggleOjo(inputId, svgId) {
        var inp = document.getElementById(inputId);
        var svg = document.getElementById(svgId);
        if (inp.type === 'password') {
          inp.type = 'text';
          svg.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/>';
        } else {
          inp.type = 'password';
          svg.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
        }
      }
      function validarPass() {
        document.getElementById('errNueva').textContent = '';
        document.getElementById('errConfirma').textContent = '';
        var nueva    = document.getElementById('passNueva').value;
        var confirma = document.getElementById('passConfirma').value;
        if (nueva.length < 8) { document.getElementById('errNueva').textContent = 'Mínimo 8 caracteres'; return false; }
        if (nueva !== confirma) { document.getElementById('errConfirma').textContent = 'Las contraseñas no coinciden'; return false; }
        return true;
      }
    </script>
    </body>
</html>
