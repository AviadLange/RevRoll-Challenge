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