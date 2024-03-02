WITH td AS(
SELECT
		id,
		--Time (in days) since the user signed up to the app 
		CURRENT_DATE-(DATE_TRUNC('DAY', signed_up_time::timestamp)::date) as time_in_days
	FROM users
	ORDER BY id DESC
), 
user_time_total_avg AS(
SELECT	o.user_id as user_id,
		--Time (in days) since the user signed up to the app 
		ROUND(AVG(td.time_in_days),0) as time_in_days,
		--Total number of orders placed by the user 
		COUNT(*) AS total_number_orders,
		--Average order value 
		ROUND(CAST(AVG(total_price) AS numeric),2) AS avg_order_value		
FROM orders AS o
INNER JOIN td as td on o.user_id=td.id
GROUP BY o.user_id,td.id
ORDER BY user_id ASC
),
		--Name of their favourite store, understanding this as the store with
		--more orders (if there is a tie use the one with the most recent order)
fav_store AS(
SELECT	
		--find number of orders per store and latest_order_date
		o.user_id as user_id,
		s.id as store_id,
		s.name as name_store,
		COUNT(*) as order_count,
		MAX(o.creation_time) as latest_order_date
FROM orders o
INNER JOIN stores s on o.store_id=s.id	
GROUP BY o.user_id, s.id
ORDER BY o.user_id
)
,
ran as(
 SELECT
	--rank orders per date, because if there is a tie  we need to use with the most recent order
	user_id,
	store_id,
	name_store,
	order_count,
	latest_order_date,
	RANK() OVER(PARTITION BY user_id ORDER BY order_count DESC, latest_order_date DESC) as rn
FROM fav_store
)
,	
	   --final set of name of favorite store
name_of_fstore as(	   
SELECT
		user_id,
		name_store
FROM ran
WHERE rn=1
ORDER BY user_id DESC
),

		--% of delivered orders
persent_delivery_orders AS(
SELECT a.user_id,
	   COUNT(user_id) as total_per_user,
	   (SELECT COUNT(*)
	    FROM orders as b
	    WHERE b.final_status='DeliveredStatus' and b.user_id=a.user_id
		GROUP BY b.user_id
	    ORDER BY b.user_id DESC)as deliv_orders	   
	
FROM orders as a
GROUP BY a.user_id
ORDER BY a.user_id DESC
)
,
p_or AS(
SELECT  user_id,
		ROUND((deliv_orders::numeric/total_per_user::numeric)*100,0) as por_deliv_orders
FROM persent_delivery_orders
ORDER BY user_id DESC
)
,
	--Time (in days) that passed from the second last order to the last one
order_dif AS (
SELECT
        user_id,
        creation_time,
        LAG(creation_time) OVER (PARTITION BY user_id ORDER BY creation_time DESC) AS previous_order_date,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY creation_time DESC) AS order_rank
FROM orders
),
	--Time (in days) that passed from the second last order to the last one
time_in_days_second_first AS(
SELECT
    user_id,
    EXTRACT (days from previous_order_date - creation_time) AS days_difference,
	previous_order_date as last_order_user
FROM
    order_dif
WHERE
    order_rank = 2
)
SELECT	utta.user_id as user_id,
		--Time (in days) since the user signed up to the app 
		utta.time_in_days,
		--Total number of orders placed by the user 
		utta.total_number_orders,
		--Average order value 
		utta.avg_order_value,		
		--Name of their favourite store, understanding this as the store with
		--more orders 
		nof.name_store as name_of_favorite_store,
		--% of delivered orders
		por.por_deliv_orders,
		--Time when the last order was placed
		tidsf.last_order_user,
		--Time (in days) that passed from the second last order to the last one
		tidsf.days_difference
		
FROM user_time_total_avg as utta
INNER JOIN name_of_fstore as nof on utta.user_id=nof.user_id 
INNER JOIN p_or as por on utta.user_id=por.user_id 
INNER JOIN time_in_days_second_first as tidsf on utta.user_id=tidsf.user_id
WHERE utta.total_number_orders>5
ORDER BY user_ID DESC;
