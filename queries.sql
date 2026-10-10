
-- ============================================================
-- OLIST KPI PROJECT
-- CLEAN AND RELOAD FINAL TABLES
-- Source data in stg_* tables remains unchanged.
-- ============================================================

PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

-- 1. Clear final tables in child-to-parent order.
DELETE FROM order_reviews;
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM products;
DELETE FROM category_translation;
DELETE FROM sellers;
DELETE FROM customers;

-- 2. Load customers.
INSERT INTO customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM stg_customers;

-- 3. Load sellers.
INSERT INTO sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg_sellers;

-- 4. Load available category translations.
INSERT INTO category_translation (
    product_category_name,
    product_category_name_english
)
SELECT
    product_category_name,
    product_category_name_english
FROM stg_category_translation
WHERE product_category_name IS NOT NULL;

-- 5. Add product categories missing from the translation table.
INSERT INTO category_translation (
    product_category_name,
    product_category_name_english
)
SELECT DISTINCT
    p.product_category_name,
    NULL
FROM stg_products AS p
LEFT JOIN category_translation AS c
    ON c.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND c.product_category_name IS NULL;

-- 6. Load products.
INSERT INTO products (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM stg_products;

-- 7. Load orders.
INSERT INTO orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM stg_orders;

-- 8. Load order items.
INSERT INTO order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM stg_order_items;

-- 9. Load every review row.
-- ROW_NUMBER creates unique review IDs when the source ID repeats.
INSERT INTO order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    CASE
        WHEN COUNT(*) OVER (PARTITION BY review_id) = 1
            THEN review_id
        ELSE review_id || '__' ||
             ROW_NUMBER() OVER (
                 PARTITION BY review_id
                 ORDER BY order_id, review_creation_date,
                          review_answer_timestamp
             )
    END AS review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM stg_order_reviews;

-- 10. Commit only if all inserts succeed.
COMMIT;
