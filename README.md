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
