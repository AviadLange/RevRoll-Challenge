--This part calculates each customer's number of order and ranking.
WITH orders_count AS(
	SELECT COUNT(order_id) AS num_of_orders, customer_id, preferred_name,
		RANK() OVER(ORDER BY COUNT(order_id) DESC) AS ranking
	FROM orders
	INNER JOIN customers
	USING(customer_id)
	GROUP BY customer_id, preferred_name)

--This part filters for the customer with the most orders.
SELECT preferred_name
FROM orders_count
WHERE ranking = 1;
