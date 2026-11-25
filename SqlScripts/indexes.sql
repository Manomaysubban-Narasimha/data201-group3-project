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