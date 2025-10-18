install.packages("tidyverse")
install.packages("skimr")
install.packages("janitor")
install.packages("readxl")
install.packages("scales")
library(tidyverse)
library(skimr)
library(janitor)
library(readxl)
library(scales)

#Uploading the data
fact_events <- read_csv("Downloads/C9_Input_Files/dataset/fact_events.csv")
dim_campaigns <- read_csv("Downloads/C9_Input_Files/dataset/dim_campaigns.csv")
dim_products <- read_csv("Downloads/C9_Input_Files/dataset/dim_products.csv")
dim_stores <- read_csv("Downloads/C9_Input_Files/dataset/dim_stores.csv")
View(fact_events)
View(dim_campaigns)
View(dim_products)
View(dim_stores)

#Joining the data
fact_events <- left_join(fact_events, dim_campaigns, by= "campaign_id")
fact_events_1 <- left_join(fact_events, dim_products, by = "product_code")
fact_events_2 <- left_join(fact_events_1, dim_stores, by = "store_id")
View(fact_events)
View(fact_events_1)
View(fact_events_2)

#Transforming the data
#Incremental Revenue Calculation
fact_events_3 <- fact_events_2 %>%
  mutate(
    revenue_before_promo = base_price * `quantity_sold(before_promo)`,
    revenue_after_promo = case_when(
      promo_type == "BOGOF" ~ base_price * 0.5 * `quantity_sold(after_promo)` * 2,
      promo_type == "500 Cashback" ~ (base_price - 500) * `quantity_sold(after_promo)`,
      promo_type == "50% OFF" ~ base_price * 0.5 * `quantity_sold(after_promo)`,
      promo_type == "33% OFF" ~ base_price * 0.67 * `quantity_sold(after_promo)`,
      promo_type == "25% OFF" ~ base_price * 0.75 * `quantity_sold(after_promo)`,
      TRUE ~ 0
    )
  )
View(fact_events_3)

# Calculate IR separately
IR_value <- fact_events_3 %>%
  summarise(
    IR_Percentage = round(((sum(revenue_after_promo) - sum(revenue_before_promo)) * 100) / sum(revenue_before_promo), 2)
  )

IR_value  # Shows IR 
fact_events_3$IR_Percentage <- IR_value$IR_Percentage
View(fact_events_3)

fact_events_3 <- fact_events_3 %>%
  select(!IR_Percentage)

View(fact_events_3)

#Incremental Sold Units Calculation
fact_events_3 <- fact_events_3 %>%
  mutate(sold_units_after_promo = ifelse(promo_type == "BOGOF",
                                         `quantity_sold(after_promo)` * 2,
                                         `quantity_sold(after_promo)`),
         incremental_sold_units = sold_units_after_promo - `quantity_sold(before_promo)`
         )
View(fact_events_3)


#Incremental Sold Units %
ISU_Value <- fact_events_3 %>%
  summarise(
    ISU_Percentage = ((sum(sold_units_after_promo) - sum(`quantity_sold(before_promo)`))* 100 /sum(`quantity_sold(before_promo)`))
  )

ISU_Value #Shows ISU Value

#Plotting the Data
#Top 10 stores in terms of Incremental Revenue Generated
top10_stores <- fact_events_3 %>%
  mutate(incremental_revenue = revenue_after_promo - revenue_before_promo) %>%
  group_by(store_id) %>%
  summarise(city = first(city),
    total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE)) %>%
  arrange(desc(total_incremental_revenue)) %>%
  slice_head(n=10)

View(top10_stores)

bottom10_stores <- fact_events_3 %>%
  mutate(incremental_revenue = revenue_after_promo - revenue_before_promo) %>%
  group_by(store_id) %>%
  summarise(city = first(city),
    total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE)) %>%
  arrange(total_incremental_revenue) %>%
  slice_head(n=10)

View(bottom10_stores)

#Plotting the top 10 stores
ggplot(top10_stores, aes(x = reorder(store_id, total_incremental_revenue),
                         y = total_incremental_revenue)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Top 10 Stores by Incremental Revenue",
    x = "Stores",
    y = "Incremental Revenue"
  ) +
  theme_minimal()

#Bottom 10 Stores in terms of Incremental Sold Units
bottom10_stores_isu <- fact_events_3 %>%
  group_by(store_id) %>%
  summarise(city = first(city),
            total_incremental_sold_units = sum(incremental_sold_units, na.rm = TRUE)) %>%
  arrange(total_incremental_sold_units) %>%
  slice_head(n=10)

