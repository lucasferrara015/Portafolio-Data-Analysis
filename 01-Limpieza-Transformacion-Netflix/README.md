# Proyecto: Limpieza y Transformación de Datos (Data Wrangling) - Netflix Dataset

Este proyecto forma parte de mi portafolio profesional de Análisis de Datos. El objetivo principal es aplicar técnicas esenciales de **Data Wrangling** (limpieza y transformación) utilizando Python y la librería `pandas`, tomando un dataset del mundo real con imperfecciones y optimizándolo estructuralmente para que quede completamente listo para fases de análisis exploratorio (EDA) o modelado predictivo.

## 📌 Objetivo del Proyecto
Demostrar competencia técnica en la manipulación y curación de datos tabulares, abordando problemas comunes como valores faltantes, tipos de datos incorrectos, ingeniería de características simple y detección estadística de valores atípicos (outliers).

## 🛠️ Tecnologías y Herramientas
* **Lenguaje:** Python 3.x
* **Librerías Clave:** Pandas, NumPy
* **Entorno de Desarrollo:** Google Colab / Jupyter Notebooks

## 📊 El Dataset Original: Diagnóstico Inicial
El conjunto de datos original (`netflix_titles.csv`) contiene información sobre las películas y series de televisión disponibles en la plataforma hasta 2021. Al realizar el diagnóstico inicial (`df.isnull().sum()`), se detectaron las siguientes problemáticas críticas:
* **`director`:** 2,634 valores nulos.
* **`cast`:** 825 valores nulos.
* **`country`:** 831 valores nulos.
* **`date_added` y `rating`:** Pocos registros nulos pero inconsistentes.
* **Tipos de datos:** Columnas temporales tratadas como texto (`object`).
* **Columnas irrelevantes:** Datos redundantes o no estructurados para análisis tabular básico.

---

## 🛠️ Fases del Proceso de Limpieza y Transformación

### 1. Gestión de Valores Nulos (Imputación vs. Filtrado)
* **Imputación Categórica:** Para las columnas de texto con alto volumen de nulos (`director`, `cast`, `country`), se aplicó una estrategia de relleno con el valor constante `"Unknown"`. Esto evitó la pérdida de casi el 35% de los datos del dataset.
* **Imputación por Moda:** La columna `rating` se completó utilizando el valor más frecuente (la moda) del conjunto de datos por ser una variable categórica cerrada.
* **Filtrado Directo:** Se eliminaron las filas correspondientes a nulos en `date_added` y `duration` mediante `dropna()`, dado que representaban un impacto marginal (solo 13 filas en total) y no afectaban la representatividad de la muestra.

### 2. Transformación de Tipos de Datos (Parsing)
* La columna `date_added` venía codificada como texto (ej: "September 25, 2021"). Se limpiaron los espacios en blanco y se parseó al tipo de dato nativo de fecha `datetime64` de pandas para permitir operaciones de ordenamiento cronológico.
* La columna `type` se convirtió al tipo `category` para optimizar el uso de memoria RAM del entorno de ejecución.

### 3. Ingeniería de Características (Feature Engineering)
Para enriquecer el dataset de cara a futuros análisis estacionales y de segmentación, se crearon nuevas variables extraídas de los datos limpios:
* **`year_added`:** Extrae exclusivamente el año en el que el contenido se sumó a la plataforma.
* **`month_added`:** Extrae el nombre del mes de adición.
* **`primary_genre`:** Se utilizó `str.split(',')` sobre la columna `listed_in` para extraer únicamente el género principal o primer género listado, reduciendo la dispersión en las categorías.

### 4. Justificación de Columnas Eliminadas
Se aplicó una reducción de dimensiones descartando variables que añadían ruido analítico:
* `show_id`: Eliminada por ser una clave secuencial arbitraria sin peso estadístico o correlativo.
* `description`: Texto libre no estructurado de gran longitud. Su análisis requiere técnicas avanzadas de Procesamiento de Lenguaje Natural (NLP), por lo que se descartó en esta etapa puramente tabular.

### 5. Detección Estadística de Outliers (Valores Atípicos)
Focalizándonos en el catálogo de películas, se extrajo el valor numérico de la columna `duration` (eliminando la cadena ' min'). Utilizando el método del **Rango Intercuartílico (IQR)**, se definieron los umbrales estadísticos de normalidad:
* **Límite Inferior:** 46.5 minutos.
* **Límite Superior:** 154.5 minutos.

Se identificaron **450 películas atípicas** (muy cortas o muy largas). 
> **Criterio Analítico:** Se tomó la decisión de *conservar* estos outliers en el dataset final (`netflix_titles_clean.csv`), puesto que representan registros comerciales legítimos (cortometrajes, documentales breves o largometrajes extensos) que no constituyen errores de medición, sino diversidad real del negocio.

---

## 📈 Resultados: El "Antes y Después"

| Métrica / Columna | Dataset Original | Dataset Limpio (`netflix_titles_clean.csv`) |
| :--- | :---: | :---: |
| **Total de Registros Nulos** | 4,307 | **0 (100% Libre de Nulos)** |
| **Formato de Fechas** | Texto (`object`) | Temporal (`datetime64`) |
| **Columnas Clave Creadas** | Ninguna | `year_added`, `month_added`, `primary_genre` |
| **Columnas Eliminadas** | Ninguna | `show_id`, `description` |

## 📁 Estructura del Repositorio
* `Limpieza_y_transformación_Dataset_Netflix.ipynb`: Notebook de Google Colab documentado con bloques de código y explicaciones paso a paso.
* `netflix_titles_clean.csv`: Archivo final exportado, normalizado y listo para herramientas de Business Intelligence (como Power BI o Tableau) o análisis estadísticos avanzados.

## 🧠 Aprendizajes Clave
Este proyecto consolidó mi entendimiento sobre el impacto del *Data Wrangling* en el ciclo de vida de los datos, demostrando que la limpieza no es un proceso mecánico, sino una serie de decisiones metodológicas donde cada fila eliminada o imputada requiere una justificación orientada a los objetivos del negocio.
