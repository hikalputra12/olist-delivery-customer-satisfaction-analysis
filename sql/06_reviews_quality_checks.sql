-- 1. Check review and order ID uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(review_id) AS non_null_review_ids,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(order_id) AS non_null_order_ids,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM raw.reviews;

-- 2. Inspect orders with multiple review rows
SELECT
    order_id,
    COUNT(*) AS review_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score,
    MIN(review_answer_timestamp) AS first_answer,
    MAX(review_answer_timestamp) AS last_answer
FROM raw.reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_rows DESC, order_id
LIMIT 10;

-- 3. Summarize orders with multiple review rows
WITH reviews_per_order AS (
    SELECT
        order_id,
        COUNT(*) AS review_rows,
        COUNT(DISTINCT review_score) AS distinct_scores
    FROM raw.reviews
    GROUP BY order_id
)
SELECT
    COUNT(*) FILTER (
        WHERE review_rows > 1
    ) AS orders_with_multiple_reviews,

    COUNT(*) FILTER (
        WHERE review_rows > 1
          AND distinct_scores > 1
    ) AS orders_with_different_scores,

    MAX(review_rows) AS max_reviews_per_order
FROM reviews_per_order;

-- 4. Check review score validity
SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM raw.reviews
GROUP BY review_score
ORDER BY review_score NULLS LAST;

-- 5. Check review timestamp completeness
SELECT
    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS missing_answer_timestamp,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS missing_creation_date

FROM raw.reviews;