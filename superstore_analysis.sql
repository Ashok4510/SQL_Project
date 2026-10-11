-- Retail Sales Profitability Analysis (MySQL 8)
-- Dataset: 9,994 sales records from a US retail store. One row = one sales record.
-- The data is one flat table: no order id, dates or product names.

-- ===== STEP 1: CREATE THE DATABASE AND TABLE =====
CREATE DATABASE IF NOT EXISTS superstore_project;
USE superstore_project;

DROP TABLE IF EXISTS superstore;
CREATE TABLE superstore (
    ship_mode     VARCHAR(20),
    segment       VARCHAR(20),
    country       VARCHAR(30),
    city          VARCHAR(50),
    state         VARCHAR(30),
    postal_code   INT,
    region        VARCHAR(15),
    category      VARCHAR(20),
    sub_category  VARCHAR(20),
    sales         DECIMAL(12,4),
    quantity      INT,
    discount      DECIMAL(4,2),
    profit        DECIMAL(12,4)
);

-- ===== STEP 2: LOAD THE CSV =====
-- Change the path to where data/SampleSuperstore.csv is on your computer.
-- If you get a local_infile error, run: SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/path/to/data/SampleSuperstore.csv'
INTO TABLE superstore
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- ===== ANALYSIS QUERIES =====
-- Margin = total profit / total sales (never an average of row margins).

-- 1. Overall performance
SELECT COUNT(*) AS records,
       ROUND(SUM(sales), 0) AS total_sales,
       ROUND(SUM(profit), 0) AS total_profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct,
       SUM(profit < 0) AS loss_making_records
FROM superstore;

-- 2. Category performance and share of total profit
SELECT category,
       ROUND(SUM(sales), 0) AS sales,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct,
       ROUND(100.0 * SUM(profit) / (SELECT SUM(profit) FROM superstore), 1) AS profit_share_pct
FROM superstore
GROUP BY category
ORDER BY profit DESC;

-- 3. Rank sub-categories by profit and by margin (window functions)
SELECT sub_category, sales, profit, margin_pct,
       RANK()       OVER (ORDER BY profit DESC)     AS profit_rank,
       DENSE_RANK() OVER (ORDER BY margin_pct DESC) AS margin_rank
FROM (
    SELECT sub_category,
           ROUND(SUM(sales), 0) AS sales,
           ROUND(SUM(profit), 0) AS profit,
           ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
    FROM superstore
    GROUP BY sub_category
) AS s
ORDER BY profit_rank;

-- 4. Loss-making sub-categories
SELECT sub_category,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore
GROUP BY sub_category
HAVING SUM(profit) < 0
ORDER BY profit;

-- 5. Profit by discount band
SELECT CASE WHEN discount = 0    THEN '0%'
            WHEN discount <= 0.1 THEN '1-10%'
            WHEN discount <= 0.2 THEN '11-20%'
            WHEN discount <= 0.3 THEN '21-30%'
            WHEN discount <= 0.5 THEN '31-50%'
            ELSE '51-80%' END AS discount_band,
       COUNT(*) AS records,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
       ROUND(100.0 * AVG(profit < 0), 1) AS loss_making_pct
FROM superstore
GROUP BY discount_band
ORDER BY MIN(discount);

-- 6. How much of the total loss comes from discounts above 20%?
SELECT ROUND(SUM(CASE WHEN discount > 0.2 THEN profit END), 0) AS profit_on_deep_discount_sales,
       ROUND(SUM(CASE WHEN profit < 0 THEN profit END), 0) AS total_loss,
       ROUND(100.0 * SUM(CASE WHEN discount > 0.2 AND profit < 0 THEN profit END)
                   / SUM(CASE WHEN profit < 0 THEN profit END), 1) AS pct_of_loss_from_deep_discounts
FROM superstore;

-- 7. Loss-making sub-categories with and without deep discounts
SELECT sub_category,
       CASE WHEN discount > 0.2 THEN 'deep discount (above 20%)' ELSE 'normal (20% or less)' END AS discount_type,
       COUNT(*) AS records,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM superstore
WHERE sub_category IN ('Tables', 'Bookcases', 'Supplies')
GROUP BY sub_category, discount_type
ORDER BY sub_category, discount_type;

-- 8. States that lose money, with their average discount
SELECT state,
       COUNT(*) AS records,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
       ROUND(AVG(discount), 3) AS avg_discount
FROM superstore
GROUP BY state
HAVING SUM(profit) < 0
ORDER BY profit;

-- 9. Region and category margin, with each cell's share of the region's profit (CTEs and a JOIN)
WITH region_category AS (
    SELECT region, category, SUM(sales) AS sales, SUM(profit) AS profit
    FROM superstore
    GROUP BY region, category
),
region_total AS (
    SELECT region, SUM(profit) AS region_profit
    FROM superstore
    GROUP BY region
)
SELECT rc.region, rc.category,
       ROUND(100.0 * rc.profit / rc.sales, 1) AS margin_pct,
       ROUND(100.0 * rc.profit / rt.region_profit, 1) AS pct_of_region_profit
FROM region_category rc
JOIN region_total rt ON rc.region = rt.region
ORDER BY rc.region, margin_pct DESC;

-- 10. What if the deep-discount sales (above 20%) had never happened?
SELECT ROUND(SUM(profit), 0) AS actual_profit,
       ROUND(SUM(CASE WHEN discount <= 0.2 THEN profit END), 0) AS profit_without_deep_discount_sales,
       ROUND(100.0 * (SUM(CASE WHEN discount <= 0.2 THEN profit END) - SUM(profit)) / SUM(profit), 1) AS profit_change_pct
FROM superstore;
