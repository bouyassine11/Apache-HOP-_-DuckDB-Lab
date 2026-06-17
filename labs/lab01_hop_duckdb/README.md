Here's a full summary of everything we built and fixed throughout this session.

---

## Project Overview

We built a complete ETL pipeline for a retail BI lab using **Apache Hop** as the ETL tool and **DuckDB** as the local data warehouse. The architecture is:

```
data/raw/ (CSV) → Hop ETL → staging.* → Hop ETL → warehouse.*
```

---

## What We Fixed Before Building

Before writing any pipelines, we resolved three infrastructure issues:

1. **DuckDB connection variable** — the connection file used `${HOP_PROJECT_HOME}` which doesn't exist in Hop. We corrected it to `${PROJECT_HOME}`.
2. **Project Home misconfiguration** — Hop was resolving paths relative to `/opt/hop/` instead of the lab folder. We set Project Home to `.../labs/lab01_hop_duckdb`.
3. **CSV file path** — the `filename` field in p01's CSV Input pointed to a directory instead of a file. We fixed it to `${PROJECT_HOME}/data/raw/customers.csv`.

---

## p01 — CSV to Staging (Part A)

**What it does:** Reads 8 CSV files and loads them into `staging.*` with type conversion and technical validation.

**Transforms used:** `CSVInput → FilterRows → SelectValues → TableOutput` + `TextFileOutput` for rejects.

**8 flows on one canvas:**
- `staging.customers` — filter on `customer_id IS NOT NULL`, city trimmed
- `staging.categories` — filter on `category_id IS NOT NULL`
- `staging.products` — filter on `product_id IS NOT NULL`, BigNumber for prices
- `staging.orders` — filter on `order_id IS NOT NULL`
- `staging.order_items` — filter on `order_item_id IS NOT NULL`
- `staging.payments` — filter on `payment_id IS NOT NULL`
- `staging.stock_movements` — filter on `movement_id IS NOT NULL`
- `staging.budget` — filter on `budget_id IS NOT NULL` (for Part B)

**Key lesson:** Hop's `Truncate=Y` on `TableOutput` works fine here because p01 runs full batch loads.

---

## p02 — Build Dimensions (Part B)

**What it does:** Transforms `staging.*` into 4 clean dimensions in `warehouse.*`.

**Key problems we solved:**
- `DBLookup` plugin generates `SELECT FROM null` with DuckDB JDBC — replaced with `StreamLookup`
- `SystemInfo` transform is a row generator, not a passthrough — dropped `loaded_at` instead
- `Truncate=Y` on `TableOutput` races with batch inserts in DuckDB — replaced with explicit `ExecSql TRUNCATE` before data flows
- Two separate `ExecSql` transforms run in parallel — merged into single multi-statement `ExecSql`
- Date type fields from DuckDB JDBC crash Hop's row reader — cast dates to `VARCHAR` in `TableInput` SQL

**Final flow for each dimension:**

- **dim_date** — single `ExecSql` (TRUNCATE + calendar INSERT using `GENERATE_SERIES` — allowed as plumbing)
- **dim_customer** — `TableInput (SQL with QUALIFY dedup + UPPER city)` → `ValueMapper (city normalization)` → `IfNull (email default)` → `Sequence (customer_key)` → `SelectValues` → `TableOutput`
- **dim_product** — `TableInput (products)` + `TableInput (categories)` → `StreamLookup (category_id → category_name, department)` → `Sequence (product_key)` → `SelectValues` → `TableOutput`
- **dim_channel** — `TableInput (DISTINCT channel ORDER BY channel)` → `ValueMapper (→ channel_type)` → `Sequence (channel_key)` → `SelectValues` → `TableOutput`

---

## p03 — Build Facts (Part B)

**What it does:** Builds `warehouse.fact_sales` and `warehouse.fact_stock` from staging + dimensions.

