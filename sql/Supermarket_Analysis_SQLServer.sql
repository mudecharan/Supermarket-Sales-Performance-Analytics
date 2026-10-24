/* =============================================================================
   SUPERMARKET SALES PERFORMANCE - SQL SERVER ANALYSIS SCRIPT
   =============================================================================
   Database: SupermarketAnalysis
   Compatible with: SQL Server 2019+ / Azure SQL Database
   Author: Data Analysis Team
   Date: 2026-10-15
   
   This script reproduces the complete Python data analysis project in T-SQL:
   1. Schema design (CREATE TABLE)
   2. Data quality checks
   3. KPI computation
   4. Core performance analysis
   5. Comparative analysis (YoY, segments, regions)
   6. Time series & trends
   7. RFM analysis
   8. Cohort retention
   9. Anomaly detection & KPI flags
   10. Views, stored procedures, and indexed views for performance
   
   Run order: Sections 1-12 sequentially.
============================================================================= */

USE master;
GO

-- =============================================================================
-- SECTION 1: DATABASE & SCHEMA CREATION
-- =============================================================================

IF DB_ID('SupermarketAnalysis') IS NOT NULL
    DROP DATABASE SupermarketAnalysis;
GO

CREATE DATABASE SupermarketAnalysis;
GO

USE SupermarketAnalysis;
GO

-- Main transaction-line fact table
CREATE TABLE dbo.FactTransactions (
    transaction_id           BIGINT       NOT NULL,
    transaction_line_id     BIGINT       NOT NULL,
    basket_id                BIGINT       NULL,
    customer_id              BIGINT       NULL,
    store_id                 INT          NULL,
    product_id               BIGINT       NULL,
    employee_id              BIGINT       NULL,
    transaction_date        DATE          NOT NULL,
    transaction_time        TIME(0)       NULL,
    day_of_week             TINYINT      NULL,
    day_name                VARCHAR(10)  NULL,
    month                   TINYINT      NULL,
    month_name              VARCHAR(10)  NULL,
    quarter                 TINYINT      NULL,
    year                    SMALLINT     NULL,
    is_weekend              BIT          NULL,
    is_holiday              BIT          NULL,
    season                  VARCHAR(10)  NULL,
    shopping_hour           TINYINT      NULL,
    shopping_period         VARCHAR(20)  NULL,
    quantity                INT          NOT NULL,
    unit_price              DECIMAL(10,2) NOT NULL,
    gross_sales             DECIMAL(12,2) NOT NULL,
    net_sales               DECIMAL(12,2) NOT NULL,
    total_amount            DECIMAL(12,2) NOT NULL,
    cost_of_goods_sold      DECIMAL(12,2) NOT NULL,
    gross_profit            DECIMAL(12,2) NOT NULL,
    profit_margin_pct       DECIMAL(6,2) NULL,
    discount_amount         DECIMAL(10,2) NULL,
    discount_percent        DECIMAL(6,2) NULL,
    tax_amount              DECIMAL(10,2) NULL,
    CONSTRAINT PK_FactTransactions PRIMARY KEY (transaction_id, transaction_line_id)
);

-- Customer dimension
CREATE TABLE dbo.DimCustomer (
    customer_id             BIGINT       NOT NULL PRIMARY KEY,
    customer_age            INT          NULL,
    customer_gender         VARCHAR(10)  NULL,
    customer_income         DECIMAL(12,2) NULL,
    customer_segment        VARCHAR(30)  NULL,
    customer_region         VARCHAR(20)  NULL,
    customer_city           VARCHAR(50)  NULL,
    customer_membership_status VARCHAR(10) NULL,
    membership_tier         VARCHAR(10)  NULL,
    loyalty_program_member  BIT          NULL,
    loyalty_points_earned   INT          NULL,
    loyalty_tier            VARCHAR(20)  NULL,
    customer_since_year     SMALLINT     NULL,
    customer_tenure_months  INT          NULL
);

-- Store dimension
CREATE TABLE dbo.DimStore (
    store_id                INT          NOT NULL PRIMARY KEY,
    store_type              VARCHAR(30)  NULL,
    store_city              VARCHAR(50)  NULL,
    store_region            VARCHAR(20)  NULL,
    store_area_type         VARCHAR(20)  NULL,
    store_size_sqft         INT          NULL,
    store_format            VARCHAR(20)  NULL,
    store_age_years         DECIMAL(5,2) NULL,
    number_of_employees     INT          NULL,
    store_rating            DECIMAL(3,2) NULL,
    store_operational_status VARCHAR(10) NULL
);

