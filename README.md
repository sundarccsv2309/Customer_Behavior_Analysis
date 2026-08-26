# Customer Shopping Behavior Analysis

End-to-end analysis of customer shopping behavior — from data cleaning in Python to business-question SQL queries and an interactive Power BI dashboard.

## 📊 Overview
This project explores customer purchasing patterns across 3,900 customers to answer key business questions: who spends more, which products perform best, whether discounts and subscriptions drive revenue, and how customers segment by loyalty and age group.

## 🛠️ Tools & Tech
- **Python (Pandas)** — data cleaning, feature engineering
- **MySQL** — business-question querying
- **Power BI** — dashboard and visualization
- **SQLAlchemy** — Python-to-MySQL pipeline

## 🧹 Data Cleaning & Feature Engineering
- Filled missing `review_rating` values using category-wise median
- Standardized column names (lowercase, underscores)
- Created `age_group` (Young Adult / Adult / Middle-aged / Senior) via quartile binning
- Mapped `frequency_of_purchases` to numeric `purchase_frequency_days`
- Removed redundant `promo_code_used` column (duplicate of `discount_applied`)
- Loaded cleaned data into MySQL via SQLAlchemy for querying

## ❓ Business Questions Answered
- Total revenue: male vs female customers
- Customers who used a discount but still spent above average
- Top 5 products by average review rating
- Average purchase amount: standard vs express shipping
- Do subscribed customers spend more? (avg spend + total revenue comparison)
- Top 5 products by discount-usage rate
- Customer segmentation: New / Returning / Loyal (by purchase history)
- Top 3 best-selling products within each category
- Do repeat buyers (5+ purchases) subscribe more often?
- Revenue contribution by age group

## 📈 Key Insights
- **Revenue split**: Male customers generated $157,890 vs $75,191 from female customers — nearly 2x
- **Discount ≠ price-sensitive**: 839 customers used a discount yet still spent above the $59.76 average purchase
- **Top-rated products**: Gloves (3.9★), followed by Backpack, Belt, Handbag, and Boots (all 3.8★)
- **Shipping type barely matters**: Express ($60.48 avg) vs Standard ($58.46 avg) — only a ~$2 difference
- **Subscribers don't outspend non-subscribers**: non-subscribers actually spend slightly more on average ($59.87 vs $59.49), though non-subscribers make up 73% of customers and drive most of total revenue ($170,436 vs $62,645)
- **Discount-heavy products**: Hats lead at a 50% discount-usage rate, followed by Sneakers, Coats, Sweaters, and Pants (~47-50%)
- **Customer base is loyalty-heavy**: 3,116 "Loyal" customers (10+ purchases) vs only 83 "New" customers — a highly retained base
- **Category leaders**: Jewelry (Accessories), Blouse (Clothing), Sandals (Footwear), Jacket (Outerwear) are each the top-selling item in their category
- **Repeat buyers skew non-subscriber**: of customers with 5+ previous purchases, 2,518 are non-subscribers vs 958 subscribers
- **Age group revenue is fairly even**: Young Adults lead slightly ($62,143), with Adult, Middle-aged, and Senior all close behind (~$56K-59K each)

## 🐍 Data Cleaning & Feature Engineering (Python)

```python
import pandas as pd

df = pd.read_csv('customer_shopping_behavior.csv')

df['Review Rating'] = df.groupby('Category')['Review Rating'].transform(lambda x: x.fillna(x.median()))

df.columns = df.columns.str.lower()
df.columns = df.columns.str.replace(' ', '_')
df = df.rename(columns={'purchase_amount_(usd)': 'purchase_amount'})

labels = ['Young Adult', 'Adult', 'Middle-aged', 'Senior']
df['age_group'] = pd.qcut(df['age'], q=4, labels=labels)

frequency_mapping = {
    'Fortnightly': 14,
    'Weekly': 7,
    'Monthly': 30,
    'Quarterly': 90,
    'Bi-weekly': 14,
    'Annually': 365,
    'Every 3 months': 90
}
df['purchase_frequency_days'] = df['frequency_of_purchases'].map(frequency_mapping)

df = df.drop('promo_code_used', axis=1)
```

