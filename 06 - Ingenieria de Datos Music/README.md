# Pipeline ETL para Monitoreo de Tendencias Musicales Globales (Last.fm API)

## 📌 Visión General del Proyecto
Este proyecto diseña e implementa un pipeline ETL (Extracción, Transformación y Carga) de extremo a extremo que interactúa con la API oficial de Last.fm para capturar diariamente las tendencias de reproducción global (*Global Charts*). El objetivo principal es normalizar estos datos crudos JSON provenientes de internet y modelar un **Data Warehouse (Bodega de Datos) bajo un Esquema en Estrella** dentro de una instancia local de **MySQL**, construyendo una base histórica sólida para análisis de inteligencia competitiva en la industria musical.

---

## 🏗️ Modelo de Datos (Esquema en Estrella)
Para optimizar las consultas analíticas y garantizar la integridad referencial, la base de datos `lastfm_dw` se estructuró dividiendo los datos descriptivos de las métricas transaccionales diarias.

## 📁 Estructura del Repositorio en esta Carpeta
* **`pipeline_lastfm.ipynb`**: Script en Python ejecutado en Google Colab para la extracción vía API REST, sanitización de IDs, normalización en DataFrames de Pandas y exportación de la materia prima a archivos CSV.
* **`queries_y_modelado.sql`**: Script SQL estructurado para MySQL que contiene el Data Definition Language (DDL) del Data Warehouse, la lógica de optimización, índices, emulación de vistas y analítica avanzada, PL-SQL.
* **`data/`**: Carpeta que contiene las muestras de datos extraídas en formato CSV (`dim_songs.csv`, `dim_artists.csv`, `fact_global_charts.csv`) para permitir la replicabilidad del proyecto.


### 📊 Tabla de Hechos (Fact Table)
* **`fact_global_charts`**: Almacena las métricas cuantitativas del ranking que cambian día a día.
  * `fact_id` (INT AUTO_INCREMENT - Primary Key)
  * `date_key` (DATE - Foreign Key ➡️ Conecta con la dimensión temporal)
  * `song_id` (VARCHAR - Foreign Key ➡️ Conecta con `dim_songs`)
  * `artist_id` (VARCHAR - Foreign Key ➡️ Conecta con `dim_artists`)
  * `rank_position` (INT): Puesto ocupado en el ranking global de ese día.
  * `playcount_daily` (INT): Total histórico de reproducciones de la canción acumulado a esa fecha.
  * `listeners_daily` (INT): Cantidad total de oyentes únicos registrados.

### 📂 Tablas de Dimensiones (Dimensional Tables)
* **`dim_songs`**: Mantiene los atributos estáticos e independientes de las canciones.
  * `song_id` (VARCHAR - Primary Key): Clave única generada mediante sanitización (`artist_name + song_name`).
  * `song_name` (VARCHAR)
  * `song_url` (TEXT)
* **`dim_artists`**: Almacena el perfil descriptivo de los creadores de contenido.
  * `artist_id` (VARCHAR - Primary Key)
  * `artist_name` (VARCHAR)
  * `artist_url` (TEXT)

---

## 🚀 Arquitectura Escalable a 1000x (Respuestas Técnicas)
El pipeline actual procesa de forma eficiente el Top 50 global de manera local. Ante un escenario corporativo donde se requiera escalar este proceso a **1.000 o más rankings/cuentas en paralelo**, se planificó la siguiente migración de arquitectura:

1. **Desacoplamiento mediante un Data Lake (Inbound):** Mover 1.000 peticiones en paralelo directamente hacia la base de datos relacional colapsaría el sistema. La solución es limitar el script de Python exclusivamente a extraer los JSON puros de la API de forma ultra-rápida y depositarlos como "datos crudos" (Raw Data) en un almacenamiento elástico y económico como **AWS S3** o **Google Cloud Storage**.
2. **Procesamiento Masivo en Paralelo (MPP):** Para la fase de Transformación (separación de dimensiones y tablas de hechos), se sustituiría la librería Pandas por **Apache Spark (PySpark)**. Spark distribuye la carga del volumen masivo de JSON en un clúster de computadoras. El destino final de carga mutaría hacia un Cloud Data Warehouse administrado como **Snowflake** o **Google BigQuery**.
3. **Orquestación y Control de API Limits:** Para automatizar el proceso al 100%, las tareas de Python se encapsulan en DAGs de **Apache Airflow**, calendarizados mediante expresiones CRON (ej. ejecutarse diariamente a las 23:59). Para mitigar el bloqueo por límite de peticiones de la API de Last.fm (*Rate Limiting*), se implementa una cola de mensajería como **Apache Kafka** que regula el flujo de peticiones utilizando políticas de reintento automático (*Exponential Backoff*).

---

## 💡 Optimización Analítica & Consultas Avanzadas (SQL)
Dentro del archivo `queries_y_modelado.sql` se implementaron soluciones avanzadas orientadas a reportes de alto rendimiento y análisis de series de tiempo:

1. **Emulación de Vista Materializada (`mv_artist_performance_summary`):** Dado que MySQL no cuenta con soporte nativo para *Materialized Views*, se diseñó una tabla física pre-calculada de resumen de performance por artista. Para garantizar la eficiencia, se estructuró una carga incremental utilizando la cláusula `ON DUPLICATE KEY UPDATE`, evitando realizar un escaneo completo (`Table Scan`) y recalculación de JOINs masivos en cada consulta del negocio.
2. **Cálculo de Volatilidad con Funciones de Ventana (`LAG`):** Se implementó una query analítica utilizando `LAG() OVER (PARTITION BY ... ORDER BY ...)` para contrastar el ranking diario actual de una canción frente al del día anterior, calculando el delta exacto de puestos escalados o descendidos.
3. **Participación de Mercado (Market Share):** Uso de funciones analíticas de agregación `SUM() OVER (PARTITION BY date_key)` para identificar de manera dinámica qué porcentaje total de oyentes absorbe cada artista por día sobre el tráfico global de la plataforma.
4. **Índice de Fidelidad (Engagement):** Consultas métricas agrupadas aplicando filtros agregados (`HAVING`) para calcular el ratio de `Reproducciones / Oyentes Únicos`, aislando el comportamiento de "usuarios fanáticos" frente a oyentes casuales.

---

## 🛠️ Tecnologías Utilizadas y Valor Técnico
* **Python (Requests & Pandas):** Consumo de API REST de forma nativa, manejo de payloads JSON, limpieza de strings, hashing/generación de IDs artificiales y normalización tabular.
* **SQL (MySQL):** Modelado físico de bases de datos relacionales, asignación estricta de tipos de datos, configuración de índices de claves primarias y restricciones de claves foráneas para resguardar la integridad referencial.
* **MySQL Workbench:** Administración, ingeniería directa y auditoría de datos.
