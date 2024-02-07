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