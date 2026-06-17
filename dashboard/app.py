import streamlit as st
import duckdb
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path

st.set_page_config(
    page_title="BI Lab 1 — Sales Dashboard",
    page_icon="📊",
    layout="wide",
)

DB_PATH = Path(__file__).resolve().parent.parent / "labs" / "lab01_hop_duckdb" / "duckdb" / "lab1.duckdb"


@st.cache_resource
def get_conn():
    if not DB_PATH.exists():
        st.error(f"Database not found at {DB_PATH}. Run the ETL pipeline first.")
        st.stop()
    return duckdb.connect(str(DB_PATH))


conn = get_conn()


@st.cache_data(ttl=60)
def query(q):
    return conn.execute(q).fetchdf()


# ─────────────────────────────────────────────
#  SIDEBAR — filters
# ─────────────────────────────────────────────
st.sidebar.title("📊 BI Dashboard")
st.sidebar.caption("Lab 1 — Hop + DuckDB")

dates = query("""
    SELECT MIN(order_date) AS min_dt, MAX(order_date) AS max_dt
    FROM staging.orders
""")
min_date = dates["min_dt"].iloc[0]
max_date = dates["max_dt"].iloc[0]

date_range = st.sidebar.date_input(
    "Order date range",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date,
)

status_filter = st.sidebar.multiselect(
    "Order status",
    ["Completed", "Returned", "Cancelled", "Shipped"],
    default=["Completed"],
)

# ─────────────────────────────────────────────
#  TOP-LEVEL KPI CARDS
# ─────────────────────────────────────────────
d1, d2 = date_range[0], date_range[1] if len(date_range) > 1 else date_range[0]
status_cond = ", ".join(f"'{s}'" for s in status_filter)

kpi = query(f"""
    SELECT
        COALESCE(SUM(net_amount), 0)                         AS total_revenue,
        COALESCE(COUNT(DISTINCT order_id), 0)                AS total_orders,
        ROUND(COALESCE(SUM(net_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 0), 2)
                                                              AS avg_order_value,
        ROUND(COALESCE(SUM(discount_amount) / NULLIF(SUM(gross_amount), 0) * 100, 0), 1)
                                                              AS discount_rate_pct,
        COALESCE(SUM(quantity), 0)                           AS total_units
    FROM warehouse.fact_sales
    WHERE order_status IN ({status_cond})
      AND date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                       AND {d2.year * 10000 + d2.month * 100 + d2.day}
""")

col1, col2, col3, col4, col5 = st.columns(5)
with col1:
    st.metric("💰 Total Revenue", f"${kpi['total_revenue'].iloc[0]:,.2f}")
with col2:
    st.metric("📦 Orders", f"{kpi['total_orders'].iloc[0]:,}")
with col3:
    st.metric("🛒 Avg Order Value", f"${kpi['avg_order_value'].iloc[0]:,.2f}")
with col4:
    st.metric("🏷️ Discount Rate", f"{kpi['discount_rate_pct'].iloc[0]}%")
with col5:
    st.metric("📦 Units Sold", f"{kpi['total_units'].iloc[0]:,}")

st.divider()

# ─────────────────────────────────────────────
#  ROW 1 — Revenue trend + Channel
# ─────────────────────────────────────────────
row1_left, row1_right = st.columns(2)

# Revenue trend by month
with row1_left:
    st.subheader("📈 Revenue Trend")
    trend = query(f"""
        SELECT
            dd.year,
            dd.month_num,
            dd.month_name,
            SUM(fs.net_amount) AS revenue
        FROM warehouse.fact_sales fs
        JOIN warehouse.dim_date dd ON fs.date_key = dd.date_key
        WHERE fs.order_status IN ({status_cond})
          AND fs.date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                             AND {d2.year * 10000 + d2.month * 100 + d2.day}
        GROUP BY dd.year, dd.month_num, dd.month_name
        ORDER BY dd.year, dd.month_num
    """)
    trend["label"] = trend["month_name"] + " " + trend["year"].astype(str)
    fig = px.line(trend, x="label", y="revenue", markers=True)
    fig.update_layout(height=320, margin=dict(l=20, r=20, t=20, b=20))
    st.plotly_chart(fig, use_container_width=True)

# Revenue by channel
with row1_right:
    st.subheader("📊 Revenue by Channel")
    chan = query(f"""
        SELECT
            dch.channel_name,
            ROUND(SUM(fs.net_amount), 2) AS revenue
        FROM warehouse.fact_sales fs
        JOIN warehouse.dim_channel dch ON fs.channel_key = dch.channel_key
        WHERE fs.order_status IN ({status_cond})
          AND fs.date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                             AND {d2.year * 10000 + d2.month * 100 + d2.day}
        GROUP BY dch.channel_name
        ORDER BY revenue DESC
    """)
    fig = px.bar(chan, x="channel_name", y="revenue", text_auto=".2s", color="channel_name")
    fig.update_layout(height=320, showlegend=False, margin=dict(l=20, r=20, t=20, b=20))
    st.plotly_chart(fig, use_container_width=True)

