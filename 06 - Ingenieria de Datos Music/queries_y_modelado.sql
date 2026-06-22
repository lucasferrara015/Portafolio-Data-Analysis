-- ============================================================================
-- SCRIPT DE CREACIÓN DE TABLAS, MODELADO DIMENSIONAL Y ANALÍTICA AVANZADA
-- Proyecto: Pipeline ETL para Monitoreo de Tendencias Musicales Globales
-- Autor: Lucas Ferrara
-- Base de Datos: MySQL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CONFIGURACIÓN E INFRAESTRUCTURA DEL DATA WAREHOUSE (DDL)
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS lastfm_dw;
USE lastfm_dw;

-- Eliminar tablas previas en orden inverso debido a restricciones de FK
DROP TABLE IF EXISTS fact_global_charts;
DROP TABLE IF EXISTS dim_songs;
DROP TABLE IF EXISTS dim_artists;

-- Crear Dimensión de Artistas
CREATE TABLE dim_artists (
    artist_id VARCHAR(100) PRIMARY KEY,
    artist_name VARCHAR(255) NOT NULL,
    artist_url TEXT
) ENGINE=InnoDB;

-- Crear Dimensión de Canciones
CREATE TABLE dim_songs (
    song_id VARCHAR(100) PRIMARY KEY,
    song_name VARCHAR(255) NOT NULL,
    song_url TEXT
) ENGINE=InnoDB;

