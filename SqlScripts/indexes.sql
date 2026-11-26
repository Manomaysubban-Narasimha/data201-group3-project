USE amazon_ecommerce;

-- Recording the pre-index execution plan and elapsed time before adding the proposed index.
SHOW INDEX FROM purchase_line;

EXPLAIN
SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';

EXPLAIN ANALYZE 
SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';

SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';



CREATE INDEX idx_pl_order_date_cover_spend
    ON purchase_line (order_date, response_id, unit_price, quantity);

SHOW INDEX FROM purchase_line;

EXPLAIN
SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';

EXPLAIN ANALYZE
SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';

SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';



-- After index creation, compare two plans on the same live database.
-- IGNORE INDEX approximates the unindexed access path; it is NOT a historical baseline.
EXPLAIN ANALYZE
SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line IGNORE INDEX (idx_pl_order_date_cover_spend)
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';

EXPLAIN ANALYZE
SELECT COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line FORCE INDEX (idx_pl_order_date_cover_spend)
WHERE order_date >= '2022-10-01'
  AND order_date < '2022-11-01';

-- Results must match even when MySQL chooses different access paths.
SELECT 'without_candidate' AS access_path,
       COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line IGNORE INDEX (idx_pl_order_date_cover_spend)
WHERE order_date >= '2022-10-01' AND order_date < '2022-11-01'
UNION ALL
SELECT 'with_candidate' AS access_path,
       COUNT(*) AS purchase_lines,
       COUNT(DISTINCT response_id) AS customers,
       ROUND(SUM(unit_price * quantity), 2) AS spend_usd
FROM purchase_line FORCE INDEX (idx_pl_order_date_cover_spend)
WHERE order_date >= '2022-10-01' AND order_date < '2022-11-01';