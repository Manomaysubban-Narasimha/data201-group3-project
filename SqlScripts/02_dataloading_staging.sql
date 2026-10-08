-- =====================================================================
-- STEP 3 - Load the four raw files into the staging tables
--
-- Before running: copy amazon-purchases.csv, survey.csv, state.txt and NST-EST2023-ALLDATA.csv
-- into MySQL's upload folder: C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\
-- Check the folder with:   SELECT @@secure_file_priv;
-- =====================================================================
USE amazon_ecommerce;

-- 3a. State codes: 57 rows (50 states, DC, Puerto Rico and 5 other territories)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/state.txt'
INTO TABLE stg_census_codes
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;