# BA_SQL-Postgress
- Orders: Information about each of the purchases made in the app
(orders.sql)
- Users: Information about clients (users.sql)
- Stores: Information about the different partners (stores.sql)
- 
Task is to build an SQL query that creates a new table: user_orders, for
users that have placed at least 5 orders, containing the following information:

- User ID
- Time (in days) since the user signed up to the app 
- Total number of orders placed by the user 
- Average order value 
- Name of their favourite store, understanding this as the store with
more orders (if there is a tie use the one with the most recent order)

- % of delivered orders 
- Time when the last order was placed 
- Time (in days) that passed from the second last order to the last one

  The result is in user_orders.csv
  
Partners analysis
1. How many active partners do we have in our dataset?
2. What is the breakdown per country? And per business segment? 
3. What percentage of partners have delivered 80% of the orders? 
4. What is the average delivery time in Portugal (PT)? 
5. What is the share of orders that integrated partners delivered?
6. What is the distribution of the cost per order? Does it follow any
known distribution? Is there anything odd in the distribution? )
7. What is the number of orders compared to connected time? Is there
a correlation between the two? 
8. What are the differences in the metrics for food vs Q-commerce? 
9. Among all the possible combinations of dimensions (segments), which
one has the highest number of partners?

The summary you can find 
https://public.tableau.com/app/profile/irina8030/viz/OrderAnalysis_17097361279840/Story1?publish=yes
