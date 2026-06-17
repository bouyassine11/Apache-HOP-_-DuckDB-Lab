# Complete Guide — Lab 1 : Apache Hop + DuckDB

> This guide is the single reference for running Lab 1 end-to-end in Apache Hop GUI.
> It incorporates all fixes discovered during setup (project home, JDBC path, variable resolution).

## Overview

The lab builds a full ETL pipeline in two parts:

- **Part A** — Load 7 CSV sources → `staging.*` in DuckDB
- **Part B** — Transform `staging.*` → star schema `warehouse.*`, incremental load, budget vs actuals

Architecture:

```text
data/raw/ (CSV)  →  Hop ETL (p01)  →  staging.*  →  Hop ETL (p02/p03/p04/p05)  →  warehouse.*
```

---

## Step 0 — Installation & Setup

### Java 17+

```bash
java -version   # must be 17+
```

If not installed, download from https://adoptium.net (Java 21 recommended).

### Apache Hop 2.x

Download from https://hop.apache.org/download/ and extract anywhere (e.g. `~/tools/hop/`).

```bash
cd ~/tools/hop
./hop-gui.sh        # Linux/macOS
```

### DuckDB CLI

```bash
duckdb --version
```

If not installed on Linux:

```bash
curl -L https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip -o duckdb.zip
unzip duckdb.zip && chmod +x duckdb && sudo mv duckdb /usr/local/bin/
```

### DuckDB JDBC Driver

The JDBC driver is already included in the project at:

```
hop/lib/duckdb_jdbc-1.5.3.0.jar
```

Copy it into the `lib/` folder of your Hop installation:

```bash
cp labs/lab01_hop_duckdb/hop/lib/duckdb_jdbc-1.5.3.0.jar ~/tools/hop/lib/
```

Then **restart Hop** so it picks up the new driver.

---

## Step 1 — Create the Hop Project

1. Launch Hop GUI
2. Go to **File → New Project**
3. Set **Project Name**: `Lab1` (or any name)
4. Set **Project Home** to the **absolute path** of `labs/lab01_hop_duckdb`:

   ```
   /home/azyen/Downloads/business-intelligence-labs-main/labs/lab01_hop_duckdb
   ```

5. In the Project Properties dialog, change **Metadata base folder** from `${PROJECT_HOME}/metadata` to:

   ```
   ${PROJECT_HOME}/hop/metadata
   ```

6. Click **OK / Finish**

> **Why this matters:** `${PROJECT_HOME}` is the variable Hop uses for all relative paths.
> If Project Home is wrong, `${DATA_DIR}`, `${PROJECT_HOME}/duckdb/lab1.duckdb`, and all
> pipeline paths will fail to resolve.

---

## Step 2 — Verify the DuckDB Connection

The connection file is already provided at `hop/metadata/rdbms/DuckDB_Lab1.json`.
It points to `${PROJECT_HOME}/duckdb/lab1.duckdb` (the `.duckdb` file is created on first run).

To verify in Hop GUI:

1. Open the **Metadata** panel (left sidebar)
2. Expand **Relational Database Connections**
3. Right-click `DuckDB_Lab1` → **Test connection**
4. You should see **Connection successful**

If it fails:
- Check that `duckdb_jdbc-*.jar` is in `~/tools/hop/lib/`
- Restart Hop after copying the jar
- Verify Project Home is set to `labs/lab01_hop_duckdb` (not the `hop/` subfolder)

---

## Step 3 — One-Time Schema Setup

Before running any Hop pipeline, create the schemas in DuckDB.
Run these from the `labs/lab01_hop_duckdb` folder:

```bash
cd /home/azyen/Downloads/business-intelligence-labs-main/labs/lab01_hop_duckdb

# Create schemas (staging, warehouse, control)
duckdb duckdb/lab1.duckdb ".read sql/00_create_schema.sql"

# Create staging table structures
duckdb duckdb/lab1.duckdb ".read sql/10_create_staging_schema.sql"
```