-- Product dimension
CREATE TABLE dbo.DimProduct (
    product_id              BIGINT       NOT NULL PRIMARY KEY,
    product_name            NVARCHAR(100) NULL,
    product_category        NVARCHAR(50) NULL,
    product_subcategory     NVARCHAR(50) NULL,
    product_department      NVARCHAR(50) NULL,
    brand                    NVARCHAR(50) NULL,
    brand_type              NVARCHAR(20) NULL,
    product_type            NVARCHAR(30) NULL,
    product_size            NVARCHAR(20) NULL,
    unit_cost               DECIMAL(10,2) NULL,
    regular_price           DECIMAL(10,2) NULL,
    selling_price           DECIMAL(10,2) NULL,
    wholesale_price         DECIMAL(10,2) NULL,
    product_perishable      BIT          NULL,
    product_status          VARCHAR(20)  NULL
);

-- Promotion dimension
CREATE TABLE dbo.DimPromotion (
    promotion_id            BIGINT       NULL,
    promotion_active        BIT          NULL,
    promotion_type          NVARCHAR(30) NULL,
    promotion_channel       NVARCHAR(30) NULL,
    promotion_discount_pct  DECIMAL(6,2) NULL,
    coupon_used             BIT          NULL,
    coupon_value            DECIMAL(10,2) NULL,
    loyalty_discount        DECIMAL(10,2) NULL,
    bundle_offer            BIT          NULL,
    buy_one_get_one         BIT          NULL,
    clearance_sale          BIT          NULL,
    seasonal_promotion      BIT          NULL,
    marketing_channel       NVARCHAR(30) NULL,
    campaign_response       NVARCHAR(20) NULL
);

-- Payment dimension
CREATE TABLE dbo.DimPayment (
    payment_method          VARCHAR(20)  NULL,
    payment_channel        VARCHAR(20)  NULL,
    payment_status         VARCHAR(20)  NULL,
    card_type              VARCHAR(20)  NULL,
    digital_wallet         VARCHAR(30)  NULL,
    payment_processing_time_seconds INT NULL
);

-- Sales channel dimension
CREATE TABLE dbo.DimSalesChannel (
    sales_channel          VARCHAR(30)  NULL,
    online_order          BIT          NULL,
    mobile_app_order      BIT          NULL,
    website_order         BIT          NULL,
    in_store_purchase     BIT          NULL,
    click_and_collect     BIT          NULL,
    home_delivery         BIT          NULL,
    delivery_distance_km DECIMAL(6,2) NULL,
    delivery_fee          DECIMAL(10,2) NULL
);

-- Date dimension
CREATE TABLE dbo.DimDate (
    date_key               INT          NOT NULL PRIMARY KEY,
    full_date              DATE         NOT NULL,
    day_of_week            TINYINT     NULL,
    day_name               VARCHAR(10) NULL,
    day_of_month           TINYINT     NULL,
    week_of_year           TINYINT     NULL,
    month                  TINYINT     NULL,
    month_name             VARCHAR(10) NULL,
    quarter                TINYINT     NULL,
    year                   SMALLINT    NULL,
    is_weekend             BIT         NULL,
    is_holiday             BIT         NULL,
    season                 VARCHAR(10) NULL
);

-- =============================================================================
-- SECTION 2: INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IX_FactTxn_Date ON dbo.FactTransactions(transaction_date);
CREATE INDEX IX_FactTxn_Customer ON dbo.FactTransactions(customer_id);
CREATE INDEX IX_FactTxn_Store ON dbo.FactTransactions(store_id);
CREATE INDEX IX_FactTxn_Product ON dbo.FactTransactions(product_id);
CREATE INDEX IX_FactTxn_YearMonth ON dbo.FactTransactions(year, month);

GO

-- =============================================================================
-- SECTION 3: DATA QUALITY CHECK VIEWS
-- =============================================================================

