-- STEP 1 - Create the staging tables

USE amazon_ecommerce;

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

-- Filled in step 4: one flat row per state with its division and region
CREATE TABLE stg_census (
  state_code CHAR(2), state_name VARCHAR(40),
  division_id TINYINT UNSIGNED, division_name VARCHAR(30),
  region_id TINYINT UNSIGNED, region_name VARCHAR(20)
);

-- survey.csv: the 23 columns in file order, all as text
CREATE TABLE stg_survey (
  response_id         VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin,
  age_group           VARCHAR(100),
  hispanic_origin     VARCHAR(100),
  race_list           VARCHAR(255),   -- several answers in one cell, e.g. 'White or Caucasian,Asian'
  education           VARCHAR(100),
  income_bracket      VARCHAR(100),
  gender              VARCHAR(100),
  sexual_orientation  VARCHAR(100),
  state_name          VARCHAR(100),   -- a name such as 'California'; step 5 swaps it for the code
  account_sharing     VARCHAR(100),
  household_size      VARCHAR(100),
  order_frequency     VARCHAR(100),
  cigarettes          VARCHAR(100),
  marijuana           VARCHAR(100),
  alcohol             VARCHAR(100),
  diabetes            VARCHAR(100),
  wheelchair          VARCHAR(100),
  life_change_list    VARCHAR(255),   -- several answers in one cell
  sell_own_data       VARCHAR(100),
  sell_consumer_data  VARCHAR(100),
  small_biz_access    VARCHAR(100),
  census_use          VARCHAR(100),
  research_use        VARCHAR(100)
);

-- Filled in step 4: one row per (respondent, answer)
CREATE TABLE stg_survey_race (
  response_id VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin, race VARCHAR(100)
);
CREATE TABLE stg_survey_life_change (
  response_id VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin, life_change VARCHAR(100)
);