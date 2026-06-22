<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect("inicioSesion.jsp");
        return;
    }
    String usuarioNombre = (String) session.getAttribute("usuarioNombre");
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Reportes - PayStream</title>
    <link rel="stylesheet" href="estilo.css" />
  </head>
  <body>
    <div class="boton-volver">
      <input type="button" class="boton boton-borde"
             value="← Volver al menu"
             onclick="location.href='menu.jsp'" />
    </div>

    <section class="seccion">
      <h2 class="titulo-seccion">Reportes</h2>
      <p class="subtitulo-seccion">Selecciona el reporte que deseas consultar</p>

      <div class="grid-opciones">

        <div class="tarjeta-opcion" onclick="location.href='historialVentas.jsp'">
          <div class="area-imagen2 fondo-naranja">
            <img src="carro-vacio.png" class="imagen2" />
          </div>
          <div class="texto-opcion">
            <p class="titulo-opcion">Historial de Ventas</p>
            <p class="descripcion-opcion">Consulta todas las transacciones realizadas</p>
          </div>
        </div>

        <div class="tarjeta-opcion" onclick="location.href='reporteInventario.jsp'">
          <div class="area-imagen2 fondo-verde">
            <img src="inventario.png" class="imagen2" />
          </div>
          <div class="texto-opcion">
            <p class="titulo-opcion">Movimientos de Inventario</p>
            <p class="descripcion-opcion">Altas, bajas y ajustes del inventario</p>
          </div>
        </div>

        <div class="tarjeta-opcion" onclick="location.href='balanceSemanal.jsp'">
          <div class="area-imagen2 fondo-morado">
            <img src="ventas.png" class="imagen2" />
          </div>
          <div class="texto-opcion">
            <p class="titulo-opcion">Balance Semanal</p>
            <p class="descripcion-opcion">Resumen financiero por semana</p>
          </div>
        </div>

      </div>
    </section>
  </body>
</html>