**Key design decisions:**
- Used a single `TableInput` with all JOINs in SQL for `fact_sales` — avoids all Hop/DuckDB date type issues from `DBLookup` chains
- Used `ExecSql` for `fact_stock` because `qty_in`/`qty_out` require CASE logic not expressible in `Calculator`
- Added explicit `ExecSql TRUNCATE` before both facts to avoid primary key conflicts

**fact_sales flow:**
`ExecSql (TRUNCATE)` → `TableInput (JOIN order_items + orders + all 4 dims in SQL)` → `Calculator (gross/net/cost/margin)` → `Sequence (sales_key)` → `SelectValues (rename fields)` → `TableOutput`

**fact_stock flow:**
`ExecSql (TRUNCATE + INSERT with CASE WHEN for qty_in/qty_out)`

**Expected results:** 13 rows in `fact_sales`, 10 rows in `fact_stock`

---

## p04 — Incremental Load (Part B)

**What it does:** Loads the April 2025 batch into staging with watermark filtering and deduplication, then p03 rebuilds the facts.

**Key problems we solved:**
- `FilterRows` with a literal Date comparison crashes — read dates as `String` from CSVInput and used the correct `<value><name>constant</name><type>String</type><text>2025-03-21</text>` XML structure
- `StreamLookup` key name mismatch — `<name>` is the lookup stream field, `<field>` is the main stream field

**3 parallel flows:**
- **orders_april** — `CSVInput (dates as String)` → `FilterRows (order_date > 2025-03-21)` → `StreamLookup (dedup vs existing order_ids)` → `FilterRows (keep NULL = new only)` → `TableOutput (Truncate=N)`
- **order_items_april** — `CSVInput` → `StreamLookup (dedup vs existing order_item_ids)` → `FilterRows (keep NULL)` → `TableOutput (Truncate=N)`
- **payments_april** — `CSVInput (dates as String)` → `FilterRows (payment_date > 2025-03-21)` → `StreamLookup (dedup vs existing payment_ids)` → `FilterRows (keep NULL)` → `TableOutput (Truncate=N)`
- **ExecSql** — updates `control.load_watermark` for orders and payments

**Expected results after p04 + p03 rerun:** 19 rows in `fact_sales`

---

## p05 — Load Budget (Part B)

**What it does:** Loads `staging.budget` into `warehouse.fact_budget` resolving `category_name` and `channel_key`.

**Flow:**
`ExecSql (TRUNCATE fact_budget)` → `TableInput (staging.budget)` + `TableInput (staging.categories)` → `StreamLookup (category_id → category_name)` + `TableInput (dim_channel)` → `StreamLookup (channel → channel_key)` → `SelectValues (rename month → month_num)` → `TableOutput`

**Expected results:** 12 rows, 0 null channel_keys

---

## Key Technical Lessons Learned

| Problem | Root Cause | Fix |
|---------|-----------|-----|
| `DBLookup` generates `SELECT FROM null` | DuckDB JDBC doesn't support Hop's schema/table XML format | Replace with `StreamLookup` |
| `Truncate=Y` causes primary key conflicts | DuckDB rolls back TRUNCATE and INSERT in same batch transaction | Explicit `ExecSql TRUNCATE` before data flow |
| Two `ExecSql` transforms race | Independent transforms run in parallel | Single multi-statement `ExecSql` with `single_statement=N` |
| Date fields crash row reader | DuckDB JDBC timestamp format incompatible with Hop | Cast dates to `VARCHAR` in `TableInput` SQL |
| `FilterRows` date comparison fails | `<rightexact>` tag is wrong; needs `<value><name>constant</name>` block | Use correct official Hop XML structure |
| `SystemInfo` drops rows | It's a row generator (1 output), not a passthrough | Remove it; loaded_at is nullable |
| DuckDB lock conflicts | Only one writer allowed at a time | Never run DuckDB CLI while Hop pipeline is running |
| Hop ignores file changes | Hop keeps in-memory version when tab is open | Always close tab and reopen after editing XML on disk |
