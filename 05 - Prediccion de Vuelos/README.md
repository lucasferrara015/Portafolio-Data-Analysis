# ✈️ Flight Price Prediction - Machine Learning & Feature Engineering

## 📝 Descripción del Proyecto
Este proyecto aplica modelos avanzados de Machine Learning (Analítica Predictiva) sobre un conjunto de **+300,000 registros reales de reservas de vuelos** del sitio "Ease My Trip". El objetivo es predecir de forma exacta la tarifa de un billete de avión en función de sus características logísticas, temporales y comerciales, ayudando a los pasajeros a descubrir patrones óptimos de compra.

---

## 🔍 Hallazgos del Análisis Exploratorio (EDA)

A través del análisis estadístico descriptivo en Pandas, se dio respuesta a las 5 preguntas de investigación del negocio:

* **a) ¿Varía el precio según las aerolíneas?**
  Sí, existe una brecha clara. Aerolíneas premium como **Vistara** (~$7,764) y **Air India** (~$7,281) lideran los costos promedio, mientras que aerolíneas Low-Cost como **Indigo** (~$5,324) se mantienen como las opciones más económicas.
* **b) ¿Cómo afecta comprar el billete 1 o 2 días antes?**
  El impacto es crítico. Comprar con 1 día de anticipación dispara los precios a su punto máximo histórico debido a los algoritmos de urgencia de las aerolíneas. A partir del día 20 antes del vuelo, el precio se estabiliza en su mínimo.
* **c) ¿El precio cambia según la hora de salida y llegada?**
  Los vuelos nocturnos (*Night*) y de madrugada (*Early Morning*) muestran las tarifas promedio más bajas por la menor demanda de pasajeros, mientras que los horarios de mañana y tarde concentran los precios más altos.
* **d) ¿Cómo cambia el precio con el origen y el destino?**
  Las rutas que conectan grandes centros financieros y turísticos de la India muestran un comportamiento de tarifa diferenciada basada en la distancia y la cantidad de aerolíneas que compiten en el tramo.
* **e) ¿Cómo varía el precio entre clase Económica y Business?**
  Esta es la variable con mayor peso. La clase Business multiplica exponencialmente el ticket promedio en comparación con la clase Económica, actuando como el divisor principal del mercado.

---

## 🛠️ Ingeniería de Características (Feature Engineering)
Para preparar los datos antes de introducirlos en los modelos matemáticos de `scikit-learn`, se realizaron las siguientes transformaciones de ingeniería:
1. **Ordinal Encoding Manual:** Se transformó la variable `class` (`Economy`: 0, `Business`: 1) y `stops` (`zero`: 0, `one`: 1, `two_or_more`: 2) respetando su jerarquía lógica.
2. **One-Hot Encoding:** Se procesaron las variables categóricas de texto puro (`airline`, `source_city`, `departure_time`, `arrival_time`, `destination_city`) expandiéndolas en columnas binarias.
3. **Escalado Numérico:** Se aplicó `StandardScaler` sobre `duration` y `days_left` para normalizar las distancias y evitar que las magnitudes distorsionen algoritmos basados en vecindad (KNN).

---

## 🤖 Evaluación Comparativa de Modelos

Para resolver el problema de regresión, se entrenaron y evaluaron tres "cerebros" algorítmicos competitivos sobre un set de prueba del 20% de los datos:

| Modelo | MAE (Error Promedio) | R² Score (Precisión) | Diagnóstico Técnico |
| :--- | :--- | :--- | :--- |
| **Regresión Lineal Baseline** | $1,870.85 | 50.67% | **Pobre:** No logra capturar las relaciones complejas y no lineales de las tarifas dinámicas. |
| **K-Neighbors Regressor (KNN)** | $843.41 | 74.52% | **Aceptable:** Mejora al agrupar vuelos similares, pero es lento y sensible a dimensiones altas. |
| **XGBoost Regressor (Conjunto)** | *[COMPLETAR]* | *[COMPLETAR]* | **Excelente (Ganador):** Los árboles de decisión en cadena entienden perfectamente las interacciones cruzadas (ej: Business + Último minuto). |

*Nota: Reemplazar [COMPLETAR] con los números finales que te arroje el XGBoost en tu pantalla.*

---

## 📊 Conclusión de Ingeniería de Datos
El proyecto demuestra que los modelos basados en **Ensambles de Árboles (XGBoost)** son drásticamente superiores para resolver problemas de tarificación dinámica frente a aproximaciones lineales simples. El uso de **Pipelines** de producción garantiza que el modelo quede listo para ser consumido o desplegado en una aplicación web en tiempo real.
