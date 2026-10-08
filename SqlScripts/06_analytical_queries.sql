-- STEP 6 - Analytical queries: analyze the normalized data


USE amazon_ecommerce;   -- the database from step 1: if you renamed it there, use the same name here

-- ---------------------------------------------------------------------
-- Sales over time
-- ---------------------------------------------------------------------

-- @Q01 | Basic | GROUP BY + aggregates |
-- How much did customers spend each year, and how much per active customer per month?
SELECT YEAR(order_date)                      AS order_year,
       COUNT(DISTINCT MONTH(order_date))     AS months_in_data,
       COUNT(*)                              AS purchase_lines,
       ROUND(SUM(unit_price * quantity), 2)  AS spend_usd,
       COUNT(DISTINCT response_id)           AS active_customers,
       ROUND(SUM(unit_price * quantity) / COUNT(DISTINCT response_id)
             / COUNT(DISTINCT MONTH(order_date)), 2) AS monthly_spend_per_active_customer
FROM v_study_purchase
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- @Q02 | Basic | GROUP BY + ORDER BY |
-- In an average year, which calendar months bring the most spending?
SELECT MONTH(order_date)                     AS month_no,
       COUNT(DISTINCT YEAR(order_date))      AS years_in_data,   -- November and December: 2018-2021 only
       ROUND(SUM(unit_price * quantity) / COUNT(DISTINCT YEAR(order_date)), 2) AS avg_spend_per_year_usd,
       ROUND(AVG(unit_price), 2)             AS avg_unit_price
FROM v_study_purchase
GROUP BY MONTH(order_date)
ORDER BY avg_spend_per_year_usd DESC;

-- @Q03 | M1 | Advanced | CTE + self-join + correlated subquery |
-- Comparing the same months (January to October) each year, how fast did spending grow?
WITH jan_oct AS (                           
  SELECT YEAR(order_date) AS order_year,
         SUM(unit_price * quantity) AS spend
  FROM v_study_purchase
  WHERE MONTH(order_date) <= 10
  GROUP BY YEAR(order_date)
)
SELECT cur.order_year,
       ROUND(cur.spend, 2) AS jan_oct_spend_usd,
       ROUND(100 * (cur.spend / prev.spend - 1), 1) AS yoy_growth_pct,      
       ROUND((SELECT SUM(j.spend) FROM jan_oct j
              WHERE j.order_year <= cur.order_year), 2) AS cumulative_jan_oct_spend_usd
FROM jan_oct cur
LEFT JOIN jan_oct prev ON prev.order_year = cur.order_year - 1   
ORDER BY cur.order_year;

-- @Q04 | Advanced | CTEs + correlated subqueries |
-- What was the peak month each year, and how far above the previous three months was it?
WITH monthly AS (
  SELECT YEAR(order_date)  AS order_year,
         MONTH(order_date) AS order_month,
         SUM(unit_price * quantity) AS spend
  FROM v_study_purchase
  GROUP BY YEAR(order_date), MONTH(order_date)
),
numbered AS (
  SELECT order_year, order_month, spend,
         order_year * 12 + order_month AS month_number   -- consecutive months differ by 1, even across a new year
  FROM monthly
),
peaks AS (
  SELECT m.order_year, m.order_month, m.spend,
         (SELECT AVG(b.spend) FROM numbered b
          WHERE b.month_number BETWEEN m.month_number - 3 AND m.month_number - 1) AS prior_3_month_avg
  FROM numbered m
  WHERE m.spend = (SELECT MAX(x.spend) FROM numbered x WHERE x.order_year = m.order_year)  -- the year's best month
)
SELECT order_year,
       order_month AS peak_month,
       ROUND(spend, 2) AS spend_usd,
       ROUND(prior_3_month_avg, 2) AS prior_3_month_avg_usd,
       ROUND(100 * (spend / prior_3_month_avg - 1), 1) AS pct_above_prior_3_months
FROM peaks
ORDER BY order_year;

-------------------------------------------------------
-- Products and categories analytics queries

