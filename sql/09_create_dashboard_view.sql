CREATE OR REPLACE VIEW analytics.delivery_review_dashboard AS
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date
        AS purchase_month,

    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    CASE
        WHEN o.order_delivered_customer_date::date
             > o.order_estimated_delivery_date::date
            THEN 'Late'
        ELSE 'On-time'
    END AS delivery_status,

    o.order_delivered_customer_date::date
        - o.order_estimated_delivery_date::date
        AS days_vs_estimate,

    r.review_score,
    r.review_answer_timestamp,

    CASE
        WHEN r.order_id IS NULL
            THEN 'No review'
        WHEN r.review_answer_timestamp
             < o.order_delivered_customer_date
            THEN 'Before delivery'
        ELSE 'At or after delivery'
    END AS review_timing

FROM analytics.orders_quality AS o
LEFT JOIN analytics.latest_order_reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.has_sequence_issue = FALSE;