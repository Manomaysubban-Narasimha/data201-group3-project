-- STEP 3 - Clean the staging tables
--
-- Three small text functions are needed for cleaning
--   TRIM(x)               removes spaces at the start and end of x
--   REPLACE(x, a, b)      replaces every a inside x with b
--   FIND_IN_SET(a, list)  > 0 when a is one of the comma-separated items in list
USE amazon_ecommerce;  

-- Workbench's "safe update mode" refuses an UPDATE whose WHERE does not use a key.
-- Switch it off for this session only.
SET SQL_SAFE_UPDATES = 0;

-- 3a. Purchases: an empty cell came in as '' (empty text). Make it NULL, the missing value.
UPDATE stg_purchase SET ship_state = NULL WHERE ship_state = '';   
UPDATE stg_purchase SET title      = NULL WHERE title      = '';
UPDATE stg_purchase SET asin       = NULL WHERE asin       = '';   -- 973 rows; dropped in step 5
UPDATE stg_purchase SET category   = NULL WHERE category   = '';