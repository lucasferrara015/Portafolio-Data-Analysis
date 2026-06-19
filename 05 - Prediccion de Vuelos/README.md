# ✈️ Flight Price Prediction - Machine Learning & Feature Engineering

## 📝 Descripción del Proyecto
Este proyecto aplica modelos de Machine Learning (Analítica Predictiva) sobre un conjunto masivo de **más de 300,000 registros reales de reservas de vuelos** obtenidos de la plataforma "Ease My Trip". El objetivo central es predecir de forma exacta la tarifa continua de un billete de avión en función de sus características logísticas, temporales y comerciales, aislando las variables de mayor impacto y comparando el rendimiento de arquitecturas lineales frente a algoritmos basados en vecindad y conjuntos de árboles.

---

## 🔍 Hallazgos del Análisis Exploratorio (EDA)

A través del análisis estadístico descriptivo en Pandas, se dio respuesta formal a las preguntas de investigación del negocio:

* **a) ¿Varía el precio según las aerolíneas?** Sí, existe una brecha tarifaria clara. Las aerolíneas premium como **Vistara** y **Air India** lideran los costos promedio debido a sus servicios incluidos, mientras que compañías como **Indigo** y **GO FIRST** se consolidan como las opciones más económicas (*Low-Cost*).
* **b) ¿Cómo afecta comprar el billete 1 o 2 días antes?** El impacto de la anticipación (`days_left`) es el predictor crítico no lineal del negocio. Comprar con 24 o 48 horas de antelación dispara los precios a su punto máximo histórico debido a los algoritmos de urgencia de las compañías. El precio tiende a estabilizarse y encontrar su mínimo a partir de los 20 días previos al despegue.
* **c) ¿El precio cambia según la hora de salida y llegada?** Los vuelos nocturnos (*Night*) y de madrugada (*Early Morning*) registran las tarifas promedio más bajas por la menor demanda de pasajeros, mientras que los horarios de mañana y tarde concentran los picos de precio.
* **d) ¿Cómo cambia el precio con el origen y el destino?** Las rutas que conectan los principales centros financieros y de alta densidad demográfica de la India muestran un comportamiento dinámico condicionado por la distancia del tramo y la cantidad de competidores operativos en la ruta.
* **e) ¿Cómo varía el precio entre clase Económica y Business?** Esta es la variable con mayor peso absoluto en el dataset. La clase Business multiplica exponencialmente el costo del ticket respecto a la clase Económica, actuando como el divisor estructural del mercado analizado.

---

## 🛠️ Ingeniería de Características (Feature Engineering)
Para preparar la matriz de datos antes de introducirla en las funciones matemáticas de `scikit-learn`, se diseñó un pipeline de procesamiento robusto:
1. **Ordinal Encoding Jerárquico:** Se transformaron manualmente las variables con orden lógico implícito: `class` (`Economy`: 0, `Business`: 1) y `stops` (`zero`: 0, `one`: 1, `two_or_more`: 2).
2. **One-Hot Encoding Extendido:** Se procesaron de forma automática las variables categóricas nominales (`airline`, `source_city`, `departure_time`, `arrival_time`, `destination_city`), convirtiéndolas en vectores binarios y descartando la primera columna (`drop='first'`) para evitar la multicolinealidad.
3. **Escalado Numérico Estándar:** Se aplicó `StandardScaler` sobre las variables continuas (`duration` y `days_left`). Esto fue crítico para normalizar las magnitudes e impedir que las diferencias de escala distorsionaran los algoritmos basados en distancias como KNN.

---

## 🤖 Evaluación Comparativa de Modelos

Para resolver el problema de regresión, se entrenaron tres arquitecturas algorítmicas competitivas utilizando un esquema de validación cruzada sobre un set de testeo independiente del 20%:

| Modelo Evaluado | MAE (Error en Dinero) | RMSE (Castigo a Desvíos) | R² Score (Precisión) | Diagnóstico Técnico |
| :--- | :--- | :--- | :--- | :--- |
| **Regresión Lineal Baseline** | \$1,870.85 | \$2,572.77 | 50.67% | **Pobre:** Incapaz de capturar las relaciones complejas y los saltos dinámicos de las tarifas aéreas. |
| **XGBoost Regressor (Conjunto)** | \$1,060.09 | \$1,699.21 | 78.48% | **Bueno:** Gran capacidad de generalización, pero limitado por la parametrización base ante la alta densidad local de los datos. |
| **K-Neighbors Regressor (KNN)** | **\$843.41** | **\$1,635.50** | **80.07%** | **Excelente (Ganador):** Logró la máxima precisión y el menor margen de error promedio del experimento. |

---

## 💡 Conclusión Analítica y Defensa del Modelo Ganador

El resultado de este proyecto arrojó una conclusión técnica sumamente enriquecedora para la toma de decisiones: **K-Neighbors Regressor (KNN) superó a XGBoost alcanzando un 80.07% de precisión**. 

Aunque los modelos de ensamble de árboles suelen dominar los datos tabulares, el mercado aerocomercial masivo de este dataset demostró ser altamente repetitivo. Al contar con un volumen denso de datos (+300K registros), el algoritmo KNN logró explotar de manera óptima la similitud física. Ante la consulta de un vuelo nuevo, el modelo localizó con exactitud "vuelos vecinos idénticos" vendidos en el pasado (misma aerolínea, misma anticipación, misma clase), logrando estimar la tarifa real con un error promedio de apenas **\$843.41**.

El uso de **Pipelines de Scikit-Learn** implementado en este código garantiza la reproducibilidad del experimento, aislando por completo el procesamiento de datos del entrenamiento y dejando el modelo listo para ser exportado a producción en una arquitectura de microservicios o una *Data App* interactiva.