-- View: Missing values summary per column
CREATE OR ALTER VIEW dbo.vw_DataQuality_MissingValues AS
SELECT
    'transaction_id' AS column_name,
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS missing_count,
    COUNT(*) AS total_rows,
    CAST(100.0 * SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(6,2)) AS missing_pct
FROM dbo.FactTransactions
UNION ALL
SELECT 'customer_id',
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END),
    COUNT(*), CAST(100.0 * SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(6,2))
FROM dbo.FactTransactions
UNION ALL
SELECT 'store_id',
    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END),
    COUNT(*), CAST(100.0 * SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(6,2))
FROM dbo.FactTransactions;
GO

-- View: Duplicate transaction check
CREATE OR ALTER VIEW dbo.vw_DataQuality_Duplicates AS
SELECT transaction_id, COUNT(*) AS dup_count
FROM dbo.FactTransactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;
GO

-- View: Negative profit transactions
CREATE OR ALTER VIEW dbo.vw_DataQuality_NegativeProfit AS
SELECT transaction_id, transaction_date, product_id,
       total_amount, cost_of_goods_sold, gross_profit, profit_margin_pct
FROM dbo.FactTransactions
WHERE gross_profit < 0
ORDER BY gross_profit;
GO

-- =============================================================================
-- SECTION 4: CORE KPI COMPUTATION
-- =============================================================================

-- View: Headline KPIs
CREATE OR ALTER VIEW dbo.vw_KPIs_Headline AS
SELECT
    SUM(total_amount) AS total_revenue,
    SUM(gross_profit) AS total_gross_profit,
    SUM(cost_of_goods_sold) AS total_cogs,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity) AS total_items_sold,
    AVG(total_amount) AS avg_order_value,
    CAST(SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) AS DECIMAL(10,2)) AS avg_profit_margin_pct,
    MIN(transaction_date) AS period_start_date,
    MAX(transaction_date) AS period_end_date
FROM dbo.FactTransactions;
GO

-- View: Yearly comparison (YoY)
CREATE OR ALTER VIEW dbo.vw_KPIs_Yearly AS
SELECT
    year,
    SUM(total_amount) AS revenue,
    SUM(gross_profit) AS profit,
    COUNT(DISTINCT transaction_id) AS transactions,
    COUNT(DISTINCT customer_id) AS customers,
    CAST(SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) AS DECIMAL(10,2)) AS margin_pct,
    CAST(SUM(total_amount) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS DECIMAL(10,2)) AS aov
FROM dbo.FactTransactions
GROUP BY year
ORDER BY year;
GO

-- YoY Growth query
CREATE OR ALTER VIEW dbo.vw_KPIs_YoYGrowth AS
SELECT
    cur.year AS current_year,
    prev.year AS previous_year,
    cur.revenue AS current_revenue,
    prev.revenue AS previous_revenue,
    CAST((cur.revenue - prev.revenue) * 100.0 / NULLIF(prev.revenue, 0) AS DECIMAL(10,2)) AS yoy_revenue_growth_pct,
    CAST((cur.profit - prev.profit) * 100.0 / NULLIF(prev.profit, 0) AS DECIMAL(10,2)) AS yoy_profit_growth_pct,
    CAST((cur.transactions - prev.transactions) * 100.0 / NULLIF(prev.transactions, 0) AS DECIMAL(10,2)) AS yoy_txn_growth_pct
FROM (
    SELECT year, SUM(total_amount) AS revenue, SUM(gross_profit) AS profit,
           COUNT(DISTINCT transaction_id) AS transactions
    FROM dbo.FactTransactions GROUP BY year
) cur
INNER JOIN (
    SELECT year, SUM(total_amount) AS revenue, SUM(gross_profit) AS profit,
           COUNT(DISTINCT transaction_id) AS transactions
    FROM dbo.FactTransactions GROUP BY year
) prev ON cur.year = prev.year + 1;
GO

-- =============================================================================
-- SECTION 5: CORE PERFORMANCE ANALYSIS VIEWS
-- =============================================================================

