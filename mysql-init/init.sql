-- Script de inicializacion de bases de datos
-- Se ejecuta automaticamente al levantar MySQL por primera vez

CREATE DATABASE IF NOT EXISTS despacho_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS ventas_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
