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

-- @Q09 | Manomay | Basic | JOIN + GROUP BY + ORDER BY CASE | How much does a customer spend per year in each income bracket?
SELECT c.income_bracket,
       COUNT(DISTINCT c.response_id)              AS customers,
       ROUND(SUM(pl.unit_price * pl.quantity), 2) AS spend_usd,
       -- 58 months in the study window; x 12 turns spend per month into spend per year
       ROUND(SUM(pl.unit_price * pl.quantity) / COUNT(DISTINCT c.response_id) / 58 * 12, 2) AS spend_per_customer_per_year
FROM customer c
JOIN v_study_purchase pl ON pl.response_id = c.response_id
GROUP BY c.income_bracket
ORDER BY CASE c.income_bracket                  -- income order, not alphabetical order
           WHEN 'Less than $25,000'   THEN 1
           WHEN '$25,000 - $49,999'   THEN 2
           WHEN '$50,000 - $74,999'   THEN 3
           WHEN '$75,000 - $99,999'   THEN 4
           WHEN '$100,000 - $149,999' THEN 5
           WHEN '$150,000 or more'    THEN 6
           ELSE 7
         END;

-- @Q10 | Manomay | Basic | JOIN + GROUP BY + COUNT(DISTINCT) | Do customers who say they order often really shop on more days?
SELECT c.order_frequency                       AS self_reported_frequency,
       COUNT(DISTINCT c.response_id)           AS customers,
       -- COUNT(DISTINCT customer, day) counts shopping days: several items on one day count once
       ROUND(COUNT(DISTINCT pl.response_id, pl.order_date) / COUNT(DISTINCT c.response_id) / 58, 2)
                                               AS actual_shopping_days_per_month,
       ROUND(SUM(pl.unit_price * pl.quantity) / COUNT(DISTINCT c.response_id) / 58 * 12, 2) AS spend_per_customer_per_year
FROM customer c
JOIN v_study_purchase pl ON pl.response_id = c.response_id
GROUP BY c.order_frequency
ORDER BY CASE c.order_frequency
           WHEN 'Less than 5 times per month'  THEN 1
           WHEN '5 - 10 times per month'       THEN 2
           ELSE 3
         END;

-- @Q11 | Manomay | Advanced | CTEs + correlated COUNT subquery + CASE | How concentrated is spending? What share comes from the top 10% of customers?
WITH customer_spend AS (
  SELECT response_id, SUM(unit_price * quantity) AS spend
  FROM v_study_purchase
  GROUP BY response_id
),
ranked AS (
  SELECT s.spend,
         1 + (SELECT COUNT(*) FROM customer_spend s2 WHERE s2.spend > s.spend) AS spend_rank   -- 1 = biggest spender
  FROM customer_spend s
),
grouped AS (
  SELECT spend,
         CASE WHEN spend_rank <= 0.1 * (SELECT COUNT(*) FROM customer_spend) THEN '1. top 10%'
              WHEN spend_rank <= 0.2 * (SELECT COUNT(*) FROM customer_spend) THEN '2. next 10%'
              WHEN spend_rank <= 0.5 * (SELECT COUNT(*) FROM customer_spend) THEN '3. next 30%'
              ELSE '4. bottom 50%'
         END AS customer_group
  FROM ranked
)
SELECT customer_group,
       COUNT(*)                 AS customers,
       ROUND(SUM(spend), 2)     AS spend_usd,
       ROUND(100 * SUM(spend) / (SELECT SUM(spend) FROM customer_spend), 1) AS share_of_spend_pct,
       ROUND(MIN(spend), 2)     AS lowest_customer_usd,
       ROUND(MAX(spend), 2)     AS highest_customer_usd
FROM grouped
GROUP BY customer_group
ORDER BY customer_group;

-- @Q12 | Manomay | Advanced | CTEs + correlated scalar subquery | In each age group, how many customers spend at least twice their group's average?
WITH customer_spend AS (
  SELECT c.response_id, c.age_group, SUM(pl.unit_price * pl.quantity) AS total_spend
  FROM customer c
  JOIN v_study_purchase pl ON pl.response_id = c.response_id
  GROUP BY c.response_id, c.age_group
),
age_group_avg AS (
  SELECT age_group,
         COUNT(*)         AS customers,
         AVG(total_spend) AS avg_spend,
         MAX(total_spend) AS top_spend
  FROM customer_spend
  GROUP BY age_group
)
SELECT a.age_group,
       a.customers,
       ROUND(a.avg_spend, 2) AS avg_total_spend_usd,
       (SELECT COUNT(*) FROM customer_spend s                  -- runs once per age group
        WHERE s.age_group = a.age_group AND s.total_spend >= 2 * a.avg_spend) AS heavy_buyers,
       ROUND(a.top_spend, 2) AS top_customer_usd
FROM age_group_avg a
ORDER BY a.age_group;