```python
from dotenv import load_dotenv
import os
from sqlalchemy import create_engine
from urllib.parse import quote_plus

load_dotenv()

USER = os.getenv("DB_USER")
PASSWORD = quote_plus(os.getenv("DB_PASSWORD"))
HOST = os.getenv("DB_HOST")
PORT = os.getenv("DB_PORT")
DATABASE = os.getenv("DB_NAME")

connection_string = f"mysql+mysqlconnector://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}"
engine = create_engine(connection_string)

df.to_sql(
    name="customer_data",
    con=engine,
    if_exists="replace",
    index=False,
)
```

## 🗄️ Business-Question SQL Queries

```sql
create database customers_behavior;
select * from customer_data limit 3;

-- total revenue by male vs female
select gender, sum(purchase_amount) from customer_data group by gender;

-- which customer used discount but still spend more than the average
select customer_id, purchase_amount from customer_data where discount_applied = "Yes" and
    purchase_amount >= (select avg(purchase_amount) from customer_data);

-- top 5 products with highest average review rating
select item_purchased, round(avg(review_rating),1) as review_rating from customer_data
group by item_purchased order by avg(review_rating) desc limit 5;

-- compare average purchase amount between standard and express shipping
select shipping_type, avg(purchase_amount) from customer_data where shipping_type in ("Express", "Standard") group by shipping_type;

-- do subscribed customer spend more? compare avg spend and total revenue between subscriber and non-subscriber
select subscription_status, count(customer_id), sum(purchase_amount), avg(purchase_amount) from customer_data group by subscription_status;

-- which 5 products have the highest percentage of purchase with discount applied
select item_purchased, round(sum(case when discount_applied = "Yes" then 1 else 0 end)/count(*) * 100,2) as discount_rate
from customer_data group by item_purchased order by discount_rate desc limit 5;

-- segment customer into new, returning and loyal based on their total number of previous purchase and show the count of each segment
with customer_type as (
    select customer_id, previous_purchases,
    case
        when previous_purchases = 1 then "NEW"
        when previous_purchases between 2 and 10 then "Returning"
        else "Loyal"
        end as customer_segment
from customer_data
)
select customer_segment, count(*) as number_of_customers from customer_type group by customer_segment;

-- what are the top 3 most purchase product within each category
with item_counts as (
    select category, item_purchased,
    count(customer_id) as total_orders,
    row_number() over(partition by category order by count(customer_id) desc) as item_rank
    from customer_data
    group by category, item_purchased
)
select item_rank, category, item_purchased, total_orders
from item_counts where item_rank <= 3;

-- are customer who are repeated buyers (more than 5 previous purchases) also likely to subscribe
select subscription_status, count(customer_id) as repeated_buyers
from customer_data where previous_purchases > 5 group by subscription_status;

-- what is revenue contribution of each age group
select age_group, sum(purchase_amount) from customer_data group by age_group;
```

## 📁 Repository Structure
- [`customer_shopping_behavior.csv`](./customer_shopping_behavior.csv) — Raw dataset
- [`customer_behavior.ipynb`](./customer_behavior.ipynb) — Full notebook
- [`customer_behav.sql`](./customer_behav.sql) — Full SQL script
- [`customer_behavior.pbix`](./customer_behavior.pbix) — Power BI dashboard (binary — open in Power BI Desktop)

## ▶️ How to Run
1. Clone the repo and open `customer_behavior.ipynb` in Jupyter
2. Install dependencies: `pip install pandas mysql-connector-python sqlalchemy python-dotenv`
3. Create a `.env` file with your DB credentials (see repo `.gitignore`)
4. Run the notebook to clean data and load it into MySQL
5. Execute `customer_behav.sql` against the `customers_behavior` database
6. Open `customer_behavior.pbix` in Power BI Desktop to explore the dashboard

## 👤 Author
**Sundareshwaran C**
Data Analyst | SQL, Python, Power BI
[LinkedIn] | [GitHub]
