# DAX measures used in the dashboard

Model: star schema — `fact_orders` joined to `dim_customer`, `dim_product`,
`dim_store`, `dim_date` (marked as the date table). All measures live in a
dedicated `_Measures` table so the field list stays clean.

```dax
Total Revenue =
SUM ( fact_orders[line_total] )

Total Orders =
DISTINCTCOUNT ( fact_orders[order_id] )

Avg Order Value =
DIVIDE ( [Total Revenue], [Total Orders] )

Revenue LY =
CALCULATE (
    [Total Revenue],
    SAMEPERIODLASTYEAR ( dim_date[full_date] )
)

Revenue YoY % =
DIVIDE (
    [Total Revenue] - [Revenue LY],
    [Revenue LY]
)

Revenue YTD =
TOTALYTD ( [Total Revenue], dim_date[full_date] )

Premium Share % =
DIVIDE (
    CALCULATE (
        [Total Revenue],
        dim_customer[segment] = "Premium"
    ),
    [Total Revenue]
)

-- Dynamic title for the KPI cards, respects slicers
Selected Period Label =
VAR MinD = MIN ( dim_date[full_date] )
VAR MaxD = MAX ( dim_date[full_date] )
RETURN
    FORMAT ( MinD, "mmm yyyy" ) & " – " & FORMAT ( MaxD, "mmm yyyy" )
```

Notes from building it:
- `dim_date` is a proper date table (continuous dates, no gaps) — time
  intelligence falls apart without one, so I generate it in Power Query
  rather than relying on auto date/time.
- Row-level security: a role `Store Managers` filters `dim_store[region]`
  with `USERNAME()` mapped through a manager-region table. Keeps the demo
  honest about how RLS is actually wired.
- The fact table stays at order-line grain; anything order-level
  (order count, AOV) goes through `DISTINCTCOUNT(order_id)`.
