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

# Limitations and Challenges #
One key limitation in the dataset relates to the 'BOGOF' (Buy One Get One Free) promotion type. The dataset does not explicitly capture the quantity of free units given to customers, and the additional free item has to be assumed and calculated manually.

As a result:
- The reported sales quantity may not fully reflect the actual uplift generated by 'BOGOF' campaigns.
- There is risk of underestimating or overestimating the true impact of this promotion type when compared with other promos like Cashback or Percentage Discounts.
- This may introduce interpretation bias when comparing promotional effectiveness across strategies.

# Insights Generated #
From the analysis of AtliQ Mart's Diwali 2023 and Sankranti 2024 promotional campaigns, the following key business insights were identified:

#### Store and City Performance ####
- **Bengaluru, Chennai, and Myrusu** emerged as the strongest promo-responsive cities, with their stores dominating the Top 10 ranking for both Incremental Revenue and Incremental Sold Units.
- Stores in **Visakhapatnam, Trivandrum, and Mangalore** showed moderate lift, indicating scope for campaign optimization.
- **Coimbatore and Vijaywada** stores repeatedly appeared in **lower uplift range**, suggesting **weaker promo engagement or execution inefficiencies**.
- **Bengalure** stores **(STBLR-7, STBLR-0, STBLR-6)** recorded the highest unit lift, especially under **BOGOF and Cashback** campaigns.
- **Chennai outlets** also showed strong sales acceleration, making them as **priority locations for future targeted promotions**.


#### Promotion-Type Effectiveness ####
- **Cashback and BOGOF promotions** drove **maximum sales uplift** while keeping margins relatively healthy.
- Flat **percentage-based discounts (25%,33%,50% OFF) resulted in **low revenue uplift and higher margin loss**, making them less efficient.
- Promotions with **high perceived value (BOGOF, Cashback)** clearly outperformed pure discount offers.


#### Category Performance ####
- **Grocery & Staples** and **Home Appliances** drove the **highest promo lift**, showing strong responsiveness.
- **Home Care & Combo Products** showed moderate uplift, potential targets for optimized promo strategy.
- **Personal Care** delivered **minimal lift**, indicating **low promo sensitivity** and requiring rethink in offer positioning.

#### Promotion Effectiveness ####
- **500 Cashback** - Best for Revenue Growth (High ROI)
- **BOGOF** - Best for Volume Lift (High Unit Uplift)
- **Flat Discounts(25-50% OFF)** - Lowest Impact and Margin Dilution.
- **BOGOF** = Best for driving volume and **Cashback** = Best for driving profit.

#### Product Response Insight ####
- **High-performing SKUs** like Chakki Atta, Sunflower Oil, LED Bulb, Immersion Rod showed 100K+ incremental units, ideal for future promo scaling.
- **Low-impact products** in Personal Care categories showed little to negative uplift and should be deprioritized in future campaigns.


#### Campaign Efficiency ####
- **Sankranti campaign + BOGOF combo** generated the highest incremental units sold, showing strong festival buying sentiment.
- **Diwali + Cashback** promotions delivered the best revenue uplift, indicating better margin-to-return balance.
- **Flat discounts** showed **negative ROI** in both campaigns, confirming that **discount-heavy promotions** dilute profitability.


## Conclusion ##
- **Not all promotions deliver equal ROI** - Cashback and BOGOF clearly outperform blanket discounts.
- **Targeted promotion strategy** based on product, city and store performance is **more effective than uniform promotions**.
- **Top stores and responsive cities** shoul be used as **replication benchmark** for improving results in underperforming regions.
- **Future promotions** should priorotize **high-responsive SKUs** and **Profitable categories** instead of applying offers to the entire catalog.
- Introducing a **promo optimization strategy (Promo ROI Score/ Lift Matrix) can improve **decision-making and budget allocation** for upcoming campaigns.

 