-- Crear Tabla de Hechos (Esquema en Estrella)
CREATE TABLE fact_global_charts (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    date_key DATE NOT NULL,
    rank_position INT NOT NULL,
    song_id VARCHAR(100),
    artist_id VARCHAR(100),
    playcount_daily INT,
    listeners_daily INT,
    -- Restricciones de Integridad Referencial
    FOREIGN KEY (song_id) REFERENCES dim_songs(song_id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES dim_artists(artist_id) ON DELETE CASCADE,
    -- Índice para optimizar consultas basadas en tiempo
    INDEX idx_date (date_key)
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 2. SOLUCIÓN AVANZADA: EMULACIÓN DE MATERIALIZED VIEW (VISTA MATERIALIZADA)
-- ----------------------------------------------------------------------------
-- Explicación Técnica: Como MySQL no posee "Materialized Views" nativas, 
-- se crea una tabla física de resumen analítico (Pre-calculada) para evitar 
-- recalcular millones de filas en JOINs costosos cada vez que el negocio consulta.

DROP TABLE IF EXISTS mv_artist_performance_summary;

CREATE TABLE mv_artist_performance_summary (
    artist_name VARCHAR(255) PRIMARY KEY,
    total_reproducciones_acumuladas BIGINT,
    total_oyentes_unicos BIGINT,
    mejor_posicion_alcanzada INT,
    dias_en_el_top INT,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Script de Carga/Refresco (Simula el REFRESH MATERIALIZED VIEW)
-- Este bloque se ejecutaría al final del pipeline ETL diario
INSERT INTO mv_artist_performance_summary (artist_name, total_reproducciones_acumuladas, total_oyentes_unicos, mejor_posicion_alcanzada, dias_en_el_top)
SELECT 
    a.artist_name,
    SUM(f.playcount_daily) AS total_reproducciones,
    SUM(f.listeners_daily) AS total_oyentes,
    MIN(f.rank_position) AS mejor_posicion,
    COUNT(DISTINCT f.date_key) AS dias_en_top
FROM fact_global_charts f
INNER JOIN dim_artists a ON f.artist_id = a.artist_id
GROUP BY a.artist_name
ON DUPLICATE KEY UPDATE 
    total_reproducciones_acumuladas = VALUES(total_reproducciones_acumuladas),
    total_oyentes_unicos = VALUES(total_oyentes_unicos),
    mejor_posicion_alcanzada = VALUES(mejor_posicion_alcanzada),
    dias_en_el_top = VALUES(dias_en_el_top);


-- ----------------------------------------------------------------------------
-- 3. QUERIES ANALÍTICAS DE REPORTE Y FUNCIONES DE VENTANA (WINDOW FUNCTIONS)
-- ----------------------------------------------------------------------------

-- CONSULTA A: Volatilidad y Variación Diaria del Ranking (Window Function: LAG)
-- Objetivo: Determinar cuántos puestos subió o bajó una canción respecto al día anterior.
SELECT 
    f.date_key AS 'Fecha',
    s.song_name AS 'Canción',
    a.artist_name AS 'Artista',
    f.rank_position AS 'Posición Actual',
    LAG(f.rank_position, 1) OVER (
        PARTITION BY f.song_id 
        ORDER BY f.date_key
    ) AS 'Posición Día Anterior',
    -- Cálculo del delta de movimiento
    (LAG(f.rank_position, 1) OVER (PARTITION BY f.song_id ORDER BY f.date_key) - f.rank_position) AS 'Desplazamiento'
FROM fact_global_charts f
INNER JOIN dim_songs s ON f.song_id = s.song_id
INNER JOIN dim_artists a ON f.artist_id = a.artist_id
ORDER BY f.date_key DESC, f.rank_position ASC;


-- CONSULTA B: Distribución del Mercado Musical (Window Function: DENSE_RANK & SUM OVER)
-- Objetivo: Calcular el porcentaje de oyentes que abarca cada artista por día sobre el total global.
SELECT 
    f.date_key AS 'Fecha',
    a.artist_name AS 'Artista',
    SUM(f.listeners_daily) AS 'Oyentes Artista Día',
    -- Suma acumulada de todos los oyentes de ese día específico
    SUM(SUM(f.listeners_daily)) OVER (PARTITION BY f.date_key) AS 'Total Oyentes Global Día',
    -- Ratio de participación de mercado (Market Share)
    ROUND((SUM(f.listeners_daily) / SUM(SUM(f.listeners_daily)) OVER (PARTITION BY f.date_key)) * 100, 2) AS 'Market Share %'
FROM fact_global_charts f
INNER JOIN dim_artists a ON f.artist_id = a.artist_id
GROUP BY f.date_key, a.artist_name
ORDER BY f.date_key DESC, `Market Share %` DESC;


-- CONSULTA C: Ratio de Engagement/Fidelidad por Artista
-- Objetivo: Determinar qué canciones generan mayor repetición de escucha (Reproducciones por Usuario).
SELECT 
    s.song_name AS 'Canción',
    a.artist_name AS 'Artista',
    SUM(f.playcount_daily) AS 'Total Reproducciones',
    SUM(f.listeners_daily) AS 'Total Oyentes',
    ROUND(SUM(f.playcount_daily) / SUM(f.listeners_daily), 2) AS 'Índice Repetición (Fidelidad)'
FROM fact_global_charts f
INNER JOIN dim_songs s ON f.song_id = s.song_id
INNER JOIN dim_artists a ON f.artist_id = a.artist_id
GROUP BY s.song_id, s.song_name, a.artist_name
HAVING `Total Oyentes` > 0
ORDER BY `Índice Repetición (Fidelidad)` DESC;

-- ----------------------------------------------------------------------------
-- 4. AUTOMATIZACIÓN EN BASE DE DATOS: STORED PROCEDURE (PL/SQL)
-- ----------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE sp_refresh_artist_summary()
BEGIN
    -- Declaramos un bloque transaccional para asegurar consistencia
    START TRANSACTION;
    
    -- Ejecuta la actualización incremental de nuestra "Vista Materializada"
    INSERT INTO mv_artist_performance_summary (
        artist_name, 
        total_reproducciones_acumuladas, 
        total_oyentes_unicos, 
        mejor_posicion_alcanzada, 
        dias_en_el_top
    )
    SELECT 
        a.artist_name,
        SUM(f.playcount_daily),
        SUM(f.listeners_daily),
        MIN(f.rank_position),
        COUNT(DISTINCT f.date_key)
    FROM fact_global_charts f
    INNER JOIN dim_artists a ON f.artist_id = a.artist_id
    GROUP BY a.artist_name
    ON DUPLICATE KEY UPDATE 
        total_reproducciones_acumuladas = VALUES(total_reproducciones_acumuladas),
        total_oyentes_unicos = VALUES(total_oyentes_unicos),
        mejor_posicion_alcanzada = VALUES(mejor_posicion_alcanzada),
        dias_en_el_top = VALUES(dias_en_el_top);
        
    COMMIT;
END //

DELIMITER ;

-- Para ejecutarlo desde la aplicación o Python: CALL sp_refresh_artist_summary();
