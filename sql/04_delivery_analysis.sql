-- 1. Count orders by delivery status
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL
          OR order_estimated_delivery_date IS NULL
            THEN 'Unknown'
        WHEN order_delivered_customer_date::date
             > order_estimated_delivery_date::date
            THEN 'Late'
        ELSE 'On-time'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM analytics.orders_quality
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY total_orders DESC;


-- 2. Calculate the baseline late delivery rate
SELECT
    COUNT(*) AS eligible_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date::date
            > order_estimated_delivery_date::date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date::date
                > order_estimated_delivery_date::date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM analytics.orders_quality
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- 3. Compare results by timestamp sequence quality
SELECT
    has_sequence_issue,
    COUNT(*) AS eligible_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date::date
            > order_estimated_delivery_date::date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date::date
                > order_estimated_delivery_date::date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM analytics.orders_quality
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY has_sequence_issue
ORDER BY has_sequence_issue;


-- 4. Monthly late delivery rate by purchase month
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date
        AS purchase_month,
    COUNT(*) AS eligible_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date::date
            > order_estimated_delivery_date::date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date::date
                > order_estimated_delivery_date::date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM analytics.orders_quality
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND has_sequence_issue = FALSE
GROUP BY 1
ORDER BY 1;