-- Revenue by Region
CREATE OR ALTER VIEW dbo.vw_Performance_ByRegion AS
SELECT
    s.store_region,
    SUM(f.total_amount) AS revenue,
    SUM(f.gross_profit) AS profit,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    COUNT(DISTINCT f.customer_id) AS customers,
    CAST(SUM(f.gross_profit) * 100.0 / NULLIF(SUM(f.total_amount), 0) AS DECIMAL(10,2)) AS margin_pct,
    CAST(SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.transaction_id), 0) AS DECIMAL(10,2)) AS aov,
    CAST(SUM(f.total_amount) * 100.0 / NULLIF(SUM(SUM(f.total_amount)) OVER (), 0) AS DECIMAL(6,2)) AS share_pct
FROM dbo.FactTransactions f
JOIN dbo.DimStore s ON f.store_id = s.store_id
GROUP BY s.store_region;
GO

-- Revenue by Product Department
CREATE OR ALTER VIEW dbo.vw_Performance_ByDepartment AS
SELECT
    p.product_department,
    SUM(f.total_amount) AS revenue,
    SUM(f.gross_profit) AS profit,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CAST(SUM(f.gross_profit) * 100.0 / NULLIF(SUM(f.total_amount), 0) AS DECIMAL(10,2)) AS margin_pct,
    CAST(SUM(f.total_amount) * 100.0 / NULLIF(SUM(SUM(f.total_amount)) OVER (), 0) AS DECIMAL(6,2)) AS share_pct
FROM dbo.FactTransactions f
JOIN dbo.DimProduct p ON f.product_id = p.product_id
GROUP BY p.product_department;
GO

-- Revenue by Product Category (Top 10)
CREATE OR ALTER VIEW dbo.vw_Performance_TopCategories AS
SELECT TOP 10
    p.product_category,
    SUM(f.total_amount) AS revenue,
    SUM(f.gross_profit) AS profit,
    SUM(f.quantity) AS qty_sold,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CAST(SUM(f.gross_profit) * 100.0 / NULLIF(SUM(f.total_amount), 0) AS DECIMAL(10,2)) AS margin_pct
FROM dbo.FactTransactions f
JOIN dbo.DimProduct p ON f.product_id = p.product_id
GROUP BY p.product_category
ORDER BY revenue DESC;
GO

-- =============================================================================
-- SECTION 6: COMPARATIVE ANALYSIS VIEWS
-- =============================================================================

-- Customer Segment Analysis
CREATE OR ALTER VIEW dbo.vw_Compare_CustomerSegments AS
SELECT
    c.customer_segment,
    SUM(f.total_amount) AS revenue,
    SUM(f.gross_profit) AS profit,
    COUNT(DISTINCT f.customer_id) AS customers,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CAST(SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.transaction_id), 0) AS DECIMAL(10,2)) AS aov,
    CAST(SUM(f.gross_profit) * 100.0 / NULLIF(SUM(f.total_amount), 0) AS DECIMAL(10,2)) AS margin_pct
FROM dbo.FactTransactions f
JOIN dbo.DimCustomer c ON f.customer_id = c.customer_id
GROUP BY c.customer_segment;
GO

-- Store Format Analysis
CREATE OR ALTER VIEW dbo.vw_Compare_StoreFormats AS
SELECT
    s.store_type,
    SUM(f.total_amount) AS revenue,
    SUM(f.gross_profit) AS profit,
    COUNT(DISTINCT f.store_id) AS stores,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CAST(SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.store_id), 0) AS DECIMAL(12,2)) AS revenue_per_store,
    CAST(SUM(f.gross_profit) * 100.0 / NULLIF(SUM(f.total_amount), 0) AS DECIMAL(10,2)) AS margin_pct
FROM dbo.FactTransactions f
JOIN dbo.DimStore s ON f.store_id = s.store_id
GROUP BY s.store_type;
GO

-- Payment Method Analysis
CREATE OR ALTER VIEW dbo.vw_Compare_PaymentMethods AS
SELECT
    f.payment_method,
    SUM(f.total_amount) AS revenue,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CAST(SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.transaction_id), 0) AS DECIMAL(10,2)) AS aov,
    CAST(SUM(f.total_amount) * 100.0 / NULLIF(SUM(SUM(f.total_amount)) OVER (), 0) AS DECIMAL(6,2)) AS share_pct,
    AVG(CAST(f.payment_processing_time_seconds AS DECIMAL(10,2))) AS avg_processing_time_sec
FROM dbo.FactTransactions f
GROUP BY f.payment_method;
GO

