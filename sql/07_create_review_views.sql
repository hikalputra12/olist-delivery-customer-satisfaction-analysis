-- Select the latest answered review for each order
CREATE OR REPLACE VIEW analytics.latest_order_reviews AS
SELECT
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM (
    SELECT
        review_id,
        order_id,
        review_score,
        review_creation_date,
        review_answer_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_answer_timestamp DESC
        ) AS row_num
    FROM raw.reviews
) AS ranked_reviews
WHERE row_num = 1;