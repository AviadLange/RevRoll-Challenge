/*
Question #1:

Write a query to find the customer(s) with the most orders. 
Return only the preferred name.

Expected column names: preferred_name
*/

-- q1 solution:

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

/*
Question #2: 
RevRoll does not install every part that is purchased. 
Some customers prefer to install parts themselves. 
This is a valuable line of business 
RevRoll wants to encourage by finding valuable self-install customers and sending them offers.

Return the customer_id and preferred name of customers 
who have made at least $2000 of purchases in parts that RevRoll did not install. 

Expected column names: customer_id, preferred_name

*/

-- q2 solution:

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

/*
Question #3: 
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter since we want to recommend these customers buy an Air Filter.
Return the result table ordered by `customer_id`.

Expected column names: customer_id, preferred_name

*/

-- q3 solution:

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

/*
Question #4: 

Write a solution to calculate the cumulative part summary for every part that 
the RevRoll team has installed.

The cumulative part summary for an part can be calculated as follows:

- For each month that the part was installed, 
sum up the price*quantity in **that month** and the **previous two months**. 
This is the **3-month sum** for that month. 
If a part was not installed in previous months, 
the effective price*quantity for those months is 0.
- Do **not** include the 3-month sum for the **most recent month** that the part was installed.
- Do **not** include the 3-month sum for any month the part was not installed.

Return the result table ordered by `part_id` in ascending order. In case of a tie, order it by `month` in descending order. Limit the output to the first 10 rows.

Expected column names: part_id, month, part_summary
*/

-- q4 solution:

--This part generates a serie of 12 values (months) for each part.
WITH all_month AS(
	SELECT DISTINCT part_id, generate_series(1, 12) AS twelve_months 
	FROM parts),

--This part sums each part monthly spending.
spent_per_month AS(
	SELECT part_id,
  	EXTRACT(MONTH FROM install_date) AS month_installed, SUM(price*quantity) AS monthly_spent
	FROM installs
	INNER JOIN orders
	USING(order_id)
	INNER JOIN parts
	USING(part_id)
	GROUP BY 1, 2
	ORDER BY 1),
  
--This part joins the previous tables to get every month, even without purchases.  
joined_tables AS(
  SELECT a.part_id, COALESCE(monthly_spent, 0) AS month_spent, twelve_months, month_installed
	FROM all_month AS a
	LEFT JOIN spent_per_month AS s --Preserves the months with no purchases for every part.
	ON a.part_id = s.part_id
		AND a.twelve_months = s.month_installed
  ORDER BY a.part_id, month_installed DESC),

--This part mainly calculates the umulative sum as requested.
cum_sum AS(
	SELECT *,
		--This field holds the cumulative sum of the month end 2 preceding for every part. 
  	SUM(month_spent) OVER(PARTITION BY part_id ORDER BY twelve_months
       ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS part_summary,
  	--this field hold the last month with action for every part.
  	MAX(month_installed) OVER(PARTITION BY part_id ORDER BY twelve_months
       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS max_month
	FROM joined_tables
	ORDER BY part_id, month_installed DESC)

--This part gets only the desired records, limited to first 10 results.
SELECT part_id, twelve_months AS month, part_summary
FROM cum_sum
WHERE max_month - twelve_months > 0 --Eliminates each part's last month.
	AND month_installed IS NOT NULL --Eliminates months with no part's purchases.
LIMIT 10;
