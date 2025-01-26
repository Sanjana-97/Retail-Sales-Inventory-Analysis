---- SALES DOMAIN ANALYSIS

create database Store_Sales_analysis;
use Store_Sales_analysis;

----creating container table and bulk uploading data

--sales
create table Sales
(Sale_ID varchar(max), Date varchar(max), Store_ID varchar(max), Product_ID varchar(max), Units varchar(max));

select * from Sales;

---- Bulk insert to import the data into our container
bulk insert Sales
from 'C:\Users\FCI1626\Downloads\Analytics_project\SQL\Store_sales\sales.csv'
with (fieldterminator = ',', 
      rowterminator = '\n',
	  firstrow = 2,
	  maxerrors = 10);

select * from Sales;

--product
create table Products
(Product_ID	varchar(max),Product_Name varchar(max),	Product_Category varchar(max),	Product_Cost varchar(max),
	Product_Price varchar(max));

bulk insert Products
from 'C:\Users\FCI1626\Downloads\Analytics_project\SQL\Store_sales\products.csv'
with (fieldterminator = ',',
	 rowterminator ='\n',
	 firstrow = 2,
	 maxerrors = 10);

select * from Products;

-- stores
create table Stores
(Store_ID	varchar(max),Store_Name varchar(max),	Store_City varchar(max),	Store_Location varchar(max),
	Store_Open_Date varchar(max));

bulk insert Stores
from 'C:\Users\FCI1626\Downloads\Analytics_project\SQL\Store_sales\stores.csv'
with (fieldterminator = ',',
	 rowterminator ='\n',
	 firstrow = 2,
	 maxerrors = 10);

select * from Stores;

-- inventory
create table Inventory
(Store_ID varchar(max),	Product_ID varchar(max),Stock_On_Hand varchar(max));

bulk insert Inventory
from 'C:\Users\FCI1626\Downloads\Analytics_project\SQL\Store_sales\inventory.csv'
with (fieldterminator = ',',
	 rowterminator ='\n',
	 firstrow = 2,
	 maxerrors = 10);

select * from Inventory;


---checking the data inconsistency, then changing the datatype

select column_name,data_type
from INFORMATION_SCHEMA.columns
where table_name = 'Sales';

select * from Sales;

alter table Sales
alter column sale_id int;

-- checking anamoliles in date column 
select date from sales
where isdate(date) = 0; 

update Sales
set date = convert(date,date,103)
where isdate(date) = 0;

alter table Sales
alter column date date;

alter table Sales
alter column store_id int;

alter table Sales
alter column product_id int;

alter table Sales
alter column units int;


select column_name,data_type
from INFORMATION_SCHEMA.columns
where table_name = 'Products';

select * from Products;

alter table Products
alter column product_id int;

update Products
set Product_Cost = replace(Product_Cost, '$','');

alter table Products
alter column product_cost decimal (5,2);

update Products
set Product_Price = replace(Product_Price, '$','');

alter table Products
alter column product_price decimal (5,2);


select column_name,data_type
from INFORMATION_SCHEMA.columns
where table_name = 'Stores';

select * from Stores;

alter table stores 
alter column store_id int;

alter table stores
alter column store_open_date date;

select * from stores
where isdate(store_open_date) = 0;

update Stores
set Store_Open_Date = convert(date,Store_Open_Date,103)
where isdate(Store_Open_Date) = 0;


select column_name,data_type
from INFORMATION_SCHEMA.columns
where table_name = 'Inventory';

select * from Inventory;

alter table Inventory
alter column store_id int;

alter table Inventory
alter column product_id int;

alter table Inventory
alter column stock_on_hand int;


select column_name,data_type
from INFORMATION_SCHEMA.columns;

--- checking for dulplicate records

--sales
select * from Sales;

with duplicates_s as (select *, row_number() over(partition by sale_id, 
date,store_id, product_id, units order by sale_id) as row_num
from sales)
select * from duplicates_s
where row_num > 1;