---

## Part A — Pipeline p01: CSV → staging.*

### Open the skeleton

**File → Open** → navigate to `hop/pipelines/p01_csv_to_staging.hpl`

The canvas already has the `customers` flow as a template. You will replicate it for all 7 tables.

### How the customers flow works

```text
[Read customers.csv]
        │
        ▼
[Validate customer_id]  ──FALSE──▶  [Rejects customers]
        │ TRUE
        ▼
[Select customer fields]
        │
        ▼
[Write staging.customers]
```

### Configure each transform

#### CSV Input — "Read customers.csv"

| Setting | Value |
|---------|-------|
| Filename | `${PROJECT_HOME}/data/raw/customers.csv` |
| Separator | `,` |
| Enclosure | `"` |
| Header row | `Y` |

Field definitions (click **Get Fields** then adjust types manually):

| Field | Type | Format | Trim |
|-------|------|--------|------|
| customer_id | Integer | | none |
| customer_name | String | | none |
| email | String | | none |
| city | String | | both |
| country | String | | none |
| signup_date | Date | yyyy-MM-dd | none |
| segment | String | | none |

#### Filter Rows — "Validate customer_id"

| Setting | Value |
|---------|-------|
| Condition | `customer_id IS NOT NULL` |
| Send true to | `Select customer fields` |
| Send false to | `Rejects customers` |

#### Select Values — "Select customer fields"

The skeleton has a **Dummy** placeholder here — replace it:

