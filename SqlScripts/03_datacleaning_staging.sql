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

-- 3b. Survey: remove stray spaces ("Lost a job " -> "Lost a job") in every column

UPDATE stg_survey
SET response_id = TRIM(response_id), age_group = TRIM(age_group), hispanic_origin = TRIM(hispanic_origin), race_list = TRIM(race_list),
    education = TRIM(education), income_bracket = TRIM(income_bracket), gender = TRIM(gender),
    sexual_orientation = TRIM(sexual_orientation), state_name = TRIM(state_name),
    account_sharing = TRIM(account_sharing), household_size = TRIM(household_size),
    order_frequency = TRIM(order_frequency), cigarettes = TRIM(cigarettes), marijuana = TRIM(marijuana),
    alcohol = TRIM(alcohol), diabetes = TRIM(diabetes), wheelchair = TRIM(wheelchair),
    life_change_list = TRIM(life_change_list), sell_own_data = TRIM(sell_own_data),
    sell_consumer_data = TRIM(sell_consumer_data), small_biz_access = TRIM(small_biz_access),
    census_use = TRIM(census_use), research_use = TRIM(research_use);

-- Spaces can also sit next to the commas inside a list: 'Lost a job ,Divorce'
UPDATE stg_survey
SET race_list        = REPLACE(REPLACE(race_list, ' ,', ','), ', ', ','),
    life_change_list = REPLACE(REPLACE(life_change_list, ' ,', ','), ', ', ',');

UPDATE stg_survey SET race_list = NULL        WHERE race_list = '';
UPDATE stg_survey SET life_change_list = NULL WHERE life_change_list = '';   -- no life change reported