--product
select * from Products;

with duplicate_p as (select *, row_number() over (partition by product_id,
product_name, product_category, product_cost, product_price order by product_id) as row_num
from Products)
select * from duplicate_p
where row_num > 1;

--stores
select * from Stores;

with duplicates_s as (select *, row_number() over(partition by store_id, store_name,
store_city, store_location, store_open_date order by store_id) as row_num
from Stores)
select * from duplicates_s
where row_num > 1;


--inventory
select * from inventory

with duplicate_i as (select *, row_number() over(partition by store_id, product_id,
stock_on_hand order by store_id) as row_num
from Inventory)
select * from duplicate_i
where row_num > 1;

-- no duplicates

-- creating relation between tables
select column_name, data_type
from INFORMATION_SCHEMA.columns

select * from Sales;
select count(distinct sale_id) from Sales;

alter table sales
alter column sale_id int not null;

alter table sales
add constraint pksid primary key(sale_id);
 
select * from Products;
select count(distinct product_id) from products;

alter table products
alter column Product_id int not null;

alter table products
add constraint pkpid primary key(product_id);


select * from Stores;
select count(distinct store_id) from stores;

alter table stores
alter column store_id int not null;

alter table stores
add constraint pkstrid primary key(store_id);


alter table sales
add constraint fkstr foreign key(store_id) references stores(store_id);

alter table Inventory
add constraint fkstr1 foreign key(store_id) references stores(store_id);

alter table sales
add constraint fkprd foreign key(product_id) references products(product_id);

alter table Inventory
add constraint fkprd1 foreign key(product_id) references products(product_id);





---- Product perfomance analysis
select * from Products;

select distinct(product_category) as Prod_cat from Products;
select distinct(product_name) as Prod_name from Products;

--- Profitability by category
select Product_Category, sum(Units * (Product_Price - Product_Cost)) as Total_Profit
from Sales sa
join Products p on sa.Product_ID = p.Product_ID
group by Product_Category
order by Total_Profit desc;

select p.Product_Name, 
sum(s.Units) as total_units_sold
from Sales s
JOIN Products p on s.Product_ID = p.Product_ID
group by p.Product_Name
order by total_units_sold desc;
/*top selling products - colorbuds 104368 units, 
PlayDoh Can 103128 units, 
Barrel O' Slime 91663 units, 
Deck Of Cards 84034 units,
Magic Sand 60598*/

select p.Product_Name, 
sum(s.Units * p.Product_Price) as total_revenue
from Sales s
join Products p on s.Product_ID = p.Product_ID
group by p.Product_Name
order by total_revenue desc;
/*top revenue generators - Lego Bricks 2388882.63, 
Colorbuds 1564476.32, 
Magic Sand 968962.02,
Action Figure 926748.42,
Rubik's Cube	912983.28 */

--category wise bifurcation of revenue and units sold				  
with product_analysis as 
(select p.Product_Category, p.product_name,
sum(case when year(date) = 2022 then s.Units else 0 end) as total_units_sold_2022,
sum(case when year(date) = 2023 then s.Units else 0 end) as total_units_sold_2023,
sum(case when year(date) = 2022 then s.units * p.product_price else 0 end) as total_revenue_2022,
sum(case when year(date) = 2023 then s.units * p.product_price else 0 end) as total_revenue_2023
from Sales s
join Products p on s.Product_ID = p.Product_ID
group by p.Product_Category, Product_Name)
select *, total_units_sold_2023 - total_units_sold_2022 as 'Difference_in_units', 
          total_revenue_2023 - total_revenue_2022 as 'Difference_in_Revenue',
		  rank() over (partition by Product_Category order by (total_revenue_2023 - total_revenue_2022) desc) as rank_by_units
from product_analysis;
/* apart from magic sand, all other products revenue have fallen down in 2023 as compared tp 2022 */

