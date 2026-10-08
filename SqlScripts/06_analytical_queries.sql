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
