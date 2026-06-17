import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import streamlit as sns_st  # Cambiamos nombre para evitar conflicto con seaborn
import streamlit as st

# Configuración de la página web
st.set_page_config(page_title="Amazon Market Analytics", layout="wide")

# 1. Cargar los datos (usamos caché para que cargue ultra rápido)
@st.cache_data
def load_data():
    # Asegúrate de que el CSV esté en la misma carpeta que este script
    df = pd.read_csv("amazon_products_clean.csv")
    return df

df_visual = load_data()

# 2. Encabezado de la aplicación
st.title("📊 Amazon Products Market Analysis & Consumer Behavior")
st.markdown("---")

# 3. FILTRO INTERACTIVO (La magia de Streamlit)
st.sidebar.header("🕹️ Panel de Control")
categorias_disponibles = sorted(df_visual['main_category'].dropna().unique())
categoria_seleccionada = st.sidebar.selectbox(
    "Selecciona una Categoría Principal para filtrar:",
    categorias_disponibles,
    index=categorias_disponibles.index("appliances") if "appliances" in categorias_disponibles else 0
)

# Filtrar el DataFrame según la selección del usuario
df_filtrado = df_visual[df_visual['main_category'] == categoria_seleccionada]

# 4. FILA DE KPIs DINÁMICOS
st.subheader(f"📈 Métricas Clave para: {categoria_seleccionada.upper()}")
col1, col2, col3 = st.columns(3)

with col1:
    total_productos = len(df_filtrado)
    st.metric("Modelos Analizados", f"{total_productos:,}")

with col2:
    # Para Aires Acondicionados específicos si la categoría es appliances
    if categoria_seleccionada == "appliances":
        df_ac = df_filtrado[df_filtrado['sub_category'].str.contains('Air Conditioners', case=False, na=False)]
        precio_medio = df_ac['price_clean'].mean() if not df_ac.empty else df_filtrado['price_clean'].mean()
        label = "Precio Promedio (Aires AC)"
    else:
        precio_medio = df_filtrado['price_clean'].mean()
        label = "Precio Promedio"
    st.metric(label, f"${precio_medio:,.2f}")

with col3:
    if categoria_seleccionada == "appliances" and 'df_ac' in locals() and not df_ac.empty:
        precio_mediana = df_ac['price_clean'].median()
        label_med = "Mediana de Precio (Aires AC)"
    else:
        precio_mediana = df_filtrado['price_clean'].median()
        label_med = "Mediana de Precio"
    st.metric(label_med, f"${precio_mediana:,.2f}")

st.markdown("---")

# 5. SECCIÓN DE GRÁFICOS (Se actualizan solos)
col_izq, col_der = st.columns(2)

# Configuración estética global de gráficos
sns.set_theme(style="whitegrid")
plt.rcParams['font.family'] = 'sans-serif'

with col_izq:
    st.subheader("🏆 Subcategorías por Precio Máximo")
    # Quitamos outliers extremos para escala humana
    df_barras = df_filtrado[df_filtrado['price_clean'] < 1000000]
    top_subcats = df_barras.groupby('sub_category')['price_clean'].max().sort_values(ascending=False).head(8).reset_index()
    
    fig_bar, ax_bar = plt.subplots(figsize=(8, 5))
    sns.barplot(x='price_clean', y='sub_category', data=top_subcats, ax=ax_bar, palette='Oranges_r', hue='sub_category', legend=False)
    ax_bar.set_xlabel("Precio Máximo ($)")
    ax_bar.set_ylabel("")
    st.pyplot(fig_bar)

with col_der:
    st.subheader("🎯 Correlación: Precio vs Calificación")
    # Filtro para expandir la nube
    df_disp = df_filtrado[df_filtrado['price_clean'] < 150000]
    # Muestra aleatoria para no saturar el navegador si la categoría es enorme
    df_muestra = df_disp.sample(n=min(5000, len(df_disp)), random_state=42)
    
    fig_scat, ax_scat = plt.subplots(figsize=(8, 5))
    sns.scatterplot(x='price_clean', y='ratings_clean', data=df_muestra, ax=ax_scat, alpha=0.5, color='#FF9900', edgecolor='none')
    sns.regplot(x='price_clean', y='ratings_clean', data=df_muestra, ax=ax_scat, scatter=False, color='#111111', line_kws={"linewidth": 2})
    ax_scat.set_xlabel("Precio del Producto ($)")
    ax_scat.set_ylabel("Calificación (Estrellas)")
    ax_scat.set_ylim(0.8, 5.2)
    st.pyplot(fig_scat)

# 6. TABLA DETALLADA ABAJO
st.subheader("📦 Explorador de Datos Integrado")
st.dataframe(df_filtrado[['name', 'sub_category', 'price_clean', 'ratings_clean']].head(100), use_container_width=True)