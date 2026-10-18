/* ============================================================
   Retail Sales Analytics - star schema (SQL Server / T-SQL)
   One fact table, four dimensions. Grain of the fact table:
   one row per order line item.
   ============================================================ */

CREATE TABLE dim_customer (
    customer_key  INT IDENTITY(1,1) PRIMARY KEY,
    customer_id   VARCHAR(10)  NOT NULL UNIQUE,
    customer_name NVARCHAR(100) NOT NULL,
    segment       VARCHAR(20)  NOT NULL,
    signup_date   DATE         NOT NULL
);

CREATE TABLE dim_product (
    product_key   INT IDENTITY(1,1) PRIMARY KEY,
    sku           VARCHAR(10)   NOT NULL UNIQUE,
    product_name  NVARCHAR(100) NOT NULL,
    category      VARCHAR(30)   NOT NULL,
    subcategory   VARCHAR(30)   NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL
);

CREATE TABLE dim_store (
    store_key   INT IDENTITY(1,1) PRIMARY KEY,
    store_id    VARCHAR(10)   NOT NULL UNIQUE,
    store_name  NVARCHAR(100) NOT NULL,
    city        VARCHAR(50)   NOT NULL,
    region      VARCHAR(20)   NOT NULL
);

CREATE TABLE dim_date (
    date_key    INT PRIMARY KEY,          -- YYYYMMDD
    full_date   DATE NOT NULL UNIQUE,
    year_num    SMALLINT NOT NULL,
    quarter_num TINYINT  NOT NULL,
    month_num   TINYINT  NOT NULL,
    month_name  VARCHAR(10) NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    is_weekend  BIT NOT NULL
);

CREATE TABLE fact_orders (
    order_line_key INT IDENTITY(1,1) PRIMARY KEY,
    order_id       VARCHAR(10) NOT NULL,
    customer_key   INT NOT NULL REFERENCES dim_customer(customer_key),
    product_key    INT NOT NULL REFERENCES dim_product(product_key),
    store_key      INT NOT NULL REFERENCES dim_store(store_key),
    date_key       INT NOT NULL REFERENCES dim_date(date_key),
    quantity       INT NOT NULL CHECK (quantity > 0),
    unit_price     DECIMAL(10,2) NOT NULL,
    discount       DECIMAL(4,2) NOT NULL DEFAULT 0,
    line_total     AS (quantity * unit_price * (1 - discount)) PERSISTED
);

CREATE INDEX IX_fact_orders_date    ON fact_orders(date_key);
CREATE INDEX IX_fact_orders_product ON fact_orders(product_key);
CREATE INDEX IX_fact_orders_store   ON fact_orders(store_key);
