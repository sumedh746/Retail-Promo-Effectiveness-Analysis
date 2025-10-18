# AtliQ Mart – Diwali & Sankranti Promotion Effectiveness Analysis #

This repository showcases a complete Retail Promotion Effectiveness Analysis project for AtliQ Mart’s Diwali 2023 and Sankranti 2024 campaigns, powered by SQL for data extraction and R (ggplot2 & dplyr) for business analytics and visual storytelling.

## Workflow Highlights: ##

SQL Scripts — Used to extract, clean, and join campaign-level datasets to answer targeted business questions.

### ✅ R-based Analytics Pipeline — Computation of: ###
- Incremental Revenue
- Incremental Sold Units %
- Promotion Type ROI Analysis
- Category & Product Responsiveness to Promotions

### ✅ Business Insight Generation — Identification of: ###
- High-impact products
- Best and underperforming stores/cities
- Most profitable promotion types (Cashback vs BOGOF vs Discounts)
- Campaign-wise ROI comparison

### ✅ Visual Insights using ggplot2 ### 
Clear and compelling charts to communicate trends, uplift impact, and actionable recommendations to decision-makers

## Data Sources ##
The analysis is based on AtliQ Mart's internal retail datasets, extracted and prepared through SQL.
The primary datasets used includes:
- fact_events.
- dim_products.
- dim_stores.
- dim_campaigns.

These datasets together enabled a comprehensive view of promotion performance across products, stores, cities, and campaigns.


## Business Questions ##
### 1. High-Value Products in 'BOGOF' Promotion

**Objective:** Identify high-value products featured in the 'BOGOF' (Buy One Get One Free) promotion.

```sql
SELECT DISTINCT p.product_name,
       f.base_price
FROM fact_events f
JOIN dim_products p ON f.product_code = p.product_code
WHERE f.promo_type = 'BOGOF' AND f.base_price > 500; 
```

### 2. Store Distribution by City

**Objective:** Generate a report showing how many stores AtliQ Mart has in each city, sorted by highest presence.

```sql
SELECT city,
       COUNT(store_id) AS no_of_stores
FROM dim_stores
GROUP BY city
ORDER BY no_of_stores DESC;
```

### 3. Campaign-wise Revenue Before vs After Promotions
**Objective:** Display each campaign with total revenue generated before and after promotions, considering discount logic

```sql
SELECT c.campaign_name,
       CONCAT(ROUND(SUM(f.base_price * f.quantity_sold_before_promo) / 1000000, 2), 'M') AS total_revenue_before_promotion,
       CONCAT(ROUND(SUM(CASE
                        WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo * 2
                        WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                        WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                        WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                        WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                       END) / 1000000, 2), 'M') AS total_revenue_after_promotion
FROM dim_campaigns c
JOIN fact_events f ON f.campaign_id = c.campaign_id
GROUP BY 1;
```

### 4. ISU% (Incremental Sold Units %) by Category During Diwali
**Objective:** Calculate the Incremental Sold Units % uplift for each category during the Diwali campaign and rank them by effectiveness.

```sql
WITH diwali_campaign_sales AS (
  SELECT p.category,
         ROUND(SUM((CASE
                     WHEN f.promo_type = 'BOGOF' THEN f.quantity_sold_after_promo * 2
                     ELSE f.quantity_sold_after_promo
                   END - f.quantity_sold_before_promo) * 100)
               / SUM(f.quantity_sold_before_promo), 2) AS ISU_Percent
  FROM dim_products p
  JOIN fact_events f ON f.product_code = p.product_code
  JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
  WHERE c.campaign_name = 'Diwali'
  GROUP BY category
)
SELECT category,
       ISU_Percent,
       RANK() OVER(ORDER BY ISU_Percent DESC) AS rank_order
FROM diwali_campaign_sales;
```

### 5. Top 5 Products by Incremental Revenue % Across All Campaigns
**Objective:** Identify the top 5 products that showed the highest Incremental Revenue % uplift due to promotional campaigns.

```sql
SELECT p.product_name,
       p.category,
       ROUND((SUM(CASE
                    WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo * 2
                    WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                    WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                    WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                    WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                  END)
             - SUM(f.base_price * f.quantity_sold_before_promo)) 
             / SUM(f.base_price * f.quantity_sold_before_promo) * 100, 2) AS IR_Percent
FROM dim_products p
JOIN fact_events f ON p.product_code = f.product_code
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5;
```