-- Membership Tier Analysis
CREATE OR ALTER VIEW dbo.vw_Compare_MembershipTiers AS
SELECT
    c.membership_tier,
    SUM(f.total_amount) AS revenue,
    SUM(f.gross_profit) AS profit,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    SUM(c.loyalty_points_earned) AS loyalty_pts_earned,
    CAST(SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.transaction_id), 0) AS DECIMAL(10,2)) AS aov,
    CAST(SUM(f.gross_profit) * 100.0 / NULLIF(SUM(f.total_amount), 0) AS DECIMAL(10,2)) AS margin_pct
FROM dbo.FactTransactions f
JOIN dbo.DimCustomer c ON f.customer_id = c.customer_id
GROUP BY c.membership_tier;
GO

-- =============================================================================
-- SECTION 7: TIME SERIES & TREND VIEWS
-- =============================================================================

-- Monthly revenue trend with rolling averages
CREATE OR ALTER VIEW dbo.vw_TimeSeries_Monthly AS
SELECT
    year, month,
    SUM(total_amount) AS revenue,
    SUM(gross_profit) AS profit,
    COUNT(DISTINCT transaction_id) AS transactions,
    CAST(SUM(total_amount) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS DECIMAL(10,2)) AS aov
FROM dbo.FactTransactions
GROUP BY year, month
ORDER BY year, month;
GO

