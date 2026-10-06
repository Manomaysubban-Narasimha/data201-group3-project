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