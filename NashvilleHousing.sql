use [PortfolioProject]
--Data Cleaning 
--Check first 10 rows
select top 10 * from [dbo].[Nashville_housing]

--Remove Extra Spaces in Address
update Nashville_housing 
set Property_Address=REPLACE(Property_Address,' ',' ')

--Trim All Text Columns
update Nashville_housing
set 
Land_Use=LTRIM(rtrim(Land_Use)),
Property_Address=LTRIM(RTRIM(Property_Address)),
Property_City=LTRIM(rtrim(Property_City)),
Owner_Name=LTRIM(rtrim(Owner_Name)),
City=LTRIM(rtrim(City)),
State=LTRIM(rtrim(State)),
Grade=LTRIM(RTRIM(Grade))

--Standardize Date
--If datatype is datetime, convert to date:
alter table Nashville_housing
alter column Sale_Date date

--Remove Duplicate Records
--Check duplicates:
with CTE as(
select *, ROW_NUMBER()
over(partition by Parcel_ID, Property_Address, Sale_Price
 order by Unique_ID) as row_num
from Nashville_housing
)
select * from CTE where row_num>1

--Delete duplicates:

with CTE as(
select *, ROW_NUMBER()
over(partition by Parcel_ID, Property_Address, Sale_Price
 order by Unique_ID) as row_num
from Nashville_housing
)
delete from CTE where row_num>1

--Clean Acreage Column
alter table Nashville_housing
alter column Acreage decimal(10,2)

--Remove Unnecessary Columns
alter table Nashville_housing
drop column image

--Check NULL Percentage
select count(*) as Total_rows,
sum(case when Owner_Name is null then 1 else 0 end) as nullowner
from Nashville_housing

--If NULL % is very high → consider dropping that column
ALTER TABLE Nashville_housing
DROP COLUMN Owner_Name

--Check NULL Percentage
select count(*) as Total_rows,
sum(case when Suite_Condo is null then 1 else 0 end) as nullowner
from Nashville_housing

--If NULL % is very high → consider dropping that column
ALTER TABLE Nashville_housing
DROP COLUMN Suite_Condo

--Check NULL Percentage
select count(*) as Total_rows,
sum(case when Address is null then 1 else 0 end) as nullowner
from Nashville_housing

--If NULL % is very high → consider dropping that column
ALTER TABLE Nashville_housing
DROP COLUMN Address

--Drop Unneccessary columns
ALTER TABLE Nashville_housing
DROP COLUMN PropertySplitAddress,PropertySplitCity

--Validate Sale_Price
--Check for suspicious prices:
select MIN(Sale_Price), MAX(Sale_Price) from Nashville_housing

--Investigate Very Low Prices
--A house selling for $50 is almost certainly:
--Check them:
select * from Nashville_housing where Sale_Price <=1000
order by Sale_Price

--They are not real market transactions → remove them.
delete from Nashville_housing
where Sale_Price<1000

--More than 50% of a column is NULL then drop such column based on business requirement
SELECT 
SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS NullCity,
SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS NullState,
SUM(CASE WHEN Tax_District IS NULL THEN 1 ELSE 0 END) AS NullTaxDistrict,
SUM(CASE WHEN Neighborhood IS NULL THEN 1 ELSE 0 END) AS NullNeighborhood,
SUM(CASE WHEN Land_Value IS NULL THEN 1 ELSE 0 END) AS NullLandValue,
SUM(CASE WHEN Building_Value IS NULL THEN 1 ELSE 0 END) AS NullBuildingValue,
SUM(CASE WHEN Total_Value IS NULL THEN 1 ELSE 0 END) AS NullTotalValue,
SUM(CASE WHEN Finished_Area IS NULL THEN 1 ELSE 0 END) AS NullFinishedValue,
SUM(CASE WHEN Foundation_Type IS NULL THEN 1 ELSE 0 END) AS NullFoundationType,
SUM(CASE WHEN Year_Built IS NULL THEN 1 ELSE 0 END) AS NullYear_Built
FROM Nashville_housing

alter table Nashville_housing
drop column City, State, Tax_District, Neighborhood, Land_Value, Building_Value, 
Total_Value, Finished_Area, Foundation_Type, Year_Built

-- =========================================
-- ADVANCED SQL ANALYSIS
-- =========================================
--1.Window Functions
--Rank Most Expensive Properties
select Property_City,Sale_Price,
RANK() over(Partition by Property_City order by Sale_Price desc) as Price_Rank
from [dbo].[Nashville_housing] where Property_City is not null

--Running Total of Sales
select Sale_Date,
sum(cast(Sale_Price as bigint)) over(order by Sale_Date) as 
Running_Sales from [dbo].[Nashville_housing]

--2.Trend Analysis
select year(Sale_Date) as year, 
count(*) as total_sales,
avg(cast(Sale_Price as bigint)) as 
avg_price from [dbo].[Nashville_housing]
group by year(Sale_Date) order by year

--3. Business Insights
--Identify High-Value Properties
with AvgPrice as (
select AVG(cast(Sale_Price as bigint)) 
as Avg_Price from [dbo].[Nashville_housing]
)
select Sale_Price from [dbo].[Nashville_housing] 
where Sale_Price >(select Avg_Price from AvgPrice)

--4. Case Statements with Business Logic
select Sale_Price,
case when Sale_Price < 100000 then 'low_value'
     when Sale_Price between 100000 and 300000 then 'mid_value'
	 else 'high_value'
end as Price_Category
from [dbo].[Nashville_housing]

--5. Location-Based Insights
select Property_City,
COUNT(*) as total_properties,
AVG(cast(Sale_Price as bigint)) as avg_price
from [dbo].[Nashville_housing]
group by Property_City
order by avg_price desc

--7. Indexing (Performance Optimization)
create index idx_sale_date on Nashville_housing(Sale_Date)
create index idx_city on Nashville_housing(Property_City)

--8. Views 
create view citypriceanalysis as 
select Property_City,
COUNT(*) as total_sales,
AVG(cast(Sale_Price as bigint)) as Avg_Price
from [dbo].[Nashville_housing]
group by Property_City

--9. Advanced Aggregations 
select Property_City,
COUNT(*) as sales_count,
SUM(cast(Sale_Price as bigint)) as total_revenue,
AVG(cast(Sale_Price as bigint)) as avg_price,
MAX(cast(Sale_Price as bigint)) as max_price,
MIN(cast(Sale_Price as bigint)) as min_price
from [dbo].[Nashville_housing]
group by Property_City

--10. Subqueries (Analytical Thinking)
select * from [dbo].[Nashville_housing] where Sale_Price>
(select AVG(cast(Sale_Price as bigint)) from [dbo].[Nashville_housing])