-- Daily revenue with 7-day & 30-day rolling averages
CREATE OR ALTER VIEW dbo.vw_TimeSeries_DailyRolling AS
WITH Daily AS (
    SELECT
        transaction_date AS txn_date,
        SUM(total_amount) AS daily_revenue,
        COUNT(DISTINCT transaction_id) AS daily_transactions
    FROM dbo.FactTransactions
    GROUP BY transaction_date
)
SELECT
    txn_date,
    daily_revenue,
    daily_transactions,
    AVG(daily_revenue) OVER (ORDER BY txn_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7day_revenue,
    AVG(daily_revenue) OVER (ORDER BY txn_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS ma_30day_revenue,
    AVG(daily_revenue) OVER (ORDER BY txn_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7day_transactions
FROM Daily;
GO

-- Hourly revenue pattern
CREATE OR ALTER VIEW dbo.vw_TimeSeries_HourlyPattern AS
SELECT
    shopping_hour,
    SUM(total_amount) AS revenue,
    COUNT(DISTINCT transaction_id) AS transactions
FROM dbo.FactTransactions
WHERE shopping_hour IS NOT NULL
GROUP BY shopping_hour
ORDER BY shopping_hour;
GO

-- Day-of-Week pattern
CREATE OR ALTER VIEW dbo.vw_TimeSeries_DayOfWeek AS
SELECT
    day_name,
    SUM(total_amount) AS revenue,
    COUNT(DISTINCT transaction_id) AS transactions
FROM dbo.FactTransactions
GROUP BY day_name;
GO

-- =============================================================================
-- SECTION 8: PROMOTION & DISCOUNT ANALYSIS
-- =============================================================================

-- Promotion impact on AOV & margin
CREATE OR ALTER VIEW dbo.vw_Promo_PromotionImpact AS
SELECT
    CASE WHEN promotion_active = 1 THEN 'Yes' ELSE 'No' END AS promotion_active,
    SUM(total_amount) AS revenue,
    SUM(gross_profit) AS profit,
    COUNT(DISTINCT transaction_id) AS transactions,
    CAST(SUM(total_amount) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS DECIMAL(10,2)) AS aov,
    CAST(SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) AS DECIMAL(10,2)) AS margin_pct,
    AVG(discount_percent) AS avg_discount_pct
FROM dbo.FactTransactions
GROUP BY CASE WHEN promotion_active = 1 THEN 'Yes' ELSE 'No' END;
GO

-- Discount tier vs margin trade-off
CREATE OR ALTER VIEW dbo.vw_Promo_DiscountTierImpact AS
SELECT
    CASE
        WHEN discount_percent = 0 THEN '0%'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        WHEN discount_percent <= 30 THEN '21-30%'
        ELSE '31-50%'
    END AS discount_tier,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(total_amount) AS revenue,
    SUM(gross_profit) AS profit,
    CAST(SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) AS DECIMAL(10,2)) AS margin_pct,
    CAST(SUM(total_amount) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS DECIMAL(10,2)) AS aov
FROM dbo.FactTransactions
GROUP BY
    CASE
        WHEN discount_percent = 0 THEN '0%'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        WHEN discount_percent <= 30 THEN '21-30%'
        ELSE '31-50%'
    END;
GO

-- =============================================================================
-- SECTION 9: RFM ANALYSIS (Recency, Frequency, Monetary)
-- =============================================================================

-- RFM scoring per customer
CREATE OR ALTER VIEW dbo.vw_RFM_CustomerScores AS
WITH CustomerMetrics AS (
    SELECT
        customer_id,
        DATEDIFF(DAY, MAX(transaction_date), GETDATE()) AS recency,
        COUNT(DISTINCT transaction_id) AS frequency,
        SUM(total_amount) AS monetary,
        AVG(total_amount) AS avg_order_value,
        MIN(transaction_date) AS first_purchase,
        MAX(transaction_date) AS last_purchase
    FROM dbo.FactTransactions
    GROUP BY customer_id
),
Percentiles AS (
    SELECT
        customer_id, recency, frequency, monetary, avg_order_value,
        first_purchase, last_purchase,
        NTILE(5) OVER (ORDER BY recency DESC) AS R_score_desc,
        NTILE(5) OVER (ORDER BY frequency) AS F_score,
        NTILE(5) OVER (ORDER BY monetary) AS M_score
    FROM CustomerMetrics
)
SELECT
    customer_id,
    recency, frequency, monetary, avg_order_value,
    first_purchase, last_purchase,
    CASE R_score_desc WHEN 1 THEN 5 WHEN 2 THEN 4 WHEN 3 THEN 3 WHEN 4 THEN 2 ELSE 1 END AS R_score,
    F_score, M_score,
    (CASE R_score_desc WHEN 1 THEN 5 WHEN 2 THEN 4 WHEN 3 THEN 3 WHEN 4 THEN 2 ELSE 1 END
     + F_score + M_score) / 3.0 AS RFM_score
FROM Percentiles;
GO

-- RFM segment classification
CREATE OR ALTER VIEW dbo.vw_RFM_Segments AS
SELECT
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score <= 2 THEN 'New Customers'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score <= 2 THEN 'Potential Loyalists'
        WHEN R_score <= 2 AND F_score >= 4 AND M_score >= 3 THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2 THEN 'Hibernating'
        WHEN R_score <= 1 AND F_score >= 3 THEN 'Lost'
        WHEN M_score >= 4 AND F_score <= 2 THEN 'Promising'
        ELSE 'Need Attention'
    END AS segment,
    COUNT(*) AS customers,
    CAST(AVG(recency) AS DECIMAL(10,1)) AS avg_recency_days,
    CAST(AVG(frequency) AS DECIMAL(10,2)) AS avg_frequency,
    CAST(AVG(monetary) AS DECIMAL(12,2)) AS avg_monetary,
    SUM(monetary) AS total_revenue,
    CAST(SUM(monetary) * 100.0 / NULLIF(SUM(SUM(monetary)) OVER (), 0) AS DECIMAL(6,2)) AS share_revenue_pct
FROM dbo.vw_RFM_CustomerScores
GROUP BY
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score <= 2 THEN 'New Customers'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score <= 2 THEN 'Potential Loyalists'
        WHEN R_score <= 2 AND F_score >= 4 AND M_score >= 3 THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2 THEN 'Hibernating'
        WHEN R_score <= 1 AND F_score >= 3 THEN 'Lost'
        WHEN M_score >= 4 AND F_score <= 2 THEN 'Promising'
        ELSE 'Need Attention'
    END;
GO

-- =============================================================================
-- SECTION 10: COHORT ANALYSIS (Customer Retention)
-- =============================================================================

-- Customer first-purchase cohort
CREATE OR ALTER VIEW dbo.vw_Cohort_FirstPurchases AS
SELECT
    customer_id,
    MIN(transaction_date) AS first_purchase_date,
    DATEFROMPARTS(YEAR(MIN(transaction_date)), MONTH(MIN(transaction_date)), 1) AS cohort_month
FROM dbo.FactTransactions
GROUP BY customer_id;
GO

-- Cohort retention matrix
CREATE OR ALTER VIEW dbo.vw_Cohort_Retention AS
WITH CustomerCohort AS (
    SELECT
        c.cohort_month,
        f.transaction_date,
        DATEDIFF(MONTH, c.cohort_month, DATEFROMPARTS(YEAR(f.transaction_date), MONTH(f.transaction_date), 1)) AS cohort_index,
        f.customer_id
    FROM dbo.FactTransactions f
    JOIN dbo.vw_Cohort_FirstPurchases c ON f.customer_id = c.customer_id
),
CohortCounts AS (
    SELECT cohort_month, cohort_index, COUNT(DISTINCT customer_id) AS customers
    FROM CustomerCohort
    GROUP BY cohort_month, cohort_index
),
CohortSizes AS (
    SELECT cohort_month, MAX(customers) AS cohort_size
    FROM CohortCounts
    WHERE cohort_index = 0
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    c.cohort_index,
    c.customers AS active_customers,
    s.cohort_size,
    CAST(c.customers * 100.0 / NULLIF(s.cohort_size, 0) AS DECIMAL(6,2)) AS retention_pct
FROM CohortCounts c
JOIN CohortSizes s ON c.cohort_month = s.cohort_month;
GO

-- =============================================================================
-- SECTION 11: ANOMALY DETECTION & KPI FLAGS
-- =============================================================================

-- Daily revenue with z-scores (anomaly detection)
CREATE OR ALTER VIEW dbo.vw_Trends_DailyAnomalies AS
WITH Daily AS (
    SELECT
        transaction_date AS txn_date,
        SUM(total_amount) AS daily_revenue
    FROM dbo.FactTransactions
    GROUP BY transaction_date
),
Stats AS (
    SELECT
        AVG(daily_revenue) AS mean_rev,
        STDEVP(daily_revenue) AS std_rev
    FROM Daily
)
SELECT
    d.txn_date,
    d.daily_revenue,
    CAST((d.daily_revenue - s.mean_rev) / NULLIF(s.std_rev, 0) AS DECIMAL(10,4)) AS z_score,
    CASE
        WHEN ABS((d.daily_revenue - s.mean_rev) / NULLIF(s.std_rev, 0)) > 2.5 THEN 'ANOMALY'
        ELSE 'Normal'
    END AS status
FROM Daily d
CROSS JOIN Stats s;
GO

-- KPI Status Dashboard with Red/Yellow/Green flags
CREATE OR ALTER VIEW dbo.vw_Trends_KPIFlags AS
SELECT
    'Profit Margin' AS KPI,
    CAST(SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) AS DECIMAL(6,2)) AS value,
    'pct' AS unit,
    CASE
        WHEN SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) >= 30 THEN 'GREEN'
        WHEN SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) >= 25 THEN 'YELLOW'
        ELSE 'RED'
    END AS status
