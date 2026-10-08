-- =====================================================================
-- STEP 2 - Create the staging tables (run after ../sql/01_schema.sql)
--
-- Staging tables are a landing area: the raw files go in exactly as they are, with no
-- primary keys on the data, no foreign keys and no CHECK rules. Cleaning (step 4) and
-- normalization (step 5) then happen inside MySQL with SQL.
--
-- IDs use ascii_bin and product text uses utf8mb4_bin, so comparisons are exact
-- ("B00A" is not "b00a"), the same as in the source files.
-- =====================================================================
USE project;

DROP TABLE IF EXISTS stg_census_codes, stg_census_areas, stg_census,
                     stg_survey, stg_survey_race, stg_survey_life_change, stg_purchase;

-- state.txt: one row per state code, e.g. 06 | CA | California | 01779778
CREATE TABLE stg_census_codes (
  state_fips   CHAR(2),
  state_code   CHAR(2),
  state_name   VARCHAR(40),
  statens      VARCHAR(10)
);

-- NST-EST2023-ALLDATA.csv: the first 5 of its 60 columns. SUMLEV says what a row is:
-- 010 = the nation, 020 = a region, 030 = a division, 040 = a state
CREATE TABLE stg_census_areas (
  sumlev       CHAR(3),
  region       CHAR(1),
  division     CHAR(1),
  state_fips   CHAR(2),
  name         VARCHAR(60)
);

