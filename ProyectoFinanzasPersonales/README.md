# ETL Automatizado de Finanzas Personales & Cloud Data Warehouse

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Neon.tech-336791?logo=postgresql&logoColor=white)](https://neon.tech)
[![Power BI](https://img.shields.io/badge/Power_BI-Desktop-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![Make](https://img.shields.io/badge/Orquestaci%C3%B3n-Make.com-6E3FF3?logo=make&logoColor=white)](https://make.com)
[![Google Gemini](https://img.shields.io/badge/PLN-Google_Gemini_AI-8E75B2?logo=googlegemini&logoColor=white)](https://gemini.google.com)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-blue.svg)](LICENSE)

Un pipeline **End-to-End** automatizado de ingeniería de datos e inteligencia de negocios (BI) diseñado para la gestión integral de finanzas personales. El sistema captura transacciones no estructuradas mediante comandos de texto o voz enviados a través de Telegram, extrae metadatos clave con Procesamiento de Lenguaje Natural (PLN), orquesta la ingesta transaccional y analítica en tiempo real, y alimenta un **Data Warehouse en la Nube (PostgreSQL/Neon)** visualizado mediante un Dashboard dinámico e interactivo en **Power BI**.

---

## Arquitectura del Sistema

El flujo de datos sigue un modelo descentralizado de ingesta en tiempo real que separa de forma estricta la capa operacional (**OLTP**) de la capa analítica (**OLAP**):

```text
┌─────────────────┐       ┌────────────────────────┐       ┌──────────────────────┐
│  Bot Telegram   │ ───>  │    Google Gemini AI    │ ───>  │    Make.com (iPaaS)  │
│(Ingesta Texto/Voz)│     │(Extracción Entidades)  │       │ (Orquestación & ETL) │
└─────────────────┘       └────────────────────────┘       └──────────┬───────────┘
                                                                      │
                                     ┌────────────────────────────────┴────────────────────────────────┐
                                     ▼                                                                 ▼
                          ┌──────────────────────┐                                          ┌──────────────────────┐
                          │   Notion Database    │                                          │   Neon PostgreSQL    │
                          │   (Capa OLTP / ODS)  │                                          │  (Data Warehouse /   │
                          └──────────────────────┘                                          │    Capa OLAP Star)   │
                                                                                            └──────────┬───────────┘
                                                                                                       │
                                                                                                       ▼
                                                                                            ┌──────────────────────┐
                                                                                            │   Power BI Desktop   │
                                                                                            │ (Dashboard Analytics)│
                                                                                            └──────────────────────┘

```

### Flujo de Trabajo

1. **Ingesta:** El usuario envía un mensaje de voz o texto en lenguaje natural a través de Telegram (ej. *"Gasté 23000 en parqueadero con tarjeta de débito"*).
2. **Procesamiento PLN:** Google Gemini IA analiza el contenido no estructurado y extrae variables normalizadas (`concepto`, `monto`, `categoría`, `método de pago`, `fecha`).
3. **Orquestación ETL:** Make.com procesa el evento webhook, ejecuta validaciones de esquema, mapea identificadores de dimensión y realiza la doble escritura sincrónica.
4. **Almacenamiento Híbrido:**
* **OLTP (Notion):** Registra el dato operacional en formato plano para consulta rápida desde dispositivos móviles.
* **OLAP (Neon PostgreSQL):** Modifica y persiste las tablas de hechos y dimensiones en la nube bajo un esquema relacional.


5. **Business Intelligence:** Power BI se conecta al Data Warehouse para recalcular los KPI analíticos e ilustrar la distribución financiera mediante métricas DAX.

---

## 🗄️ Modelo de Datos Dimensional (Star Schema)

El Data Warehouse fue diseñado bajo la metodología de Kimball mediante un modelo en estrella (*Star Schema*) para optimizar el rendimiento de las consultas analíticas y la agilidad de cómputo en DAX:

```text
     ┌───────────────────────┐                    ┌───────────────────────┐
     │     dim_categoria     │                    │    dim_metodo_pago    │
     ├───────────────────────┤                    ├───────────────────────┤
     │ PK  categoria_id      │                    │ PK  metodo_id         │
     │     nombre            │                    │     nombre            │
     └──────────┬────────────┘                    └──────────┬────────────┘
                │                                            │
                │              ┌───────────────────┐         │
                └───────────>  │    fact_gastos    │ <───────┘
                               ├───────────────────┤
                               │ PK  notion_page_id│
                               │     fecha         │
                               │     concepto      │
                               │     monto         │
                               │ FK  categoria_id  │
                               │ FK  metodo_id     │
                               │     synced_at     │
                               │     updated_at    │
                               └───────────────────┘

```

---

## Métricas & Lógica DAX

Se implementaron medidas dinámicas en Power BI para garantizar la correcta evaluación del contexto de filtro y la segmentación de la caja operativa versus cuentas de capitalización (Ahorro):

#### 1. Total Gastos Operativos

Excluye los flujos de dinero destinados a capitalización personal manteniendo el contexto de desglose en visualizaciones por categoría:

```dax
Total Gastos = 
CALCULATE(
    SUM('public fact_gastos'[monto]), 
    KEEPFILTERS('public dim_categoria'[nombre] <> "Ahorro")
)

```

#### 2. Acumulado en Ahorro

Aísla la métrica de reservas de capital registradas dentro del pipeline:

```dax
Total Ahorro = 
CALCULATE(
    SUM('public fact_gastos'[monto]), 
    KEEPFILTERS('public dim_categoria'[nombre] = "Ahorro")
)

```

#### 3. Auditoría Transaccional

```dax
Total Transacciones = COUNTROWS('public fact_gastos')

```

---

## 📁 Estructura del Repositorio

```text
ProyectoFinanzasPersonales/
├── README.md                      # Documentación principal del proyecto
├── dashboards/
│   └── Dashboard_Finanzas_Personales.pbix  # Reporte de Power BI (Tema Oscuro / UI Ejecutiva)
└── sql/
    └── schema.sql                 # Scripts DDL para la creación del Data Warehouse en PostgreSQL

```

---

## Despliegue y Configuración

### Prerrequisitos

* Instancia en la nube de **PostgreSQL** (Neon.tech recomendado).
* Cuenta de **Make.com** con conectores HTTP/Webhook, Telegram, Notion y PostgreSQL.
* **Power BI Desktop** (Versión reciente).

### 1. Inicialización de la Base de Datos

Ejecute el script alojado en `sql/schema.sql` sobre la consola de PostgreSQL para aprovisionar las dimensiones y la tabla de hechos:

```bash
psql -h <HOST_NEON> -U <USUARIO> -d <DATABASE> -f sql/schema.sql

```

### 2. Configuración del Pipeline en Make

1. Configurar el Webhook de entrada conectado al Bot de Telegram.
2. Añadir el módulo de IA (Google Gemini API) especificando el Prompt de extracción JSON de entidades.
3. Configurar los nodos de PostgreSQL para resolver la búsqueda de claves foráneas (`categoria_id`, `metodo_id`) e insertar los hechos en la tabla `fact_gastos`.

### 3. Conexión de Power BI

1. Abrir `dashboards/Dashboard_Finanzas_Personales.pbix`.
2. En la barra superior, seleccionar **Transformar Datos ➔ Configuración de origen de datos**.
3. Reemplazar las credenciales de host PostgreSQL por las de su instancia de Neon.
4. Hacer clic en **Actualizar** (*Refresh*) para cargar la información transaccional.

---

## Autor

**Desarrollado por:** Juan Felipe Rodriguez Santaella | Ingeniero de Sistemas / Ingeniero en Base de Datos

* **LinkedIn:** https://www.linkedin.com/in/felipe-rodriguez-41146732b/ 
* **GitHub:** https://github.com/juanfrods

