WITH over_under AS (
	SELECT 
		schedule_date,
		schedule_season,
		CASE
			WHEN schedule_week = 'Wildcard' THEN 20
			WHEN schedule_week = 'Division' THEN 21
			WHEN schedule_week = 'Conference' THEN 22
			WHEN schedule_week = 'Superbowl' THEN 23
			ELSE schedule_week::INT
		END AS schedule_week_int, -- The schedule_week column is a varchar and sorts lexicographically. Created schedule_week_int to fix this. 
		schedule_week,
		team_home,
		score_home,
		score_away,
		team_away,
		score_home + score_away AS total_score,
		over_under_line,
		CASE
			WHEN score_home + score_away > over_under_line THEN 'Over'
			WHEN score_home + score_away < over_under_line THEN 'Under'
			ELSE 'Push'
		END AS result		
	FROM
		game_info
	WHERE
		over_under_line IS NOT NULL
)

SELECT
	schedule_week,
	schedule_week_int,
	result,
	COUNT(result),
	SUM(COUNT(result)) OVER(PARTITION BY schedule_week_int) AS total_games,
	ROUND(100 * COUNT(result) / SUM(COUNT(result)) OVER(PARTITION BY schedule_week_int), 1) AS percentage
FROM over_under
GROUP BY
	schedule_week_int,
	schedule_week,
	result
ORDER BY
	schedule_week_int,
	result