# ─────────────────────────────────────────────
#  ROW 2 — Category + Status breakdown
# ─────────────────────────────────────────────
row2_left, row2_right = st.columns(2)

with row2_left:
    st.subheader("🏷️ Revenue by Category")
    cat = query(f"""
        SELECT
            COALESCE(dp.category_name, 'Unknown') AS category,
            ROUND(SUM(fs.net_amount), 2) AS revenue
        FROM warehouse.fact_sales fs
        JOIN warehouse.dim_product dp ON fs.product_key = dp.product_key
        WHERE fs.order_status IN ({status_cond})
          AND fs.date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                             AND {d2.year * 10000 + d2.month * 100 + d2.day}
        GROUP BY dp.category_name
        ORDER BY revenue DESC
    """)
    fig = px.bar(cat, x="revenue", y="category", orientation="h", color="category", text_auto=".2s")
    fig.update_layout(height=320, showlegend=False, margin=dict(l=20, r=20, t=20, b=20))
    st.plotly_chart(fig, use_container_width=True)

with row2_right:
    st.subheader("📋 Order Status Distribution")
    status = query(f"""
        SELECT order_status, COUNT(*) AS cnt
        FROM warehouse.fact_sales
        WHERE date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                           AND {d2.year * 10000 + d2.month * 100 + d2.day}
        GROUP BY order_status
        ORDER BY cnt DESC
    """)
    fig = px.pie(status, values="cnt", names="order_status", hole=0.4)
    fig.update_layout(height=320, margin=dict(l=20, r=20, t=20, b=20))
    st.plotly_chart(fig, use_container_width=True)

st.divider()

# ─────────────────────────────────────────────
#  ROW 3 — Budget vs Actuals
# ─────────────────────────────────────────────
st.subheader("🎯 Budget vs Actuals")
budget = query("""
    SELECT
        dd.year,
        dd.month_num,
        dd.month_name,
        SUM(fs.net_amount) AS actual_revenue,
        MAX(fb.budget_amount) AS budget_revenue
    FROM warehouse.fact_sales fs
    JOIN warehouse.dim_date dd ON fs.date_key = dd.date_key
    LEFT JOIN warehouse.fact_budget fb
        ON dd.year = fb.year
        AND dd.month_num = fb.month_num
    WHERE fs.order_status = 'Completed'
    GROUP BY dd.year, dd.month_num, dd.month_name
    ORDER BY dd.year, dd.month_num
""")

budget["budget_revenue"] = budget["budget_revenue"].fillna(0)
budget["label"] = budget["month_name"] + " " + budget["year"].astype(str)

fig = go.Figure()
fig.add_trace(go.Bar(name="Actual", x=budget["label"], y=budget["actual_revenue"]))
fig.add_trace(go.Bar(name="Budget", x=budget["label"], y=budget["budget_revenue"]))
fig.update_layout(barmode="group", height=350, margin=dict(l=20, r=20, t=20, b=20))
st.plotly_chart(fig, use_container_width=True)

budget_pct = query("""
    WITH sales AS (
        SELECT dd.year, dd.month_num, SUM(fs.net_amount) AS actual
        FROM warehouse.fact_sales fs
        JOIN warehouse.dim_date dd ON fs.date_key = dd.date_key
        WHERE fs.order_status = 'Completed'
        GROUP BY dd.year, dd.month_num
    ),
    budget AS (
        SELECT year, month_num, SUM(budget_amount) AS budget
        FROM warehouse.fact_budget
        GROUP BY year, month_num
    )
    SELECT
        s.year, s.month_num,
        ROUND(s.actual, 2) AS actual,
        b.budget,
        ROUND(s.actual / NULLIF(b.budget, 0) * 100, 1) AS achievement_pct
    FROM sales s
    LEFT JOIN budget b ON s.year = b.year AND s.month_num = b.month_num
    ORDER BY s.year, s.month_num
""")
st.dataframe(budget_pct, use_container_width=True, hide_index=True)

st.divider()

# ─────────────────────────────────────────────
#  ROW 4 — Top products & Returns
# ─────────────────────────────────────────────
row4_left, row4_right = st.columns(2)

