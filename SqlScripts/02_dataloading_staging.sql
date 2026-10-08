-- STEP 2 - Load the four raw files into the staging tables

USE amazon_ecommerce;

-- 2a. State codes: 57 rows (50 states, DC, Puerto Rico and 5 other territories)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/state.txt'
INTO TABLE stg_census_codes
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;