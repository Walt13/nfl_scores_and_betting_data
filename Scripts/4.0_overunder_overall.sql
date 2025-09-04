WITH over_under AS (
	SELECT 
		schedule_date,
		schedule_season,
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
	result,
	COUNT(result) AS number_of_games,
	SUM(COUNT(result)) OVER() AS total_games,
	ROUND(100 * (COUNT(result) / SUM(COUNT(result)) OVER()), 1) AS percentage
FROM
	over_under
GROUP BY
	result