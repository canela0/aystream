package com.devbiz.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Punto único de conexión a la base de datos.
 * Lee host/usuario/clave de variables de entorno (configurables en Azure App Service)
 * y cae de vuelta a los valores de desarrollo local si no están definidas.
 */
public class DB {

    private static final String HOST = System.getenv().getOrDefault("DB_HOST", "localhost:3306");
    private static final String NAME = System.getenv().getOrDefault("DB_NAME", "payStream");
    private static final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private static final String PASS = System.getenv().getOrDefault("DB_PASS", "n0m3l0");
    private static final String EXTRA = System.getenv().getOrDefault("DB_PARAMS", "");

    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        String url = "jdbc:mysql://" + HOST + "/" + NAME + EXTRA;
        return DriverManager.getConnection(url, USER, PASS);
    }
}
