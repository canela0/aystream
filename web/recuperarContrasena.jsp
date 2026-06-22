<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.security.MessageDigest"%>
<%@page import="java.math.BigInteger"%>
<%@page import="java.util.Random"%>
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
  String paso    = request.getParameter("paso");
  String correo  = request.getParameter("correo");
  String msgOk   = null;
  String msgErr  = null;

  // ── PASO 1: verificar correo y generar código ──────────────────────
  if ("verificar".equals(paso) && correo != null) {
    Connection con = null;
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = com.devbiz.util.DB.getConnection();
      PreparedStatement st = con.prepareStatement("SELECT id FROM usuarios WHERE correo=?");
      st.setString(1, correo.trim());
      ResultSet rs = st.executeQuery();
      if (rs.next()) {
        // Generar código de 6 dígitos y guardarlo en sesión
        String codigo = String.format("%06d", new Random().nextInt(999999));
        session.setAttribute("reset_correo", correo.trim());
        session.setAttribute("reset_codigo", codigo);
        session.setAttribute("reset_ts",     System.currentTimeMillis());
        paso = "codigo"; // avanzar al paso de verificación
      } else {
        msgErr = "No existe una cuenta con ese correo.";
        paso = null;
      }
      rs.close(); st.close();
    } catch(Exception e) { msgErr = "Error: " + e.getMessage(); paso = null; }
    finally { if(con!=null) try{con.close();}catch(Exception e){} }
  }

  // ── PASO 2: verificar código ingresado ─────────────────────────────
  if ("check_codigo".equals(paso)) {
    String codigoIngresado = request.getParameter("codigo");
    String codigoSesion    = (String) session.getAttribute("reset_codigo");
    String correoSesion    = (String) session.getAttribute("reset_correo");
    Long   ts              = (Long)   session.getAttribute("reset_ts");

    if (codigoSesion == null || correoSesion == null) {
      msgErr = "La sesión expiró. Vuelve a ingresar tu correo.";
      paso = null;
    } else if (System.currentTimeMillis() - ts > 10 * 60 * 1000) { // 10 min
      session.removeAttribute("reset_codigo");
      msgErr = "El código expiró (10 min). Inténtalo de nuevo.";
      paso = null;
    } else if (!codigoSesion.equals(codigoIngresado)) {
      msgErr = "Código incorrecto. Inténtalo de nuevo.";
      correo = correoSesion;
      paso   = "codigo";
    } else {
      // Código correcto → avanzar a nueva contraseña
      correo = correoSesion;
      paso   = "nueva";
    }
  }

  // ── PASO 3: cambiar contraseña ─────────────────────────────────────
  if ("cambiar".equals(paso)) {
    String correoSesion = (String) session.getAttribute("reset_correo");
    String codigoSesion = (String) session.getAttribute("reset_codigo");
    String nueva    = request.getParameter("nuevaPass");
    String confirma = request.getParameter("confirmaPass");

    if (correoSesion == null || codigoSesion == null) {
      msgErr = "Sesión inválida. Vuelve a iniciar el proceso.";
      paso = null;
    } else if (nueva == null || nueva.length() < 8) {
      msgErr = "La contraseña debe tener al menos 8 caracteres.";
      correo = correoSesion;
      paso   = "nueva";
    } else if (!nueva.equals(confirma)) {
      msgErr = "Las contraseñas no coinciden.";
      correo = correoSesion;
      paso   = "nueva";
    } else {
      Connection con = null;
      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = com.devbiz.util.DB.getConnection();
        PreparedStatement st = con.prepareStatement("UPDATE usuarios SET contrasena=? WHERE correo=?");
        st.setString(1, sha256(nueva.trim()));
        st.setString(2, correoSesion);
        st.executeUpdate(); st.close();
        // Limpiar sesión de recuperación
        session.removeAttribute("reset_correo");
        session.removeAttribute("reset_codigo");
        session.removeAttribute("reset_ts");
        msgOk = "ok";
      } catch(Exception e) { msgErr = "Error: " + e.getMessage(); correo = correoSesion; paso = "nueva"; }
      finally { if(con!=null) try{con.close();}catch(Exception e){} }
    }
  }

  // Recuperar correo de sesión para los pasos intermedios
  if ("codigo".equals(paso) && correo == null)
    correo = (String) session.getAttribute("reset_correo");
  if ("nueva".equals(paso) && correo == null)
    correo = (String) session.getAttribute("reset_correo");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Recuperar contraseña – PayStream</title>
  <link rel="stylesheet" href="estilo.css"/>
  <style>
    .input-pass-wrap { position: relative; }
    .input-pass-wrap .input-datos { width: 100%; box-sizing: border-box; padding-right: 42px; }
    .btn-ojo { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #9CA3AF; padding: 4px; display: flex; align-items: center; }
    .btn-ojo:hover { color: #374151; }
    .alerta-ok  { background:#dcfce7; border:1px solid #bbf7d0; color:#166534; border-radius:8px; padding:12px 16px; font-size:13px; font-weight:500; margin-bottom:16px; }
    .alerta-err { background:#fee2e2; border:1px solid #fecaca; color:#991b1b; border-radius:8px; padding:12px 16px; font-size:13px; font-weight:500; margin-bottom:16px; }

    /* Pasos */
    .pasos { display:flex; align-items:center; gap:8px; justify-content:center; margin-bottom:24px; }
    .paso-dot { width:28px; height:28px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:700; background:#E5E7EB; color:#9CA3AF; }
    .paso-dot.activo { background:#2563EB; color:#fff; }
    .paso-dot.done   { background:#10B981; color:#fff; }
    .paso-linea { flex:1; height:2px; background:#E5E7EB; max-width:40px; }
    .paso-linea.done { background:#10B981; }

    /* Código */
    .codigo-box {
      background: linear-gradient(135deg, #EFF6FF, #DBEAFE);
      border: 1.5px solid #BFDBFE;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      text-align: center;
    }
    .codigo-label { font-size: 12px; color: #3B82F6; font-weight: 600; text-transform: uppercase; letter-spacing: .06em; margin-bottom: 8px; }
    .codigo-numero { font-size: 36px; font-weight: 800; letter-spacing: 10px; color: #1D4ED8; font-family: monospace; }
    .codigo-expira { font-size: 11px; color: #6B7280; margin-top: 8px; }

    /* Input código */
    .input-codigo {
      width: 100%; text-align: center; font-size: 28px; font-weight: 700;
      letter-spacing: 8px; padding: 12px; border: 1.5px solid #D1D5DB;
      border-radius: 10px; font-family: monospace; transition: border-color .2s;
    }
    .input-codigo:focus { outline: none; border-color: #2563EB; box-shadow: 0 0 0 3px rgba(37,99,235,.1); }

    /* Fuerza */
    .strength-bars { display:flex; gap:4px; margin-top:8px; margin-bottom:4px; }
    .strength-bar { flex:1; height:4px; border-radius:99px; background:#E5E7EB; transition:background .3s; }
    .strength-bar.activa.debil  { background:#EF4444; }
    .strength-bar.activa.media  { background:#F59E0B; }
    .strength-bar.activa.fuerte { background:#10B981; }
    .strength-label { font-size:12px; color:#6B7280; }
    .btn-continuar-disabled { opacity: .45 !important; cursor: not-allowed !important; pointer-events: none; }
  </style>
</head>
<body>
<div class="contenedor-login">
  <div class="caja-login tarjeta texto-centro">

    <div class="titulos">
      <h1 class="titulo-login">PayStream</h1>
      <p class="subtitulo-login">recuperar contraseña</p>
    </div>

    <%-- Indicador de pasos --%>
    <%
      boolean p1 = true;
      boolean p2 = "codigo".equals(paso) || "nueva".equals(paso) || "cambiar".equals(paso);
      boolean p3 = "nueva".equals(paso)  || "cambiar".equals(paso);
      boolean p1done = p2; boolean p2done = p3;
    %>
    <div class="pasos">
      <div class="paso-dot <%= p1done ? "done" : "activo" %>"><%= p1done ? "✓" : "1" %></div>
      <div class="paso-linea <%= p1done ? "done" : "" %>"></div>
      <div class="paso-dot <%= p2done ? "done" : (p2 ? "activo" : "") %>"><%= p2done ? "✓" : "2" %></div>
      <div class="paso-linea <%= p2done ? "done" : "" %>"></div>
      <div class="paso-dot <%= p3 ? "activo" : "" %>">3</div>
    </div>

    <% if (msgErr != null && !"codigo".equals(paso) && !"nueva".equals(paso)) { %>
      <div class="alerta-err">✗ <%= msgErr %></div>
    <% } %>

    <%-- ══ ÉXITO ══ --%>
    <% if ("ok".equals(msgOk)) { %>
      <div class="alerta-ok">✓ Contraseña actualizada correctamente.</div>
      <p class="subtitulo-seccion" style="margin-bottom:20px;">Ya puedes iniciar sesión con tu nueva contraseña.</p>
      <a href="inicioSesion.jsp" class="boton boton-primario" style="display:block;">Ir a Iniciar sesión</a>

    <%-- ══ PASO 1: correo ══ --%>
    <% } else if (!"codigo".equals(paso) && !"nueva".equals(paso)) { %>
      <p class="titulo-seccion">Recuperar contraseña</p>
      <p class="subtitulo-seccion">Ingresa tu correo registrado</p>

      <form class="grupo-formulario" method="post" action="recuperarContrasena.jsp" onsubmit="return correoOk === true">
        <input type="hidden" name="paso" value="verificar"/>
        <div class="grupo-input">
          <label>Correo electrónico</label>
          <div style="position:relative;">
            <input class="input-datos" type="email" id="correoInput" name="correo"
                   placeholder="correo@ejemplo.com" required autocomplete="email"
                   value="<%= correo != null ? correo : "" %>"
                   oninput="verificarCorreo(this.value)" style="padding-right:38px;box-sizing:border-box;width:100%;"/>
            <span id="correoSpinner" style="display:none;position:absolute;right:12px;top:50%;transform:translateY(-50%);font-size:14px;">⏳</span>
            <span id="correoIcono"  style="display:none;position:absolute;right:12px;top:50%;transform:translateY(-50%);font-size:16px;"></span>
          </div>
          <div id="correoMsg" style="font-size:12px;margin-top:5px;min-height:16px;"></div>
        </div>
        <button class="boton boton-primario btn-continuar-disabled" type="submit" id="btnContinuar" disabled>Continuar</button>
        <a href="inicioSesion.jsp" class="boton boton-secundario" style="display:block;margin-top:10px;text-align:center;">Volver</a>
      </form>

    <%-- ══ PASO 2: código ══ --%>
    <% } else if ("codigo".equals(paso)) {
         String codigo = (String) session.getAttribute("reset_codigo");
    %>
      <p class="titulo-seccion">Verificar identidad</p>
      <p class="subtitulo-seccion">Se generó este código de verificación para <strong><%= correo %></strong></p>

      <div class="codigo-box">
        <div class="codigo-label">Tu código de verificación</div>
        <div class="codigo-numero"><%= codigo %></div>
        <div class="codigo-expira">Válido por 10 minutos</div>
      </div>

      <% if (msgErr != null) { %><div class="alerta-err">✗ <%= msgErr %></div><% } %>

      <form class="grupo-formulario" method="post" action="recuperarContrasena.jsp" onsubmit="return validarCodigo()">
        <input type="hidden" name="paso"   value="check_codigo"/>
        <input type="hidden" name="correo" value="<%= correo %>"/>
        <div class="grupo-input">
          <label>Ingresa el código</label>
          <input class="input-codigo" type="text" id="codigo" name="codigo"
                 placeholder="000000" maxlength="6" autocomplete="off"/>
          <a id="errCodigo" class="mensajeError"></a>
        </div>
        <button class="boton boton-primario" style="margin-top:16px" type="submit">Verificar código</button>
        <a href="recuperarContrasena.jsp" class="boton boton-secundario" style="display:block;margin-top:10px;text-align:center;">Reintentar</a>
      </form>

    <%-- ══ PASO 3: nueva contraseña ══ --%>
    <% } else if ("nueva".equals(paso)) { %>
      <p class="titulo-seccion">Nueva contraseña</p>
      <p class="subtitulo-seccion">Elige una contraseña segura para <strong><%= correo %></strong></p>

      <% if (msgErr != null) { %><div class="alerta-err">✗ <%= msgErr %></div><% } %>

      <form class="grupo-formulario" method="post" action="recuperarContrasena.jsp" onsubmit="return validarNueva()">
        <input type="hidden" name="paso"   value="cambiar"/>
        <input type="hidden" name="correo" value="<%= correo %>"/>

        <div class="grupo-input">
          <label>Nueva contraseña</label>
          <div class="input-pass-wrap">
            <input class="input-datos" type="password" id="nuevaPass" name="nuevaPass"
                   placeholder="••••••••" oninput="evalFuerza(this.value)"/>
            <button type="button" class="btn-ojo" onclick="toggleOjo('nuevaPass','ojo1')" tabindex="-1">
              <svg id="ojo1" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
              </svg>
            </button>
          </div>
          <div class="strength-bars">
            <div class="strength-bar" id="sb1"></div><div class="strength-bar" id="sb2"></div>
            <div class="strength-bar" id="sb3"></div><div class="strength-bar" id="sb4"></div>
          </div>
          <div class="strength-label" id="slbl">Escribe tu contraseña</div>
          <a id="errNueva" class="mensajeError"></a>
        </div>

        <div class="grupo-input">
          <label>Confirmar contraseña</label>
          <div class="input-pass-wrap">
            <input class="input-datos" type="password" id="confirmaPass" name="confirmaPass" placeholder="••••••••" oninput="verificarCoincidencia()"/>
            <button type="button" class="btn-ojo" onclick="toggleOjo('confirmaPass','ojo2')" tabindex="-1">
              <svg id="ojo2" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
              </svg>
            </button>
          </div>
          <a id="errConfirma" class="mensajeError"></a>
        </div>

        <button class="boton boton-primario" style="margin-top:20px" type="submit">Cambiar contraseña</button>
      </form>
    <% } %>

  </div>
</div>
<script>
  var correoOk = false;
  var correoTimer = null;

  function verificarCorreo(val) {
    clearTimeout(correoTimer);
    var msg    = document.getElementById('correoMsg');
    var icono  = document.getElementById('correoIcono');
    var spin   = document.getElementById('correoSpinner');
    var btn    = document.getElementById('btnContinuar');
    correoOk   = false;
    btn.disabled = true;
    icono.style.display = 'none';

    if (!val || val.length < 4 || !val.includes('@')) {
      msg.textContent = ''; spin.style.display = 'none';
      btn.disabled = true; btn.classList.add('btn-continuar-disabled');
      return;
    }

    spin.style.display = 'inline';
    msg.textContent = '';

    correoTimer = setTimeout(function() {
      fetch('checkCorreo.jsp?correo=' + encodeURIComponent(val))
        .then(function(r){ return r.json(); })
        .then(function(data) {
          spin.style.display = 'none';
          icono.style.display = 'inline';
          if (data.existe) {
            icono.textContent = '✓';
            icono.style.color = '#16A34A';
            msg.textContent   = 'Correo registrado ✓';
            msg.style.color   = '#16A34A';
            correoOk = true;
            btn.disabled = false;
            btn.classList.remove('btn-continuar-disabled');
          } else {
            icono.textContent = '✗';
            icono.style.color = '#DC2626';
            msg.textContent   = 'No existe una cuenta con ese correo';
            msg.style.color   = '#DC2626';
            correoOk = false;
            btn.disabled = true;
            btn.classList.add('btn-continuar-disabled');
          }
        })
        .catch(function(){ spin.style.display = 'none'; });
    }, 500); // espera 500ms tras dejar de escribir
  }

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
  function tieneSecuencia(val) {
    var v = val.toLowerCase();
    var nums  = '0123456789012';
    var alfaN = 'abcdefghijklmnopqrstuvwxyzabcd';
    for (var i = 0; i < v.length - 2; i++) {
      var t = v.slice(i, i+3);
      if (nums.includes(t) || alfaN.includes(t)) return true;
      // secuencia invertida
      var tr = t.split('').reverse().join('');
      if (nums.includes(tr) || alfaN.includes(tr)) return true;
      // repetición: aaa, 111
      if (t[0] === t[1] && t[1] === t[2]) return true;
    }
    return false;
  }

  function evalFuerza(val) {
    var len   = val.length >= 8;
    var upper = /[A-Z]/.test(val);
    var num   = /[0-9]/.test(val);
    var sym   = /[^A-Za-z0-9]/.test(val);
    var noSeq = val.length > 0 && !tieneSecuencia(val);

    var score = [len, upper, num, sym, noSeq].filter(Boolean).length;
    // Máx 4 barras: mapear score 0-5 → 0-4
    var barras = Math.min(4, Math.floor(score * 4 / 5));
    var cls = barras <= 1 ? 'debil' : (barras <= 2 ? 'media' : 'fuerte');
    ['sb1','sb2','sb3','sb4'].forEach(function(b,i){
      document.getElementById(b).className='strength-bar'+(i<barras?' activa '+cls:'');
    });
    var labels = {0:'Muy débil',1:'Débil',2:'Regular',3:'Buena',4:'Fuerte'};
    document.getElementById('slbl').textContent = val.length===0 ? 'Escribe tu contraseña' : labels[barras];
    if (val.length > 0 && tieneSecuencia(val)) {
      document.getElementById('slbl').textContent = 'Contiene secuencias (123, abc...) — cámbiala';
      document.getElementById('slbl').style.color = '#DC2626';
    } else {
      document.getElementById('slbl').style.color = '';
    }
  }
  function verificarCoincidencia() {
    var p = document.getElementById('nuevaPass').value;
    var c = document.getElementById('confirmaPass').value;
    var err = document.getElementById('errConfirma');
    if (c.length === 0) { err.textContent = ''; return; }
    err.textContent = p === c ? '' : 'Las contraseñas no coinciden';
    err.style.color = '#DC2626';
  }

  function validarCodigo() {
    var c = document.getElementById('codigo').value.trim();
    if (c.length !== 6 || isNaN(c)) {
      document.getElementById('errCodigo').textContent = 'El código debe ser de 6 dígitos';
      return false;
    }
    return true;
  }
  function validarNueva() {
    var p = document.getElementById('nuevaPass').value;
    var c = document.getElementById('confirmaPass').value;
    document.getElementById('errNueva').textContent = '';
    document.getElementById('errConfirma').textContent = '';
    if (p.length < 8) { document.getElementById('errNueva').textContent = 'Mínimo 8 caracteres'; return false; }
    if (!/[A-Z]/.test(p)) { document.getElementById('errNueva').textContent = 'Debe tener al menos una mayúscula'; return false; }
    if (!/[0-9]/.test(p)) { document.getElementById('errNueva').textContent = 'Debe tener al menos un número'; return false; }
    if (tieneSecuencia(p)) { document.getElementById('errNueva').textContent = 'No uses secuencias como "123" o "abc"'; return false; }
    if (p !== c) { document.getElementById('errConfirma').textContent = 'Las contraseñas no coinciden'; return false; }
    return true;
  }
</script>
</body>
</html>
