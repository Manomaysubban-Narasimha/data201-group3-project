-- STEP 5 - Dataloading: move the data from staging into the 8 final tables
USE amazon_ecommerce;


-- 5a. Census tables (3NF). stg_census repeats "Pacific, West" for every Pacific state:
--     region depends on division, division on state (a transitive dependency).
--     SELECT DISTINCT pulls each fact out once.

INSERT INTO census_region (region_id, region_name)
SELECT DISTINCT region_id, region_name
FROM stg_census
WHERE region_id IS NOT NULL;                                   

INSERT INTO census_division (division_id, division_name, region_id)
SELECT DISTINCT division_id, division_name, region_id
FROM stg_census
WHERE division_id IS NOT NULL;                                 

INSERT INTO state (state_code, state_name, division_id)
SELECT state_code, state_name, division_id
FROM stg_census;                                               


-- 5b. Customers: one row per respondent. The survey stores the state as a name; the LEFT JOIN
--     (Lecture 6) swaps it for the code. The 2 people living outside the US match no state and
--     get NULL instead of being lost.
INSERT INTO customer (response_id, age_group, hispanic_origin, education, income_bracket, gender,
                      sexual_orientation, account_sharing, household_size, order_frequency,
                      cigarettes, marijuana, alcohol, diabetes, wheelchair, sell_own_data,
                      sell_consumer_data, small_biz_access, census_use, research_use, state_code)
SELECT s.response_id, s.age_group, s.hispanic_origin, s.education, s.income_bracket, s.gender,
       s.sexual_orientation, s.account_sharing, s.household_size, s.order_frequency,
       s.cigarettes, s.marijuana, s.alcohol, s.diabetes, s.wheelchair, s.sell_own_data,
       s.sell_consumer_data, s.small_biz_access, s.census_use, s.research_use, st.state_code
FROM stg_survey s
LEFT JOIN state st ON st.state_name = s.state_name;            -- 5,027 rows

-- 5c. Race and life changes (1NF): already one answer per row in staging.
--     DISTINCT would drop an answer given twice.
INSERT INTO customer_race (response_id, race)
SELECT DISTINCT response_id, race
FROM stg_survey_race;                                          -- 5,329 rows

INSERT INTO customer_life_change (response_id, life_change)
SELECT DISTINCT response_id, life_change
FROM stg_survey_life_change;                                   -- 2,055 rows

-- 5d. Products (2NF/3NF): title and category depend on the product (asin), not on the purchase.
--     Amazon renames listings, so asin -> title fails for 3.1% of products. Rule: keep each
--     product's latest non-empty title (the newest date, then the later row in the file), and the
--     same for the category. Only purchase rows we keep count.
INSERT INTO product (asin, title, category)
WITH title_day AS (            -- each product's newest purchase date that has a title
  SELECT asin, MAX(order_date) AS last_day
  FROM stg_purchase
  WHERE asin IS NOT NULL AND order_date <= '2023-03-31' AND title IS NOT NULL
  GROUP BY asin
),
title_row AS (                 -- on that date, the last such row in the file
  SELECT s.asin, MAX(s.line_id) AS line_id
  FROM stg_purchase s
  JOIN title_day d ON d.asin = s.asin AND d.last_day = s.order_date
  WHERE s.title IS NOT NULL
  GROUP BY s.asin
),
category_day AS (              -- the same two steps for the category
  SELECT asin, MAX(order_date) AS last_day
  FROM stg_purchase
  WHERE asin IS NOT NULL AND order_date <= '2023-03-31' AND category IS NOT NULL
  GROUP BY asin
),
category_row AS (
  SELECT s.asin, MAX(s.line_id) AS line_id
  FROM stg_purchase s
  JOIN category_day d ON d.asin = s.asin AND d.last_day = s.order_date
  WHERE s.category IS NOT NULL
  GROUP BY s.asin
),
products AS (                  -- every product code we keep, once
  SELECT DISTINCT asin FROM stg_purchase WHERE asin IS NOT NULL AND order_date <= '2023-03-31'
)
SELECT p.asin, t.title, c.category
FROM products p
LEFT JOIN title_row tr    ON tr.asin = p.asin
LEFT JOIN stg_purchase t  ON t.line_id = tr.line_id
LEFT JOIN category_row cr ON cr.asin = p.asin
LEFT JOIN stg_purchase c  ON c.line_id = cr.line_id;          -- 939,072 rows


-- 5e. Purchase lines: what is left of each row. The only step that removes rows.
INSERT INTO purchase_line (line_id, response_id, asin, order_date, unit_price, quantity, ship_state_code)
SELECT line_id, response_id, asin, order_date, unit_price, quantity, ship_state
FROM stg_purchase
WHERE asin IS NOT NULL                 -- 973 rows without a product code cannot point to a product
  AND order_date <= '2023-03-31';      -- 18 rows dated after data collection ended (20 March 2023)
                                       -- 1,849,726 rows

-- Fresh statistics for the query optimizer after loading
ANALYZE TABLE census_region, census_division, state, customer, customer_race,
              customer_life_change, product, purchase_line;

-- Check: nothing lost between staging and the final tables (each pair must be equal)
SELECT (SELECT COUNT(*) FROM stg_purchase WHERE asin IS NOT NULL AND order_date <= '2023-03-31') AS staged_rows_to_keep,
       (SELECT COUNT(*) FROM purchase_line) AS purchase_lines,
       (SELECT SUM(unit_price * quantity) FROM stg_purchase
        WHERE asin IS NOT NULL AND order_date <= '2023-03-31') AS staged_spend_usd,
       (SELECT SUM(unit_price * quantity) FROM purchase_line) AS loaded_spend_usd,
       (SELECT COUNT(*) FROM stg_survey) AS survey_rows,
       (SELECT COUNT(*) FROM customer) AS customers;