-- foam disk launcher and playfoam was imtroduced in 2023
select  Product_Name, sum(stock_on_hand) as stock, year(date) as Year
from Products p
join sales s
on p.Product_ID = s.Product_ID
right join Inventory i
on s.Product_ID = i.Product_ID
where Product_Name = 'Foam Disk Launcher' 
group by Product_Name, year(date);

select Product_Name, sum(stock_on_hand) as stock, year(date) as Year
from Products p
join sales s
on p.Product_ID = s.Product_ID
right join Inventory i
on s.Product_ID = i.Product_ID
where Product_Name = 'playfoam' 
group by Product_Name, year(date);

--understanding the cost structure 
select p.Product_Name, 
sum(s.Units * Product_Cost) as total_Cost
from Sales s
join Products p on s.Product_ID = p.Product_ID
group by p.Product_Name
order by total_Cost desc; 


select p.Product_Name, 
sum(s.Units * Product_Price)-sum(s.units * Product_Cost) as total_profit
from Sales s
join Products p on s.Product_ID = p.Product_ID
group by p.Product_Name
order by total_profit desc; 
/* top 5 profitable items Colorbuds	834944,
Action Figure 347748,
Lego Bricks	298685,
Deck Of Cards 252102,
Glass Marbles 187590 */

with profit_analysis as
(select p.Product_Name,
sum(case when year(date) = 2022 then s.Units * (p.Product_Price - p.Product_Cost) else 0 end) as total_profit_2022,
sum(case when year(date) = 2023 then s.Units * (p.Product_Price - p.Product_Cost) else 0 end) as total_profit_2023
from Sales s
join Products p on s.Product_ID = p.Product_ID
group by p.Product_Name)
select *, total_profit_2023 - total_profit_2022 as 'differnce_in_profit'
from profit_analysis
order by differnce_in_profit desc;
/* the items which are in top profitable items overall list, actually their whole profit declined in 2023 as compared to 2022 */

--profit margin		
select p.Product_Name,
round(((p.Product_Price - p.Product_Cost) / p.Product_Price) * 100, 2) as profit_margin
from Products p
order by profit_margin desc;
/* highest profit margin - Jenga 70.07,
Mini Basketball Hoop 64.03,
Playfoam 63.69 */

--product with the highest sales from each product category
with product_tab as(select product_category, product_name, sum(units) as 'total_units_sold'
from Products p
join sales s
on p.product_id=s.product_id
group by product_category, product_name),
rank_prod as (select *,row_number() over(partition by product_category order by total_units_sold desc) as 'rank' from product_tab)
select pt.product_category,pt.product_name,pt.total_units_sold
from product_tab pt
join rank_prod r
on pt.product_name=r.Product_name
where r.rank=1
order by total_units_sold;

--product with the lowest sales from each product category
with product_tab as(select product_category, product_name, sum(units) as 'total_units_sold'
from Products p
join sales s
on p.product_id = s.product_id
group by product_category, product_name),
ranked_products as (select *,row_number() over(partition by product_category order by total_units_sold)
as 'rank' from product_tab)
select pt.product_category,pt.product_name,pt.total_units_sold
from product_tab pt
join ranked_products r
on pt.product_name=r.Product_name
where r.rank=1
order by total_units_sold;


--stock vs units sold
select p.Product_name,
sum(i.stock_on_hand) as Total_stock,
sum(s.units) as Total_units_sold
from Products p
join Inventory i
on p.Product_ID = i.Product_ID 
left join Sales s
on p.Product_ID = s.Product_ID
group by Product_Name
order by Total_stock desc;

---sales summary
with Sales_summary as 
(select product_category, product_name, 
sum(units) as Total_units_sold,
sum(units* product_price) as Revenue, 
sum(units * product_cost) as Cost,
(sum(units* product_price)-sum(units * product_cost)) as Profit
from Products p
join sales s
on p.product_id=s.product_id
group by product_category, product_name)
select *, profit/revenue *100.0 as Profit_margin from sales_summary
order by Product_Category,Profit desc;