1. Right-click the Dummy → **Change transform type** → **Select Values**
2. In the **Select & Alter** tab, list all 7 fields in order with correct types
3. Do **NOT** normalize `city` here (that's a warehouse-layer rule)

#### Table Output — "Write staging.customers"

| Setting | Value |
|---------|-------|
| Connection | `DuckDB_Lab1` |
| Schema | `staging` |
| Table | `customers` |
| Truncate table before insert | ✅ Yes |

Click **Get fields from table** to map columns automatically.

#### Text File Output — "Rejects customers"

| Setting | Value |
|---------|-------|
| Filename | `data/processed/rejects_customers` |
| Extension | `csv` |

---

### Replicate for all 7 tables

Add a new flow on the same canvas for each table. Field definitions:

#### categories.csv → staging.categories

| Field | Type |
|-------|------|
| category_id | Integer |
| category_name | String |
| department | String |

#### products.csv → staging.products

| Field | Type |
|-------|------|
| product_id | Integer |
| product_name | String |
| category_id | Integer |
| unit_price | BigNumber |
| cost_price | BigNumber |
| active_flag | Integer |

#### orders.csv → staging.orders (filter: `order_id IS NOT NULL`)

| Field | Type | Format |
|-------|------|--------|
| order_id | Integer | |
| customer_id | Integer | |
| order_date | Date | yyyy-MM-dd |
| channel | String | |
| order_status | String | |
| city | String | |

#### order_items.csv → staging.order_items (filter: `order_item_id IS NOT NULL`)

| Field | Type |
|-------|------|
| order_item_id | Integer |
| order_id | Integer |
| product_id | Integer |
| quantity | Integer |
| unit_price | BigNumber |
| discount_amount | BigNumber |

#### payments.csv → staging.payments (filter: `payment_id IS NOT NULL`)

| Field | Type | Format |
|-------|------|--------|
| payment_id | Integer | |
| order_id | Integer | |
| payment_date | Date | yyyy-MM-dd |
| payment_method | String | |
| payment_status | String | |
| amount | BigNumber | |

#### stock_movements.csv → staging.stock_movements (filter: `movement_id IS NOT NULL`)

| Field | Type | Format |
|-------|------|--------|
| movement_id | Integer | |
| product_id | Integer | |
| movement_date | Date | yyyy-MM-dd |
| movement_type | String | |
| quantity | Integer | |
| warehouse | String | |

#### sales_budget.csv → staging.budget (Part B, add here too)

| Field | Type |
|-------|------|
| budget_id | Integer |
| year | Integer |
| month | Integer |
| category_id | Integer |
| channel | String |
| budget_amount | BigNumber |
| budget_qty | Integer |

---

### Run p01

Click the **▶ Run** button. After execution, check the Metrics tab:

- Each transform shows row counts and **Finished** status
- `Rejects *` transforms should show 0 rows
- Sum of `staging.<table>` rows + rejects = total lines in the CSV (minus header)

Verify from terminal:

```bash
cd /home/azyen/Downloads/business-intelligence-labs-main/labs/lab01_hop_duckdb
duckdb duckdb/lab1.duckdb "SELECT COUNT(*) FROM staging.customers;"
# Expected: 11
```

---

## Part A — Exploration in DuckDB (Steps 2–4)

```bash
cd /home/azyen/Downloads/business-intelligence-labs-main/labs/lab01_hop_duckdb
duckdb duckdb/lab1.duckdb
```

Inside the DuckDB prompt:

```sql
.read sql/02_profile_tables.sql      -- row counts, nulls
.read sql/03_quality_checks.sql      -- duplicates, orphan keys
.read sql/04_kpi_exploration.sql     -- optional: first KPIs
.quit
```

Fill in `deliverables/quality_report_template.md` (≥ 3 anomalies) and
`deliverables/kpi_list_template.md` (3 KPI candidates).

---

## Part B — Prerequisites

Before building Part B pipelines, create the warehouse and control schemas:

```bash
duckdb duckdb/lab1.duckdb ".read sql/20_create_warehouse_schema.sql"
duckdb duckdb/lab1.duckdb ".read sql/40_create_control_schema.sql"
```

---

## Part B — Pipeline p02: staging.* → Dimensions

Open `hop/pipelines/p02_build_dims.hpl` and build each dimension flow.

### dim_date

Use `ExecSql` (allowed here as calendar plumbing):

- Add an **ExecSql** transform
- Connection: `DuckDB_Lab1`
- Paste the content of `sql/21_dim_date.sql`

### dim_customer

```text
[Table Input: SELECT * FROM staging.customers]
    → [Filter Rows: customer_id NOT NULL AND customer_name NOT NULL]
    → [Sort Rows: customer_id, signup_date]
    → [Unique Rows: deduplicate on customer_id]
    → [Value Mapper: city normalization]
    → [Add Sequence: field = customer_key, start=1, increment=1]
    → [Table Output: warehouse.dim_customer, Truncate=Y]
```

Table Input SQL: `SELECT * FROM staging.customers`

Add Sequence settings: field name = `customer_key`, start = `1`, increment = `1`

### dim_product

```text
[Table Input: SELECT * FROM staging.products]
    → [Database Lookup: staging.categories on category_id → category_name, department]
    → [Filter Rows: product_id NOT NULL]
    → [Add Sequence: product_key]
    → [Table Output: warehouse.dim_product, Truncate=Y]
```

Database Lookup settings:
- Connection: `DuckDB_Lab1`
- Schema/Table: `staging.categories`
- Key: `category_id = category_id`
- Return fields: `category_name`, `department`
- If not found: leave empty (returns NULL, caught by Filter Rows)

### dim_channel

```text
[Table Input: SELECT DISTINCT channel FROM staging.orders]
    → [Unique Rows: on channel]
    → [Value Mapper: Online→Digital, Store→Physical, Partner→Indirect]
    → [Add Sequence: channel_key]
    → [Table Output: warehouse.dim_channel, Truncate=Y]
```

### Run p02

```bash
duckdb duckdb/lab1.duckdb "SELECT COUNT(*) FROM warehouse.dim_date;"
# Expected: 1096
```

---

## Part B — Pipeline p03: staging.* → Facts

Open `hop/pipelines/p03_build_facts.hpl`.

### fact_sales

```text
[Table Input: staging.order_items]
    → [Database Lookup: staging.orders on order_id → order_date, customer_id, channel, order_status, city]
    → [Database Lookup: warehouse.dim_date on order_date → date_key]
    → [Database Lookup: warehouse.dim_customer on customer_id → customer_key]
    → [Database Lookup: warehouse.dim_product on product_id → product_key, cost_price]
    → [Database Lookup: warehouse.dim_channel on channel → channel_key]
    → [Filter Rows: date_key NOT NULL AND customer_key NOT NULL
                    AND product_key NOT NULL AND channel_key NOT NULL
                    AND quantity > 0 AND unit_price >= 0]
    → [Calculator: gross_amount, net_amount, cost_amount, margin_amount]
    → [Add Sequence: sales_key]
    → [Table Output: warehouse.fact_sales, Truncate=Y]
```

Calculator transform — one row per measure:

| New field | Calculation | Field A | Field B |
|-----------|-------------|---------|---------|
| gross_amount | A * B | quantity | unit_price |
| net_amount | A - B | gross_amount | discount_amount |
| cost_amount | A * B | quantity | cost_price |
| margin_amount | A - B | net_amount | cost_amount |

> `order_item_id` is kept as `order_item_id_src` (rename via Select Values).
> `sales_key` is the surrogate key generated by Add Sequence.

### fact_stock

```text
[Table Input: staging.stock_movements]
    → [Database Lookup: warehouse.dim_date on movement_date → date_key]
    → [Database Lookup: warehouse.dim_product on product_id → product_key]
    → [Filter Rows: movement_type IN ('IN','OUT') AND quantity > 0 AND product_key NOT NULL]
    → [Calculator: qty_in, qty_out]
    → [Table Output: warehouse.fact_stock, Truncate=Y]
```

For `qty_in`/`qty_out`, use a **Value Mapper** before Calculator to split `movement_type`, or use a Filter Rows split + Merge Rows.

### Run p03 (only after p02 succeeds)

```bash
duckdb duckdb/lab1.duckdb "SELECT COUNT(*) FROM warehouse.fact_sales;"
# Expected: 13 after initial load

duckdb duckdb/lab1.duckdb "SELECT COUNT(*) FROM warehouse.fact_sales WHERE date_key IS NULL OR customer_key IS NULL;"
# Expected: 0
```

---

## Part B — Pipeline p05: staging.budget → warehouse.fact_budget

Open `hop/pipelines/p05_load_budget.hpl`.

```text
[Table Input: SELECT * FROM staging.budget]
    → [Database Lookup: staging.categories on category_id → category_name]
    → [Database Lookup: warehouse.dim_channel on channel → channel_key]
    → [Table Output: warehouse.fact_budget, Truncate=Y]
```

> p05 requires both `staging.budget` (from p01) and `warehouse.dim_channel` (from p02) to exist first.

---

## Part B — Run the Initial Load Workflow

Open `hop/workflows/wf_initial_load.hwf`. This orchestrates: `p01 → p02 → p03 → p05`

Click **▶ Run** — all actions should turn green.

Expected result:

```
FULL LOAD COMPLETE | fact_sales_rows=13 | fact_stock_rows=10 | fact_budget_rows=12 | latest_order_date=2025-03-21
```

Validation queries:

```sql
SELECT COUNT(*) FROM warehouse.fact_sales
WHERE date_key IS NULL OR customer_key IS NULL OR product_key IS NULL;
-- Expected: 0

SELECT COUNT(*) FROM warehouse.fact_budget;
-- Expected: 12
```

---

## Part B — Pipeline p04: Incremental Load (April batch)

Open `hop/pipelines/p04_incremental_load.hpl`.

```text
[Read orders_april.csv]          [Read order_items_april.csv]    [Read payments_april.csv]
    → [Select Values (types)]        → [Select Values (types)]       → [Select Values (types)]
    → [Filter Rows:                  → [Database Lookup               → [Filter Rows:
       order_date > watermark]          staging.order_items              payment_date > watermark]
    → [Database Lookup                  on order_item_id, keep miss]  → [Database Lookup
       staging.orders                → [Table Output staging             staging.payments
       on order_id, keep miss]          .order_items, Truncate=N]        on payment_id, keep miss]
    → [Table Output staging                                           → [Table Output staging
       .orders, Truncate=N]                                              .payments, Truncate=N]

[ExecSql: UPDATE control.load_watermark SET last_load_dt = (SELECT MAX(order_date) FROM staging.orders)]
```

Key settings for Table Output in p04: **Truncate = NO** (append, never overwrite history).

Then open `hop/workflows/wf_incremental_load.hwf` and run it. It chains `p04 → p03`.

Expected result:

```
INCREMENTAL LOAD COMPLETE | fact_sales_rows=19 | latest_order_date=2025-04-20
```

---

## Part B — Budget vs Actuals

```bash
duckdb duckdb/lab1.duckdb ".read sql/52_actuals_vs_budget.sql"
```

---

## Common Pitfalls & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| `${DATA_DIR}` not resolved | Project Home not set correctly | File → Edit Project, set correct absolute path |
| `${PROJECT_HOME}` resolves to `/opt/hop/` | Project Home is wrong or not saved | Set Project Home to `.../lab01_hop_duckdb` and restart |
| Connection failed | JDBC jar missing | Copy `duckdb_jdbc-*.jar` to `~/tools/hop/lib/` and restart Hop |
| 0 rows in staging after run | Dummy placeholder not replaced | Right-click Dummy → Change transform type → Select Values |
| Fact table has NULL keys | p03 ran before p02 | Run p02 first to populate dimensions |
| Duplicate rows on re-run | Truncate not checked | Enable Truncate = Y on Table Output for full-load tables |
| April rows duplicated | Truncate = Y on incremental | Set Truncate = N for p04 Table Outputs |
| Watermark not updated | ExecSql missing in p04 | Add ExecSql to update `control.load_watermark` after inserts |
| dim_date missing rows | Calendar SQL not executed | Run ExecSql with `sql/21_dim_date.sql` content in p02 |

---

## Execution Order Summary

```bash
# ── One-time setup ────────────────────────────────────────────────────────────
duckdb duckdb/lab1.duckdb ".read sql/00_create_schema.sql"
duckdb duckdb/lab1.duckdb ".read sql/10_create_staging_schema.sql"
duckdb duckdb/lab1.duckdb ".read sql/20_create_warehouse_schema.sql"
duckdb duckdb/lab1.duckdb ".read sql/40_create_control_schema.sql"

# ── Part A ────────────────────────────────────────────────────────────────────
# Run p01 in Hop GUI → explore in DuckDB:
duckdb duckdb/lab1.duckdb ".read sql/02_profile_tables.sql"
duckdb duckdb/lab1.duckdb ".read sql/03_quality_checks.sql"

# ── Part B — initial full load ────────────────────────────────────────────────
# Run wf_initial_load.hwf in Hop GUI  (orchestrates p01 → p02 → p03 → p05)

# ── Part B — incremental load ─────────────────────────────────────────────────
# Run wf_incremental_load.hwf in Hop GUI  (orchestrates p04 → p03)

# ── Part B — analysis ─────────────────────────────────────────────────────────
duckdb duckdb/lab1.duckdb ".read sql/52_actuals_vs_budget.sql"
```

> The skeleton `.hpl` and `.hwf` files are already in `hop/pipelines/` and `hop/workflows/`.
> Open them in Hop GUI, replace Dummy placeholders with real transforms, configure each dialog, and run.
> The SQL scripts in `sql/` are your validation oracle at every step.