with row4_left:
    st.subheader("⭐ Top Products by Revenue")
    top = query(f"""
        SELECT
            dp.product_name,
            ROUND(SUM(fs.net_amount), 2) AS revenue,
            SUM(fs.quantity) AS units
        FROM warehouse.fact_sales fs
        JOIN warehouse.dim_product dp ON fs.product_key = dp.product_key
        WHERE fs.order_status IN ({status_cond})
          AND fs.date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                             AND {d2.year * 10000 + d2.month * 100 + d2.day}
        GROUP BY dp.product_name
        ORDER BY revenue DESC
        LIMIT 10
    """)
    fig = px.bar(top, x="revenue", y="product_name", orientation="h", color="revenue",
                 text_auto=".2s", color_continuous_scale="Blues")
    fig.update_layout(height=350, showlegend=False, margin=dict(l=20, r=20, t=20, b=20))
    st.plotly_chart(fig, use_container_width=True)

with row4_right:
    st.subheader("🔄 Returns & Cancellations")
    returns = query(f"""
        SELECT
            COALESCE(dp.category_name, 'Unknown') AS category,
            COUNT(*) AS return_count,
            ROUND(SUM(ABS(fs.net_amount)), 2) AS impact
        FROM warehouse.fact_sales fs
        JOIN warehouse.dim_product dp ON fs.product_key = dp.product_key
        WHERE fs.order_status IN ('Returned', 'Cancelled')
          AND fs.date_key BETWEEN {d1.year * 10000 + d1.month * 100 + d1.day}
                             AND {d2.year * 10000 + d2.month * 100 + d2.day}
        GROUP BY dp.category_name
        ORDER BY return_count DESC
    """)
    if not returns.empty:
        fig = px.bar(returns, x="category", y="return_count", color="category",
                     text_auto=True, title="Returns by Category")
        fig.update_layout(height=180, showlegend=False, margin=dict(l=20, r=20, t=20, b=20))
        st.plotly_chart(fig, use_container_width=True)

        fig2 = px.bar(returns, x="category", y="impact", color="category",
                      text_auto=".2s", title="Financial Impact ($)")
        fig2.update_layout(height=180, showlegend=False, margin=dict(l=20, r=20, t=20, b=20))
        st.plotly_chart(fig2, use_container_width=True)
    else:
        st.info("No returned/cancelled orders in selected period.")

st.divider()

# ─────────────────────────────────────────────
#  ROW 5 — Data Quality Overview
# ─────────────────────────────────────────────
st.subheader("🔍 Data Quality Overview")
qual = query("""
    SELECT 'Duplicate customers' AS issue,
           COUNT(*) - COUNT(DISTINCT customer_id) AS count
    FROM staging.customers
    UNION ALL
    SELECT 'Customers without email', COUNT(*) FROM staging.customers
        WHERE email IS NULL OR email = ''
    UNION ALL
    SELECT 'Orders without customer', COUNT(*) FROM staging.orders o
        LEFT JOIN staging.customers c ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    UNION ALL
    SELECT 'Order items without product', COUNT(*) FROM staging.order_items oi
        LEFT JOIN staging.products p ON oi.product_id = p.product_id
        WHERE p.product_id IS NULL
    UNION ALL
    SELECT 'Payments without order', COUNT(*) FROM staging.payments p
        LEFT JOIN staging.orders o ON p.order_id = o.order_id
        WHERE o.order_id IS NULL
    UNION ALL
    SELECT 'Stock movements without product', COUNT(*) FROM staging.stock_movements sm
        LEFT JOIN staging.products p ON sm.product_id = p.product_id
        WHERE p.product_id IS NULL
    UNION ALL
    SELECT 'Orders with negative quantities', COUNT(*) FROM staging.order_items
        WHERE quantity <= 0
    UNION ALL
    SELECT 'Payments with negative amounts', COUNT(*) FROM staging.payments
        WHERE amount < 0
""")
qual = qual[qual["count"] > 0]
if not qual.empty:
    fig = px.bar(qual, x="issue", y="count", color="count",
                 text_auto=True, color_continuous_scale="Reds")
    fig.update_layout(height=350, showlegend=False, margin=dict(l=20, r=20, t=20, b=80))
    st.plotly_chart(fig, use_container_width=True)
else:
    st.success("No quality issues detected!")

st.divider()

# ─────────────────────────────────────────────
#  ROW 6 — Raw data explorers
# ─────────────────────────────────────────────
with st.expander("📄 Raw Staging Data"):
    tbl = st.selectbox("Select table", [
        "customers", "categories", "products", "orders",
        "order_items", "payments", "stock_movements", "budget",
    ])
    df = query(f"SELECT * FROM staging.{tbl}")
    st.dataframe(df, use_container_width=True, hide_index=True)

with st.expander("📄 Warehouse Tables"):
    wtbl = st.selectbox("Select warehouse table", [
        "dim_date", "dim_customer", "dim_product", "dim_channel",
        "fact_sales", "fact_stock", "fact_budget",
    ])
    wdf = query(f"SELECT * FROM warehouse.{wtbl}")
    st.dataframe(wdf, use_container_width=True, hide_index=True)

st.caption(f"Dashboard connected to: `{DB_PATH}`")
