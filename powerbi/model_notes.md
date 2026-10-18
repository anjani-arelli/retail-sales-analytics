# Data model notes

## Why a star schema here

The source CSVs are normalized-ish (one row per order line with IDs pointing
at customer/product/store tables), which maps cleanly onto a star: one fact,
four dimensions. I kept the fact at **order-line grain** because that's the
lowest level the business questions need — everything else (orders, customers,
revenue) rolls up from there.

## Grain and keys

- `fact_orders`: one row per order line item. Surrogate keys everywhere;
  the natural keys (`order_id`, `sku`, …) stay as attributes for drilling.
- `line_total` is a computed column in SQL (`quantity * unit_price * (1 - discount)`),
  so revenue logic lives in exactly one place.
- `dim_date` is generated, not sourced — continuous calendar 2024–2026,
  with year/quarter/month/weekday flags. Marked as *the* date table in the model.

## Relationships

All single-direction, one-to-many, dimensions → fact. No bidirectional
filtering — it causes ambiguous filter paths the moment you add a second
fact table, and this model is meant to stay extendable.

## Dashboard pages (what I built on top)

1. **Executive overview** — KPI cards (revenue, orders, AOV, YoY %), monthly
   trend with YTD overlay, category bar chart.
2. **Product deep-dive** — top-10 products table, discount-effectiveness
   visual (ties back to query 6 in `sql/`).
3. **Customer view** — RFM buckets from query 5, segment mix, premium share.
4. **Store performance** — map + ranked table, weekend vs weekday split.

## What I'd do differently at real scale

Partition `fact_orders` by year, move the CSV staging into a proper pipeline
(see my `etl-pipeline-python` project), and put the DAX behind a certified
dataset instead of embedding it per report.
