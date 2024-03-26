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