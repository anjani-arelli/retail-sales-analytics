/* ============================================================
   Retail Sales Analytics - analysis queries (T-SQL)
   Written against the star schema in 01_schema.sql.
   ============================================================ */

-- 1. Monthly revenue with month-over-month growth ----------------
WITH monthly AS (
    SELECT d.year_num, d.month_num,
           SUM(f.line_total) AS revenue
    FROM fact_orders f
    JOIN dim_date d ON d.date_key = f.date_key
    GROUP BY d.year_num, d.month_num
)
SELECT year_num, month_num, revenue,
       LAG(revenue) OVER (ORDER BY year_num, month_num) AS prev_month_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_num, month_num))
             / NULLIF(LAG(revenue) OVER (ORDER BY year_num, month_num), 0), 2)
           AS mom_growth_pct
FROM monthly
ORDER BY year_num, month_num;

-- 2. Year-over-year growth by category ---------------------------
SELECT p.category,
       SUM(CASE WHEN d.year_num = 2024 THEN f.line_total ELSE 0 END) AS revenue_2024,
       SUM(CASE WHEN d.year_num = 2025 THEN f.line_total ELSE 0 END) AS revenue_2025,
       ROUND(100.0 * (SUM(CASE WHEN d.year_num = 2025 THEN f.line_total ELSE 0 END)
                    - SUM(CASE WHEN d.year_num = 2024 THEN f.line_total ELSE 0 END))
             / NULLIF(SUM(CASE WHEN d.year_num = 2024 THEN f.line_total ELSE 0 END), 0), 2)
           AS yoy_growth_pct
FROM fact_orders f
JOIN dim_product p ON p.product_key = f.product_key
JOIN dim_date d     ON d.date_key = f.date_key
GROUP BY p.category
ORDER BY revenue_2025 DESC;

-- 3. Top 10 products by revenue ----------------------------------
SELECT TOP 10 p.product_name, p.category,
       SUM(f.quantity)   AS units_sold,
       SUM(f.line_total) AS revenue,
       COUNT(DISTINCT f.order_id) AS orders
FROM fact_orders f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.product_name, p.category
ORDER BY revenue DESC;

-- 4. Store performance with ranking -------------------------------
SELECT s.store_name, s.city, s.region,
       COUNT(DISTINCT f.order_id) AS orders,
       SUM(f.line_total) AS revenue,
       RANK() OVER (ORDER BY SUM(f.line_total) DESC) AS revenue_rank
FROM fact_orders f
JOIN dim_store s ON s.store_key = f.store_key
GROUP BY s.store_name, s.city, s.region;

-- 5. Simple RFM-ish segmentation ---------------------------------
WITH rfm AS (
    SELECT c.customer_id, c.customer_name, c.segment,
           MAX(d.full_date) AS last_order,
           COUNT(DISTINCT f.order_id) AS frequency,
           SUM(f.line_total) AS monetary
    FROM fact_orders f
    JOIN dim_customer c ON c.customer_key = f.customer_key
    JOIN dim_date d     ON d.date_key = f.date_key
    GROUP BY c.customer_id, c.customer_name, c.segment
)
SELECT *,
       DATEDIFF(DAY, last_order, '2025-12-31') AS recency_days,
       CASE WHEN DATEDIFF(DAY, last_order, '2025-12-31') <= 90
                 AND frequency >= 5 THEN 'Champions'
            WHEN DATEDIFF(DAY, last_order, '2025-12-31') > 180 THEN 'At risk'
            ELSE 'Regulars' END AS rfm_bucket
FROM rfm
ORDER BY monetary DESC;

-- 6. Discount effectiveness: does discounting lift units? ----------
SELECT discount,
       COUNT(*) AS line_items,
       SUM(quantity) AS units,
       ROUND(AVG(CAST(quantity AS FLOAT)), 2) AS avg_qty_per_line
FROM fact_orders
GROUP BY discount
ORDER BY discount;

-- 7. Weekend vs weekday revenue ------------------------------------
SELECT d.is_weekend,
       COUNT(DISTINCT f.order_id) AS orders,
       SUM(f.line_total) AS revenue,
       ROUND(AVG(f.line_total), 2) AS avg_line_total
FROM fact_orders f
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY d.is_weekend;
