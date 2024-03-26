-- This part ranks every order by it's price.
WITH max_price AS(
  SELECT order_id, part_id, price,
		RANK() OVER(PARTITION BY order_id ORDER BY price DESC) AS price_ranking
	FROM installs
	INNER JOIN orders
	USING(order_id)
	INNER JOIN parts
	USING(part_id)
	ORDER BY order_id)

-- This part takes the 5 first orders with their corresponding most expensive part.
SELECT order_id, part_id
FROM max_price
WHERE price_ranking = 1
LIMIT 5;