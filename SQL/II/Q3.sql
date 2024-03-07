--This part filters for customers who purchased engine oil.
WITH Engine_Oil AS(
	SELECT DISTINCT customer_id, name AS engine_oil
	FROM parts
	INNER JOIN orders
	USING(part_id)
	INNER JOIN customers
	USING(customer_id)
	WHERE name = 'Engine Oil'),

--This part filters for customers who purchased oil filter.
Oil_Filter AS(
	SELECT DISTINCT customer_id, name AS oil_filter
	FROM parts
	INNER JOIN orders
	USING(part_id)
	INNER JOIN customers
	USING(customer_id)
	WHERE name = 'Oil Filter'),

--This part filters for customers who purchased air filter.
Air_Filter AS(
	SELECT DISTINCT customer_id, name AS air_filter
	FROM parts
	INNER JOIN orders
	USING(part_id)
	INNER JOIN customers
	USING(customer_id)
	WHERE name = 'Air Filter')

--This part filters for those who purchased the first two and didn't purchase the third part.
SELECT c.customer_id, preferred_name
FROM Engine_Oil
FULL JOIN Oil_Filter --Makes sure I'll get all records.
USING(customer_id)
FULL JOIN Air_Filter --Makes sure I'll get all records.
USING(customer_id)
INNER JOIN customers AS c
USING(customer_id)
WHERE engine_oil IS NOT NULL
	AND oil_filter IS NOT NULL
  AND air_filter IS NULL;
