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
