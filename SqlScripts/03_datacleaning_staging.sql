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

-- ---------------------------------------------------------------------
-- 3c. 1NF: one row per answer. A cell 'White or Caucasian,Asian' becomes two rows.
--     Each list is joined to the allowed answers (the same values as the CHECK
--     constraints in ../sql/01_schema.sql), written as a small table with UNION ALL (Lecture 7).
-- ---------------------------------------------------------------------
INSERT INTO stg_survey_race (response_id, race)
SELECT s.response_id, a.race
FROM stg_survey s
JOIN (SELECT 'White or Caucasian' AS race
      UNION ALL SELECT 'Black or African American'
      UNION ALL SELECT 'Asian'
      UNION ALL SELECT 'American Indian/Native American or Alaska Native'
      UNION ALL SELECT 'Native Hawaiian or Other Pacific Islander'
      UNION ALL SELECT 'Other') AS a
  ON FIND_IN_SET(a.race, s.race_list) > 0;

INSERT INTO stg_survey_life_change (response_id, life_change)
SELECT s.response_id, a.life_change
FROM stg_survey s
JOIN (SELECT 'Moved place of residence' AS life_change
      UNION ALL SELECT 'Lost a job'
      UNION ALL SELECT 'Had a child'
      UNION ALL SELECT 'Became pregnant'
      UNION ALL SELECT 'Divorce') AS a
  ON FIND_IN_SET(a.life_change, s.life_change_list) > 0;

-- Check that no answer was lost: every item in a list must have matched an allowed answer.
-- Items in a list = commas + 1, so both columns of each row must be equal: 5,329 for race, 2,055 for life change.
SELECT 'race' AS answers,
       (SELECT COUNT(*) FROM stg_survey_race) AS rows_made,
       (SELECT SUM(LENGTH(race_list) - LENGTH(REPLACE(race_list, ',', '')) + 1)
        FROM stg_survey WHERE race_list IS NOT NULL) AS items_in_lists
UNION ALL
SELECT 'life change',
       (SELECT COUNT(*) FROM stg_survey_life_change),
       (SELECT SUM(LENGTH(life_change_list) - LENGTH(REPLACE(life_change_list, ',', '')) + 1)
        FROM stg_survey WHERE life_change_list IS NOT NULL);