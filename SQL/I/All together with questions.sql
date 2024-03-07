/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.

Expected column names: name, bonus
*/

-- q1 solution:

-- This query calculates 10% of each installer's parts installed.
SELECT installers.name, ROUND((SUM(price*quantity)*0.1),0) AS bonus
FROM installers
INNER JOIN installs
USING(installer_id)
INNER JOIN orders
USING(order_id)
INNER JOIN parts
USING(part_id)
GROUP BY installers.name
ORDER BY bonus;

/*
Question #2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” where installers face off to see who can change a part the fastest in a tournament style contest.

Derby points are awarded as follows:

- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by `installer_id` in increasing order.

Expected column names: `installer_id`, `name`, `num_points`

*/

-- q2 solution:

-- This part assigns points to the winner of each derby.
WITH points AS(SELECT derby_id, installer_one_id, installer_two_id,
	CASE WHEN installer_one_time < installer_two_time THEN 3
		WHEN installer_one_time = installer_two_time THEN 1
  	ELSE 0 END AS points_player_one,
  CASE WHEN installer_one_time > installer_two_time THEN 3
		WHEN installer_one_time = installer_two_time THEN 1
  	ELSE 0 END AS points_player_two
FROM install_derby),

-- This part sums each installer's points, for installer_one and installer_two.
totals AS(SELECT installer_one_id AS installer_id, SUM(points_player_one) AS points
FROM points
GROUP BY installer_one_id
UNION ALL -- Includes installers with points as installer_one and installer_two.
SELECT installer_two_id AS installer_id, SUM(points_player_two) AS points
FROM points
GROUP BY installer_two_id)

-- This part sums each installer's points from both fields.
SELECT installer_id, installers.name, COALESCE(SUM(points), 0) AS num_points
FROM totals
RIGHT JOIN installers -- Gets also installers who didn't participate in a derby.
USING(installer_id)
GROUP BY installer_id, installers.name
ORDER BY num_points DESC, installer_id;

/*
Question #3:

Write a query to find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, you should find the install with the smallest `derby_id`.

Return the result table ordered by `installer_id` in ascending order.

Expected column names: `derby_id`, `installer_id`, `install_time`
*/

-- q3 solution:

-- This part lists every score for both installers in each derby.
WITH combined_installers AS(
	SELECT derby_id, installer_one_id AS installer_id, installer_one_time AS i_time
	FROM install_derby
	UNION ALL
	SELECT derby_id, installer_two_id AS installer_id, installer_two_time AS i_time
	FROM install_derby),

-- This part finds the minimum time for each installer.
min_time AS(
	SELECT installer_id, MIN(i_time) AS install_time
	FROM combined_installers
	GROUP BY installer_id)

-- This part takes the derby with smallest id for installers with multiple minimum scores.
SELECT MIN(derby_id) AS derby_id, m.installer_id, install_time
FROM min_time AS m
INNER JOIN combined_installers AS c
ON m.installer_id = c.installer_id
	AND m.install_time = c.i_time
GROUP BY m.installer_id, install_time
ORDER BY m.installer_id;

/*
Question #4: 
Write a solution to calculate the total parts spending by customers paying for installs on each Friday of every week in November 2023. 
If there are no purchases on the Friday of a particular week, the parts total should be set to `0`.

Return the result table ordered by week of month in ascending order.

Expected column names: `november_fridays`, `parts_total`
*/

-- q4 solution:

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
