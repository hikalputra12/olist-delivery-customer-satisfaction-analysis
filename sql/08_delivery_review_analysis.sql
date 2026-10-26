-- 1. Check review coverage in the main analysis population
SELECT
    COUNT(*) AS eligible_orders,
    COUNT(r.order_id) AS orders_with_review,
    COUNT(*) FILTER (
        WHERE r.order_id IS NULL
    ) AS orders_without_review
FROM analytics.orders_quality AS o
LEFT JOIN analytics.latest_order_reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.has_sequence_issue = FALSE;

  -- 2. Compare review scores by delivery status
SELECT
    CASE
        WHEN o.order_delivered_customer_date::date
             > o.order_estimated_delivery_date::date
            THEN 'Late'
        ELSE 'On-time'
    END AS delivery_status,

    COUNT(*) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.review_score <= 2
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct

FROM analytics.orders_quality AS o
INNER JOIN analytics.latest_order_reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.has_sequence_issue = FALSE

GROUP BY 1
ORDER BY 1;

-- 3. Check whether reviews were answered before delivery
SELECT
    COUNT(*) AS reviewed_orders,
    COUNT(*) FILTER (
        WHERE r.review_answer_timestamp
            < o.order_delivered_customer_date
    ) AS reviews_answered_before_delivery
FROM analytics.orders_quality AS o
INNER JOIN analytics.latest_order_reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.has_sequence_issue = FALSE;

-- 4. Compare scores using reviews answered at or after delivery
SELECT
    CASE
        WHEN o.order_delivered_customer_date::date
             > o.order_estimated_delivery_date::date
            THEN 'Late'
        ELSE 'On-time'
    END AS delivery_status,

    COUNT(*) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.review_score <= 2
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct

FROM analytics.orders_quality AS o
INNER JOIN analytics.latest_order_reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.has_sequence_issue = FALSE
  AND r.review_answer_timestamp
      >= o.order_delivered_customer_date

GROUP BY 1
ORDER BY 1;

  -- 5. Compare review scores by delivery status and review timing
SELECT
    CASE
        WHEN o.order_delivered_customer_date::date
             > o.order_estimated_delivery_date::date
            THEN 'Late'
        ELSE 'On-time'
    END AS delivery_status,

    CASE
        WHEN r.review_answer_timestamp
             < o.order_delivered_customer_date
            THEN 'Before delivery'
        ELSE 'At or after delivery'
    END AS review_timing,

    COUNT(*) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.review_score <= 2
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct

FROM analytics.orders_quality AS o
INNER JOIN analytics.latest_order_reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.has_sequence_issue = FALSE

GROUP BY 1, 2
ORDER BY 1, 2;