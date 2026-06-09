-- ============================================================
--  PayStream – Script de base de datos
--  Base de datos: payStream
-- ============================================================

CREATE DATABASE IF NOT EXISTS payStream
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE payStream;

-- ------------------------------------------------------------
-- Tabla: usuarios
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    correo      VARCHAR(150) NOT NULL UNIQUE,
    contrasena  VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: user_roles  (requerida por DataSourceRealm de Tomcat)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_roles (
    correo      VARCHAR(150) NOT NULL,
    role_name   VARCHAR(50)  NOT NULL,
    PRIMARY KEY (correo, role_name),
    FOREIGN KEY (correo) REFERENCES usuarios(correo) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: productos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS productos (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id   INT            NOT NULL,
    nombre       VARCHAR(200)   NOT NULL,
    cantidad     INT            NOT NULL DEFAULT 0,
    precio       DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    precio_costo DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    fecha        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: ventas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ventas (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id  INT           NOT NULL,
    total       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    fecha       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: detalle_venta
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS detalle_venta (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    venta_id         INT           NOT NULL,
    producto_id      INT           NOT NULL,
    nombre_producto  VARCHAR(200)  NOT NULL,
    cantidad         INT           NOT NULL,
    precio_unitario  DECIMAL(10,2) NOT NULL,
    subtotal         DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (venta_id)    REFERENCES ventas(id)    ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: movimientos_inventario
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    producto_id       INT           NOT NULL,
    usuario_id        INT           NOT NULL,
    tipo_movimiento   ENUM('ALTA','BAJA','AJUSTE','VENTA') NOT NULL,
    cantidad_anterior INT           DEFAULT NULL,
    cantidad_nueva    INT           DEFAULT NULL,
    precio_anterior   DECIMAL(10,2) DEFAULT NULL,
    precio_nuevo      DECIMAL(10,2) DEFAULT NULL,
    venta_id          INT           DEFAULT NULL,
    descripcion       VARCHAR(255)  DEFAULT NULL,
    fecha             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id)  REFERENCES usuarios(id)  ON DELETE CASCADE,
    FOREIGN KEY (venta_id)    REFERENCES ventas(id)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: balance_semanal
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS balance_semanal (
    id                        INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id                INT           NOT NULL,
    semana_inicio             DATE          NOT NULL,
    semana_fin                DATE          NOT NULL,
    valor_inventario_inicio   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    valor_inventario_fin      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_vendido             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    costo_productos_vendidos  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    num_ventas                INT           NOT NULL DEFAULT 0,
    num_productos_agregados   INT           NOT NULL DEFAULT 0,
    num_productos_eliminados  INT           NOT NULL DEFAULT 0,
    UNIQUE KEY uq_usuario_semana (usuario_id, semana_inicio),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  Datos de ejemplo - usuario administrador
--  Correo: toro@gmail.com  |  Contrasena: 1234
-- ============================================================
INSERT IGNORE INTO usuarios (nombre, apellido, correo, contrasena)
VALUES ('Toro', 'Admin', 'toro@gmail.com', '1234');

INSERT IGNORE INTO user_roles (correo, role_name)
VALUES ('toro@gmail.com', 'admin');