FROM dbo.FactTransactions
UNION ALL
SELECT
    'AOV',
    CAST(AVG(total_amount) AS DECIMAL(10,2)),
    'USD',
    CASE
        WHEN AVG(total_amount) >= 90 THEN 'GREEN'
        WHEN AVG(total_amount) >= 80 THEN 'YELLOW'
        ELSE 'RED'
    END
FROM dbo.FactTransactions
UNION ALL
SELECT
    'Avg Discount %',
    CAST(AVG(discount_percent) AS DECIMAL(6,2)),
    'pct',
    CASE
        WHEN AVG(discount_percent) <= 10 THEN 'GREEN'
        WHEN AVG(discount_percent) <= 15 THEN 'YELLOW'
        ELSE 'RED'
    END
FROM dbo.FactTransactions;
GO

-- =============================================================================
-- SECTION 12: STORED PROCEDURES
-- =============================================================================

-- Procedure: Get full executive KPI dashboard
CREATE OR ALTER PROCEDURE dbo.sp_ExecutiveDashboard
AS
BEGIN
    SET NOCOUNT ON;
    -- Headline KPIs
    SELECT 'Headline KPIs' AS section, * FROM dbo.vw_KPIs_Headline;
    -- Yearly comparison
    SELECT 'Yearly Comparison' AS section, * FROM dbo.vw_KPIs_Yearly;
    -- YoY growth
    SELECT 'YoY Growth' AS section, * FROM dbo.vw_KPIs_YoYGrowth;
    -- Top regions
    SELECT 'Regional Performance' AS section, * FROM dbo.vw_Performance_ByRegion;
    -- Top categories
    SELECT 'Top Categories' AS section, * FROM dbo.vw_Performance_TopCategories;
    -- Department breakdown
    SELECT 'Department Performance' AS section, * FROM dbo.vw_Performance_ByDepartment;
