-- How often does the home team win the game?

WITH home_or_visitor_winner AS (
	SELECT
		score_home,
		score_away,
		CASE
			WHEN score_home > score_away THEN 'Home team wins'
			WHEN score_home < score_away THEN 'Visiting team wins'
			ELSE 'Tie game'
		END AS home_or_visitor
		
	FROM
		game_info
	WHERE
		spread_favorite IS NOT NULL AND
		team_favorite_id != 'PICK' AND
		stadium_neutral IS FALSE
)
	
SELECT
	home_or_visitor,
	COUNT(home_or_visitor),
	SUM(COUNT(home_or_visitor)) OVER() AS total_games,
	ROUND(100 * (COUNT(home_or_visitor) / SUM(COUNT(home_or_visitor)) OVER()), 1) AS percentage
FROM
	home_or_visitor_winner
GROUP BY
	home_or_visitor