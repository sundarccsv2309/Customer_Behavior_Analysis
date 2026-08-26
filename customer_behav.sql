create database customers_behavior;
select * from customer_data limit 3;
-- total revenue by male vs female
select gender,sum(purchase_amount) from customer_data group by gender;
-- which customer used discount but still spend more than the avgerage purchase
select customer_id,purchase_amount from customer_data where discount_applied = "Yes" and 
	purchase_amount >= (select avg(purchase_amount) from customer_data);
-- top 5 products with highest average review rating 
select item_purchased,round(avg(review_rating),1) as review_rating from customer_data 
group by item_purchased order by avg(review_rating) desc limit 5;
-- compare average purchase amount between standard and express shipping
select shipping_type,avg(purchase_amount) from customer_data where shipping_type in ("Express" , "Standard") group by shipping_type ;
-- do subscribed customer spend more ? compare avg spend and total revenue between subscriber and non-subscriber
select subscription_status,count(customer_id) ,sum(purchase_amount),avg(purchase_amount) from customer_data group by subscription_status;
-- which 5 products have the highest percentage of purchase with discount applied 
select item_purchased,round(sum(case when discount_applied = "Yes" then 1 else 0 end)/count(*) * 100,2) as discount_rate
from customer_data group by item_purchased order by discount_rate desc limit 5;
-- segment customer into new , returning and loyal based on their total number of previous purchase and show the count of each segment
with customer_type as(
	select customer_id,previous_purchases,
    case 
		when previous_purchases = 1 then "NEW"
        when previous_purchases between 2 and 10 then "Returning"
        else "Loyal"
        end as customer_segment
from customer_data
)
select customer_segment,count(*) as number_of_customers from customer_type group by customer_segment;
-- what are the top 3 most purchase product within each category

with item_counts as(
	select category,item_purchased,
    count(customer_id) as total_orders,
    row_number() over(partition by category order by count(customer_id) desc) as item_rank
    from customer_data
    group by category,item_purchased
)
select item_rank, category , item_purchased ,total_orders
from item_counts where item_rank <= 3 ;

-- are customer who are repeated buyers(more than 5 previous purchases) also likely to subscriber
select subscription_status,count(customer_id) as repeated_buyers
from customer_data where previous_purchases > 5 group by subscription_status;
-- what is revenue contribution of each age group
select age_group,sum(purchase_amount) from customer_data group by age_group; 