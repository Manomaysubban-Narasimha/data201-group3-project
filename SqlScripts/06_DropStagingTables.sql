-- =====================================================================
-- STEP 6 - Remove the staging tables
-- =====================================================================
USE amazon_ecommerce;  
DROP TABLE IF EXISTS stg_census_codes, stg_census_areas, stg_census,
                     stg_survey, stg_survey_race, stg_survey_life_change, stg_purchase;

SHOW TABLES;
