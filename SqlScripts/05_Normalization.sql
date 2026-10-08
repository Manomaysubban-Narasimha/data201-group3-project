-- =====================================================================
-- STEP 5 - Normalize: move the data from staging into the 8 final tables
-- =====================================================================
USE amazon_ecommerce;

-- ---------------------------------------------------------------------
-- 5a. Census tables (3NF). stg_census repeats "Pacific, West" for every Pacific state:
--     region depends on division, division on state (a transitive dependency).
--     SELECT DISTINCT pulls each fact out once.
-- ---------------------------------------------------------------------
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


