CREATE DATABASE IF NOT EXISTS amazon_ecommerce
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE amazon_ecommerce;

-- ---------- Reference tables (U.S. Census Bureau) ----------

CREATE TABLE census_region (
  region_id    TINYINT UNSIGNED NOT NULL,
  region_name  VARCHAR(20)      NOT NULL,
  CONSTRAINT pk_census_region PRIMARY KEY (region_id),
  CONSTRAINT uq_region_name UNIQUE (region_name)
);

CREATE TABLE census_division (
  division_id    TINYINT UNSIGNED NOT NULL,
  division_name  VARCHAR(30)      NOT NULL,
  region_id      TINYINT UNSIGNED NOT NULL,   -- division -> region (each division is in one region)
  CONSTRAINT pk_census_division PRIMARY KEY (division_id),
  CONSTRAINT uq_division_name UNIQUE (division_name),
  CONSTRAINT fk_division_region FOREIGN KEY (region_id) REFERENCES census_region (region_id)
);

CREATE TABLE state (
  state_code   CHAR(2) CHARACTER SET ascii NOT NULL,   -- USPS code, e.g. 'CA'
  state_name   VARCHAR(40)                 NOT NULL,
  division_id  TINYINT UNSIGNED            NULL,       -- NULL for Puerto Rico (no Census region)
  CONSTRAINT pk_state PRIMARY KEY (state_code),
  CONSTRAINT uq_state_name UNIQUE (state_name),
  CONSTRAINT fk_state_division FOREIGN KEY (division_id) REFERENCES census_division (division_id)
);

-- ---------- Customers (one survey respondent = one Amazon account holder) ----------

CREATE TABLE customer (
  response_id         VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  age_group           VARCHAR(20)  NOT NULL,
  hispanic_origin     VARCHAR(3)   NOT NULL,
  education           VARCHAR(80)  NOT NULL,
  income_bracket      VARCHAR(25)  NOT NULL,
  gender              VARCHAR(20)  NOT NULL,
  sexual_orientation  VARCHAR(30)  NOT NULL,
  state_code          CHAR(2) CHARACTER SET ascii NULL,   -- state of residence
  account_sharing     VARCHAR(15)  NOT NULL,   -- people sharing the Amazon account
  household_size      VARCHAR(15)  NOT NULL,
  order_frequency     VARCHAR(30)  NOT NULL,   -- self-reported deliveries per month
  cigarettes          VARCHAR(30)  NOT NULL,
  marijuana           VARCHAR(30)  NOT NULL,
  alcohol             VARCHAR(30)  NOT NULL,
  diabetes            VARCHAR(20)  NOT NULL,
  wheelchair          VARCHAR(20)  NOT NULL,
  sell_own_data       VARCHAR(40)  NOT NULL,
  sell_consumer_data  VARCHAR(45)  NOT NULL,
  small_biz_access    VARCHAR(15)  NOT NULL,
  census_use          VARCHAR(15)  NOT NULL,
  research_use        VARCHAR(15)  NOT NULL,
  CONSTRAINT pk_customer PRIMARY KEY (response_id),
  CONSTRAINT fk_customer_state FOREIGN KEY (state_code) REFERENCES state (state_code),
  CONSTRAINT chk_age_group CHECK (age_group IN
    ('18 - 24 years', '25 - 34 years', '35 - 44 years', '45 - 54 years', '55 - 64 years', '65 and older')),
  CONSTRAINT chk_hispanic CHECK (hispanic_origin IN ('Yes', 'No')),
  CONSTRAINT chk_education CHECK (education IN
    ('Some high school or less', 'High school diploma or GED', 'Bachelor''s degree',
     'Graduate or professional degree (MA, MS, MBA, PhD, JD, MD, DDS, etc)', 'Prefer not to say')),
  CONSTRAINT chk_income CHECK (income_bracket IN
    ('Less than $25,000', '$25,000 - $49,999', '$50,000 - $74,999', '$75,000 - $99,999',
     '$100,000 - $149,999', '$150,000 or more', 'Prefer not to say')),
  CONSTRAINT chk_gender CHECK (gender IN ('Female', 'Male', 'Other', 'Prefer not to say')),
  CONSTRAINT chk_account_sharing CHECK (account_sharing IN ('1 (just me!)', '2', '3', '4+')),
  CONSTRAINT chk_household_size CHECK (household_size IN ('1 (just me!)', '2', '3', '4+')),
  CONSTRAINT chk_order_frequency CHECK (order_frequency IN
    ('Less than 5 times per month', '5 - 10 times per month', 'More than 10 times per month'))
);