View(bottom10_stores_isu)

top10_stores_isu <- fact_events_3 %>%
  group_by(store_id) %>%
  summarise(city = first(city),
            total_incremental_sold_units = sum(incremental_sold_units, na.rm = TRUE)) %>%
  arrange(desc(total_incremental_sold_units)) %>%
  slice_head(n=10)

View(top10_stores_isu)


#Plotting the bottom 10 stores
ggplot(bottom10_stores, aes(x = reorder(store_id, total_incremental_sold_units),
                            y = total_incremental_sold_units)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Bottom 10 Stores by Incremental Sold Units",
    x = "Stores",
    y = "Incremental Sold Units"
  ) +
  theme_minimal()

#Performance by City 
city_performance <- fact_events_3 %>%
  mutate(incremental_revenue = revenue_after_promo - revenue_before_promo) %>%
  group_by(city) %>%
  summarise(total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE),
            avg_incremental_revenue = mean(incremental_revenue, na.rm = TRUE),
            store_count = n_distinct(store_id)) %>%
  arrange(desc(total_incremental_revenue))

View(city_performance)

#Plotting the city performance
ggplot(city_performance, aes(x = reorder(city, total_incremental_revenue), 
                             y = total_incremental_revenue)) +
  geom_col(fill = "blue") +
  coord_flip() +
  labs(
    title = "City-wise Incremental Revenue Performance",
    x = "City",
    y = "Total Incremental Revenue"
  ) +
  theme_minimal()

#Common Traits of top performing stores
top_stores <- fact_events_3 %>%
  mutate(incremental_revenue = revenue_after_promo - revenue_before_promo) %>%
  group_by(store_id, city, promo_type) %>%
  summarise(total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE)) %>%
  arrange(desc(total_incremental_revenue)) %>%
  slice_head(n=10)

View(top_stores)


#Common features
top_stores_summary <- top_stores %>%
  group_by(city, promo_type) %>%
  summarise(
    avg_incremental_revenue = mean(total_incremental_revenue, na.rm = TRUE),
    count_of_top_stores = n()
  ) %>%
  arrange(desc(avg_incremental_revenue))

View(top_stores_summary)


#Promo type and Incremental Revenue
promo_type_analysis <- fact_events_3 %>%
  mutate(incremental_revenue = revenue_after_promo - revenue_before_promo) %>%
  group_by(promo_type) %>%
  summarise(total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE)) %>%
  arrange(desc(total_incremental_revenue))

View(promo_type_analysis)

#Plotting the Promo type analysis
ggplot(promo_type_analysis, aes(x = reorder(promo_type, total_incremental_revenue),
                                y = total_incremental_revenue)) +
  geom_bar(stat = "identity", fill = "green") +
  coord_flip() +
  labs(
    title = "Promo-wise analysis of Incremental Revenue",
    x = "Promo Type",
    y = "Total Incremental Revenue"
  ) +
  theme_minimal()

#Promo type and Incremental Sold Units
promo_analysis <- fact_events_3 %>%
  group_by(promo_type) %>%
  summarise(total_incremental_sold_units = sum(incremental_sold_units, na.rm = TRUE)) %>%
  arrange(desc(total_incremental_sold_units))

View(promo_analysis)


#Plotting Incremental Sold Units vs Promo Type
ggplot(promo_analysis, aes(x = reorder(promo_type, total_incremental_sold_units),
                           y = total_incremental_sold_units)) +
  geom_bar(stat = "identity", fill = "blue") +
  coord_flip() +
  labs(
    title = "Promo-wise analysis of Incremental Sold Units",
    x = "Promo Type",
    y = "Total Incremental Sold Units") +
  theme_minimal()


#Calculate Incremental Revenue Per Promotion Type
promo_performance <- fact_events_3 %>%
  mutate(incremental_revenue = revenue_after_promo - revenue_before_promo) %>%
  group_by(promo_type) %>%
  summarise(
    avg_incremental_revenue = mean(incremental_revenue, na.rm = TRUE),
    median_incremental_revenue = median(incremental_revenue, na.rm = TRUE),
    sd_incremental_revenue = sd(incremental_revenue, na.rm = TRUE),
    store_count = n()
  ) %>%
  arrange(desc(avg_incremental_revenue))

View(promo_performance)