-----Store performance analysis-----
select * from Stores;

select st.Store_name,
sum(s.units) AS Total_units_sold,
sum(s.units * p.product_price) AS Total_revenue,
round(sum(s.units * p.product_price) / sum(s.units), 2) as Revenue_per_unit
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
join Products p
on s.Product_ID = p.Product_ID
group by st.Store_name
order by Total_revenue DESC;

select Store_location,count(distinct st.store_id) Num_of_stores,
sum(s.units) as Totat_units
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
group by Store_location
order by Totat_units desc;
/*Downtown 29
Commercial 12
Residential 6
Airport 3*/

--profitability for each loaction
select st.Store_location,
count(distinct st.store_id) as Num_of_stores,
sum(s.units * (p.Product_Price - p.Product_Cost)) as Total_profit,
round(sum(s.units * (p.Product_Price - p.Product_Cost)) / count(distinct st.store_id), 2) as Profit_per_store
from Stores st
join Sales s on st.Store_ID = s.Store_ID
join Products p on s.Product_ID = p.Product_ID
group by st.Store_location
order by Total_profit desc;

--sales summary for each location
select st.Store_Location, 
sum(s.units) as Totat_units,
sum(p.product_cost) as Total_Cost,
sum(s.units * p.product_price) as Total_Revenue,
sum(s.units * (p.product_price - p.product_cost)) as Total_profit,
round((sum(s.units *p.product_price) - sum(s.units * p.product_cost))/sum(p.product_price)*100,2) as Profit_margin
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
join Products p
on s.Product_ID = p.Product_ID
group by Store_Location
order by Total_profit desc;

select st.Store_Location,p.product_category,
sum(s.units) as Totat_units,
sum(p.product_cost) as Total_Cost,
sum(s.units * p.product_price) as Total_Revenue,
sum(s.units * p.product_price) - sum(p.product_cost) as Total_profit,
round((sum(s.units *p.product_price) - sum(s.units * p.product_cost))/sum(p.product_price)*100,2) as Profit_margin
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
join Products p
on s.Product_ID = p.Product_ID
group by Store_Location, Product_Category
order by store_location, Total_profit desc;

--each store sale analysis
select st.Store_name, 
sum(s.units) as Totat_units,
sum(p.product_cost) as Total_Cost,
sum(s.units * p.product_price) as Total_Revenue,
sum(s.units * p.product_price) - sum(p.product_cost) as Total_profit,
round((sum(s.units *p.product_price) - sum(s.units * p.product_cost))/sum(p.product_price)*100,2) as Profit_margin
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
join Products p
on s.Product_ID = p.Product_ID
group by Store_Name
order by Total_profit desc;

--highest selling product in each store
with prod_high_cat as (select st.Store_name, p.Product_Name,
sum(s.units) as Total_units,
sum(p.product_cost) as Total_Cost,
sum(s.units * p.product_price) as Total_Revenue,
sum(s.units * p.product_price) - sum(p.product_cost) as Total_profit,
round((sum(s.units *p.product_price) - sum(s.units * p.product_cost))/sum(p.product_price)*100,2) as Profit_margin
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
join Products p
on s.Product_ID = p.Product_ID
group by Store_Name, Product_Name),
ranked as( select *, row_number() over(partition by store_name order by total_units desc) as 'Rank'
from prod_high_cat)
select pc.store_name, pc.Product_Name, pc.Total_units, pc.Total_cost, pc.Total_revenue, pc.Total_Profit, pc.Profit_margin
from ranked pc
where pc.rank = 1

