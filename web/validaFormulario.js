/* --------- Inicio de sesión --------- */
function validaInicioSesion() {
  let valido = true;
  let correoInput = document.getElementById("correoElectronico");
  let contraInput = document.getElementById("contrasena");

  correoInput.classList.remove("input-datosError");
  contraInput.classList.remove("input-datosError");

  mensajeErrorCorreo.innerText = "";
  mensajeErrorContra.innerText = "";

  if (correoInput.value.trim() === "") {
    correoInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorCorreo.innerText = "Introduce un correo valido o registrate";
  }

  if (contraInput.value.trim() === "") {
    contraInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorContra.innerText = "Contraseña erronea";
  }
  return valido;
}


/* --------- Registro de usuario --------- */
function validaRegistro() {
  let valido = true;

  let nombreInput    = document.getElementById("nombreUsuario");
  let apellidoInput  = document.getElementById("apellidoUsuario");
  let correoInput    = document.getElementById("correoElectronico");
  let contraInput    = document.getElementById("contrasena");
  let confirmaInput  = document.getElementById("confirmaContrasena");

  const soloLetras = /^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$/;

  nombreInput.classList.remove("input-datosError");
  apellidoInput.classList.remove("input-datosError");
  correoInput.classList.remove("input-datosError");
  contraInput.classList.remove("input-datosError");
  confirmaInput.classList.remove("input-datosError");

  mensajeErrorNombre.innerText   = "";
  mensajeErrorApellido.innerText = "";
  mensajeErrorCorreo.innerText   = "";
  mensajeErrorContra.innerText   = "";
  mensajeErrorConfirma.innerText = "";

  if (nombreInput.value.trim() === "") {
    nombreInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorNombre.innerText = "Introduce un nombre válido";
  } else if (!soloLetras.test(nombreInput.value.trim())) {
    nombreInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorNombre.innerText = "El nombre solo debe contener letras";
  }

  if (apellidoInput.value.trim() === "") {
    apellidoInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorApellido.innerText = "Introduce un apellido válido";
  } else if (!soloLetras.test(apellidoInput.value.trim())) {
    apellidoInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorApellido.innerText = "El apellido solo debe contener letras";
  }

  if (correoInput.value.trim() === "") {
    correoInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorCorreo.innerText = "Introduce un correo válido";
  }

  if (contraInput.value.trim() === "") {
    contraInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorContra.innerText = "Introduce una contraseña válida";
  }

  if (confirmaInput.value.trim() !== contraInput.value.trim()) {
    confirmaInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorConfirma.innerText = "No coincide la contraseña";
  }

  return valido;
}


/* --------- Registro de productos --------- */
function validaRegistroProducto() {
  let valido = true;

  let nombreInput   = document.getElementById("nombre");
  let cantidadInput = document.getElementById("cantidad");
  let precioInput   = document.getElementById("precio");

  let mensajeErrorNombre   = document.getElementById("mensajeErrorNombre");
  let mensajeErrorCantidad = document.getElementById("mensajeErrorCantidad");
  let mensajeErrorPrecio   = document.getElementById("mensajeErrorPrecio");

  // CORRECCIÓN: se permiten letras, números, espacios, guiones y #
  // para soportar nombres como "Coca-Cola 2L", "Aceite #3", etc.
  const nombreProductoValido = /^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9\s\-#\.]+$/;
  const soloNumeros          = /^\d+$/;
  const numerosDosDecimales  = /^\d*\.?\d{0,2}$/;

  nombreInput.classList.remove("input-datosError");
  cantidadInput.classList.remove("input-datosError");
  precioInput.classList.remove("input-datosError");

  mensajeErrorNombre.innerText   = "";
  mensajeErrorCantidad.innerText = "";
  mensajeErrorPrecio.innerText   = "";

  if (nombreInput.value.trim() === "") {
    nombreInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorNombre.innerText = "Introduce un nombre de producto válido";
  } else if (!nombreProductoValido.test(nombreInput.value.trim())) {
    nombreInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorNombre.innerText = "Nombre inválido (evita caracteres especiales)";
  }

  if (cantidadInput.value.trim() === "") {
    cantidadInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorCantidad.innerText = "Introduce una cantidad";
  } else if (!soloNumeros.test(cantidadInput.value.trim())) {
    cantidadInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorCantidad.innerText = "La cantidad solo puede ser numérica";
  }

  if (precioInput.value.trim() === "") {
    precioInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorPrecio.innerText = "Introduce un precio";
  } else if (!numerosDosDecimales.test(precioInput.value.trim())) {
    precioInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorPrecio.innerText = "El precio solo puede tener máximo 2 decimales";
  }

  return valido;
}

/* --------- Modificación de productos --------- */
document.addEventListener("DOMContentLoaded", () => {
  deshabilitarFormularioDerecha();
});

function deshabilitarFormularioDerecha() {
  const contenedor = document.getElementById("formDerecha");
  if (!contenedor) return;

  contenedor.classList.add("form-deshabilitado");

  const elementos = contenedor.querySelectorAll("input, button");
  elementos.forEach(el => el.disabled = true);
}

function validaDatosProducto() {
  let valido = true;
  let nombreInput  = document.getElementById("nombreBusqueda");
  let mensajeError = document.getElementById("mensajeErrorBusqueda");

  const nombreProductoValido = /^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9\s\-#\.]+$/;

  nombreInput.classList.remove("input-datosError");
  mensajeErrorBusqueda.innerText = "";

  if (nombreInput.value.trim() === "") {
    nombreInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorBusqueda.innerText = "Producto no encontrado";
  } else if (!nombreProductoValido.test(nombreInput.value.trim())) {
    nombreInput.classList.add("input-datosError");
    valido = false;
    mensajeErrorBusqueda.innerText = "Nombre inválido (evita caracteres especiales)";
  }

  return valido;
}