#Calculate Incremental Sold Units Per Promotion Type
promo_performance_sold_units <- fact_events_3 %>%
  group_by(promo_type) %>%
  summarise(
    avg_incremental_sold_units = mean(incremental_sold_units, na.rm = TRUE),
    median_incremental_sold_units = median(incremental_sold_units, na.rm = TRUE),
    sd_incremental_sold_units = sd(incremental_sold_units, na.rm = TRUE),
    store_count = n()
  ) %>%
  arrange(desc(avg_incremental_sold_units))

View(promo_performance_sold_units)

#Boxplot for distribution comparison
ggplot(fact_events_3 %>%
         mutate(incremental_revenue = revenue_after_promo - revenue_before_promo),
       aes(x = promo_type, y = incremental_revenue)) +
  geom_boxplot() +
  labs(
    title = "Distribution of Incremental Revenue by Promotion Type",
    x = "Promotion Type",
    y = "Incremental Revenue"
  ) +
  theme_minimal()



#Metric evaluation
fact_events_3 <- fact_events_3 %>%
  mutate(
    incremental_revenue = revenue_after_promo - revenue_before_promo,
    margin_per_unit = revenue_after_promo / `quantity_sold(after_promo)`,  # Approximation
    discount_depth = case_when(
      promo_type %in% c("25% OFF", "33% OFF", "50% OFF") ~ "High Margin Loss",
      promo_type == "BOGOF" ~ "Medium Margin Loss",
      promo_type == "500 Cashback" ~ "Controlled Margin Loss"
    )
  )

View(fact_events_3)

#Summarising Promo Efficiency
promo_efficiency <- fact_events_3 %>%
  group_by(promo_type) %>%
  summarise(
    avg_incremental_sold_units = mean(incremental_sold_units, na.rm = TRUE),
    avg_incremental_revenue = mean(incremental_revenue, na.rm = TRUE),
    avg_margin_per_unit = mean(margin_per_unit, na.rm = TRUE)
  ) %>%
  arrange(desc(avg_incremental_sold_units))

View(promo_efficiency)

#Incremental Sold Units vs Margin Per Unit
ggplot(promo_efficiency, aes(x = avg_incremental_sold_units, y = avg_margin_per_unit, label = promo_type)) +
  geom_point(size = 5, fill = "blue") +
  geom_text(vjust = -1) +
  labs(
    title = "Trade-off Between Incremental Units and Margin Health by Promotion Type",
    x = "Avg Incremental Units (Sales Lift)",
    y = "Avg Margin Per Unit (Profitability)"
  ) +
  theme_minimal()


#Analysis by Product Category
product_category_analysis <- fact_events_3 %>%
  group_by(category) %>%
  summarise(
    total_incremental_sold_units = sum(incremental_sold_units, na.rm = TRUE),
    total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE),
    avg_lift_per_store = mean(incremental_sold_units, na.rm = TRUE)
  ) %>%
  arrange(desc(total_incremental_sold_units))

View(product_category_analysis)

#Plotting the graph
ggplot(product_category_analysis, aes(x = reorder(category, total_incremental_sold_units),
                                      y = total_incremental_sold_units)) +
  geom_col(fill = "red") +
  coord_flip() +
  labs (
    title = "Top Product Categories by Incremental Sales Lift",
    x = "Product Category",
    y = "Total Incremental Sold Units"
  ) +
  theme_minimal()

#Product response to promotions
product_lift <- fact_events_3 %>%
  group_by(product_code, product_name) %>%
  summarise(
    total_incremental_sold_units = sum(incremental_sold_units, na.rm = TRUE),
    total_incremental_revenue = sum(incremental_revenue, na.rm = TRUE),
    avg_lift_per_store = mean(incremental_sold_units, na.rm = TRUE)
  ) %>%
  arrange(desc(total_incremental_sold_units))

View(product_lift)

#Top and Bottom Stores
top_products <- product_lift %>%
  ungroup() %>%
  mutate(total_incremental_sold_units = as.numeric(total_incremental_sold_units)) %>%  # ensure numeric
  arrange(desc(total_incremental_sold_units)) %>%
  slice_head(n = 10)   # or FALSE if you want exactly 10


bottom_products <- product_lift %>%
  ungroup() %>%
  mutate(total_incremental_sold_units = as.numeric(total_incremental_sold_units)) %>%
  arrange(total_incremental_sold_units) %>%
  slice_head(n=10)


View(top_products)
View(bottom_products)

#plotting top and bottom products
ggplot(top_products, aes(x = reorder(product_name, total_incremental_sold_units),
                         y = total_incremental_sold_units)) +
  geom_col(fill = "green") +
  coord_flip() +
  labs(title = "Top 10 Products — High Lift from Promotions", x = "Product", y = "Incremental Units") +
  theme_minimal()