--lowest selling product in each store
with prod_high_cat as (select st.Store_name, p.Product_Name,
sum(s.units) as Total_units,
sum(p.product_cost) as Total_Cost,
sum(s.units * p.product_price) as Total_Revenue,
sum(s.units * p.product_price) - sum(p.product_cost) as Total_profit,
round((sum(s.units *p.product_price) - sum(s.units * p.product_cost))/sum(p.product_price)*100,2) as Profit_margin
from Stores st
join Sales s
on st.Store_ID = s.Store_ID
join Products p
on s.Product_ID = p.Product_ID
group by Store_Name, Product_Name),
ranked as( select *, row_number() over(partition by store_name order by total_units) as 'Rank'
from prod_high_cat)
select pc.store_name, pc.Product_Name, pc.Total_units, pc.Total_cost, pc.Total_revenue, pc.Total_Profit, pc.Profit_margin
from ranked pc
where pc.rank = 1

create function
Store_Product_Analysis(@StoreName nvarchar(100))
returns table
as
return
(with prod_high_cat as (select st.Store_name, p.product_category,p.product_name,
                               sum(s.units) AS Total_units,
                               sum(p.product_cost) as Total_Cost,
                               sum(s.units * p.product_price) as Total_Revenue,
                               sum(s.units * p.product_price) - sum(p.product_cost) as Total_profit,
                               round((sum(s.units * p.product_price) - sum(s.units * p.product_cost)) / 
                               sum(p.product_price) * 100, 2) as Profit_margin
from Stores st
join Sales s
on st.Store_ID = s.Store_ID 
join Products p
on s.Product_ID = p.Product_ID
where st.Store_name = @StoreName  -- Filter by store name
group by  Store_Name, Product_Category, p.product_name),
ranked_products as (select *,row_number() over (partition by product_category order by Total_units desc) as Rank from prod_high_cat)
select Store_name, product_category, product_name,Total_units, Total_Revenue,Total_profit, Profit_margin FROM ranked_products);

select distinct(store_name) from Stores;

select * from Store_Product_Analysis(' Toys Ciudad de Mexico 4')
order by total_units desc;




----- Sales trend analysis -----

--first and last day of sales
select min(date) as First_order, max(date) as Last_order_recorded, datediff(month, min(date),max(date)) as Sales_period_in_months
from Sales;

--weekly sales
select datename(weekday, date) as Sales_week, sum(units) as Total_units
from Sales
where format(date, 'yyyy') in (2022,2023) and datename(weekday,date) in ('sunday','saturday')
group by datename(weekday, date)
union all
select datename(weekday, date) as Sales_week, sum(units) as Total_units
from Sales
where format(date, 'yyyy') in (2022,2023) and datename(weekday,date) not in ('sunday','saturday')
group by datename(weekday, date)
order by Total_units desc;

--quarterly sales
select 
    year(s.Date) AS year,
    datepart(quarter, s.Date) AS Quarter,
    sum(s.units) AS Total_units_sold,
    sum(s.units * p.product_price) as Total_revenue
from Sales s
join Products p
on s.Product_ID = p.Product_ID
group by year(s.Date), datepart(quarter, s.Date)
order by Year, Quarter;

--monthly sales
select format(s.Date, 'yyyy-MM') AS Month,
sum(s.units) AS Total_units_sold,
sum(s.units * p.product_price) AS Total_revenue
from Sales s
join Products p
on s.Product_ID = p.Product_ID
group by FORMAT(s.Date, 'yyyy-MM')
order by Month;

--difference in 2022 and 2023 sales
with com_Sales as 
(select month(date) as Month, datepart(quarter,date) as Quarter,
sum(case when year(date) = 2022 then units else 0 end) as Total_units_sold_2022,
sum(case when year(date) = 2023 then units else 0 end) as Total_units_sold_2023
from Sales
group by month(date), datepart(quarter,date))
select *,Total_units_sold_2023 - Total_units_sold_2022 as Difference,
case when Total_units_sold_2023 - Total_units_sold_2022 > 0 then 'Incline' else 'Decline' end as Sales_trend
from com_Sales
order by Month;

