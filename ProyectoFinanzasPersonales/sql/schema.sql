-- Tablas de Dimensión
CREATE TABLE IF NOT EXISTS dim_categoria (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_metodo_pago (
    metodo_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla de Hechos
CREATE TABLE IF NOT EXISTS fact_gastos (
    notion_page_id VARCHAR(100) PRIMARY KEY,
    fecha DATE NOT NULL,
    concepto TEXT NOT NULL,
    monto NUMERIC(12, 2) NOT NULL,
    categoria_id INT REFERENCES dim_categoria(categoria_id),
    metodo_id INT REFERENCES dim_metodo_pago(metodo_id),
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);