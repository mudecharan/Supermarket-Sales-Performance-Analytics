# Supermarket Sales Performance Analytics

A full-stack retail analytics project that explores a large-scale supermarket transaction dataset (120,000 records) end-to-end — from raw data quality checks to business KPIs, RFM segmentation, cohort retention, anomaly detection, and executive dashboards. The analysis is delivered across Python (Jupyter), T-SQL (SQL Server), DAX (Power BI), and pre-computed KPI artifacts.

## Project Overview

| Metric | Value |
|---|---|
| Total Revenue | $11.29M |
| Total Profit | $3.77M |
| Avg Profit Margin | 33.39% |
| Transactions | 120,000 |
| Customers | 75,799 |
| Stores | 200 |
| Products | 5,000 |
| Date Range | 2023-01-01 → 2024-12-30 |
| YoY Revenue Growth | +13.0% |
| YoY Profit Growth | +19.1% |
| Online Revenue Share | 40.2% |
| Return Rate | 3.06% |
| Avg Customer Satisfaction | 3.96 / 5 |

## Repository Structure

```
Supermarket/
├── supermarket_Data_Analysis.ipynb   # Main Python analysis notebook
├── Data/
│   └── supermarket_large_dataset.csv # Source dataset (102 columns)
├── kpi/                              # Pre-computed KPI & summary CSV/JSON files
├── charts/                           # 15 exported visualizations
├── sql/
│   └── Supermarket_Analysis_SQLServer.sql  # Full SQL Server analysis script
└── dax/
    └── Supermarket_Analysis_DAX_Measures.txt # Power BI DAX measures & columns
```

## Tech Stack

- **Python** — pandas, numpy, matplotlib/seaborn for EDA and KPI computation
- **SQL Server (T-SQL)** — schema design, KPI views, stored procedures, indexed views
- **DAX** — Power BI measures, calculated columns, time intelligence, RFM, anomaly detection
- **Jupyter Notebook** — interactive analysis & reporting
- **Data visualization** — 15 charts (trends, regions, categories, segments, etc.)

## Analysis Coverage

1. **Data Quality** — duplicate detection, missing-value profiling (avg 2.38% missing across 7 columns), schema validation
2. **Core KPIs** — revenue, profit, COGS, transactions, basket value, margin
3. **Performance Analysis** — by region, department, category, product, store type
4. **Customer Analytics** — RFM segmentation, cohort retention, demographics, membership tiers
5. **Promotions & Discounts** — promotion effect, coupon usage, discount-tier impact
6. **Time Patterns** — monthly/seasonal trends, YoY comparison, day-of-week, weekend share
7. **Anomaly Detection** — daily revenue z-score flagging
8. **KPI Status Flags** — Red/Yellow/Green thresholds for executive monitoring

## Key Deliverables

- `kpi/` folder with 25+ pre-computed summary files (region, category, channel, promo, etc.)
- `charts/` with 15 publication-ready visualizations
- Reusable SQL Server schema + views + stored procedures for BI tools
- Power BI-ready DAX measure library

## Getting Started

1. Clone the repository.
2. Open `supermarket_Data_Analysis.ipynb` in Jupyter and run all cells (requires Python 3.9+).
3. For SQL: run `sql/Supermarket_Analysis_SQLServer.sql` in SQL Server (imports CSV via BULK INSERT).
4. For Power BI: import the CSV, create relationships, then paste measures from `dax/`.

## Author

Data Analysis Team — 2026-10-15
README.md
