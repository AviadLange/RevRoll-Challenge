-- This part joins all relevant data and orders each customer's orders by date.
WITH orders_by_customers AS(
	SELECT *, RANK() OVER(PARTITION BY customer_id ORDER BY install_date) AS orders_by_date,
		price*quantity AS transaction_spend
	FROM customers
	INNER JOIN orders
	USING(customer_id)
	INNER JOIN installs
	USING(order_id)
	INNER JOIN parts
	USING(part_id)),

-- This part limits for the first three transactions, and ranks them.
three_first AS(
  SELECT customer_id, transaction_spend, install_date, orders_by_date,
  	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY transaction_spend) AS d_rank_by_spent,
    RANK() OVER(PARTITION BY customer_id ORDER BY transaction_spend) AS rank_by_spent
	FROM orders_by_customers
	WHERE orders_by_date IN (1, 2, 3))

-- This part gets the third transactions under all required restrictions.
SELECT customer_id, transaction_spend AS third_transaction_spend,
	install_date AS third_transaction_date
FROM three_first
WHERE orders_by_date = 3
	-- Makes sure the third transaction is the unique highest.
  AND (d_rank_by_spent = 3 OR rank_by_spent = 3);