-- Create a database
DROP DATABASE IF EXISTS autotheft_ottawa;
CREATE DATABASE autotheft_ottawa
DEFAULT CHARACTER SET utf8mb4;

USE autotheft_ottawa;

/* 
Exploratory Data Analysis on over 7000 reported AutoTheft incidents in Ottawa
from 2018-2023. 
*/
-- 1. Number of Vehicle Thefs in 2023 and the total loss value
SELECT COUNT(*) AS Num_Stolen, SUM(VEH_VALUE) AS Loss_Value
FROM autotheft
WHERE OCC_YEAR = 2023;

-- 2. Recovery Rate
SELECT RECOVERED, COUNT(*),
ROUND((COUNT(*) * 100)/SUM(COUNT(*)) OVER (), 2) AS Percentage
FROM autotheft
GROUP BY RECOVERED;

-- 3. Number of Thefts per Year and YoY Change
SELECT OCC_YEAR, COUNT(*),
CASE
	WHEN LAG(COUNT(*)) OVER (ORDER BY OCC_YEAR) IS NOT NULL
    THEN ROUND((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY OCC_YEAR)) * 100.0 
		/ LAG(COUNT(*)) OVER (ORDER BY OCC_YEAR), 2)
	ELSE NULL
END AS YoY_Change
FROM autotheft
GROUP BY OCC_YEAR
ORDER BY OCC_YEAR;

-- 4. Number of Monthly Thefts through the year
SELECT OCC_MONTH, COUNT(*)
FROM autotheft
GROUP BY OCC_MONTH
ORDER BY COUNT(*) DESC;

-- 5. Num of thefts BY TIME OF DAY
SELECT TOD, COUNT(*)
FROM autotheft
GROUP BY TOD
ORDER BY COUNT(*) DESC;

-- 6. Thefts % increase across different DIVISIONS
with total_thefts AS (
	SELECT OCC_YEAR, Division, COUNT(*) as total_count
	FROM autotheft
	WHERE OCC_YEAR in (2018, 2023)
	GROUP BY OCC_Year, Division
),
yearly_comparison AS (
	SELECT t2018.Division, 
    t2018.total_count AS total_thefts2018, 
    t2023.total_count AS total_thefts2023
    FROM (SELECT * FROM total_thefts WHERE OCC_YEAR = 2018) t2018
	JOIN (SELECT * FROM total_thefts WHERE OCC_YEAR = 2023) t2023
    ON t2018.Division = t2023.Division
)
SELECT 
Division,
total_thefts2018,
total_thefts2023,
CASE 
	WHEN total_thefts2018 IS NULL THEN 'N/A'
	WHEN total_thefts2018 = 0 THEN 'Infinity'
	ELSE ROUND(((total_thefts2023 - total_thefts2018) * 100.0) / total_thefts2018, 2)
END AS PercentIncrease
FROM yearly_comparison;

-- 7. Highest Theft Division
SELECT Division, Count(*), 
ROUND((COUNT(*) * 100)/SUM(COUNT(*)) OVER (), 2) AS Percentage
FROM autotheft
GROUP BY Division;

-- 8. Highest Theft Neighbourhood
SELECT NB_NAME_EN, COUNT(*), SUM(VEH_VALUE)
FROM autotheft
GROUP BY NB_NAME_EN
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 9. Thefts by Vehicle Manufacturer
SELECT VEH_MAKE, COUNT(*),
ROUND((COUNT(*) * 100)/SUM(COUNT(*)) OVER (), 2) AS Percentage
FROM autotheft
GROUP BY VEH_MAKE
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 10. Thefts by Vehicle Model and Year
SELECT VEH_DESCRIPTION, COUNT(*),
ROUND((COUNT(*) * 100)/SUM(COUNT(*)) OVER (), 2) AS Percentage
FROM autotheft
GROUP BY VEH_DESCRIPTION
ORDER BY COUNT(*) DESC
LIMIT 10;


-- 11. Num of Theft and Vehicle Value for cars manufactured 2017 or newer
SELECT count(*), SUM(VEH_VALUE)
FROM autotheft
WHERE VEH_YEAR >= 2017;

-- 12. Recovery Rate of cars 2017 or newer
with recovery AS (
	SELECT COUNT(*) as total_recovered
    FROM autotheft
    WHERE VEH_YEAR >= 2017 AND RECOVERED = 'Y'
),
totalthefts AS (
	SELECT COUNT(*) AS total_count
    FROM autotheft 
    WHERE VEH_YEAR >= 2017
)
SELECT ROUND((total_recovered/total_count) * 100,2) as recovery_rate
FROM recovery
CROSS JOIN totalthefts;

-- 13. Number of theft by Vehicle Style
SELECT VEH_STYLE, COUNT(*)
FROM autotheft 
GROUP BY VEH_STYLE
ORDER BY COUNT(*) DESC;

-- 14. Recovery Rate by Vehicle Make with at least 200 reported theft
with cte_recovered AS (
	select VEH_MAKE, count(*) as amount_recovered
	from theft_data
	where RECOVERED = 'Y'
	GROUP BY VEH_MAKE
),
cte_count AS (
	SELECT veh_make, COUNT(*) as total_amount
	FROM theft_data
	group by veh_make
),
cte_value AS (
	SELECT veh_make, AVG(VEH_VALUE) as veh_val
    FROM theft_data
    GROUP BY veh_make
)
select cc.veh_make, cc.total_amount as total_thefts, cr.amount_recovered, (cr.amount_recovered/cc.total_amount) * 100 as recovery_rate, ROUND(cv.veh_val,2) AS average_value
from cte_recovered cr
join cte_count cc ON cr.VEH_MAKE = cc.VEH_MAKE
join cte_value cv ON cr.VEH_MAKE = cv.VEH_MAKE
WHERE cc.total_amount > 200
ORDER by recovery_rate DESC;

select VEH_MAKE, AVG(VEH_VALUE)
from theft_data
GROUP BY VEH_MAKE
ORDER BY AVG(VEH_VALUE) DESC;

-- 15. recovery rate by neighbourhood
with cte_recovered AS (
	select DIVISION, count(*) as amount_recovered
	from theft_data
	where RECOVERED = 'Y'
	GROUP BY DIVISION
),
cte_count AS (
	SELECT DIVISION, COUNT(*) as total_amount
	FROM theft_data
	group by DIVISION
)
select cc.DIVISION, cc.total_amount, cr.amount_recovered, (cr.amount_recovered/cc.total_amount) * 100 as recovery_rate
from cte_recovered cr
join cte_count cc ON cr.DIVISION = cc.DIVISION
ORDER by recovery_rate DESC;

    
    


