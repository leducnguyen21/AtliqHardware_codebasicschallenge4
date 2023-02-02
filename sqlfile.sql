/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region	*/
select distinct market 
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields: unique_products_2020, unique_products_2021, percentage_chg */
with 2020_ as (select count(distinct s.product_code) as unique_count
			from fact_sales_monthly s
            join fact_gross_price g
            on g.product_code = s.product_code
			where s.fiscal_year = 2020),
	2021_ as (select count(distinct s.product_code) as unique_count
			from fact_sales_monthly s
            join fact_gross_price g
            on g.product_code = s.product_code
			where s.fiscal_year = 2021)
            
select a.unique_count as unique_products_2020,
		b.unique_count as unique_products_2021,
        concat(round((b.unique_count - a.unique_count) / a.unique_count*100,2),'%') as percentage_chg
from 2020_ as a
join 2021_ as b;

/* 3. Provide a report with all the unique product counts for each segment and sort them in descending 
order of product counts. The final output contains 2 fields, segment & product_count
*/
select segment, count(product_code) as product_counts
from dim_product
group by segment
order by product_counts desc;

/* 4. Which segment had the most increase in unique products in 2021 vs 2020? 
The final output contains these fields: segment, product_count_2020, product_count_2021, difference
*/
with A as (select segment, count(distinct(p.product_code)) as product_count
			from dim_product p
            join fact_gross_price g on p.product_code = g.product_code
            where fiscal_year = 2020
            group by segment),
	B as (select segment, count(distinct(p.product_code)) as product_count
			from dim_product p
            join fact_gross_price g on p.product_code = g.product_code
            where fiscal_year = 2021
            group by segment)
select A.segment, A.product_count as product_count_2020,
	   B.product_count as product_count_2021,
	   B.product_count - A.product_count as difference
from A
join B on A.segment = B.segment;
        
/* 5. Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields: product_code, product, manufacturing_cost
*/
select p.category, m.product_code, p.product, m.manufacturing_cost as manufacturing_cost
from fact_manufacturing_cost m 
join dim_product p on p.product_code = m.product_code
where manufacturing_cost = (
		select min(m.manufacturing_cost) 
		from fact_manufacturing_cost m
		join dim_product p on p.product_code = m.product_code
	)
UNION
select  p.category, m.product_code, p.product, m.manufacturing_cost as manufacturing_cost
from fact_manufacturing_cost m 
join dim_product p on p.product_code = m.product_code
where manufacturing_cost = (
		select max(m.manufacturing_cost) 
		from fact_manufacturing_cost m
		join dim_product p on p.product_code = m.product_code
	);

/* 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
for the fiscal year 2021 and in the Indian market. The final output contains these fields: 
customer_code, customer, average_discount_percentage
*/
select c.customer_code, c.customer, avg(p.pre_invoice_discount_pct) as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions p on c.customer_code = p.customer_code
where p.fiscal_year = 2021 and c.market = "India"
group by c.customer_code
order by p.pre_invoice_discount_pct desc
limit 5;

/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month, Year, Gross sales Amount
*/
select month(date) as month, year(date) as year,
	(g.gross_price * s.sold_quantity) as Gross_sales_Amount
from fact_sales_monthly s
join dim_customer c on c.customer_code = s.customer_code
join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year
where c.customer = "Atliq Exclusive"
group by month(date), year(date)
order by year(date);

/* 8.  In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity: Quarter, total_sold_quantity
*/
select 
case when month(date) in (9,10,11) then "Q1"
	when month(date) in (12,1,2) then "Q2"
    when month(date) in (3,4,5) then "Q3"
    when month(date) in (6,7,8) then "Q4"
end as Quarter,
sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by total_sold_quantity desc
;

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields: channel, gross_sales_mln, percentage
*/
with T as (select c.channel, round((sum(g.gross_price * s.sold_quantity) / 1000000), 2) as gross_sales_mln
					from fact_sales_monthly s
					join dim_customer c on s.customer_code = c.customer_code
					join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year
					where s.fiscal_year = 2021
					group by c.channel)
select *, T.gross_sales_mln, 
	concat(round(T.gross_sales_mln * 100 / (select sum(gross_sales_mln) from T), 2),"%") as 'percentage_of_contribution'
from T;

/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields: division, product_code, product, total_sold_quantity, rank_order
*/
select * 
from (select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity,
			rank() over 
            (partition by p.division order by sum(s.sold_quantity) desc) as rank_order
			from fact_sales_monthly s
			join dim_product p on p.product_code = s.product_code
			where s.fiscal_year = 2021
			group by division, product_code) as t 
where rank_order <= 3;




        