END;
GO

-- Procedure: Get RFM report
CREATE OR ALTER PROCEDURE dbo.sp_RFMReport
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 'RFM Segments' AS section, * FROM dbo.vw_RFM_Segments ORDER BY total_revenue DESC;
END;
GO

-- Procedure: Get anomaly alerts
CREATE OR ALTER PROCEDURE dbo.sp_AnomalyAlerts
AS
BEGIN
    SET NOCOUNT ON;
    SELECT txn_date, daily_revenue, z_score, status
    FROM dbo.vw_Trends_DailyAnomalies
    WHERE status = 'ANOMALY'
    ORDER BY ABS(z_score) DESC;
END;
GO

-- =============================================================================
-- SECTION 13: USAGE EXAMPLES (Run these to query the analysis)
-- =============================================================================

/*
-- Example 1: Get headline KPIs
SELECT * FROM dbo.vw_KPIs_Headline;

-- Example 2: Get yearly comparison
SELECT * FROM dbo.vw_KPIs_Yearly;

-- Example 3: Get revenue by region (ranked)
SELECT *, RANK() OVER (ORDER BY revenue DESC) AS rank
FROM dbo.vw_Performance_ByRegion;

-- Example 4: Get top 10 product categories
SELECT * FROM dbo.vw_Performance_TopCategories;

-- Example 5: Get monthly trend
SELECT * FROM dbo.vw_TimeSeries_Monthly ORDER BY year, month;

-- Example 6: Get RFM segments
SELECT * FROM dbo.vw_RFM_Segments ORDER BY total_revenue DESC;

-- Example 7: Get cohort retention heatmap data
SELECT cohort_month, cohort_index, active_customers, retention_pct
FROM dbo.vw_Cohort_Retention
ORDER BY cohort_month, cohort_index;

-- Example 8: Get anomaly alerts
EXEC dbo.sp_AnomalyAlerts;

-- Example 9: Get full executive dashboard
EXEC dbo.sp_ExecutiveDashboard;

-- Example 10: Get discount tier analysis
SELECT * FROM dbo.vw_Promo_DiscountTierImpact ORDER BY discount_tier;

-- Example 11: YoY monthly growth using LAG
WITH Monthly AS (
    SELECT
        YEAR(transaction_date) AS yr,
        MONTH(transaction_date) AS mo,
        SUM(total_amount) AS revenue
    FROM dbo.FactTransactions
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
)
SELECT
    yr, mo, revenue,
    LAG(revenue, 12) OVER (ORDER BY yr, mo) AS prev_yr_revenue,
    CAST((revenue - LAG(revenue, 12) OVER (ORDER BY yr, mo)) * 100.0
         / NULLIF(LAG(revenue, 12) OVER (ORDER BY yr, mo), 0) AS DECIMAL(10,2)) AS yoy_growth_pct
FROM Monthly
ORDER BY yr, mo;

-- Example 12: Discount impact on profit using CASE for tiering
SELECT
    CASE
        WHEN discount_percent = 0 THEN '0%'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        WHEN discount_percent <= 30 THEN '21-30%'
        ELSE '31-50%'
    END AS discount_tier,
    COUNT(*) AS txn_count,
    SUM(gross_profit) AS total_profit,
    AVG(gross_profit) AS avg_profit_per_txn,
    CAST(SUM(gross_profit) * 100.0 / NULLIF(SUM(total_amount), 0) AS DECIMAL(10,2)) AS margin_pct
FROM dbo.FactTransactions
GROUP BY
    CASE
        WHEN discount_percent = 0 THEN '0%'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        WHEN discount_percent <= 30 THEN '21-30%'
        ELSE '31-50%'
    END
ORDER BY discount_tier;
*/

-- =============================================================================
-- END OF SCRIPT
-- =============================================================================
