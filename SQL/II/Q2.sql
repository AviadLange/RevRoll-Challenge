--This query finds the self installing customers who spent more than 2000$ on pars.
SELECT c.customer_id, preferred_name
FROM installs
RIGHT JOIN orders
USING(order_id)
INNER JOIN parts
USING(part_id)
INNER JOIN customers AS c
USING(customer_id)
WHERE install_id IS NULL --Filters for only self installed orders.
GROUP BY c.customer_id, preferred_name
HAVING SUM(quantity*price) >= 2000;
