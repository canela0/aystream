<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    // ── Verificar autenticación via Realm o sesión manual ──
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    String usuarioNombre = (String) session.getAttribute("usuarioNombre");

    if (usuarioId == null) {
        // El Realm autenticó al usuario — obtener datos desde el principal
        java.security.Principal principal = request.getUserPrincipal();
        if (principal == null) {
            response.sendRedirect("inicioSesion.jsp");
            return;
        }
        String correoAuth = principal.getName();
        Connection conAuth = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conAuth = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/payStream", "root", "n0m3l0"
            );
            PreparedStatement stAuth = conAuth.prepareStatement(
                "SELECT id, nombre FROM usuarios WHERE correo = ?"
            );
            stAuth.setString(1, correoAuth);
            ResultSet rsAuth = stAuth.executeQuery();
            if (rsAuth.next()) {
                usuarioId     = rsAuth.getInt("id");
                usuarioNombre = rsAuth.getString("nombre");
                session.setAttribute("usuarioId",     usuarioId);
                session.setAttribute("usuarioNombre", usuarioNombre);
            }
            rsAuth.close(); stAuth.close();
        } catch (Exception e) {
            response.sendRedirect("inicioSesion.jsp");
            return;
        } finally {
            if (conAuth != null) try { conAuth.close(); } catch(Exception e){}
        }
    }

    String inicial = usuarioNombre != null ? String.valueOf(usuarioNombre.charAt(0)).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>PayStream</title>
  <link rel="stylesheet" href="estilo.css" />
  <style>
    html, body { height: 100%; overflow: hidden; }

    /* ── Mobile: sidebar colapsado ── */
    @media (max-width: 600px) {
      .sidebar {
        width: 60px;
        min-width: 60px;
      }
      .sidebar-brand-name,
      .sidebar-brand-sub,
      .sidebar-label,
      .sidebar-link span,
      .account-name,
      .account-sub { display: none; }
      .sidebar-link {
        justify-content: center;
        padding: 12px;
      }
      .sidebar-link svg { margin: 0; }
      .account-btn { justify-content: center; padding: 8px; }
      .account-avatar { margin: 0; }
      .account-chevron { display: none; }
      .account-dropdown { left: 60px; bottom: 60px; width: 180px; position: fixed; }
    }

    /* ── Dropdown cuenta ── */
    .account-wrapper {
      position: relative;
      padding: 12px;
    }

    .account-btn {
      display: flex;
      align-items: center;
      gap: 10px;
      width: 100%;
      padding: 8px 10px;
      border-radius: 8px;
      background: transparent;
      border: none;
      cursor: pointer;
      transition: background .15s;
      text-align: left;
    }

    .account-btn:hover { background: rgba(255,255,255,.06); }

    .account-avatar {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: linear-gradient(135deg, #2563eb, #8b5cf6);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 13px;
      font-weight: 700;
      color: #fff;
      flex-shrink: 0;
    }

    .account-info { flex: 1; overflow: hidden; }

    .account-name {
      font-size: 13px;
      font-weight: 600;
      color: #e2e8f0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .account-sub {
      font-size: 11px;
      color: #64748b;
      margin-top: 1px;
    }

    .account-chevron {
      color: #64748b;
      transition: transform .2s;
      flex-shrink: 0;
    }

    .account-btn.open .account-chevron { transform: rotate(180deg); }

    .account-dropdown {
      display: none;
      background: #1e293b;
      border: 1px solid rgba(255,255,255,.08);
      border-radius: 8px;
      overflow: hidden;
      margin-bottom: 4px;
    }

    .account-dropdown.visible { display: block; }

    .dropdown-item {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 14px;
      font-size: 13px;
      color: #94a3b8;
      cursor: pointer;
      border: none;
      background: transparent;
      width: 100%;
      text-align: left;
      font-family: inherit;
      transition: background .15s, color .15s;
    }

    .dropdown-item:hover { background: rgba(255,255,255,.06); color: #fff; }
    .dropdown-item.danger:hover { background: rgba(239,68,68,.12); color: #f87171; }
  </style>
</head>
<body>

<div class="app-shell">

  <!-- ── Sidebar ── -->
  <aside class="sidebar">

    <div class="sidebar-brand">
      <div class="sidebar-brand-name">PayStream</div>
      <div class="sidebar-brand-sub">por DevBiz</div>
    </div>

    <nav class="sidebar-nav">
      <span class="sidebar-label">Menú</span>

      <button class="sidebar-link active" onclick="navegar('menu.html', this)">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
          <rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>
        </svg>
        Inicio
      </button>

      <button class="sidebar-link" onclick="navegar('productos.html', this)">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
          <polyline points="3.27 6.96 12 12.01 20.73 6.96"/>
          <line x1="12" y1="22.08" x2="12" y2="12"/>
        </svg>
        Inventario
      </button>

      <button class="sidebar-link" onclick="navegar('ventas.jsp', this)">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
          <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
        </svg>
        Ventas
      </button>

      <button class="sidebar-link" onclick="navegar('reportes.jsp', this)">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="18" y1="20" x2="18" y2="10"/>
          <line x1="12" y1="20" x2="12" y2="4"/>
          <line x1="6"  y1="20" x2="6"  y2="14"/>
        </svg>
        Reportes
      </button>
    </nav>

    <!-- ── Cuenta ── -->
    <div style="border-top: 1px solid rgba(255,255,255,.08);">
      <div class="account-wrapper">

        <div class="account-dropdown" id="accountDropdown">
          <button class="dropdown-item" onclick="navegar('misDatos.jsp', null)">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
            Ver mis datos
          </button>
          <button class="dropdown-item danger" onclick="cerrarSesion()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
              <polyline points="16 17 21 12 16 7"/>
              <line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
            Cerrar sesión
          </button>
        </div>

        <button class="account-btn" id="accountBtn" onclick="toggleDropdown()">
          <div class="account-avatar"><%= inicial %></div>
          <div class="account-info">
            <div class="account-name"><%= usuarioNombre %></div>
            <div class="account-sub">Mi cuenta</div>
          </div>
          <svg class="account-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="18 15 12 9 6 15"/>
          </svg>
        </button>

      </div>
    </div>

  </aside>

  <!-- ── Área de contenido ── -->
  <main class="content-area">
    <iframe
      id="contenido"
      class="marco-contenido"
      src="menu.html"
      name="contenido">
    </iframe>
  </main>

</div>

<script>
  const iframe = document.getElementById('contenido');
  iframe.addEventListener('load', () => { iframe.style.opacity = '1'; });

  function navegar(url, btn) {
    iframe.style.opacity = '0';
    setTimeout(() => { iframe.src = url; }, 150);
    document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
    if (btn) btn.classList.add('active');
    // Cerrar dropdown si estaba abierto
    document.getElementById('accountDropdown').classList.remove('visible');
    document.getElementById('accountBtn').classList.remove('open');
  }

  function toggleDropdown() {
    const dropdown = document.getElementById('accountDropdown');
    const btn = document.getElementById('accountBtn');
    dropdown.classList.toggle('visible');
    btn.classList.toggle('open');
  }

  function cerrarSesion() {
    window.location.href = 'inicioSesion.jsp';
  }

  // Cerrar dropdown al hacer clic fuera
  document.addEventListener('click', (e) => {
    const wrapper = document.querySelector('.account-wrapper');
    if (!wrapper.contains(e.target)) {
      document.getElementById('accountDropdown').classList.remove('visible');
      document.getElementById('accountBtn').classList.remove('open');
    }
  });
</script>

</body>
</html>
