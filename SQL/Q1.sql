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
