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

