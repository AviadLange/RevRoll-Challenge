-- This part creates a field of every day of November 2023.
WITH whole_nov AS (
  SELECT generate_series('2023-11-01'::date, '2023-11-30'::date,
                         '1 day'::interval) AS nov_days),

-- This part joins the installs data for every day of November 2023, and gets each date's DOW.
days_and_dates AS(
	SELECT wn.nov_days, i.*,
  	TO_CHAR(nov_days, 'Dy') AS day_of_week
	FROM whole_nov AS wn
	LEFT JOIN installs AS i -- Preseves only the November dates.
	ON wn.nov_days = i.install_date)

-- This part sums each Friday's spending on parts for November 23.
SELECT TO_CHAR(nov_days, 'YYYY-MM-DD') AS november_fridays,
   COALESCE(ROUND(SUM(price*quantity),2), 0) AS parts_total
FROM days_and_dates
FULL JOIN orders
USING(order_id)
FULL JOIN parts
USING(part_id)
WHERE day_of_week = 'Fri'
GROUP BY nov_days
ORDER BY november_fridays;
