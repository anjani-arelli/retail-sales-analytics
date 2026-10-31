/* ============================================================
   Retail Sales Analytics - RFM customer segmentation (T-SQL)
   Written against the star schema in 01_schema.sql.

   Recency   = days between the customer's last order and the
               most recent order date in the data
   Frequency = number of distinct orders
   Monetary  = total spend

   Each metric is scored 1-5 with NTILE(5). Recency is scored in
   reverse (fewest days since last order = highest score).
   ============================================================ */

WITH last_order_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dim_date d
    JOIN fact_orders f ON f.date_key = d.date_key
),
rfm AS (
    SELECT c.customer_id,
           c.customer_name,
           c.segment,
           DATEDIFF(DAY, MAX(d.full_date), (SELECT max_date FROM last_order_date))
               AS recency_days,
           COUNT(DISTINCT f.order_id) AS frequency_orders,
           SUM(f.line_total)          AS monetary_total
    FROM fact_orders f
    JOIN dim_customer c ON c.customer_key = f.customer_key
    JOIN dim_date d     ON d.date_key = f.date_key
    GROUP BY c.customer_id, c.customer_name, c.segment
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
           NTILE(5) OVER (ORDER BY frequency_orders ASC) AS f_score,
           NTILE(5) OVER (ORDER BY monetary_total ASC)   AS m_score
    FROM rfm
)
SELECT customer_id,
       customer_name,
       segment,
       recency_days,
       frequency_orders,
       ROUND(monetary_total, 2) AS monetary_total,
       r_score, f_score, m_score,
       CONCAT(r_score, f_score, m_score) AS rfm_cell,
       CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN f_score >= 4 AND m_score >= 3                 THEN 'Loyal'
           WHEN r_score >= 4 AND f_score <= 2                 THEN 'New / promising'
           WHEN r_score <= 2 AND f_score >= 3                 THEN 'At risk'
           WHEN r_score = 1 AND f_score = 1                   THEN 'Lost'
           ELSE 'Needs attention'
       END AS rfm_segment
FROM scored
ORDER BY monetary_total DESC;
