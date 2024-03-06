--How many active partners do we have in our dataset?
SELECT COUNT(DISTINCT partner_id) as total_partners
FROM data_orders;

--What is the breakdown per country? And per business segment? 
SELECT dc.country,
		dbs. business_segment,
		COUNT(DISTINCT dc.partner_id) as number_of_partners	

FROM data_countries as dc
INNER JOIN data_business_segments AS dbs on dc.partner_id=dbs.partner_id
GROUP BY dc.country, dbs. business_segment
ORDER BY dc.country,
		dbs. business_segment,
		COUNT(DISTINCT dc.partner_id);
--What percentage of partners have delivered 80% of the orders. 21%
WITH total_orders AS (
    SELECT SUM(orders_daily) AS total
    FROM data_orders
),
aggregated_orders AS (
    SELECT
        partner_id,
        SUM(orders_daily) AS orders_sum
    FROM data_orders
    GROUP BY partner_id
),
cumulative_sum AS (
    SELECT
        partner_id,
        orders_sum,
        SUM(orders_sum) OVER (ORDER BY orders_sum DESC) AS running_total
    FROM aggregated_orders
)
,
total_partners AS (
    SELECT COUNT(DISTINCT partner_id) AS total_partner_count
    FROM data_orders
)
--table AS(
SELECT
	CASE WHEN running_total<= (total_orders.total * 0.8) THEN 'Group80%orders'
		ELSE 'Group20%orders'
		END as group80_20,
	COUNT(DISTINCT partner_id) as number_partners,
	ROUND((COUNT(DISTINCT partner_id)/ AVG(total_partner_count) * 100),0) AS percentage_of_partners
FROM cumulative_sum, total_orders, total_partners 
GROUP BY group80_20;

--What is the average delivery time in Portugal (PT)? 35 min
WITH partners_portugal AS(
SELECT 
	partner_id
FROM data_countries
WHERE country='PT'
)
SELECT 
		ROUND(AVG(avg_delivery_time_min),0) AS avg_delivery_time_min
FROM data_operations as da
INNER JOIN partners_portugal as pp on da.partner_id=pp.partner_id
;
--What is the share of orders that integrated partners delivered?
WITH partners_integrated AS(
	SELECT
		partner_id
	FROM data_integrations
	WHERE is_integrated IS TRUE
)
SELECT
		ROUND(SUM(d.orders_daily)/(SELECT SUM(orders_daily) AS total FROM data_orders)*100,1) AS share_of_int_orders
FROM data_orders as d
INNER JOIN partners_integrated as pi on d.partner_id=pi.partner_id;

--What is the distribution of the cost per order? Does it follow any
--known distribution? Is there anything odd in the distribution?
WITH part_1 AS(
SELECT  dod.orders_daily as number_of_orders,
		--COUNT(DISTINCT dod.partner_id),
		ROUND(AVG(df.avg_order_cost),2) AS cost_of_order
FROM data_orders AS dod
LEFT JOIN  data_finance as df on dod.partner_id=df.partner_id
WHERE df.avg_order_cost>0
GROUP BY dod.orders_daily
ORDER BY dod.orders_daily ASC)
,
part_2 AS(
SELECT
	CASE WHEN cost_of_order<2.6 THEN 'Very Low cost'
		WHEN cost_of_order<5.2 THEN 'Low'
		WHEN cost_of_order<7.8 THEN 'Medium cost'
		WHEN cost_of_order<10.4 THEN 'High'
		ELSE 'Very high cost'
		END as group_of_avg_cost,
	cost_of_order,
	SUM(number_of_orders) number_of_orders_cost
FROM part_1
GROUP BY cost_of_order
)

SELECT  
	group_of_avg_cost,
	SUM(number_of_orders_cost) as number_of_orders
FROM part_2
GROUP BY group_of_avg_cost;

WITH part_cost AS(
SELECT
		partner_id,
		ROUND (AVG(avg_order_cost),2) as avg_cost_part
FROM data_finance
GROUP BY partner_id
)

SELECT
		ROUND(avg_cost_part,2) AS avg_order_cost_part ,
		COUNT(DISTINCT partner_id) as number_partners
FROM part_cost
WHERE avg_cost_part>0
GROUP BY avg_cost_part
ORDER BY avg_cost_part ASC;

--What is the number of orders compared to connected time? Is there
--a correlation between the two? 

SELECT ROUND(corr (connected_hours,orders_daily)::numeric,3)
FROM data_orders;


--What are the differences in the metrics for food vs Q-commerce?
SELECT bs.business_segment,
		dv.vertical,
		COUNT(bs.partner_id),
		ROUND(AVG (avg_delivery_time_min),2) as avg_delivery_time,
		ROUND(AVG(avg_order_cost),2) as avg_order_cost,
		ROUND(AVG(avg_order_revenue)) as avg_order_revenue
FROM data_business_segments as bs
JOIN data_vertical as dv on bs.partner_id=dv.partner_id
LEFT JOIN data_operations as dod on bs.partner_id=dod.partner_id
LEFT JOIN data_finance as df on bs.partner_id=df.partner_id
GROUP BY bs.business_segment, dv.vertical;

--Among all the possible combinations of dimensions (segments), which
--one has the highest number of partners? 
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM CROSSTAB(
  $$
  WITH f AS (
    SELECT 
      dv.vertical AS vertical,
      bs.business_segment AS business_segment,
      dc.country AS country,
      COUNT(DISTINCT bs.partner_id) AS number_of_partners
    FROM data_business_segments AS bs
    JOIN data_vertical AS dv ON bs.partner_id = dv.partner_id
    JOIN data_countries AS dc ON bs.partner_id = dc.partner_id
    GROUP BY bs.business_segment, dv.vertical, dc.country
    ORDER BY dv.vertical, bs.business_segment, dc.country
  )
  SELECT 
    vertical || ' - ' || business_segment AS business_segment, 
    country, 
    number_of_partners
  FROM f
  ORDER BY 1, 2
  $$,
  $$ SELECT unnest(ARRAY['ES', 'IT', 'PT', 'UA']) $$  -- This part needs to be adjusted if your countries change
) AS final_result (
  business_segment TEXT,
  "ES" INT,
  "IT" INT,
  "PT" INT,
  "UA" INT
);
