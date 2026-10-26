CREATE SCHEMA IF NOT EXISTS analytics;

CREATE OR REPLACE VIEW analytics.orders_quality AS
SELECT
    *,
    order_delivered_customer_date IS NULL
        AS missing_actual_delivery_date,

    order_delivered_carrier_date IS NULL
        AS missing_carrier_date,

    CASE
        WHEN order_delivered_carrier_date
                 < order_purchase_timestamp
          OR order_delivered_customer_date
                 < order_delivered_carrier_date
          OR order_delivered_customer_date
                 < order_purchase_timestamp
        THEN TRUE
        ELSE FALSE
    END AS has_sequence_issue

FROM raw.orders;