-- @Q05 | Basic | JOIN + GROUP BY + COALESCE + LIMIT | Which 10 product categories earn the most, and how many customers buy them?
SELECT COALESCE(p.category, 'UNKNOWN')         AS category,
       COUNT(*)                                AS purchase_lines,
       COUNT(DISTINCT pl.response_id)          AS customers,
       ROUND(SUM(pl.unit_price * pl.quantity), 2) AS spend_usd,
       ROUND(AVG(pl.unit_price), 2)            AS avg_unit_price
FROM v_study_purchase pl
JOIN product p ON p.asin = pl.asin
GROUP BY COALESCE(p.category, 'UNKNOWN')
ORDER BY spend_usd DESC
LIMIT 10;

-- @Q06 | Basic | CASE + GROUP BY | How are purchase lines and spend split across price bands?
SELECT CASE
         WHEN unit_price < 10  THEN '1. under $10'
         WHEN unit_price < 25  THEN '2. $10 - $24.99'
         WHEN unit_price < 50  THEN '3. $25 - $49.99'
         WHEN unit_price < 100 THEN '4. $50 - $99.99'
         ELSE                       '5. $100 and up'
       END                                   AS price_band,
       COUNT(*)                              AS purchase_lines,
       SUM(quantity)                         AS units,
       ROUND(SUM(unit_price * quantity), 2)  AS spend_usd
FROM v_study_purchase
GROUP BY price_band
ORDER BY price_band;

-- @Q07 | Advanced | CTEs + correlated COUNT subquery | Leaving out unknown and gift-card items, which 3 categories led each year, and what share did each take?
WITH category_year AS (
  SELECT YEAR(pl.order_date) AS order_year,
         p.category,
         SUM(pl.unit_price * pl.quantity) AS spend
  FROM v_study_purchase pl
  JOIN product p ON p.asin = pl.asin
  WHERE p.category IS NOT NULL                 -- unknown items are reported separately in Q05
    AND p.category NOT LIKE '%GIFT_CARD%'      -- gift cards are money, not a product type
  GROUP BY YEAR(pl.order_date), p.category
),
ranked AS (
  SELECT c.order_year, c.category, c.spend,
         1 + (SELECT COUNT(*) FROM category_year c2          -- rank = categories that sold more, plus one
              WHERE c2.order_year = c.order_year AND c2.spend > c.spend) AS rank_in_year,
         100 * c.spend / (SELECT SUM(c3.spend) FROM category_year c3
                          WHERE c3.order_year = c.order_year) AS share
  FROM category_year c
)
SELECT order_year, rank_in_year, category,
       ROUND(spend, 2) AS spend_usd,
       ROUND(share, 1) AS share_pct
FROM ranked
WHERE rank_in_year <= 3
ORDER BY order_year, rank_in_year;

-- @Q08 | Advanced | CTEs + CASE sums + scalar subqueries | Which categories gained the most share of spending in 2020, the first pandemic year?
WITH category_spend AS (
  SELECT COALESCE(p.category, 'UNKNOWN') AS category,
         SUM(CASE WHEN pl.order_date <  '2020-01-01' THEN pl.unit_price * pl.quantity ELSE 0 END) AS spend_2019,
         SUM(CASE WHEN pl.order_date >= '2020-01-01' THEN pl.unit_price * pl.quantity ELSE 0 END) AS spend_2020
  FROM v_study_purchase pl
  JOIN product p ON p.asin = pl.asin
  WHERE pl.order_date BETWEEN '2019-01-01' AND '2020-12-31'
  GROUP BY COALESCE(p.category, 'UNKNOWN')
),
shares AS (
  SELECT category, spend_2019, spend_2020,
         100 * spend_2019 / (SELECT SUM(spend_2019) FROM category_spend) AS share_2019,
         100 * spend_2020 / (SELECT SUM(spend_2020) FROM category_spend) AS share_2020
  FROM category_spend
)
SELECT category,
       ROUND(spend_2019, 2) AS spend_2019_usd,
       ROUND(spend_2020, 2) AS spend_2020_usd,
       ROUND(share_2019, 2) AS share_2019_pct,
       ROUND(share_2020, 2) AS share_2020_pct,
       ROUND(share_2020 - share_2019, 2) AS share_change_pts
FROM shares
ORDER BY share_change_pts DESC
LIMIT 10;