-- Analysing monthly sales trends using a 3-month rolling average
-- Classifies trends as:
-- - Significant Growth: Sales > 120% of rolling average
-- - Significant Decline: Sales < 80% of rolling average
-- - Stable: Sales within 80%-120% of rolling average
with Monthly_Sales as (
select format(Date, 'yyyy-MM') AS Month,
       sum(Units) AS Total_units_sold
from Sales
group by format(Date, 'yyyy-MM')
),
Rolling as (
select [Current].Month,
       [Current].Total_units_sold,
       round(avg(Past.Total_units_sold), 0) AS Rolling_3_Month_Avg
from Monthly_Sales as [Current]
left join Monthly_Sales as Past
on cast(Past.Month + '-01' as date) 
between dateadd(Month, -2, cast([Current].Month + '-01' as date)) 
and eomonth(cast([Current].Month + '-01' as date))
group by [Current].Month, [Current].Total_units_sold
)
select Month,Total_units_sold,Rolling_3_Month_Avg,
case 
    when Total_units_sold > Rolling_3_Month_Avg * 1.2 then 'Significant Growth'
    when Total_units_sold < Rolling_3_Month_Avg * 0.8 then 'Significant Decline'
    else 'Stable'
    end as Trend
from Rolling
order by Month;


create function
get_product_sales(@productname nvarchar(100))
returns table
as
return
(select p.product_name,
format(s.date, 'yyyy-MM') as month,
sum(s.units) as total_units_sold,
sum(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
where p.product_name = @productname  -- filter by the specified product name
group by p.product_name, format(s.date, 'yyyy-MM'));

select distinct(product_name) from Products;
select * from get_product_sales('Animal Figures');





---- Cumulative Distribution of Profit Margin

with profitmargins as (select p.product_category, p.product_name,
sum(s.units * p.product_price) - sum(s.units * p.product_cost) as total_profit,
round((p.product_price - p.product_cost) / p.product_price * 100, 2) as profit_margin
from sales s
join products p
on s.product_id = p.product_id
group by p.product_category, p.product_name, p.product_price, p.product_cost)
select product_category, product_name, profit_margin,
sum(profit_margin) over (partition by product_category order by profit_margin) as cumulative_profit_margin
from profitmargins
order by profit_margin desc;





---- Inventory shortages
select i.Store_ID, s.Store_Name, i.Product_ID, p.Product_Name, i.Stock_On_Hand
from Inventory i
join Stores s on i.Store_ID = s.Store_ID
join Products p on i.Product_ID = p.Product_ID
where i.Stock_On_Hand < 10
order by i.Stock_On_Hand;

---- Store Inventory Turnover Analysis
With sales_analys as(select product_name, sum(case when year(date) =2022 then units*product_cost else 0 end) as COGS_2022,
						sum(case when year(date) =2023 then units*product_cost else 0 end) as COGS_2023
						from sales s
						join products p
						on s.product_id =p.product_id
						group by product_name)
,average_inv as (select p.product_name, avg(case when year(s.date) =2022 then stock_on_hand else 0 end) as 'avg_inv_2022',
										avg(case when year(s.date) =2023 then stock_on_hand else 0 end) as 'avg_inv_2023'
										from inventory i
										join products p 
										on i.product_id=p.product_id
										join sales s
										on i.product_id=s.product_id
										group by product_name
										)
select sa.Product_name, sa.COGS_2022, ai.avg_inv_2022,sa.COGS_2023, ai.avg_inv_2023,
		case when avg_inv_2022=0 then Null
		else (COGS_2022/avg_inv_2022) end as Inv_ratio_2022,
		case when avg_inv_2023=0 then Null
		else (COGS_2023/avg_inv_2023) end as Inv_ratio_2023
		from sales_analys sa
		join average_inv ai
		on sa.product_name=ai.product_name;
