-- STEP 2 - Load the four raw files into the staging tables

USE amazon_ecommerce;

-- 2a. State codes: 57 rows (50 states, DC, Puerto Rico and 5 other territories)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/state.txt'
INTO TABLE stg_census_codes
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 2b. Census areas: keep the first 5 columns; @skip throws away the 55 population columns
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/NST-EST2023-ALLDATA.csv'
INTO TABLE stg_census_areas
CHARACTER SET latin1
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(sumlev, region, division, state_fips, name,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip);

-- 2c. Survey: one row per respondent, 23 columns in file order
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/survey.csv'
INTO TABLE stg_survey
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
 