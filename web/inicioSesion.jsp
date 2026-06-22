<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Si ya está autenticado, ir directo al dashboard
    if (request.getUserPrincipal() != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    boolean error = "1".equals(request.getParameter("error"));

    // Límite de intentos (5 máx, bloqueo 10 min)
    final int MAX_INTENTOS  = 5;
    final long BLOQUEO_MS   = 10 * 60 * 1000L;
    Integer intentos        = (Integer) session.getAttribute("loginIntentos");
    Long    bloqueadoHasta  = (Long)    session.getAttribute("loginBloqueadoHasta");
    if (intentos  == null) intentos = 0;
    if (bloqueadoHasta == null) bloqueadoHasta = 0L;

    boolean bloqueado = System.currentTimeMillis() < bloqueadoHasta;

    if (error && !bloqueado) {
        intentos++;
        session.setAttribute("loginIntentos", intentos);
        if (intentos >= MAX_INTENTOS) {
            bloqueadoHasta = System.currentTimeMillis() + BLOQUEO_MS;
            session.setAttribute("loginBloqueadoHasta", bloqueadoHasta);
            bloqueado = true;
        }
    }
    if (!error && !bloqueado) {
        session.setAttribute("loginIntentos", 0);
    }
    long segundosRestantes = bloqueado ? Math.max(0, (bloqueadoHasta - System.currentTimeMillis()) / 1000) : 0;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Inicio de sesion</title>
    <link rel="stylesheet" href="estilo.css" />
    <style>
      .input-pass-wrap { position: relative; }
      .input-pass-wrap .input-datos { width: 100%; box-sizing: border-box; padding-right: 42px; }
      .btn-ojo { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #9CA3AF; padding: 4px; display: flex; align-items: center; transition: color .15s; }
      .btn-ojo:hover { color: #374151; }
      .enlace-recuperar { font-size: 12px; color: #6B7280; text-decoration: none; float: right; margin-top: 4px; }
      .enlace-recuperar:hover { color: #2563EB; }
    </style>
</head>
<body>
    <div class="contenedor-login">
        <div class="caja-login tarjeta texto-centro">
            <div class="titulos">
                <h1 class="titulo-login">PayStream</h1>
                <p class="subtitulo-login">creado por devbiz</p>
            </div>
            <div>
                <p class="titulo-seccion">Iniciar Sesion</p>
                <p class="subtitulo-seccion">Ingresa tus datos para continuar</p>
            </div>
            <% if (bloqueado) { %>
            <div style="background:#FEE2E2;border:1px solid #FECACA;color:#991B1B;border-radius:10px;padding:14px 16px;margin-bottom:16px;font-size:13px;">
              🔒 Demasiados intentos fallidos. Espera <strong id="countdown"><%= segundosRestantes %></strong> segundos.
            </div>
            <% } else if (error && intentos > 1) { %>
            <div style="background:#FFF7ED;border:1px solid #FED7AA;color:#92400E;border-radius:10px;padding:10px 14px;margin-bottom:12px;font-size:12px;">
              ⚠ Intento <%= intentos %> de <%= MAX_INTENTOS %>. Después se bloqueará 10 minutos.
            </div>
            <% } %>
            <form class="grupo-formulario" method="post" action="j_security_check" <%= bloqueado ? "onsubmit='return false'" : "" %>>
                <div class="grupo-input">
                    <label>Correo Electronico</label>
                    <input class="input-datos" type="email" id="j_username" name="j_username"
                           placeholder="correo@ejemplo.com"/>
                </div>
                <div class="grupo-input">
                    <label style="margin-top: 18px">Contraseña</label>
                    <div class="input-pass-wrap">
                      <input class="input-datos" type="password" id="j_password" name="j_password"
                             placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;"/>
                      <button type="button" class="btn-ojo" onclick="toggleOjo()" tabindex="-1">
                        <svg id="ojo-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                        </svg>
                      </button>
                    </div>
                    <a href="recuperarContrasena.jsp" class="enlace-recuperar">¿Olvidaste tu contraseña?</a>
                </div>
                <% if (error && !bloqueado) { %>
                    <p style="color:#DC2626; text-align:left; font-size:13px;">Correo o contraseña incorrectos.</p>
                <% } %>
                <button class="boton boton-primario" style="margin-top:20px;<%= bloqueado ? "opacity:.5;cursor:not-allowed;" : "" %>" type="submit" <%= bloqueado ? "disabled" : "" %>>
                    Iniciar sesión
                </button>
            </form>
            <div class="div-enlace">
                <a href="registro.html" class="enlace">¿No tienes cuenta? Crear cuenta</a>
            </div>
        </div>
    </div>
<script>
  <% if (bloqueado) { %>
  var secs = <%= segundosRestantes %>;
  var cd = document.getElementById('countdown');
  var iv = setInterval(function() {
    secs--;
    if (secs <= 0) { clearInterval(iv); location.reload(); }
    else if (cd) cd.textContent = secs;
  }, 1000);
  <% } %>

  function toggleOjo() {
    var inp = document.getElementById('j_password');
    var svg = document.getElementById('ojo-icon');
    if (inp.type === 'password') {
      inp.type = 'text';
      svg.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/>';
    } else {
      inp.type = 'password';
      svg.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
    }
  }
</script>
</body>
</html>
