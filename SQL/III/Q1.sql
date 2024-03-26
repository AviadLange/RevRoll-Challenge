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
