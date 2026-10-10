# Olist E-Commerce KPI Analysis

## 1. Project objective

This project analyzes Olist e-commerce operations using SQLite, SQL,
Python, pandas, and Matplotlib. It examines sales, product categories,
sellers, delivery performance, and customer reviews.

## 2. Data and validation

The source staging tables contain:

| Table | Rows |
|---|---:|
| Customers | 99,441 |
| Sellers | 3,095 |
| Category translation | 71 |
| Products | 32,951 |
| Orders | 99,441 |
| Order items | 112,650 |
| Order reviews | 99,224 |

The final category translation table contains 73 rows because category
names without English translations were retained. Foreign-key validation
reported no violations.

## 3. Analytical method

The main analysis focuses on delivered orders. Revenue is defined as
the sum of item prices (`order_items.price`); freight is excluded.

A reusable analytical view joins orders to order items, products,
category translations, and reviews. Reviews are aggregated to one row
per order before joining to item rows, preventing multiple reviews from
inflating item revenue.

Join rationale:
- Orders to order items: INNER JOIN, because the analysis requires
  items belonging to delivered orders.
- Products: LEFT JOIN, to retain item revenue even if product details
  are missing.
- Category translation: LEFT JOIN, to retain untranslated categories.
- Reviews: LEFT JOIN to reviews aggregated by order, so orders without
  reviews remain in the analytical dataset.

## 4. Revenue reconciliation

| Metric | Result |
|---|---:|
| Delivered item rows in source | 110,197 |
| Item rows in analytical view | 110,197 |
| Source item revenue | R$13,221,498.11 |
| Analytical view revenue | R$13,221,498.11 |
| Difference | R$0.00 |

The zero difference confirms that the analytical view preserves item
revenue for the delivered-order scope.

## 5. Overall KPIs

| KPI | Result |
|---|---:|
| Delivered orders | 96,470 |
| Delivered item rows | 110,197 |
| Item revenue | R$13,221,498.11 |
| Average order value | R$137.04 |
| Average delivery time | 12.56 days |
| Average delivery delay | -11.18 days |
| Average review score | 4.16 / 5 |

A negative average delivery delay means deliveries were earlier than
the estimated delivery date on average. Delivery time and delivery
delay are different measures.

## 6. Category findings

Top categories by delivered item revenue:
1. Health and beauty — R$1,233,131.72
2. Watches and gifts — R$1,166,176.98
3. Bed and bath table — R$1,023,434.76
4. Sports and leisure — R$954,852.55
5. Computers and accessories — R$888,724.61

Lowest-revenue categories in the ranked results:
- Christmas supplies — R$8,737.84
- Fashion underwear/beach — R$9,305.95
- Fashion male clothing — R$10,452.33
- Food and drink — R$14,942.88
- Technical books — R$18,702.23

These rankings use a minimum threshold of 100 distinct delivered orders.

Top category review scores:
- General-interest books — 4.51
- Technical books — 4.39
- Food and drink — 4.37
- Luggage and accessories — 4.35
- Fashion shoes — 4.29

Lowest category review scores:
- Office furniture — 3.51
- Fashion male clothing — 3.76
- Fixed telephony — 3.76
- Audio — 3.84
- Home comfort — 3.85

Review rankings use a minimum threshold of 100 reviewed delivered orders.
Scores should be interpreted with the aggregation method documented in
the SQL analysis.

## 7. Delivery and satisfaction

The Pearson correlation between delivery delay and review score was
-0.267, based on 95,824 reviewed delivered orders with usable delivery
dates.

This indicates a negative linear association: larger delivery delays
tend to coincide with lower review scores. Correlation does not establish
causation, and other factors may influence customer satisfaction.

## 8. Operational recommendations

1. Protect availability and seller capacity for health and beauty,
   the highest-revenue category.
2. Investigate the causes of lower ratings in bed and bath table, a
   high-revenue category with an average score of 3.92.
3. Monitor delayed deliveries and their associated reviews because
   delivery delay has a negative correlation with review score.
4. Investigate office furniture complaints, since its average review
   score is 3.51 across 1,244 reviewed orders.
5. Evaluate growth opportunities in smaller categories with strong
   ratings, such as general-interest books, before deprioritizing them
   solely because of low revenue.

## 9. Limitations

Revenue excludes freight charges. The analysis is limited to delivered
orders for the core KPIs. Categories without English translations are
retained under their source names or an unknown label. The project
notes originally suggested different example totals; validated results
from this database are reported here instead.

## 10. ER diagram

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : includes
    SELLERS ||--o{ ORDER_ITEMS : fulfills
    PRODUCTS }o--o| CATEGORY_TRANSLATION : translates
    ORDERS ||--o{ ORDER_REVIEWS : receives

    CUSTOMERS {
        string customer_id PK
        string customer_unique_id
    }
    ORDERS {
        string order_id PK
        string customer_id FK
        string order_status
        datetime order_purchase_timestamp
    }
    ORDER_ITEMS {
        string order_id PK, FK
        integer order_item_id PK
        string product_id FK
        string seller_id FK
        real price
        real freight_value
    }
    PRODUCTS {
        string product_id PK
        string product_category_name FK
    }
    SELLERS {
        string seller_id PK
    }
    CATEGORY_TRANSLATION {
        string product_category_name PK
        string product_category_name_english
    }
    ORDER_REVIEWS {
        string review_id PK
        string order_id FK
        integer review_score
    }