-- @Q13 | Kashif | Basic | 4-table LEFT JOIN + COALESCE + CASE | Where do orders ship? Spend by Census region of the shipping address.
SELECT COALESCE(r.region_name,
                CASE WHEN pl.ship_state_code IS NULL THEN 'Not shipped (digital / gift card)'
                     ELSE 'Puerto Rico (no Census region)' END) AS ship_region,
       COUNT(*)                                AS purchase_lines,
       COUNT(DISTINCT pl.response_id)          AS customers,
       ROUND(SUM(pl.unit_price * pl.quantity), 2) AS spend_usd
FROM v_study_purchase pl
LEFT JOIN state s           ON s.state_code  = pl.ship_state_code   -- LEFT JOIN keeps unshipped lines
LEFT JOIN census_division d ON d.division_id = s.division_id
LEFT JOIN census_region r   ON r.region_id   = d.region_id
GROUP BY ship_region
ORDER BY spend_usd DESC;

-- @Q14 | Kashif | Basic | JOIN + LEFT JOIN + CASE | Do customers who moved in 2021 ship outside their current state more often?
SELECT CASE WHEN lc.response_id IS NULL THEN 'Did not move in 2021' ELSE 'Moved in 2021' END AS customer_group,
       COUNT(DISTINCT c.response_id) AS customers,
       COUNT(*)                      AS shipped_lines,
       ROUND(100 * AVG(CASE WHEN pl.ship_state_code <> c.state_code THEN 1 ELSE 0 END), 1)
                                     AS pct_shipped_outside_current_state
FROM v_study_purchase pl
JOIN customer c ON c.response_id = pl.response_id
LEFT JOIN customer_life_change lc
       ON lc.response_id = c.response_id AND lc.life_change = 'Moved place of residence'
WHERE pl.ship_state_code IS NOT NULL
  AND c.state_code IS NOT NULL                 -- two respondents live outside the US
GROUP BY customer_group;

-- @Q15 | Kashif | Advanced | CTE + GROUP BY/HAVING + JOIN | When customers rebuy the same product, how many months pass between purchases?
WITH repeats AS (            -- one row per customer and product bought on two or more different days
  SELECT response_id, asin,
         COUNT(DISTINCT order_date) - 1 AS repeat_purchases,
         -- months from the first to the last purchase, counted by calendar month
         (YEAR(MAX(order_date)) * 12 + MONTH(MAX(order_date)))
           - (YEAR(MIN(order_date)) * 12 + MONTH(MIN(order_date))) AS months_first_to_last
  FROM v_study_purchase
  GROUP BY response_id, asin
  HAVING COUNT(DISTINCT order_date) >= 2
)
SELECT p.category,
       COUNT(DISTINCT r.response_id) AS repeat_customers,
       SUM(r.repeat_purchases)       AS repeat_purchases,
       -- the gaps between purchases add up to first-to-last, so this is the average gap
       ROUND(SUM(r.months_first_to_last) / SUM(r.repeat_purchases), 1) AS avg_months_between
FROM repeats r
JOIN product p ON p.asin = r.asin            -- aggregate first, then join (no fan-out)
WHERE p.category IS NOT NULL
GROUP BY p.category
HAVING SUM(r.repeat_purchases) >= 100
ORDER BY repeat_purchases DESC
LIMIT 10;

-- @Q16 | Kashif | Advanced | CTEs + CASE + EXISTS | Which customers are slipping? Share whose January-October 2022 spend fell by half or more versus the same months of 2019-2021.
WITH jan_oct AS (
  SELECT response_id,
         SUM(CASE WHEN order_date BETWEEN '2019-01-01' AND '2021-12-31' AND MONTH(order_date) <= 10
                  THEN unit_price * quantity ELSE 0 END) / 3                        AS avg_jan_oct_2019_2021,
         SUM(CASE WHEN order_date >= '2022-01-01' THEN unit_price * quantity ELSE 0 END) AS jan_oct_2022
  FROM v_study_purchase                      -- the view ends on 31 October 2022
  GROUP BY response_id
),
flagged AS (
  SELECT j.avg_jan_oct_2019_2021, j.jan_oct_2022,
         CASE WHEN j.jan_oct_2022 <= 0.5 * j.avg_jan_oct_2019_2021 THEN 1 ELSE 0 END AS slipping,
         CASE WHEN EXISTS (SELECT 1 FROM customer_life_change lc
                           WHERE lc.response_id = j.response_id AND lc.life_change = 'Lost a job')
              THEN 'Lost a job in 2021' ELSE 'No job loss reported' END AS customer_group
  FROM jan_oct j
  WHERE j.avg_jan_oct_2019_2021 > 0
)
SELECT customer_group,
       COUNT(*)                          AS customers,
       SUM(slipping)                     AS slipping_customers,
       ROUND(100 * AVG(slipping), 1)     AS pct_slipping,
       ROUND(AVG(avg_jan_oct_2019_2021), 2) AS avg_jan_oct_spend_2019_2021,
       ROUND(AVG(jan_oct_2022), 2)       AS avg_jan_oct_spend_2022
FROM flagged
GROUP BY customer_group;