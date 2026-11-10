-- 1. Check order ID uniqueness and completeness
SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS non_null_order_ids,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM raw.orders;


-- 2. Check delivery date completeness for delivered orders
SELECT
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_actual_date,
    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_date
FROM raw.orders
WHERE order_status = 'delivered';


-- 3. Inspect delivered orders without an actual delivery date
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 4. Check missing carrier dates for delivered orders
SELECT
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_date,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
    ) AS missing_carrier_but_delivery_dates_available
FROM raw.orders
WHERE order_status = 'delivered';

-- 5. Check deliveries recorded before purchase
SELECT
    COUNT(*) AS delivered_before_purchase
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date
      < order_purchase_timestamp;


-- 6. Check customer delivery recorded before carrier handoff
SELECT
    COUNT(*) AS delivered_before_carrier_handoff
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date
      < order_delivered_carrier_date;


-- 7. Inspect deliveries recorded before carrier handoff
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_delivered_carrier_date
        - order_delivered_customer_date AS time_difference
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date
      < order_delivered_carrier_date
ORDER BY time_difference DESC;

-- 8. Check carrier handoff recorded before purchase
SELECT
    COUNT(*) AS carrier_handoff_before_purchase
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date
      < order_purchase_timestamp;

      
-- 9. Inspect carrier handoffs recorded before purchase
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_purchase_timestamp
        - order_delivered_carrier_date AS time_difference
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date
      < order_purchase_timestamp
ORDER BY time_difference DESC
LIMIT 5;


-- 10. Summarize timestamp sequence issues
SELECT
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date
            < order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
            < order_delivered_carrier_date
    ) AS customer_before_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
            < order_purchase_timestamp
    ) AS customer_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date
                  < order_purchase_timestamp
           OR order_delivered_customer_date
                  < order_delivered_carrier_date
           OR order_delivered_customer_date
                  < order_purchase_timestamp
    ) AS orders_with_sequence_issue
FROM raw.orders
WHERE order_status = 'delivered';


-- 11. Check purchase date coverage in the raw dataset
SELECT
    MIN(order_purchase_timestamp) AS first_purchase,
    MAX(order_purchase_timestamp) AS last_purchase,
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_date
FROM raw.orders;

-- 12. Check monthly order coverage by delivery status
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date
        AS purchase_month,

    COUNT(*) AS all_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders

FROM raw.orders
GROUP BY 1
ORDER BY 1;


-- 13. Inspect statuses of September–October 2018 orders
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date
        AS purchase_month,
    order_status,
    COUNT(*) AS total_orders
FROM raw.orders
WHERE order_purchase_timestamp >= TIMESTAMP '2018-09-01'
  AND order_purchase_timestamp < TIMESTAMP '2018-11-01'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;