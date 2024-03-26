/*
Question #1:

Identify installers who have participated in at least one installer competition by name.

Expected column names: name
*/

-- q1 solution:

-- This query filters for only participated installers.
SELECT DISTINCT i1.name
FROM install_derby AS i_d
INNER JOIN installers AS i1 -- Keeps only participated installers.
ON i1.installer_id = i_d.installer_one_id
UNION
SELECT DISTINCT i2.name
FROM install_derby AS i_d
INNER JOIN installers AS i2 -- Keeps only participated installers.
ON i2.installer_id = i_d.installer_two_id;

/*
Question #2: 
Write a solution to find the third transaction of every customer, where the spending on the preceding two transactions is lower than the spending on the third transaction. 
Only consider transactions that include an installation, and return the result table by customer_id in ascending order.

Expected column names: customer_id, third_transaction_spend, third_transaction_date
*/

-- q2 solution:

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

/*
Question #3: 
Write a solution to report the **most expensive** part in each order. 
Only include installed orders. In case of a tie, report all parts with the maximum price. 
Order by order_id and limit the output to 5 rows.

Expected column names: `order_id`, `part_id`

*/

-- q3 solution:

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

/*
Question #4: 
Write a query to find the installers who have completed installations for at least four consecutive days. 
Include the `installer_id`, start date of the consecutive installations period and the end date of the consecutive installations period. 

Return the result table ordered by `installer_id` in ascending order.

E**xpected column names: `installer_id`, `consecutive_start`, `consecutive_end`**
*/

-- q4 solution:

-- This part makes sure there are no multiple dates for each installer.
WITH installs_count AS(
	SELECT installer_id, install_date, COUNT(*) AS num_of_installs
	FROM installs
	GROUP BY installer_id, install_date),

-- This part creates fields of before and after days differential from the current row.
before_and_after AS(
  SELECT *, 
		install_date - LAG(install_date, 1)
  		OVER(PARTITION BY installer_id ORDER BY install_date) AS gap_day_before,
  	LEAD(install_date, 1)
  		OVER(PARTITION BY installer_id ORDER BY install_date) - install_date AS gap_day_after
	FROM installs_count),

-- This part gets the highest gap for a 3 days span.
-- It's only 3 and not 4 days, as I already use a following/preceding day of the actual date.
consecutives AS(
  SELECT *,
		MAX(gap_day_before) OVER(ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS max_before,
  	MAX(gap_day_before) OVER(ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING) AS max_after
	FROM before_and_after),

-- This part gets the start day of the desired span.
consecutive_start AS(
  SELECT installer_id, install_date AS consecutive_start
	FROM consecutives
  WHERE max_after = 1 -- So there are 4 consecutives days in a row.
  	AND gap_day_after = 1 -- Still belongs to the span.
  	AND gap_day_before > 1), -- So it's the first day

-- This part gets the end day of the desired span.
consecutive_end AS(
	SELECT installer_id, install_date AS consecutive_end
 	FROM consecutives
 	WHERE max_before = 1 -- So there are 4 consecutives days in a row.
  	AND gap_day_after > 1 -- So it's the last day
  	AND gap_day_before = 1) -- Still belongs to the span.

-- This part joins the start and end dates. 
SELECT *
FROM consecutive_start
INNER JOIN consecutive_end
USING(installer_id);