ggplot(bottom_products, aes(x = reorder(product_name, total_incremental_sold_units),
                            y = total_incremental_sold_units)) +
  geom_col(fill = "red") +
  coord_flip() +
  labs(title = "Bottom 10 Products — Poor Response to Promotions", x = "Product", y = "Incremental Units") +
  theme_minimal()

#Correlation between Category and Promo
category_promo_effectiveness <- fact_events_3 %>%
  group_by(category, promo_type) %>%
  summarise(
    avg_incremental_units = mean(incremental_sold_units, na.rm = TRUE),
    avg_incremental_revenue = mean(incremental_revenue, na.rm = TRUE)
  ) %>%
  arrange(desc(avg_incremental_units))

View(category_promo_effectiveness)

#plotting the graph
ggplot(category_promo_effectiveness, 
       aes(x = category, 
           y = avg_incremental_units, 
           fill = promo_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(
    title = "Incremental Units by Promo Type Across Categories",
    x = "Product Category",
    y = "Avg Incremental Units Lift",
    fill = "Promotion Type"
  ) +
  theme_minimal()

#Plotting the category-wise quantity sold before vs after promo
category_sales <- fact_events_3 %>%
  group_by(category) %>%
  summarise (
    total_before = sum(`quantity_sold(before_promo)`, na.rm = TRUE),
    total_after = sum(`quantity_sold(after_promo)`, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = c(total_before, total_after),
               names_to = "sale_type",
               values_to = "total_units")

ggplot(category_sales, aes(x = category, y = total_units, group = sale_type, color = sale_type)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = category), vjust = -1.2, size = 3) +
  labs(
    title = "Category Sales Before Promo vs After Promo",
    x = "Product Category",
    y = "Total Quantity Sold",
    color = "Sale Type"
  ) +
  scale_color_manual(values = c("total_before" = "steelblue", "total_afte" = "darkgreen")) +
  theme_minimal () +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#Plotting the product_wise quantity sold before vs after
product_sales <- fact_events_3 %>%
  group_by(product_name) %>%
  summarise(
    total_before = sum(`quantity_sold(before_promo)`, na.rm = TRUE),
    total_after = sum(`quantity_sold(after_promo)`, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = c(total_before, total_after),
               names_to = "Sale Type",
               values_to = "Total_Units")

ggplot(product_sales, aes(x = reorder(product_name, Total_Units),
                          y = Total_Units,
                          fill = `Sale Type`)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip () +
  labs (
    title = "Product Quantity Sold Before vs After Promo",
    x = "Product Name",
    y = "Total Units Sold",
    fill = "Sale Type"
  ) +
  scale_fill_manual(values = c("total_before" = "skyblue", "total_after" = "seagreen")) +
  theme_minimal()

#Category and Product Analysis by Revenue and Quantity Sold
category_product_analysis <- fact_events_3 %>%
  group_by(category, product_name) %>%
  summarise(
    Quantity_before_Promo = sum(`quantity_sold(before_promo)`, na.rm = TRUE),
    Revenue_before_Promo = sum(revenue_before_promo, na.rm = TRUE),
    Quantity_after_promo = sum(`quantity_sold(after_promo)`, na.rm = TRUE),
    Revenue_after_promo = sum(revenue_after_promo, na.rm = TRUE),
    Incremental_revenue = sum(incremental_revenue, na.rm = TRUE),
    Incremental_sold_units = sum(incremental_sold_units, na.rm = TRUE)
  ) %>%
  mutate(
    Revenue_before_Promo = paste0("₹", comma(round(Revenue_before_Promo / 1000, 1)), "K"),
    Revenue_after_promo = paste0("₹", comma(round(Revenue_after_promo / 1000, 1)), "K"),
    Incremental_revenue = paste0("₹", comma(round(Incremental_revenue / 1000, 1)), "K")
  )

View(category_product_analysis)

#Campaign Analysis
campaign_analysis <- fact_events_3 %>%
  group_by(campaign_name, promo_type) %>%
  summarise(
    Quantity_before_promo = sum(`quantity_sold(before_promo)`, na.rm = TRUE),
    Quantity_after_promo = sum(`quantity_sold(after_promo)`, na.rm = TRUE),
    Incremental_Revenue = sum(incremental_revenue, na.rm = TRUE),
    Incremental_Sold_Units = sum(incremental_sold_units, na.rm = TRUE)
  ) %>%
  arrange(campaign_name,desc(Quantity_before_promo))

View(campaign_analysis)
